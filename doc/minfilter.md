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
      fns:*type{select{fndat,0}} = fndat
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

You have to be careful because x86 does funny stuff with NaNs. Not that it should have to handle them but some of the script monkeys in this place… I'll review that later.

Okay! Um do you mind if I make the fold and scans into their own generators? I just think better that way.

Go ahead. That's going to be the best way to vectorize this thing anyway. Here, let me shuffle around s0 first. End pointer's cleaner, you're right about not needing the global s. And… all yours.

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

Absolutely not, rein in the macro brain please. Or… how similar is a vector backwards scan to a forwards one? Eh, hold on to that. May be useful.

Vectors, right! We need vectors!

Not as bad as I need lunch. Let's leave this be for a minute.

---

All right, we were going to make those min filter scans SIMD?

Wait, first, I was thinking about inclusive and exclusive scans, and I found something! An exclusive scan is just an inclusive scan with an identity at the beginning and without the last result, right? For the first scan, you still have to write the initial value so it's not really better, but for the second one where you combine it with what's there, you can skip that spot! So you can make the window one longer, let me draw it out!

    #   0 1 2 3|4 5 6 7|8  (k=4)
    # 0 <-<-<-<|       in
    # 1   <-<-<|>
    # 2     <-<|>->
    # 3       <|>->->
    # 4         <-<|---|
    # 5 out       <|---|>

That's an exclusive scan? Looks like it's inclusive, just shifted… well that's what you said isn't it. So, use the full window size and cut the beginning of the second scan.

    fn minmax_filter_scan{op, T}(dst:*T, src:*T, n:ux, k:ux) : void = {
      end := dst + n - (k-1)
      while (dst < end) {
        r := ux~~(end - dst)
        m := src->(k-1)
        if (r >= k) r = k
        else m = fold{op, src+r, m, k-r}  # Last segment
        scan_rev{op, dst, src, m, r}
        scan_op{op, dst+1, src+k, src->k, r-1}
        dst += r; src += r
      }
    }

    0.94050455ns/elt at width 4, half: 47590078, end: 667920292
    0.81363809ns/elt at width 200, half: 15405690, end: 11431447

Oh no, it's worse! Look, it was 0.91 and 0.74 before! So it gets even worser for the bigger width but that doesn't make a lot of sense because there are way less windows and each one only changes by one—oh but it's moving from a window that's divisible by lots of 2s to an odd one, I mean it should all be doing scalar operations that don't really care about alignment but maybe if there's unrolling in the backend then—

Cool it. We haven't measured in a little while, why do you think the last change is what did it? Let's undo that and… yep, the latest change is an improvement at small widths.

    1.0401994ns/elt at width 4, half: 47590078, end: 667920292
    0.81073344ns/elt at width 200, half: 15405690, end: 11431447

Oh good! But uh what's happening?

I remember two changes between the last timing and here. Second one is moving the scans to macros, which isn't likely to change the timing because they expand to the same thing other than maybe a temp variable or two. And the first one is when I swapped over from the remainder amount to an end pointer, which is very suspicious, so let's undo back to there and… slower. So I posit that what happened is the compiler did some stuff.

It just… did stuff? But why, I mean is a pointer comparison worse?

Compilers do stuff all the time, it's a pretty good explanation. You spotted that the larger width changes times, but there it should be spending all the time in the scan loops—nothing about those is different at all.

Um I kind of think being unfalsifiable is the opposite of a good explanation! There has to be something about the pointers that it cares about, right? I bet it's really interesting!

Look, dig into it if you want to, but do it on your own time. If it even reproduces with your compiler version. It'll all change when we start vectorizing this anyway.

Oh, right… So do you know a good way to do that?

