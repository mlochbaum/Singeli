# Listing all permutations

Hey I found a way to list all the permutations in lexicographically increasing order, at billions of permutations per second! No, I don't know what it's "useful for", don't ask me questions like that!

Okay, we're going to start off with an old old algorithm that Roger Hui was using [in 1979](https://dl.acm.org/doi/10.1145/602312.602317)! There are articles explaining it in [APL](https://www.jsoftware.com/papers/50/50_19.htm), [J](https://code.jsoftware.com/wiki/Doc/Articles/Play202) and [BQN](https://saltysylvi.github.io/blog/BQNcrate-permutations.html), what about Singeli though?

The big idea is that we're going to break each permutation down into one part that just moves one index to the start, then another that leaves the first index alone. Here's an implementation, it's pretty short!

    include 'skin/c'
    include 'util/tup'

    def all_perms{k} = {
      def fixzero = each{merge{0, .}, 1 + all_perms{k - 1}}
      def ik = iota{k}
      def pick{i} = merge{i, indices{ik != i}}
      def startwith{i} = select{pick{i}, fixzero}
      join{each{startwith, ik}}
    }
    def all_perms{0} = tup{tup{}}

It's a recursive implementation, so we start by getting all the permutations on size `k - 1`. But we have to apply this to size `k` by ignoring the first element, so we put a zero in front and add one to the rest. Let's say, for a permutation `tup{3,2,1,0}` that reverses four things, we want `merge{0, 1 + tup{3,2,1,0}}` which is `tup{0,4,3,2,1}`! And I want to do this to every permutation which is `each{{p} => merge{0, 1 + p}, all_perms{k - 1}}`, but `+` works on lists so that's the same as `each{{p} => merge{0, p}, 1 + all_perms{k - 1}}` or…

      def fixzero = each{merge{0, .}, 1 + all_perms{k - 1}}

That's all the permutations of size `k` that start with `0`! If we list all the permutations then these will come first, then the ones that start with `1`, then the ones that start with `2`, and so on. So we want to map over all the starting values `iota{k}`, then join those together, that's what `join{each{startwith, ik}}` does!

`startwith{i}` has two steps. First we make the earliest permutation that starts with `i`, like for `k = 5` and `i = 3` it would be `tup{3,0,1,2,4}`! It starts with `i`, obviously, and then `indices{ik != i}` is the rest. In our example, `ik != i` is `tup{0,1,2,3,4} != 3`, which is `tup{1,1,1,0,1}`, there's a `1` at each index we need, see? And `indices` is the tuple utility that includes an index wherever it's `1`, perfect! All right, once we have this permutation `pick{i}`, we need to compose it with every permutation in `fixzero`, which is `select{pick{i}, fixzero}`. What, no `each`? It's part of `select{}`! It only makes sense for the index in `select` to be a number, so if you use a list for the index, it automatically `each`-es over it! A lot like arithmetic.

But I know you're asking why why why does `select` compose two permutations! Well, part of it is that it breaks down the second permutation into numbers for the indices, so it's even doing _two_ `each`es for us. The other part is that `select{list, perm}` applies a permutation to a list of values, but applying one permutation to another is the same as composing them! So if you have maybe `def bugs = tup{'moth','beetle','ant','cricket'}` and `def perm = tup{3,1,0,2}`, then `select{bugs, perm}` is `tup{'cricket','beetle','moth','ant'}`, which we could say is rearranging `bugs` by `perm` to put bug 3 in the first spot then but 1 and so on. But we can also say it's doing a substitution based on `bugs` in `perm`, that replaces `0` with `'moth'` and `1` with `'beetle'` and so on! If you apply two permutations with `select{select{bugs, perm_a}, perm_b}`, we could say you're substituting `perm_a` using `bugs`, then rearranging it by `perm_b`. But it doesn't matter if we substitute first and rearrange second, or do them the other way, if you turn `0` into `'moth'` and then move it somewhere or move it and uh metamorphose it you still have `'moth'` at wherever you put it. So `select{bugs, select{perm_a, perm_b}}` is the same thing, basically `select` on lists is associative! And `select{perm_a, perm_b}` is a permutation, specifically the one that applies `perm_a` then `perm_b`!

This also gives us a good way to think about `select{pick{i}, fixzero}` as a single operation! We're going to take the permutation `pick{i}` and use it as a substitution. So whenever we see `0` in `fixzero`—that's easy, it's just the first number in every permutation—we turn it into `i`, and the numbers `i` and above stay the same, but the ones between `0` and `i` go down by one.

Okay let's run `each{show,all_perms{3}}` to make sure it works…

    tup{0,1,2}
    tup{0,2,1}
    tup{1,0,2}
    tup{1,2,0}
    tup{2,0,1}
    tup{2,1,0}

