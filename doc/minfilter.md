# Purity and Ford write a min filter

Hi [Ford](compiler.md)! Can I come in?

Yeah. Hi, uh, what was it?

I'm [Purity](interpreter.md)!

Purity, yeah. What is it?

Okay, boss man said I should come to you about this minimum filter thing since you're all senior and I'm, um,

Newborn?

Exactly! Wet around the ears, right? So we have this windowed minimum thing that's taking some time in at least one of our benchmarks, and I remembered I read this [blog post](https://iabdb.me/2021/05/28/idempotent-moving-window-is-simply-a-reduction/) when I was looking at K stuff and it has an array way to do it that I think should be faster!

All right, slow down. What are we doing now, the queue thing with the ascending sequence? Let me pull that up actually. It's linear time.

So is this one! You split up the array and do scans, and each number is only in one forwards one and one backwards one!

Hm. Yeah, I never liked how branchy the queue management was. That could work if it's like you're saying. Here's the current one. Let's go through that first.

    include 'arch/c'
    include 'skin/c'
    include 'skin/cext'
    include 'clib/malloc'
    include 'util/for'; def for_rev = for_backwards
    def ux = primtype{'u', width{*void}}

    # Min or max of all length-k windows from src
    fn minmax_filter{op, T}(dst:*T, src:*T, n:ux, k:ux) : void = {
      def lt = if (is{op, __min}) __lt else __gt
      def le = if (is{op, __min}) __le else __ge
      # Cyclic queue
      # Contains values smaller than all later ones seen so far
      vals := alloc{T, k}
      inds := alloc{ux, k}
      tail := k - 1  # Last used value
      head := tail   # First used
      def store_queue{q, v, i} = { vals <-{q} v; inds <-{q} i }
      # Fill backwards starting at k
      vh := src->tail  # Tracks vals->head
      store_queue{head, vh, tail}
      @for_rev (src over i to tail) {
        if (lt{src, vh}) {
          --head
          store_queue{head, vh = src, i}
        }
      }
      # Cyclic increment and decrement
      def inc{i} = { ++i; if (i == k) i = 0 }
      def dec{i} = { if (i == 0) i = k; --i }
      # Output results while maintaining queue
      @for (src, dst in dst-k over i from k to n) {
        dst = vals->head
        # Remove head when it's out of the window
        if (inds->head == i-k) inc{head}
        # Remove entries equal to src or larger
        if (le{src, vals->head}) {
          # Jump ahead; now next loop can be unguarded
          tail = head
        } else {
          while (le{src, vals->tail}) dec{tail}
          inc{tail}
        }
        # Add new entry
        store_queue{tail, src, i}
      }
      dst <-{n-k} vals->head
      free{vals}; free{inds}
    }

Yep, I looked at it a little! I didn't work out all the queue stuff but I saw there's at least a branch for every output. And the top of the queue is always the last input so the loop starts by comparing one number to the one before, not very predictable!

True enough. You could call it an algorithm for a simpler processor. The important thing is that every iteration of that while loop drops a value permanently, so the most it can run is once for every input.

Oh cool! That's a lot easier than I thought. And if it always goes up the while loop never starts and if it always goes down you skip and don't go into—why is it `le` instead of just comparing?

You can also do a max filter with it, so it compares in the opposite direction. Take a look at the definitions at the top.

Oops, I remember now! There's two of them?

You have to keep the last equal value to get the right result, which is different going forwards and backwards, and I'm not about to subject myself to some "not lt" garbage even if I have to write the test twice. And the test hurts to look at.

Hm, if you used match there you'd know op can only be two things!

I never use that, so much typing.

Well you could also combine the two lines with a tuple! Let's see, something like…

      def {lt, le} = match (op) {
        {(__min)} => tup{__lt,__le}
        {(__max)} => tup{__gt,__ge}
      }

Match is still useless. All you've got is:

      def {lt, le} = if (is{op, __min}) tup{__lt,__le} else tup{__gt,__ge}

and I don't like those tuples everywhere… workable though I guess. Anyway, you're right, this doesn't seem that fast looking at it now. What's your idea?