We have some vector scan code already, for prefix sums, let me find it… Rolling average uses it, takes the prefix sum and then differences of that based on the window size. Come to think of it, we could probably do that without putting the sum in a buffer. I remember there are problems if the window is larger than the result but something like that scan-fold-scan thing should work. Anyway, here's the scan. Along with our lovely collection of shuffle instructions courtesy of Intel.

    include 'arch/c'
    include 'skin/c'
    include 'skin/cext'
    include 'util/for'
    include 'arch/iintrinsic/basic'

    # Lane crossing permutes shuf_32 and shuf_64 are much slower
    # e.g. 3-cycle versus 1-cycle latency
    def base{b,l} = if (0==tuplen{l}) 0 else select{l,0}+b*base{b,slice{l,1}}
    def shuf_sub{I, intrin, make}{v:V, t} = V~~emit{I, intrin, I~~v, make{t}}
    def shuf_vec{I, intrin} = shuf_sub{I, intrin, vec_make{I,.}}
    def shuf_lane_8{v, t} = shuf_vec{[32]i8, '_mm256_shuffle_epi8'}{v, merge{t,t}}
    def shuf_32 = shuf_vec{[8]i32, '_mm256_permutevar8x32_epi32'}
    def shuf_lane_32 = shuf_sub{[8]i32, '_mm256_shuffle_epi32', base{4,.}}
    def shuf_64 = shuf_sub{[4]i64, '_mm256_permute4x64_epi64', base{4,.}}

    # Left shift by n bytes
    def shl_lane{x:V, n & width{V}==256} = V~~emit{[32]i8, '_mm256_bslli_epi128', [32]i8~~x, n}

    def blend{m:M, t:T, f:T} = (t & T~~m) | andnot{f, T~~m}

    # Fill each lane with its last element
    def to_lane_last{v:V} = {
      def w = width{eltype{V}}
      def k{l, b} = l-b + range{l}%b
      if (w<=16) shuf_lane_8 {v, k{16,w/8}}
      else       shuf_lane_32{v, k{4,w/32}}
    }
    # Fill entire vector with the last element
    def to_last{v:V} = {
      l := if (width{eltype{V}}<=32) to_lane_last{v} else v
      shuf_64{l, copy{4, 3}}
    }

    fn scan{T, op==(+) & hasarch{'AVX2'}}(dst:*T, src:*T, len:u64) : void = {
      def vlen = 256/width{T}
      def V = [vlen]T
      # Shift-like step: log(vlen) of these used in a scan
      def shift{v, k} = shl_lane{v, k/8}
      def shift{v, k==128} = {
        # Add end of lane 0 to entire lane 1, correcting for lanewise shifts
        def S = [8]i32; def perm = '_mm256_permute2x128_si256'
        V~~emit{S, perm, S~~to_lane_last{v}, vec_broadcast{S,0}, 16b02}
      }
      # Scan steps from width k to end
      def pre{v, k} = if (k < width{V}) pre{op{v, shift{v,k}}, 2*k} else v
      # Full scan
      def pre{v} = pre{v, width{T}}

      x := *V~~src
      r := *V~~dst
      p := vec_broadcast{V, 0}  # Accumulator
      e := len/vlen; q := len & (vlen-1)
      @for (x, r over e) {
        r = op{pre{x}, p}
        p = to_last{r}
      }
      if (q) {
        m := vec_make{V, range{vlen}} < vec_broadcast{V, T<~q}
        s := op{pre{x->e}, p}
        r <-{e} blend{m, s, r->e}
      }
    }

You're right, what a neat collection! So the ones that take vectors are shuf—or, hrm, oh, the lane crossing ones are shuffles and the others are permutes! And then for permute it says permutevar if it takes a vector and just permute for a constant. But the shuffles are all shuffles, is it an older name?

It's thoroughly insane. There's a reason we almost always use wrappers instead of calling these things directly. Exception with the permute2x128 down here, I'd tell you it won't last long but I know better than to say it.

What's lane crossing mean though?

Oh. How about you sit down. Why… why were you standing anyway?

Okay, sitting!

Lanes, right. With the 16-byte SSE registers you have operations like—let's start with shift, it'll be easier—you have a 16-byte shift that moves the entire register by a fixed number of bytes. You might think the extension to a 32-byte AVX register is to shift the whole thing too. But no, the AVX instruction splits the register into two 16-byte lanes and shifts each of *those* by 16 bytes. Which means you get zeros in the middle and there's no easy way to shift an entire register. So AVX and AVX2 are less like an instruction set and more like a two-for-one deal on SSE operations. Twice as much work as far as I'm concerned, maybe more.

So it's a more efficient design? If you get better performance just for writing more Singeli that's good! And if you don't need the tippy-top performance you could write a generator for big shifts, right?

Hardware with lanes could be more efficient. Or maybe the cross-lane stuff is just slow because designing around lanes was convenient. It's slow even in the newer processors that support AVX-512 though, and that has a more reasonable number of lane-crossing instructions.

Think twice before crossing the lane! Now how does the scan work, pre is a scan on a vector register? Oh, what a pretty recursion! So shift by the width, and then double, and quadruple, up to a whole vector.

Ugh, that took forever to work out when I wrote it.

I've seen this scan pattern, I found a nice way to visualize it once!

    #                    000a
    #                    00ab
    #          0abc     (0abc)
    # abcd -> (abcd) -> (abcd)

Okay it doesn't look as nice when you draw it out. But see, first you shift by one, then add which I just draw by stacking, then when you shift by two it's like you're shifting both parts! And at the end the first one is a, the next is a plus b, up to a plus b plus c plus d.