Looks good! But to be sure I want to write a quick test for permutation properties. If a list has length `l` and contains every index `iota{l}` it has to be a permutation, and if each one is lexicographically after the one before they can't repeat, so if we have `l` factorial of them then that has to be all the permutations in order! To check that values are what I expect, I make cases that only match when the expectations hold. Then Singeli says useful information about what didn't work in the error a lot of the time! For type checking I use `{...p}` since it's just like `p` except it has to be a tuple.

    def fact = match { {0} => 1; {n} => n * fact{n - 1} }

    def assert_eq{a,a} = 1

    def test_perms{ps={{...p0},..._}} = {
      # Right length
      def l = length{p0}
      assert_eq{fact{l}, length{ps}}

      # Each one contains every value in iota{l} once
      def assert_perm{{...p} if length{p} == l} = {
        assert_eq{count_matches{p, iota{l}}, copy{l,1}}
      }
      each{assert_perm, ps}

      # And each one sorts strictly after the one before
      def assert_precedes = match {
        {{a,...as}, {a,...bs}} => assert_precedes{as, bs}
        {{a,..._ }, {b,..._ } if a < b} => 1
      }
      each{assert_precedes, slice{ps,0,-1}, slice{ps,1}}
    }
    test_perms{all_perms{5}}  # No errors!

Also, how fast is it? I ran `show{length{join{all_perms{9}}}}` because it was the biggest one that didn't take super long. It says 3,265,920 total indices, and from `time` it finished in 0m1.292s, and `1.292e9 / 3265920` is 396 nanoseconds per index! That's pretty fast for the Singeli interpreter, making a million numbers is usually way too slow! It's because we have `select` doing all the work, and it's a Singeli builtin. But AVX2 builtins are a lot faster than Singeli ones, could compiling be… ten thousand times faster???

## Fixing the width

But I'm not ready to jump in and start compiling things! The `each{merge{0, .}, …}` thing wouldn't be that fast, and it turns out there's a better way! Instead of making permutations for a smaller width, we'll make permutations on the whole width `k` that only rearrange the last `j` elements, and increase `j` up from `0` to `k`. The recursive step's trivial now, `all_perms{k, j - 1}` is exactly what we want! But we have to do more work than the old `startwith{}`. We don't want a permutation that starts with `i` any more, we want one where the _last `j` numbers_ start with `i`. So, we define a `widen` function to add `k - j` not-changing places at the start.

    def all_perms{k, j} = {
      def fix_d = all_perms{k, j - 1}
      def d = k - j
      def widen{p} = merge{iota{d}, d + p}
      def ij = iota{j}
      def pick{i} = merge{i, indices{ij != i}}
      def with_d{i} = select{widen{pick{i}}, fix_d}
      join{each{with_d, ij}}
    }
    def all_perms{k, 0} = tup{iota{k}}
    def all_perms{k} = all_perms{k, k}

This passes the tests, and it's faster too, with 0m0.825s or 253 nanoseconds per index for `all_perms{9}`. Now the slow part is only a `select` which I know will be a fast loop with shuffle instructions, but `indices` would be a little complicated to write so I want to take a look at that part. Let's make all the permutations `widen{pick{i}}` for `k = 6`, `j = 4` for example!

    def {k, j} = tup{6, 4}
    def d = k - j
    def move_d = {
      def id = iota{j}
      def widen{p} = merge{iota{d}, d + p}
      def pick{i} = merge{i, indices{id != i}}
      each{{i} => widen{pick{i}}, id}
    }
    each{show, move_d}

So that prints out:

    tup{0,1,2,3,4,5}
    tup{0,1,3,2,4,5}
    tup{0,1,4,2,3,5}
    tup{0,1,5,2,3,4}

You can see the first two numbers stay the same, the next one changes every time, and the ones after that mostly stay the same. This looks to me like taking pairwise differences might be useful!

    each{show, slice{move_d, 1} - slice{move_d, 0, -1}}

    # Output:
    tup{0,0,1,-1,0,0}
    tup{0,0,1,0,-1,0}
    tup{0,0,1,0,0,-1}

Now it's a lot easier to generate! For the `1`s I'll use `iota{k} == d`, which is `tup{0,0,1,0,0,0}` right now, and then for the `-1`s I'll shift it over by one at each row! I did this with a scan that ignores its second argument, so it only depends on the first row and the total number of rows.

    def start = copy{j, iota{k} == d}
    def end = scan{{l,_} => shiftright{0, l}, start}
    each{show, start - end}

    # Output:
    tup{0,0,0,0,0,0}
    tup{0,0,1,-1,0,0}
    tup{0,0,1,0,-1,0}
    tup{0,0,1,0,0,-1}