Here, I wrote up a little prototype!

    #   0 1 2 3|4 5 6 7|8 9  (k=5)
    # 0 <-<-<-<|>        in
    # 1   <-<-<|>->
    # 2     <-<|>->->
    # 3       <|>->->->
    # 4         <-<-<-<|>
    # 5 out       <-<-<|>->

    include 'skin/c'
    include 'util/tup'
    def scan_filter{op, list, k} = {
      def scanr{op, l} = reverse{scan{op, reverse{l}}}
      def segments = split{k - 1, list}
      def left_part = join{each{scanr{op, .}, slice{segments, 0, -1}}}
      def right_part = join{each{scan{op, .}, slice{segments, 1}}}
      op{slice{left_part, 0, tuplen{right_part}}, right_part}
    }

ASCII art, very fancy. What's the rest, some sort of pseudocode thing written like Singeli macros?

It's real code! You run it with the interpreter, here!

    show{scan_filter{__min, tup{1,2,3,4,5,6,5,4,3,2,1}, 4}}
    #tup{1,2,3,4,4,3,2,1}

It's—okay, window of four so if you go in the middle you hit 4 to 5 and then 5 to 4—you mean you wrote one big macro that goes through the whole algorithm?

A generator, yes! See, here you've got every segment but the last and it does a scan backwards on each one, and then every one but the first and it does forward scans!

Hold on, hold on. I've used this tup thing for like… copy, a few times. We define a backwards scan, all right, that I can figure out. What's split?

It just takes the list and chops it up! So you get segments of length k - 1. See, I marked them off with bars in the diagram, k is 5 so the segments are four numbers. With a shorter leftover at the end!

Stand-in for some pointer arithmetic I guess. All right, then you do the scan on each segment, well leaving off the last and the first like you said… yeah, and join's obvious enough, undoes the split…

A scan always leaves the length the same so it's like if you cut off the first or last segment off without splitting!

Sure, so you—oh this is all just a weird way to write some segmented scans isn't it. Okay, and there's this offset built in so you'll combine the backwards scan with the forwards scan on the *next* segment, like in the diagram… now what's this last line?

Oh, it's pretty much what you said, but it has to trim the left part! See, you cut off a whole segment on the right but only part of one on the left, so the lengths might be off. Snip snip, now they're the same length!

Thanks, the interpretive hand gestures are really essential. Can't you cut before you waste time on a scan?

No actually! I mean first it's messy but also… see the backwards part of the scan here, like row 4? It has all four numbers from that segment. But if I cut it off then the backwards scan starts at column 5 since that's how long the output is and then—these ones get left out!

    #   0 1 2 3|4 5 6 7|8 9  (k=5)
    # 0 <-<-<-<|>        in
    # 1   <-<-<|>->
    # 2     <-<|>->->
    # 3       <|>->->->
    # 4         <-<????|>
    # 5 out       <????|>->

Okay, I think I get the structure here. So output 0 is the first entry of a reverse scan, which is the min of a whole segment, and the first entry of a forwards scan, which is just that value. And then you put them together and get the min of a segment plus one. So that's why k - 1 is the segment size?

You got it, good job! It's because it's two inclusive scans there's sort of an extra one in there. Actually if you use one of the big long scans with an identity so it's like inclusive and exclusive together then you can use the window size like it is. They're my favorite kind of scan even though they're so underappreciated!

Sarah McLachlan must be thrilled you're supporting those poor scans I've never heard of. Inclusive is easy so let's stick with that. You know, a step in a scalar scan is still a lot faster than a missed branch. This might be good even before we slap the AVX stuff on it. Damn, it really is short.

Oh, I was going to ask! How do you test performance when you're writing these functions? The full benchmarks are kind of slow.

I probably still have the file I used for this one, one sec… this looks like it. Ignore that clock thing, ugliest code I've ever seen. I get that they have tuples but the Singeli guys really have to find *something* for struct interop.

    require{'string.h', 'time.h', 'stddef.h'}
    def rand{} = emit{i32, 'rand'}
    fn clock() : u64 = {  # time in nanoseconds
      ts:*u8 = undefined{u8, 16} # struct timespec
      emit{void, 'clock_gettime', 'CLOCK_MONOTONIC', *void~~ts}
      ti:*u64 = tup{0,0}
      emit{void, 'memcpy', ti  , ts, 'sizeof(time_t)'}
      emit{void, 'memcpy', ti+1, ts+emit{u64,'offsetof','struct timespec','tv_nsec'}, 8}
      1e9*ti->0 + ti->1
    }

    include 'debug/printf'
    main() : void = {
      def fndat = tup{minmax_filter{__min, i32}}
      fns:*type{tupsel{0,fndat}} = fndat
      def len = 1e4
      def iter = 1e4
      src := alloc{i32, len}; @for (src over len) src = rand{}
      dst := alloc{i32, len}
      def test{k} = @for (filt in fns over tuplen{fndat}) {
        t := clock()
        @for (iter) filt(dst, src, len, k)
        d := clock() - t
        lprintf{f32<~d/(iter*len), 'ns/elt at width ', k,
                ', half: ', dst->(len/2), ', end: ', dst->(len-k)}
      }
      test{4}
      test{200}
      free{src}; free{dst}
    }

