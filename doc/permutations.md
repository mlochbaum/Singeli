# Listing all permutations

Hey I found a way to list all the permutations in lexicographically increasing order, at billions of permutations per second! No, I don't know what it's "useful for", don't ask me questions like that!

Okay, we're going to start off with an old old algorithm that Roger Hui wrote about in 1981! There are articles explaining it in [APL](https://www.jsoftware.com/papers/50/50_19.htm), [J](https://code.jsoftware.com/wiki/Doc/Articles/Play202) and [BQN](https://saltysylvi.github.io/blog/BQNcrate-permutations.html), what about Singeli though?

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

But yeah, the reason we're stuck at 16 even though AVX2 vectors are 32 bytes is that its selection works in lanes, it splits the vectors in half and does one selection on one half and another—well, think of it like an `each` that maps over two sets of lanes really! I started with AVX2 since Ford says I have to get more comfortable with lanes, except because I don't handle `k > 16` there's not much to do really! I just make sure the two halves of `move_d` are the same, so when I run `sel{dv}` it does the same thing to every number in `dv`. Part of that is using `vec_shift_left_128` and `vec_shift_right_128` for the AVX2 versions of `shiftleft` and `shiftright`. The `128` means they work on 128-bit lanes!

Look out for `(l + vl-1)/vl`, that's a ceiling division! We want to write `l` total indices, but maybe that's not an even multiple of `vl`, so we have to round up. Watch out, `dst` might need to be allocated with some extra space in case `l` rounds up on the last step. Although for `k = 9` that would be `9 * fact{8}`, which is a multiple of 32 so that's all good! And on that note here's how you can make `genperms` run from the command line:

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