And then `scan{+, iota{k}, start - end}` gives us the permutations `move_d`! By the way, `table{==, slice{i,d}, i}` was my first thought for making `end`, but shifting will be a little less steps in AVX2. So our new SIMD-ready implementation is:

    def all_perms{k, j} = {
      def fix_d = all_perms{k, j - 1}
      def d = k - j
      def start = copy{j, iota{k} == d}
      def end = scan{{l,_} => shiftright{0, l}, start}
      def diffs = start - end
      def move_d = scan{+, iota{k}, diffs}
      join{each{select{., fix_d}, move_d}}
    }
    def all_perms{k, 0} = tup{iota{k}}
    def all_perms{k} = all_perms{k, k}

## Compiling with AVX2

Okay we're all set! My compiled code is going to be a lot like the latest definition, but I'm unrolling the recursion into a `@for` loop. The bounds are a little weird, maybe you could put `show{k}` in `all_perms` to check them if you wanted, but the idea is that `j = 1` is the base case and then it has to end on `k` but `@for` is an exclusive range so we use `k + 1` for the endpoint! We've been doing `j = 0` for a base case before, but the first step doesn't actually do anything, I mean you can't rearrange the last one element any other way than it is, so we may as well start at two! One more thing to notice, the first permutation in `move_d` is always the identity, which means… I don't have to apply it! Each step in the recursion starts with a full copy of the step before's result. So instead of allocating bigger and bigger arrays, I'm going to start by putting the identity permutation into the result as the base case, and keep extending it until the result is all filled up.

    include 'skin/c'
    include 'skin/cext'
    include 'arch/c'
    include 'util/for'
    include 'arch/iintrinsic/basic'
    include 'arch/iintrinsic/select'

    def vl = 32; def V = [vl]u8  # AVX2-sized

    fn genperms(dst:*u8, k:u8) : void = {
      if (k == 0) return{}
      vi := vec_make{V, range{vl} % 16} # Identity permutation
      dv := *V~~dst
      store{dv, 0, vi}
      next := dst + k    # Pointer to unfinished part
      start := vi == vec_broadcast{V, k - 1}
      # Multiply size by j each iteration
      @for (j from 2 to k + 1) {
        start = vec_shift_left_128{start, 1}
        end := start
        move_d := vi
        l := next - dst
        @for (_ from 1 to j) {
          end = vec_shift_right_128{end, 1}
          move_d -= start - end
          def sel = vec_shuffle{16, move_d, .}
          @for (v in *V~~next, dv over (l + vl-1)/vl) v = sel{dv}
          next += l
        }
      }
    }

Too bad to see the scans turn into mutation but that's how it goes. For `select` we have `vec_shuffle{16, ...}` from iintrinsic/select, and I guess I've gotta point out that this function is only good for `k` up to 16! Haha, regular 16, not 16 factorial! But `16 * fact{16}}` is `0x0001307777580000` bytes and you know it's a pretty big number when Singeli starts writing it as hex, so this is probably good for practical purposes, if they exist that is! Well, I just checked and `(16 * fact{16}) / fold{*, copy{4*3, 10}}` is 335 terabytes so it's not like impossible but that's a lot of hard drives, anyway `16` _is_ covered, it's 17 that doesn't work and that's 6 whole petabytes!

But yeah, the reason we're stuck at 16 even though AVX2 does 32-byte vectors is that it selects in lanes, so it breaks the vectors in half and does one selection on one half and another—well, think of it like an `each` that maps over two sets of lanes really! I started with AVX2 since Ford says I have to get more comfortable with lanes, except because I don't handle `k > 16` there's not much to do really! I just make sure the two halves of `move_d` are the same, so when I run `sel{dv}` it does the same thing to every number in `dv`. One thing is I use `vec_shift_left_128` and `vec_shift_right_128` for the AVX2 versions of `shiftleft` and `shiftright`. The `128` means they work on 128-bit lanes!

Look out for `(l + vl-1)/vl`, that's a ceiling division! We want to write `l` total indices, but maybe that's not an even multiple of `vl`, so we have to round up. And that means `dst` might need to be allocated with some extra space in case `l` rounds up on the last step. Although for `k = 9` that would be `9 * fact{8}`, which is a multiple of 32 so that's all good! On that note here's how you can make `genperms` run from the command line:

    fn test_perms(perm:*u8, k:u8, fact:u64) : u1 = {
      kw := u64^~k
      def assert{cond} = if (not cond) return{0}
      @for (i to fact * kw) assert{perm->i < k}

      def assert_sorted{a, b} = {
        j:u8 = 0
        while (a->j == b->j) { ++j; assert{j < k} }
        assert{a->j < b->j}
      }
      @for (i to fact - 1) {
        assert_sorted{perm + i * kw, perm + (i + 1) * kw}
      }
      1
    }

    include 'debug/printf'
    include 'clib/malloc'
    main(argc, argv) : i32 = {
      def arg_i32{i} = emit{i32, 'atoi', load{argv, i}}
      # Size of permutations
      kl := arg_i32{1}
      if (kl > 16) { lprintf{'Too long!'}; return{-1} }
      k := u8<~kl; kw:=u64^~k
      # Number of iterations, for timing
      iter:i32 = 1; if (argc > 2) iter = arg_i32{2}

      # Generate fact permutations, totalling size bytes
      fact:u64 = 1; @for (f from 1 to kw+1) fact *= f
      size := fact * kw
      # Last iteration is size/kw == fact bytes
      dst := alloc{u8, size + (-fact)%vl}
      @for (iter) genperms(dst, k)

      # Always have to check something to force it to run!
      passed:u1 = load{dst, size - 1} == 0
      if (argc <= 2 and not test_perms(dst, k, fact)) passed = 0
      if (not passed) lprintf{'Error!'}
      free{dst}
      0
    }