Oh neat! Wow, huh. Ooh. It's copying the parts into an integer array so it can use them—is time\_t not a known width?

Don't tell her not to look at something if you don't want her to look at it, got it. Anyway, stick this at the bottom of the file and we can get some timings.

    $ singeli min.singeli -o /tmp/m.c && gcc -O3 -march=native /tmp/m.c && ./a.out 
    3.3737676ns/elt at width 4, half: 47590078, end: 667920292
    4.2123556ns/elt at width 200, half: 15405690, end: 11431447

Larger width has smaller results, works for a sanity check. Inlining gets kind of nasty when you have static functions like Singeli generates and it can change your timings. I used a function array here which seems good enough to stop that.

Works for me! Oh, how about another quick test! Let's put this in main…

      def dat = tup{1,5,2,9,9,2,3,4,5,1,0,1,2,6}
      def l = tuplen{dat}
      def T = f32; def k = 4
      x:*T = dat
      y := undefined{T, l}
      minmax_filter{__min,T}(y, x, l, k)
      lprintf{
        fold{&, each{==,
          scan_filter{__min, dat, k},
          each{load{y,.}, range{l+1-k}}
        }}
      }

and run, and now it prints 1 to say they're the same, perfect!

But it's a macro, you can't… what, each-load… so it macros the thing to get these hard-coded constants, and then it runs the real version, and then it generates code for every value to load it and compare it to the hard-coded constant, and then somehow? Never mind, it works, whatever. Starting the compiled version soon and then we'll be back to for loops.

I use this a lot, it's a good way to make sure your interpreted version matches up with the optimized one! It's like a dot product, see, you compare two vectors one by one and check if they're all true. And equals casts interpreter numbers to compare to the runtime ones from load so it's all good!

Here's what I have for the filter, only doing the full segments for now. Reverse scan the segment that has the same index as the destination, then forward scan the next one combining the results with what we just wrote. The last scan had that full length scan though. Do we really need to allocate a buffer for it?

    fn minmax_filter_scan{op, T}(dst:*T, src:*T, n:ux, k:ux) : void = {
      s := k - 1 # length of scans
      @for (n/s - 1) { # TODO last segment
        m := src->(s-1)
        @for_rev (dst, src over s) dst = m = op{m, src}
        m = src->s
        @for (dst, src in src+s over s) dst = op{dst, m = op{m, src}}
        dst += s; src += s
      }
    }

I thought about this! If you do a scan but you don't write the first results, it's the same as a scan combined with a fold! Or an initialized scan which is a whole different structure but it's still all associative reordering. There's this cool symmetry where you can put the fold with either side because now instead of cutting it into two scans you do a scan, fold, scan, and then the fold goes with either one, associativity again! Except you can't put the fold last without commutativity.

    #   0 1 2 3|4 5 6 7|8 9  (k=5)
    # 0 <-<-<-<|>        in
    # 1   <-<-<|>->
    # 2     <-<|>->->
    # 3       <|>->->->
    # 4         <-<|---|>
    # 5 out       <|---|>->

Enough tuple macros and you can drag a thousand words out of any picture, huh. All right, the last segment can have a short length, and that's the scan length except you keep the source pointers separated by the full length and do that reduction.

    def __min{a:T, b:T} = { m:=a; if (b<a) m=b; m }
    def __max{a:T, b:T} = { m:=a; if (b>a) m=b; m }

    fn minmax_filter_scan{op, T}(dst:*T, src:*T, n:ux, k:ux) : void = {
      s := k - 1 # length of scans
      r := n - s # writes remaining
      while (r > 0) {
        m := src->(s-1)
        s0:= s
        if (r < s) {
          @for (src over _ from r to s) m = op{m, src}
          s = r
        }
        @for_rev (dst, src over s) dst = m = op{m, src}
        m = src->s
        @for (dst, src in src+s0 over s) dst = op{dst, m = op{m, src}}
        dst += s; src += s; r -= s
      }
    }

    0.91985679ns/elt at width 4, half: 47590078, end: 667920292
    0.74396759ns/elt at width 200, half: 15405690, end: 11431447