That looks like what happens on a lane, yeah.

Oh, the lane thing, right! So we actually have… *two* lanes, and then when those are done it says it copies the last result of one scan over, so that would look like, this? Oh it works! Although the shifted vector should really go first in case the operation isn't commutative. Also can I move the vector scan to its own generator?

    #                                          ....aaaa
    #                                          ....bbbb
    #                                          ....cccc
    #                                          ....dddd
    #                            ...a...A     (...a...A)
    #                            ..ab..AB     (..ab..AB)
    #              .abc.ABC     (.abc.ABC)    (.abc.ABC)
    # abcdABCD -> (abcdABCD) -> (abcdABCD) -> (abcdABCD)

    # Make generator to do a scan on one vector register
    def make_scan_vec{op==(+)} = {
      # Shift-like step: log(vlen) of these used in a scan
      def shift{v:V, k} = shl_lane{v, k/8}
      def shift{v:V, k==128} = {
        # Add end of lane 0 to entire lane 1, correcting for lanewise shifts
        def S = [8]i32; def perm = '_mm256_permute2x128_si256'
        V~~emit{S, perm, S~~to_lane_last{v}, vec_broadcast{S,0}, 16b02}
      }
      # Scan steps from width k to end
      def pre{v:V, k} = if (k < width{V}) pre{op{shift{v,k}, v}, 2*k} else v
      {v:V} => pre{v, width{eltype{V}}}
    }

      def pre = make_scan_vec{op}

Apparently you can. Sure, we're probably going to want to share some code with min-scan. This add-last-to-all step is pretty similar to how it works in the main loop here, where we do the scan on x and then add the carry value p.

      @for (x, r over e) {
        r = op{pre{x}, p}
        p = to_last{r}
      }

But with this one we know the value to add in before we start the scan! Can't we add it just once, before scanning x?

Bad idea. This design keeps pre{x} outside of the critical path, since that whole scan computation doesn't depend on anything before it. If you introduce the dependency, suddenly you're latency-bound, and scan latency is a *lot* lower than throughput.

Oh, that's because each step in pre is just a shift and an add, and they depend on the step bef—and the add depends on the shift, all the instructions are one long chain!

Yeah, so what the processor does for this is it starts one scan, dispatches a bunch of instructions, and then when they all stall out waiting on each other it has time to load the next vector and start scanning that.

Cool!

Now, we can't just drop min into your scan\_vec. Shifting in zeros is going to kill all our results.

Oh, right, we should shift in the identity value instead!

But the instruction we *have* shifts in zeros. Adding a bitwise or to each step isn't great. Better idea: we shuffle instead of shifting, and repeat the first value?

Oh, like this! Also, here, I can separate the shift pattern!

    #                            aaaaAAAA
    #                            ababABAB
    #              aabcAABC     (aabcAABC)
    # abcdABCD -> (abcdABCD) -> (abcdABCD)

    # Make prefix scan from op and shifter by applying the operation
    # at increasing power-of-two shifts
    def prefix_byshift{op, sh} = {
      def pre{v:V, k} = if (k < width{V}) pre{op{v, sh{v,k}}, 2*k} else v
      {v:V} => pre{v, width{eltype{V}}}
    }

    def make_scan_vec{op==(+)} = {
      def shift{v:V, k} = shl_lane{v, k/8}
      def shift{v:V, k==128} = {
        # Add end of lane 0 to entire lane 1, correcting for lanewise shifts
        def S = [8]i32; def perm = '_mm256_permute2x128_si256'
        V~~emit{S, perm, S~~to_lane_last{v}, vec_broadcast{S,0}, 16b02}
      }
      prefix_byshift{op, shift}
    }

So our shared code is down to… two lines. Although they are the hardest two. So the caller only provides a shift function. That's not awful.

The shift also doesn't depend on the operation! Or even the starting size, since you use the same shift for 4-byte or 2-byte that's already been shifted once or 1-byte that—wait, the last shift for 16-byte does, but to\_lane\_last reads it from the argument so you don't see it.

So, what's that mean, you can even define it on the outside?

    def shift_zero{v:V, k} = shl_lane{v, k/8}
    def shift_zero{v:V, k==128} = {
      # Add end of lane 0 to entire lane 1, correcting for lanewise shifts
      def S = [8]i32; def perm = '_mm256_permute2x128_si256'
      V~~emit{S, perm, S~~to_lane_last{v}, vec_broadcast{S,0}, 16b02}
    }
    def make_scan_vec{op==(+)} = prefix_byshift{op, shift_zero}

Trippy. Clearer to keep it all bundled together though, that shift\_zero thing is not a generally usable macro.