I'm compiling with `gcc -O3 -march=native`, and just `./a.out 9` finishes instantly so I added an `iter` argument to make it run more than once. And I have a tester but it's slower than generating the permutations so it only runs if you don't set `iter`! Now `$ time ./a.out 9 10000` shows `0m0.848s` which is 0.026 nanoseconds per index, that's right, only 26 picoseconds! So it's 10,000 times faster than my first timing of 396ns in Singeli, but just barely short for the best time of 253ns!

But also there's a huge drop off when I go from 9 to 10, over a factor of 3! But there's not anything we could do about that, is there? It's just dropping out of cache into main memory, right, since I don't have the 36MB of cache I'd need? Well, sort of! The shuffle instructions use one argument from a register, one argument from memory, and get written to memory. The result has to go into uncached memory unless I change the format, but the second argument loops over a pretty big region. It turns out we can make it smaller to keep those accesses to the L1 cache and get a speed boost!

## Permutation association

Here was our last implementation of `all_perms`!

    def all_perms{k, j} = {
      def fix_d = all_perms{k, j - 1}
      def d = k - j
      def start = copy{j, iota{k} == d}
      def end = scan{{l,_} => shiftright{0, l}, start}
      def diffs = start - end
      def move_d = scan{+, iota{k}, diffs}
      join{each{select{., fix_d}, move_d}}
    }
    def all_perms{k, 0} = tup{iota{k}}
    def all_perms{k} = all_perms{k, k}

There's a really pretty structure inside… that recursion and looping have been hiding from us! Notice how we never use `fix_d` until right at the end? First, let me pull out the part that only depends on `j`…

    def all_perms{k} = {
      def move_last{j} = {
        def i = iota{k}
        def start = copy{j, i == k - j}
        def end = scan{{l,_} => shiftright{0, l}, start}
        scan{+, i, start - end}
      }
      def perm_last{j} = {
        def fix_d = perm_last{j - 1}
        def cj = move_last{j}
        join{each{select{., fix_d}, cj}}
      }
      def perm_last{0} = tup{iota{k}}
      perm_last{k}
    }

Do you see it yet? It's a fold! The whole `perm_last{k}` definition is the same as:

      fold{
        {fix_d, cj} => join{each{select{., fix_d}, cj}},
        tup{iota{k}},
        each{move_last, 1 + iota{k}}
      }

Okay but it still doesn't look that nice! Well, for one thing we don't need the starting permutation list `tup{iota{k}}`, provided `k > 0`, since composing every permutation in a list with the identity just gives that list back! For another, `join{each{select{., fix_d}, cj}}` is a util/tup pattern, `flat_table{select, cj, fix_d}`. Which is weird backwards arguments, but if we look at `d = k - j` that's `k - (1 + iota{k})` which is `reverse{iota{k}}` so if we pass in `iota{k}` for `d` then we get a really clean presentation like…

    def all_perms{k} = {
      def i = iota{k}
      def moves_to{d} = {
        def start = copy{k - d, i == d}
        def end = scan{{l,_} => shiftright{0, l}, start}
        scan{+, i, start - end}
      }
      fold{flat_table{select, ...}, each{moves_to, i}}
    }

It still passes the tests, but this isn't actually doing the same thing, since I should have also changed it to from a left fold to a right fold to reverse everything. And actually it gets a lot slower because of that! But why's it still the same result? Remember how I said permutation composition is associative? It's a very important example of an associative but not commutative operation, even though _some_ people don't appreciate that! Well this means `flat_table{select, ...}` is also associative. If you fold it over three lists of permutations, each entry is a composition of three permutations, so the ordering of the composition doesn't affect its value. And the overall ordering is based on the position in the first argument, then the second, then the third. That also doesn't depend on whether you put the first and second together first, or the second and third!

And what does associativity mean for us? We can do the fold not just left or right but in any ordering! So I can split it up this way:

      def split_fold{op, args, l} = {
        def fslice{...s} = fold{op, slice{args, ...s}}
        op{fslice{0,l}, fslice{l}}
      }
      split_fold{flat_table{select, ...}, each{moves, i}, 4}