*Five* times faster, all right then.

You typed it so fast too! I think I can follow it, the variables keep changing though. So s starts out as the segment length but then when it's too long you change it to the… oh, it's the length of the scan and s0 is the segment! And m is the accumulator, it goes through the… this one doesn't write anything so it's a fold, and only sometimes, then this one is backwards and a scan, then this one is a scan and an operation!

Yep, all straightened out I think.

No I'm still working through it! Okay, you write after setting m so it's an inclusive scan—no, it's because you do the operation before you write. So interesting seeing the assignments in the middle of the line, you can't do that with definitions!

Yeah, I usually split them up eventually. Just banging it out here.

And if you change the scan length, that implies it was more than r but now it's equal to r so then you subtract it and r is zero and you stop. And if s is more than r when you subtract well that can't happen because the if statement would have—well it creates an invariant that s is at most r.

The scan length's k - 1 except on the last iteration where you might lower it. Stop complicating things.

It's a little spooky is all, with the variable and the loop! And then when you finish it what's s, I mean you don't need it again but what if you did?

How do you *breathe*?

Oh nooooooooo you got me thinking about it it's going to feel so weird for like an hour! Haha, got me good! Okay, okay, there's also the operation ordering. The backwards scan has m on the left but it's scanning from the right so it's kind of supposed to be the other way around, like if you have something that associates but doesn't commute.

What even does that?

Um well all the scalar stuff is both really so you have… oh, permutation! And matrix products of course.

Of course.

And for the initializer you take the first value of the scan, or fold maybe, which I guess works for min and max since they're idempotent but even for addition you add it in twice. Idem… POTENT! So I like to pass in the identity value as a parameter.

You have to be careful because x86 does funny stuff with NaNs. I'll review that later.

Okay! Um do you mind if I make the fold and scans into their own generators? I just think better that way.

Go ahead. That's going to be the best way to vectorize this anyway. Here, let me shuffle around the s0 thing first. End pointer's cleaner, you're right about not needing the global s.

    def fold{op, src:*T, init:T, len} = {
      a := init
      @for (src over len) a = op{a, src}
      a
    }

    # Reverse scan
    def scan_rev{op, dst:*T, src:*T, init:T, len} = {
      a := init
      @for_rev (dst, src over len) {
        a = op{src, a}
        dst = a
      }
    }

    # Forwards scan combined with existing values
    def scan_op{op, dst:*T, src:*T, init:T, len} = {
      a := init
      @for (dst, src over len) {
        a = op{a, src}
        dst = op{dst, a}
      }
    }

    fn minmax_filter_scan{op, T}(dst:*T, src:*T, n:ux, k:ux) : void = {
      s := k - 1
      end := dst + n - s
      while (dst < end) {
        r := ux~~(end - dst)
        m := src->(s-1)
        if (r >= s) r = s
        else m = fold{op, src+r, m, s-r}  # Last segment
        scan_rev{op, dst, src, m, r}
        scan_op{op, dst, src+s, src->s, r}
        dst += r; src += r
      }
    }

There… we… go! Oh, we could maybe put the two scans together with some functional programming. Pass in the for loop, and we write with either the operation or the identity, and then the reverse one can flip the operator too, look!

    def scan_any{for, combine, op}{dst:*T, src:*T, init:T, len} = {
      a := init
      @for (dst, src over len) {
        a = op{src, a}
        dst = combine{dst, a}
      }
    }
    def scan_rev{op} = scan_any{for_rev, {_,a}=>a, {a,b}=>op{b,a}}
    def scan_op {op} = scan_any{for    , op      , op}

Absolutely not, reign in the macro brain please. Or… how similar is a vector backwards scan to a forwards one? Eh, hold on to that. May be useful.

Vectors, right! We need vectors!

Not as bad as we need lunch. Let's leave this be for a minute.