Okay I tweaked the prefix generator a little and here's an interpreted min scan! I took your strategy for shift, so it takes a slice of the first k numbers and shifts them into the original list instead of zeros!

    include 'util/tup'
    include 'skin/c'
    def prefix_byshift{op, sh} = {
      def pre{v, k} = if (k < tuplen{v}) pre{op{v, sh{v,k}}, 2*k} else v
      {v} => pre{v, 1}
    }
    def shift{v,k} = shiftright{slice{v,0,k}, v}
    def min_scan = prefix_byshift{__min, shift}
    show{min_scan{show{tup{9,4,5,3,6,6,0,1}}}}
    #tup{9,4,5,3,6,6,0,1}
    #tup{9,4,4,3,3,3,0,0}

Macros again, this shiftright is a tuple thing? Like an align instruction, I see. And it's a Singeli right shift but an x86 left shift because the x86 instructions are named after big-endian ordering. Hate that.

And when we want to go backwards we shift left but take from the end, something like… this, perfect!

    def shift{v,k} = shiftleft{v, slice{v,-k}}
    show{min_scan{show{reverse{tup{9,4,5,3,6,6,0,1}}}}}
    #tup{1,0,6,6,3,5,4,9}
    #tup{0,0,3,3,3,4,4,9}

Hold on, we don't have instructions for any of this. The shuffle instructions take indices, not shifts.

Okay sure!

    def shift_ind{k,l} = shiftright{range{k},range{l}}
    def shift{v,k} = select{v, shift_ind{k,tuplen{v}}}

Oh, uh, yeah, that works. So I take the plus scan thing and replace the shift with a shuffle? May as well do a dedicated 32-bit one too, probably not any faster but it won't waste a register. Then for the last step… maybe not the most elegant way but using the un-permuted vector instead of zeros works.

    def make_scan_idem{T, op} = {
      def shift_ind{k,l} = shiftright{range{k},range{l}}
      def shift{v:V, k        } = shuf_lane_8 {v, shift_ind{k/8,16}}
      def shift{v:V, k & k>=32} = shuf_lane_32{v, shift_ind{k/32,4}}
      def shift{v:V, k & k==128} = {
        def S = [8]i32; def perm = '_mm256_permute2x128_si256'
        V~~emit{S, perm, S~~to_lane_last{v}, v, 16b02}
      }
      prefix_byshift{op, shift}
    }

Great! And then the outer loop is the same?

Yeah, let's just copy that body for now, and we change pre, and initializer's passed in instead of always being zero. Done.

And this is the scan\_op version, so we need to combine with the existing values!

Right.

    # Assumes op is __min or __max
    def scan_op{op, dst:*T, src:*T, init:T, len & hasarch{'AVX2'}} = {
      def vlen = 256/width{T}
      def V = [vlen]T
      def pre = make_scan_idem{T, op}
      x := *V~~src
      r := *V~~dst
      p := vec_broadcast{V, init}  # Accumulator
      e := len/vlen; q := len & (vlen-1)
      @for (x, r over e) {
        r = op{r, op{pre{x}, p}}
        p = to_last{r}
      }
      if (q) {
        m := vec_make{V, range{vlen}} < vec_broadcast{V, T<~q}
        re:= r->e
        s := op{pre{x->e}, p}
        r <-{e} blend{m, op{re, s}, re}
      }
    }

    1.7209255ns/elt at width 4, half: 47590078, end: 667920292
    0.48559672ns/elt at width 200, half: 15405690, end: 11431447

That's just one of the scans replaced, fair amount of improvement on the larger window.

But the width 4 was under a nanosecond before!

Vector loops tend to be slower to start up. We've got some length arithmetic and a masked write here, doesn't take much to push it above—well, I was surprised the scalar version was that quick for that matter. If we have to we can test the length and switch over to the scalar scan if it's short.

I didn't ask about that last step! Isn't there a partial store thing? I think I've heard of that.

For 4-byte and 8-byte types, yeah. Our prefix sums are pretty long so I didn't optimize here, just used what would work on all types. And there can be some hardware issues with maskstore. The blend's predictable.

Oh okay! So the idea is we have the range—that's the index, so where the index is less than q we set the mask to true. And for those first q ones it's the scan result, and for the rest it's the same thing that was already there! So q is the number of numbers we still have to fill in?

Yeah, you have the definition up here with a mask. It's a pretty common pattern, number of full vectors e and the remainder q.

But the last step does write over the end, right? Even though it doesn't change anything.

We manage the allocations so there's space for it. It's pretty cheap, since it doesn't matter what's after the destination array as long as we can write to it.