This is pretty easy to compile actually! First I'm going to make some little changes to `genperms` so it takes a start and end index, kind of like `slice`, and separate out the main loop that combines permutations so I can reuse it:

    def shuffle_arr{dst:(*V), src:(*V), vals, len} = {
      def sel = vec_shuffle{16, vals, .}
      @for (dst, src over (len + vl-1)/vl) dst = sel{src}
    }

    fn genperms_range(dst:*u8, k:u8, js:u8, je:u8) : i64 = {
      vi := vec_make{V, range{vl} % 16} # Identity permutation
      dv := *V~~dst
      store{dv, 0, vi}
      next := dst + k  # Pointer to unfinished part
      start := vi == vec_broadcast{V, k - js}
      @for (j from js + 1 to je + 1) {
        start = vec_shift_left_128{start, 1}
        end := start
        move_d := vi
        l := next - dst
        @for (_ from 1 to j) {
          end = vec_shift_right_128{end, 1}
          move_d -= start - end
          shuffle_arr{*V~~next, dv, move_d, l}
          next += l
        }
      }
      next - dst
    }

So our old `genperms` would do `genperms_range(dst, k, 1, k)`. But here's one with a split! When `k` is big, almost all the time gets spent in the `shuffle_arr` in this function. And one call makes `size` elements, which is `fact{e} * k` or `720 * k` bytes. We just keep reading that many bytes from `dst` and never further, which means that little section can stay in the L1 cache! Just one trick for the main loop, after reading a permutation from `tmp` you have to copy it to both lanes with `vec_select` so shuffle does what we want!

    include 'clib/malloc'
    fn genperms_split(dst:*u8, k:u8) : void = {
      if (k == 0) return{}
      e:u8 = 6; if (k < e) e = k  # Split point
      l := genperms_range(dst, k, 1, e)
      if (e < k) {
        kw := u64^~k
        len:u64 = 1; @for (f from u64^~e + 1 to kw + 1) len *= f
        size := len * kw
        tmp := alloc{u8, size + vl}
        genperms_range(tmp, k, e, k)
        next := dst + l
        @for (i from 1 to len) {
          def s = vec_select{128, load{*V~~(tmp + i * kw), 0}, tup{0,0}}
          shuffle_arr{*V~~next, *V~~dst, s, l}
          next += l
        }
        free{tmp}
      }
    }

Now `$ time ./a.out 9 10000` shows `0m0.717s`, 22 picoseconds per index which is 10,000 times faster than the fastest Singeli version! The time for `./a.out 10 1000` is faster too, but not by as big a factor. After some thinking that makes sense, because with 9 it was reading from and writing to the L3 cache, but with 10 only the writes go to main memory so changing the reads isn't quite as much more good. But for `./a.out 11 100` the reads also don't fit in L3 and the improvement gets bigger again!

## Saving space

That's really good for speed, but it does need its own allocation. I don't think it would ever be a problem, but taking it out is a good excuse to work with permutations more! Also I think you can fit it at the end of the result buffer. But anyway, it's possible to make the "outer" permutations only using some stack space. It doesn't matter if it gets a little slower because it's such a tiny fraction of the total time!

My first try was to use recursion. Instead of going bottom-up like `genperms_range`, it traverses from the top down, passing a permutation `s` along and modifying it at each layer, see? So the code to make `sm` is the same as the code for `move_d` in `genperms_range`, except when it finishes it makes a recursive call instead of making a new block with `shuffle_arr`.

    fn genperms_rec_sub{e}(dst:*u8, next:*u8, k:u8, j:u8, s:V) : *u8 = {
      if (k - j <= e) {
        if (dst == next) { # First region
          next += genperms_range(dst, k, 1, e)
        } else {
          def fact{i} = if (i <= 1) 1 else i * fact{i - 1}
          l := fact{e} * u64<~k
          shuffle_arr{*V~~next, *V~~dst, s, l}
          next += l
        }
      } else {
        sm := vec_make{V, range{vl} % 16}
        start := sm == vec_broadcast{V, j}
        end := start
        @for (_ from j to k) {
          outer := vec_shuffle{16, s, sm}
          next = genperms_rec_sub{e}(dst, next, k, j+1, outer)
          end = vec_shift_right_128{end, 1}
          sm -= start - end
        }
      }
      next
    }
    fn genperms_rec(dst:*u8, k:u8) : void = {
      if (k == 0) return{}
      genperms_rec_sub{6}(dst, dst, k, 0, vec_make{V, range{vl} % 16})
    }

It's kinda just not good though? There's so much saved state along the way, and it's even a tiny bit slower from all the recursion overhead. I see 0m0.737s for `$ time ./a.out 9 10000`! And I don't like how it's recursive but with the base cases depending on previous computations, it's spooky! But it does show what sort of structure we want for generating permutations. If I write like `m_80` for case 0 of the layer that has 8 of them total, it would be…

    select{select{m_90, m_80}, m_70}

Wait, that's too messy! Let's define `oper $ select infix left 25` so we can write it like…

    m_90 $ m_80 $ m_70
    m_90 $ m_80 $ m_71
    ...
    m_90 $ m_80 $ m_76
    m_90 $ m_81 $ m_70
    ...

For each layer of recursion there's a set of permutations, and the outermost one only ever does one set of changes while the others cycle around faster. We can generate some example components with the code from `all_perms` above, I packed the outputs together to make it easier to read over!

    def show_moves{k, d} = {
      def i = iota{k}
      def start = copy{k - d, i == d}
      def end = scan{{l,_} => shiftright{0, l}, start}
      each{show, scan{+, i, start - end}}
      show{''}
    }
    each{show_moves{7, .}, iota{3}}

    tup{0,1,2,3,4,5,6}   tup{0,1,2,3,4,5,6}   tup{0,1,2,3,4,5,6}
    tup{1,0,2,3,4,5,6}   tup{0,2,1,3,4,5,6}   tup{0,1,3,2,4,5,6}
    tup{2,0,1,3,4,5,6}   tup{0,3,1,2,4,5,6}   tup{0,1,4,2,3,5,6}
    tup{3,0,1,2,4,5,6}   tup{0,4,1,2,3,5,6}   tup{0,1,5,2,3,4,6}
    tup{4,0,1,2,3,5,6}   tup{0,5,1,2,3,4,6}   tup{0,1,6,2,3,4,5}
    tup{5,0,1,2,3,4,6}   tup{0,6,1,2,3,4,5}
    tup{6,0,1,2,3,4,5}

What I want is a way to get from one _combined_ permutation to the next. Let's say we wanted to go from `m_75 $ m_65 $ m_52` to `m_75 $ m_65 $ m_53`. We have one sort of difference with `scan{+, ...}`, but it's no good! It's more like `m_53 = update $ m_52`, with `update` on the left. Then `m_75 $ m_65 $ m_53` would be `m_75 $ m_65 $ update $ m_53`, but how do we get `update` in the middle like that? We need `m_53 = m_52 $ update` so we can compute `(m_75 $ m_65 $ m_52) $ update` and let associativity do the work! A permutation on the right side rearranges, so we need to know how to rearrange one permutation to get the next. How does that work?

    tup{0,1,2,3,4,5,6}
            X X
    tup{0,1,3,2,4,5,6}
            X   X
    tup{0,1,4,2,3,5,6}
            X     X
    tup{0,1,5,2,3,4,6}
            X       X
    tup{0,1,6,2,3,4,5}

Here's an example! First we have to swap two numbers that are next to each other, then two further apart, and so on. I can make a permutation that does that using the starting index `start` and distance `dist` like this!

    def i = iota{7}
    def {start, dist} = tup{2, 3}
    def swap = i + dist * ((i == start) - (i == start + dist))
    show{swap}                       # tup{0,1,5,3,4,2,6}
    show{tup{0,1,4,2,3,5,6} $ swap}  # tup{0,1,5,2,3,4,6}

With `dist` and `start` both broadcast to vectors that would be `vi + (dist & (vi == start)) - (dist & (vi == start + dist))`. See, `&` works because `==` sets all the result bits to 1 if it matches! Now how about to go back to the beginning? Here's the last and first permutation for each layer. I got the last row that goes between them with `show{find_index{fold{+, i, start - end}, i}}`!

    tup{6,0,1,2,3,4,5}   tup{0,6,1,2,3,4,5}   tup{0,1,6,2,3,4,5}
         / / / / / /         |  / / / / /         | |  / / / /
    tup{0,1,2,3,4,5,6}   tup{0,1,2,3,4,5,6}   tup{0,1,2,3,4,5,6}

    tup{1,2,3,4,5,6,0}   tup{0,2,3,4,5,6,1}   tup{0,1,3,4,5,6,2}

There are three parts to each of these permutations. It starts out like `iota{k}`, but it skips a step, but that skipped number comes back at the end! I can get the skipped step with `vi - (vi >= start)`, subtract not add because a true comparison gives `-1`! Then to fix up the last number there's another useful instruction from iintrinsic/select, blend! I'll write `blend_hom{vi - (vi >= start), start, is_last}`, which changes my vector to `start` where `is_last` is true. The `_hom` part stands for homogeneous! That means it assumes every element of the last argument is all 0 or all 1, exactly what we get out of a comparison! The blend instruction in AVX2 depends on the top bit, so `blend_hom` is the same as `blend_top` in that architecture. But `blend_hom` is more portable when we can make sure all the other bits are the same as the top one!

So now all I need to do is apply these operations in the right order. Here it is! The beginning goes just like `genperms_split`, but the way to update `s` is a little complicated!

    oper ** vec_broadcast infix right 55

    fn genperms_counter(dst:*u8, k:u8) : void = {
      if (k == 0) return{}
      e:u8 = 6; if (k < e) e = k  # Split point
      l := genperms_range(dst, k, 1, e)
      if (e < k) {
        next := dst + l
        digits:*u8 = @for_const (16) 0  # The counter
        vi := vec_make{V, range{vl} % 16}
        is_last := vi == V**(k - 1)
        start_e := V**(k - 1 - e)
        s := vi  # The outer permutation
        while (1) {
          # Increment first, genperms_range already did one iteration!
          i := e; start := start_e
          d := undefined{u8}
          while ((d = digits->i) == i) { # Digit rolls over to 0
            digits <-{i} 0
            shift := blend_hom{vi - (vi >= start), start, is_last}
            s = vec_shuffle{16, s, shift}
            ++i; start -= V**1
            if (i == k) return{}
          }
          # Some digit always increases by 1
          ++d; digits <-{i} d
          dist := V**d
          swap := vi + (dist & (vi == start)) - (dist & (vi == start + dist))
          s = vec_shuffle{16, s, swap}
          # Now shuffle
          shuffle_arr{*V~~next, *V~~dst, s, l}
          next += l
        }
      }
    }

On every step, we increment the last digit of our counter. If that overflows, then we do a shift instead of a swap for that digit and move up to the next digit. When we move past the top digit we're done!

It's a little faster than `genperms_rec` but still slower than `genperms_split`! I have to speed up that counter!

## Counting quick

I explained it to Ford because he's always so helpful with suggestions. He said it was "like a model train set that takes up an entire room of someone's house", yay! And also he had a really cool idea for the counter. I kept trying to apply SIMD instructions, but they're not very good for this because they're not designed to communicate between the elements too much. Ford said I can use regular addition!

    0x552 + 0x9ab = 0xefd
    0x553 + 0x9ab = 0xefe
    0x554 + 0x9ab = 0xeff
    0x600 + 0x900 = 0xf00

The trick is you add an offset to each digit, so when it reaches 16 it wraps around in hex. 64 bits is exactly enough to fit 16 4-bit digits, perfect! Each digit wraps all the way back to 0 so you have to re-add the offset at those places, but we need to know the number of wrapped digits anyway which helps with that. And it's done when all the digits wrap!

But one more thing before _we're_ done, with such a nice counter I'd hate to loop on the wrapped digit count! The effect of all the `shift`s only depends on the how many there are, I mean we always wrap the lowest one, then the one above it, and so on, until they stop wrapping. If you have the wrap permutations from before, `reverse{scan{select,reverse{wraps}}}` shows what they do cumulatively:

    tup{3,4,5,6,2,1,0}
    tup{0,3,4,5,6,2,1}
    tup{0,1,3,4,5,6,2}
    tup{0,1,2,3,4,5,6}  # No digits!

This isn't too complicated! The section `tup{3,4,5,6}` shifts around but doesn't change, and the spots before it are like `iota{k}`, and the rest of the numbers go backwards at the end. If you go from bottom to top you can follow how it got that way, first the `2` moves over to the right, then the `1` but it pushes the `2` out of the last slot, then the `0`. But we don't have to compute it like that! We'll make `tup{3,4,5,6,2,1,0}` once before the loop, then shift it over with a shuffle by `iota{k} - x`, and use a blend to fill in the entries where that was negative. Specifically `blend_top`, because the top bit is the sign bit!

So here's the function using all that stuff. And also the count-trailing-zeros function `ctz` to figure out how many digits wrapped, since it's practically designed for that!

    def ctz{x:(u64)} = emit{u8, '__builtin_ctzll', x}

    fn genperms_flat(dst:*u8, k:u8) : void = {
      if (k == 0) return{}
      e:u8 = 6; if (k < e) e = k  # Split point
      l := genperms_range(dst, k, 1, e)
      if (e < k) {
        next := dst + l
        vi := vec_make{V, range{vl} % 16}
        s := vi  # The outer permutation
        rev := V**(k - 1) - vi
        rot := blend_hom{rev, vi + V**(k - e), vi < V**e}
        # Counter: 16 digits times 4 bits each
        base:u64 = u64~~0x0123456789abcdef >> (4 * e)
        digits := base
        while (1) {
          # Increment first, genperms_range already did one iteration!
          ++digits
          nz := ctz{digits} / 4  # Number of zero digits
          i := e + nz
          if (i == k) return{}
          nb := 4 * nz
          digits |= base & ((u64~~1 << nb) - 1)
          d := u8<~(((digits - base) >> nb) & 0xf)
          # shift_rev handles digits that roll to 0, swap handles increment
          vo := V**i - rev
          vs := vo - V**1
          shift_rev := blend_top{vec_shuffle{16, rot, vs}, vi, vs}
          s = vec_shuffle{16, s, shift_rev}
          dist := V**d
          swap := vi + (dist & (vo == V**0)) - (dist & (vo == dist))
          s = vec_shuffle{16, s, swap}
          # Now shuffle
          shuffle_arr{*V~~next, *V~~dst, s, l}
          next += l
        }
      }
    }

It's finally the same speed as `genperms_split`, 0m0.716s! It barely even gets slower if I decrease `e` to 5, which for `k = 9` means a block is only 34 vectors, so the part that updates `s` is really fast! Another cool thing we can do with this function is take away the `next += l` at the end to see how fast it would be if it wasn't bottlenecked by writing to memory. This could happen if you could use each block of permutations after generating it and didn't need it any more, so you could write over the space it's in. Also make sure to decrease the allocation in `main` though! This is so fast I can run `time ./a.out 14 1` in 0m16.079s, that's 13 picoseconds per index or 76GB/s!

You could even avoid having to save the first block if you could find the permutation that transforms one block to the next. I don't know if there's a tricky way to do this, the best I could think of was to make the inverse of `s` along with `s` so you can combine the inverse of the last step each time. Which is not that hard since `swap` is its own inverse and `shift_rev` just needs some more shifting and blending. But I think… at least for now… I'll leave it as an exercise!

Okay there were a lot of steps along the way so I decided to put everything together for a unified definition of `genperms_flat`!

    include 'skin/c'
    include 'skin/cext'
    include 'arch/c'
    include 'util/for'
    include 'arch/iintrinsic/basic'
    include 'arch/iintrinsic/select'

    def vl = 32; def V = [vl]u8
    oper ** vec_broadcast infix right 55
    def ctz{x:(u64)} = emit{u8, '__builtin_ctzll', x}

    fn genperms_flat(dst:*u8, k:u8) : void = {
      if (k == 0) return{}
      vi := vec_make{V, range{vl} % 16}
      dv := *V~~dst
      store{dv, 0, vi}  # One identity permutation to start with
      next := dst + k   # Pointer to unfinished part
      l := next - dst   # Current block length
      def add_block{vals} = {
        def sel = vec_shuffle{16, vals, .}
        @for (dst in *V~~next, dv over (l + vl-1)/vl) dst = sel{dv}
        next += l
      }

      # Increase block size from k to k*fact{e}
      e:u8 = 6; if (k < e) e = k  # Split point
      rev := V**(k - 1) - vi
      start := rev == V**0
      @for (j from 2 to e + 1) {
        start = vec_shift_left_128{start, 1}
        end := start
        move_d := vi
        @for (_ from 1 to j) {
          end = vec_shift_right_128{end, 1}
          move_d -= start - end
          add_block{move_d}
        }
        l = next - dst
      }
      if (k == e) return{}

      # Do the rest with a fixed block size
      s := vi  # The outer permutation
      rot := blend_hom{rev, vi + V**(k - e), vi < V**e}
      # Counter: 16 digits times 4 bits each
      base := u64~~0x0123456789abcdef >> (4 * e)
      digits := base
      while (1) {
        # One iteration is done, so start with increment!
        ++digits
        nz := ctz{digits} / 4  # Number of zero digits
        i := e + nz
        if (i == k) return{}
        nb := 4 * nz
        digits |= base & ((u64~~1 << nb) - 1)
        d := u8<~(((digits - base) >> nb) & 0xf)
        # shift_rev handles digits that roll to 0, swap handles increment
        vo := V**i - rev
        vs := vo - V**1
        shift_rev := blend_top{vec_shuffle{16, rot, vs}, vi, vs}
        s = vec_shuffle{16, s, shift_rev}
        dist := V**d
        swap := vi + (dist & (vo == V**0)) - (dist & (vo == dist))
        s = vec_shuffle{16, s, swap}
        add_block{s}
      }
    }

I like to think of this as two permutation methods mixed together, and it's not that hard to separate them either! The first one is our very first AVX2 function `genperms`, which you get just by always setting `e` to `k`! Then `if (k == e) return{}` always returns and the code after doesn't do anything. This one always runs on the biggest block size it can. The other method is if you set `e` to `0` or `1`, and it doesn't do blocks at all, the only permutation that's ever read from `dv` is the identity! So you'd want to make a lot more changes to the code really, to skip that and write the vector `vals` right away. Then this method is a slower but zero-memory way to loop through all the permutations!

Our combination lets us choose `e` to get the best of both worlds, top speed and low memory use. It's sort of a tradeoff but a really easy one, re-reading a few kilobytes of memory and a few percent of CPU overhead are really low costs! But one last thought… especially if `k` is fixed you could set a low `e` like `4` and keep the whole first permutation block in registers!
