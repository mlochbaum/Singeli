# Singeli is a (mostly) pure functional interpreter

(And [Haskell is a dynamically-typed, interpreted language](https://aphyr.com/posts/342-typing-the-technical-interview) but it's so hard to use!)

So you want to write a quick script with Singeli! Perfect, it's a functional scripting language, kind of like Elixir. It's missing some features like reading files and the interpreter's a little basic and slow, but it's fine for small tasks!

Of course we start with Hello World. The Singeli interpreter is a little quirky, and it uses curly braces `{}` for everything! It also has different names for things. Instead of calling the `show` function on a string, in Singeli you say it's a *generator* called on a *symbol*.

    show{'Hello, World!'}

Save this to a file and run Singeli on it so it can tell you Hello, World! But if you run it with plain `singeli`, it prints an extra `#include<stdint.h>` for some reason, so actually call it like this:

    $ singeli -p "" hello.singeli

Okay, and if we want it to tell us the 12th fibonacci number is 144? I remember this one because it's 12 squared! We'll make a fibonacci generator to generate it. Singeli has a built-in `__add` generator to add numbers and so on, but you define the operators. Let's take the C-like ones from the standard include file skin/c. It's the only pre-defined set right now! `include` uses the file [include/skin/c.singeli](../include/skin/c.singeli) like it's part of our script.

    include 'skin/c'

    def fib{n} = if (n <= 1) n else fib{n-2} + fib{n-1}

    show{'fib{12} = ', fib{12}}

Running this prints out `'fib{12} = ', 144`. It's very literal I guess! The `fib{}` generator is the simple recursive version that doesn't save its results, so `fib{30}` makes like a million calls and takes forever. Can we write a version with a loop that would be faster?

Loops are imperative programming, why would you do that? We'll make one with recursion. We need to use lists but they're called tuples!

    def things = tup{12, 'Fibonacci', 'Hello'}
    show{select{things, 1}}          # 'Fibonacci'
    def {number, name, hi} = things
    show{hi, 'World!'}               # 'Hello', 'World!'

The comments with `#` say what this prints. We make a tuple with `tup{}`, and we can select one part with `select{}`. See, curly braces for everything! We also have `def {…}` to break up a tuple, but it doesn't use `tup` because it's special syntax.

Okay, to compute fibonacci numbers faster we want to keep track of two numbers at a time. For the second one we'll keep the next fibonacci number because it makes handling 0 easier. At the end we throw it out!

    include 'skin/c'

    def fib{n} = {
      def fib2{n} = { # Get tup{fib{n}, fib{n+1}}
        if (n == 0) tup{0, 1}
        else {
          def {a, b} = fib2{n - 1}
          tup{b, a+b}
        }
      }
      select{fib2{n}, 0}
    }

    show{fib{ 30}}  # 832040
    show{fib{ 90}}  # 0x27f80ddaa1ba7878
    show{fib{100}}  # 3.542248481792619e20

It prints `fib{90}` in hex, so quirky! It's not actually a special kind of number. Singeli's numbers are all the same, a kind of high precision float. It fits exact integers just past 31 digits, which is pretty big!

There's another way to define the two cases for `fib2{}` that looks more functional. You first write the general case and then the specific one `n==0`. Singeli scans the cases backwards! Secretly when you write the second definition it modifies `fib2`, which means a little bit of the language isn't pure functional. But that mostly doesn't make a difference. Also check out the [`match`](../README.md#match) structure which is another neat way to write this!

    def fib{n} = {
      def fib2{n} = {
        def {a, b} = fib2{n - 1}
        tup{b, a+b}
      }
      def fib2{n==0} = tup{0, 1}
      select{fib2{n}, 0}
    }

This recursion doesn't do that much though. It just starts with `tup{0, 1}` and does a transformation on it `n` times! Is there a simpler way to write it? Singeli has a built-in library [util/tup](../include/README.md#utiltup) with some tuple functions that help with this. It's inspired by K, how cool is that?

    include 'skin/c'
    include 'util/tup'
    show{iota{2}}           # tup{0,1}
    show{fold{+, iota{5}}}  # 10

So `iota{n}` lists the natural numbers up to `n`, and `fold{}` does a left fold or reduction or accumulate or whatever. It's 10 like bowling pins! The repeat-`n`-times thing isn't in util/tup because it's more of a generator thing, but one way to do it is with a fold that ignores the right argument!

    include 'skin/c'
    include 'util/tup'

    def repeat{gen, k, param} = fold{{a,b}=>gen{a}, param, iota{k}}
    def fib{n} = {
      def next{{a, b}} = tup{b, a+b}
      select{repeat{next, n, iota{2}}, 0}
    }

Oh, I haven't shown an anonymous function before! `{a,b}=>gen{a}` is one of those, and it just wraps `gen` and ignores the `b` argument. One last thing, there's a tricky way to write `next{}` with using tuples. If we reverse `a,b` we get `b,a`, and the only difference from `b, a+b` is the added `b`. The `scan` generator can do this. `scan{+, tup{a,b,c}}` is `tup{a,a+b,a+b+c}` but we're going to use a shorter version!

    def repeat{gen, k, param} = fold{{a,b}=>gen{a}, param, iota{k}}
    def fib{n} = {
      def next{t} = scan{+, reverse{t}}
      select{repeat{next, n, iota{2}}, 0}
    }

Lots of curly braces!

## Generating code

The Singeli interpreter's a little slow, right? But a cool extra feature it has is to generate faster code with symbolic evaluation. It makes C code, but you can get by without knowing much C! Here's a new version of our fibonacci program:

    include 'skin/c'
    include 'arch/c'
    include 'util/tup'

    fn fib(n:u64) = {
      f:copy{2,u64} = iota{2}
      def next{t} = scan{+, reverse{t}}
      while (n>0) { n = n - 1; f = next{f} }
      select{f, 0}
    }

    include 'debug/printf'
    main() = lprintf{fib(30)}

Look, the definition of `next` is the *exact same* as it was before! The only difference is what we apply it to. And arch/c, the C architecture file, which defines symbolic definitions of `+` and `-`. And all the other operators you'd expect! Like when we had two definitions of `fib2` before, these new definitions extend the old ones so the operators still work the normal way. But when they apply to a typed value that's declared with a `:` like `n` and `f`, they do a symbolic computation instead.

If I save this as fib.singeli, then I can run it this way:

    $ singeli fib.singeli -o /tmp/t.c && gcc /tmp/t.c -o fib && ./fib
    832040

I put the C file in `/tmp` so I don't have to clean it up later! I could do that with the `fib` executable too but it might be nice to be able to run it again without compiling. Like here I could run `time ./fib` to see how long it took. But it's so fast! Here's a version that takes a few seconds because it gets the last nine digits of the *billionth* fibonacci number. There's a lot of digits so it would be much harder to keep track of *all* of them!

    include 'skin/c'
    include 'arch/c'
    include 'util/tup'

    fn fib(n:u64) = {
      f:copy{2,u32} = iota{2}
      def f1 = select{f, 1}
      def next{t} = scan{+, reverse{t}}
      while (n>0) { n = n - 1; f = next{f}; f1 = f1%1e9 }
      select{f, 0}
    }

    include 'debug/printf'
    main() = lprintf{fib(1e9)}  # 560546875

I'm getting ahead of myself, there's a lot here I haven't explained! The trick for reading `fn` is that it's really a straight-line block of code, but it *defines* a loopy program. So `while` only runs the condition and block once, but it does it symbolically so then it can make C code that does it like a billion times. Exactly a billion times! And one extra on the condition. You can put `show` anywhere to see how the interpreter runs things.

      while (show{n}>0) { n = n - 1; f = next{f}; show{f1} = f1%1e9 }

Since `n` and `f1` don't have fixed values, `show` prints a symbolic description instead. For `f1` it shows `f:u32`, but that makes sense. We set `def f1 = select{f, 1}`, and why would `show{select{f, 1}}` use the name `f1`? Another thing, `show` works on the left of `=`! It's because `=` on its own without `def` is a regular operator. The only built-in one! Since the left-hand side is a symbol, it *makes* code that changes the value of this symbol but it doesn't actually change the symbol.

So symbols work this way because when you're writing for the CPU you want types that match what it will handle, like `u64` or `u32` here. And you want to be able to modify them in place like a register can, well not always, but here, kinda. A symbolic value like `n:u64` is actually called a *register* because of that! And it's really CPU-oriented, so it's always something that fits in one CPU register. When we define `f` to contain two values it defines two registers, each holding one value. That's why we can pick out one with `select{}`! Also they're both called `f` but Singeli changes the way it names registers sometimes so maybe it can get more specific!

      f:copy{2,u32} = iota{2}

I also skipped `copy` but it's from util/tup too and it makes a tuple with two copies of `u32`! When you have registers bundled together like this, the type packs multiple types together the same way.

My `while` loop works but it could look a lot nicer! And it changes the value of `n`, but sometimes I want to know what `n` was after a loop.

      while (n>0) { n = n - 1; f = next{f}; f1 = f1%1e9 }

My first instinct when I see this kind of pattern is to wrap up the messy loop into a utility function. I can pass in an `iter{}` generator that says what to do, and `repeat` calls it when it needs to!

    def repeat{count, iter} = {
      i:u64 = 0
      while (i < count) {
        iter{}
        i = i + 1
      }
    }

      repeat{n, {} => { f = next{f}; f1 = f1%1e9 }}

But *this* pattern is a case of a `@for` loop, a bit of syntax sugar! When we write `@something`, with a condition and body, it calls that thing as a generator with some particular arguments. We're not using `begin` or `vars`, but I think it's better to handle them so they're supported! For the parts we do use, `end` gets set to `n`, and `iter` is a generator that runs the block `{ f = next{f}; f1 = f1%1e9 }`.

    include 'skin/c'
    include 'arch/c'
    include 'util/tup'

    # (or include 'util/for')
    def for{vars, begin, end, iter} = {
      i:u64 = begin
      while (i < end) {
        iter{i, vars}
        i = i + 1
      }
    }

    fn fib(n:u64) = {
      f:copy{2,u32} = iota{2}
      def f1 = select{f, 1}
      def next{t} = scan{+, reverse{t}}
      @for (n) { f = next{f}; f1 = f1%1e9 }
      select{f, 0}
    }

    include 'debug/printf'
    main() = lprintf{fib(1e9)}  # 560546875

It's nice to see the `for` loop written out so you can make a different version if you need it, but the basic loop is so common there's a library for it! It's in [util/for](../include/README.md#utilfor).

## Fibonacci math

Using C speeds up that calculation a lot! But I know how to get the result instantly, just using interpreted Singeli! Here, I'll show you.

Let's say we already computed `fib(n) = x` and `fib(n+1) = y`. We know how to keep computing the sequence from there!

    x, y, x+y, y+(x+y), (x+y)+(y+x+y), (y+x+y)+(x+y+y+x+y), ...

Okay, it makes pretty patterns but writing it out like this is just confusing! It's always some number of `x`s and some `y`s, so I'll write it that way:

    fib(n)   = 1*x + 0*y
    fib(n+1) = 0*x + 1*y
    fib(n+2) = 1*x + 1*y
    fib(n+3) = 1*x + 2*y
    fib(n+4) = 2*x + 3*y
    fib(n+5) = 3*x + 5*y

Wait, we've seen these numbers! Both columns are the Fibonacci sequence, just shifted differently. That's because the number of `x`s is the sum of the numbers in the last two terms, and same for the `y`s. Actually to make the table, I didn't even count the `x`s and `y`s from above but I just added them according to that rule!

So a term like `2*x + 3*y` can also be written `fib(3)*x + fib(4)*y`. Following this pattern we can translate the first few lines, although the very first is a little tricky! The Fibonacci rule says `fib(-1) + fib(0) = fib(1)`, which means `fib(-1) = fib(1) - fib(0) = 1 - 0 = 1`. So there are *three* ways to write `1`, and I choose the one that fits the pattern!

    fib(n)   = fib(-1)*x + fib(0)*y
    fib(n+1) = fib( 0)*x + fib(1)*y
    fib(n+1) = fib( 1)*x + fib(2)*y

And here's the general version. You can prove it with induction on `j` from the first two lines if you want to be sure!

    fib(n+j) = fib(j-1)*fib(n) + fib(j)*fib(n+1)

Why is this good? If we know the Fibonacci numbers for a large value of `j`, it means we get to jump ahead by that much! Let's look at setting `j` to `n` and `n+1`, since those are the ones we already know!

    fib(n+n)   = fib(n-1)*fib(n) + fib(n)  *fib(n+1)
    fib(n+n+1) = fib(n)  *fib(n) + fib(n+1)*fib(n+1)

These formulas let us jump from `fib(n)` and `fib(n+1)` to `fib(2*n)` and `fib(2*n+1)`, so our index grows exponentially instead of linearly! Well, almost… there's still `fib(n-1)` that we don't know. But we can write it as `fib(n+1) - fib(n)`!

    fib(n+n) = (fib(n+1) - fib(n))*fib(n) + fib(n)*fib(n+1)

So here's a little derivation of how we would compute this in Singeli. We're using the `fib2{}` generator like above, so `a` is `fib(n)` and `b` is `fib(n+1)`. The first term simplifies just a little!

    def {a, b} = fib2{n}
    fib2{2*n} = tup{(b-a)*a + a*b, a*a + b*b}
              = tup{a*(b+b-a), a*a + b*b}

If `n` is a power of two that's all fine, but how do we use this to get any Fibonacci number? Well remember we actually know *two* things: we can get from `fib2{n}` to `fib2{2*n}`, but also to `fib2{n+1}`, just with the `next{}` function from before! 

Let's say `double{fib2{n}}` gives us `fib2{2*n}`. Then it's actually pretty easy to define what we want to do with recursion!
- If it's even, write as `2*k`, so it's `double{fib2{k}}`
- If it's odd, write as `2*k+1`, so it's `next{double{fib2{k}}}`

In both cases, `k` is half of the number we want to get, rounded down. We can write that as `n >> 1`, although `__floor{n/2}` works too! And `n` is odd if `n%2` is `1`. Lastly, we use the base case 0 from before—sometimes with exponential things you have to define 1 too, but when rounding down `1 >> 0` is `0` so it's not needed! Also I wrote `0` instead of `n==0` just to show another way to write it.

    include 'skin/c'
    include 'util/tup'

    def fib{n} = {
      def next  {{a, b}} = tup{b, a+b}
      def double{{a, b}} = tup{a*(b+b-a), a*a + b*b}
      def fib2{n} = {
        def g = double{fib2{n >> 1}}
        (if (n%2) next{g} else g) % 1e9
      }
      def fib2{0} = iota{2}
      select{fib2{n}, 0}
    }

    show{fib{1e9}}  # 560546875

Like I said, it's instant! 1e9 is about 2 to the 30 because 1e3 is just under 1024 which is 2 to the 10th power. So it's only 30 steps to go all the way to a billion!

Another cool thing we can see now that we can compute last digits fast is that those digits repeat! Here's the sequence starting at 1,500,000,000:

    show{each{fib, 1.5e9 + iota{5}}}  # tup{0,1,1,2,3}

Of course the actual numbers that far along in the sequence are *huge*, but the last nine digits aren't! As soon as we see 0 then 1 in the sequence we know it has to repeat exactly from the start. This is called the 1e9th [Pisano period](https://en.wikipedia.org/wiki/Pisano_period), and you can find a guaranteed multiple of it but it's a little more math than I want to go into here! But once you know the multiple you check all the divisors for that 0-1 pattern and the first one is it!

Here's an extension you can add to `fib2{}` that takes this into account. Now if there's a really huge number you won't hit a recursion limit!

      def pisano = 1.5e9  # modulo 1e9
      def fib2{n if n>=pisano} = fib2{n % pisano}

This could all be translated into a C loop, but why should I if it's already instant? Maybe it's a fun exercise though—try looking at the bits of the index.

## To infinity!

Making a specific Fibonacci number is too easy, what about making *all* the Fibonacci numbers? Well, the last nine digits. Since they repeat, writing out the first one-and-a-half billion is like having every single one, in like a list structure that goes all circly. But look out, it takes 6 gigabytes to store! I put the constants at the beginning so you can use smaller ones if you don't have 6GB free.

    include 'skin/c'
    include 'arch/c'
    include 'util/tup'
    include 'util/for'

    def mod = 1e9
    def pisano = 1.5e9
    def test_ind = 1e9

    def next{{a, b}} = tup{b, a+b}

    fn fib_fill(dst:*u32, n:u64) : void = {
      f:copy{2,u32} = iota{2}
      def {f0, f1} = f
      @for (dst over n) {
        dst = f0
        f = next{f}
        f1 = f1 % mod
      }
    }

    include 'debug/printf'
    include 'clib/malloc'  # alloc{} and free{}
    main() = {
      fs := alloc{u32, pisano}
      fib_fill(fs, pisano)
      lprintf{load{fs, test_ind}}  # 560546875
      free{fs}
    }

It's mostly the same as what we had before but there's one thing to watch for! When we start, `f0` is 0, the 0th Fibonacci number, so we want to write it to `dst` right away before calling `next{}`. After `n` loops `f0` will be the `n`th Fibonacci number, but that's exactly the one we don't need to write because it's the same as the 0th! There are some other ways to do it that don't make the extra computation at the end, but it's only one or two extra iterations out of a billion and I think this way is clearer.

Another thing is that inside the `@for` loop, `dst` doesn't have the same value as outside! This might seem scary but it's only a kind of variable shadowing, for example if I wrote `{dst} => { dst = 2 }`, it could also be passed a different value of `dst`. If you don't like it you can write `@for (d in dst over n)` instead, so it defines `d` not `dst`. But what value does `dst` have anyway? Well, the outside `dst` is a pointer to `u32` values that we allocated in `main`, but the inside one is a `u32` register that represents one of these values. At the beginning of the loop it loads the value, and if the register is ever modified, at the end of the loop it writes it back!

This takes about 5.7 seconds when I run it, which is… zero seconds per number! There's one easy improvement: since we only have one addition we can simplify the modular division, which is taking some time. The sum can be more than `mod` but not more than *two* times `mod`, so we either need to leave `f1` alone or subtract `mod`. Here's a way to do that without branching:

    fn fib_fill(dst:*u32, n:u64) : void = {
      f:copy{2,u32} = iota{2}
      def {f0, f1} = f
      @for (dst over n) {
        dst = f0
        f = next{f}
        f1 -= mod & -promote{u32, f1 >= mod}
      }
    }

If `f1` is less than `mod` the comparison gives 0, so it cancels out `mod` and `f1` doesn't change. Otherwise, we get 1 and then negating it gives the number where all bits are 1. This time `mod` gets left alone, and then it's subtracted from `f1`!

Now it's down to 3.5 seconds! And okay this is kind of a silly thing to optimize but we're going to learn some stuff about parallel computations here! Not like multi-core, since Singeli doesn't have anything for that. But a single CPU can run a lot of instructions at once, and we're not letting it! Every iteration, we need to finish the last Fibonacci number before we can add it to the one before, which means lots of instructions have to be sequential. Try running `perf stat ./fib`. For me it only shows 2.12 instructions per cycle, out of 5 possible!

We know a parallel way to compute Fibonacci numbers, from the `fib(n+j)` formula before. If we have `fib(n)` and `fib(n+1)`, plus Fibonacci numbers for a bunch of different `j` values, we could run that formula for every `j` in parallel! But that step's not as fast as the one addition we've been using, and we'd need a real modular division and actually the intermediate result wouldn't even fit in a `u32` any more! Instead, we can jump ahead to find a bunch of different starting points using the fast formula, and advance *all* of these by one in one iteration of a for loop. Something like:

      def gap = n/k
      def fs = ?    # k starting pairs
      def dsts = ?  # k destination pointers
      @for (i to gap) {
        def iter{f, dst} = {
          def {f0, f1} = f
          store{dst, i, f0}
          f = next{f}
          f1 -= mod & -promote{u32, f1 >= mod}
        }
        each{iter, fs, dsts}
      }

How do we get the starting points? Going back to our `fib(n+j)` formula, we have a way to jump ahead by `j`:

    fib(n+j)   = fib(j-1)*fib(n) + fib(j  )*fib(n+1)
    fib(n+j+1) = fib(j  )*fib(n) + fib(j+1)*fib(n+1)

You might notice that it has the structure of a matrix product! But even without knowing this, we can simplify by writing some of the columns as `fib2{}` results.

    fib2{n+j} = fib2{j-1}*fib(n) + fib2{j}*fib(n+1)

And now we can combine `fib(n)` and `fib(n+1)`, if we know how to add the results of the multiplication. We do, it's a fold!

    fib2{n+j} = fold{+, tup{fib2{j-1}, fib2{j}} * fib2{n}}

So to get `num` starting points each separated by `dist` from the next, here's what we do. It's using a scan that ignores one of the arguments, a lot like `repeat{}` from before. But we want to include the starting value, so it's not an initialized scan! I think of this like an exclusive scan with initial value `iota{2}`, but the tuple library doesn't have an exclusive scan generator to use for that.

    def fib_starts{num, dist} = {
      def mat = tup{fib2{dist-1}, fib2{dist}}
      def inc{v} = fold{+, mat * v} % mod
      scan{{a,_}=>inc{a}, copy{num, iota{2}}}
    }

Let's do some jumping ahead of our own and write the whole new function out!

    include 'skin/c'
    include 'arch/c'
    include 'util/tup'
    include 'util/for'
    include 'util/perv'
    extend perv2{__add}

    def mod = 1e9
    def pisano = 1.5e9

    def next  {{a, b}} = tup{b, a+b}
    def double{{a, b}} = tup{a*(b+b-a), a*a + b*b}
    def fib2{n} = if (n==0) iota{2} else {
      def g = double{fib2{n >> 1}}
      (if (n%2) next{g} else g) % mod
    }
    def fib_starts{num, dist} = {
      def mat = tup{fib2{dist-1}, fib2{dist}}
      def inc{v} = fold{+, mat * v} % mod
      scan{{a,_}=>inc{a}, copy{num, iota{2}}}
    }

    fn fib_fill_interleave{k, n}(dst:*u32) : void = {
      def gap = n/k
      def to_u32{a} = { f:u32 = a }
      f := each{each{to_u32, .}, flip{fib_starts{k, gap}}}
      def {f0, f1} = f
      d := dst + gap*iota{k}
      @for (i to gap) {
        each{store{., i, .}, d, f0}
        f = next{f}
        each{{f1} => f1 -= mod & -promote{u32, f1 >= mod}, f1}
      }
    }

    include 'debug/printf'
    include 'clib/malloc'
    main() = {
      fs := alloc{u32, pisano}
      fib_fill_interleave{4, pisano}(fs)
      lprintf{load{fs, test_ind}}  # 560546875
      free{fs}
    }

And it's about 2.3 seconds, so it's faster!

But the loop is totally different from what I showed before, what happened? I rewrote it using some array principles: the key is to `flip` the starting points, translating it from a list of `k` starting pairs to a pair of lists! We have a tricky thing to convert all these to registers, and then each *list* of registers can be used a lot like the single registers before.

The key line `f = next{f}` is exactly the same, but that doesn't happen automatically! All the built-in arithmetic maps over lists, but the register arithmetic from arch/c doesn't. Fortunately there's a tool to make it work. It stands for "pervasion" but it's named [perv](https://dfns.dyalog.com/n_perv.htm) after John Scholes' love of silly abbreviations. Rest in peace John!

So the extension is `include 'util/perv'` and `extend perv2{__add}`, with the 2 because `__add` takes two parameters. The definition of `d` also uses it to add multiple starting indices to `dst`! In a bigger project with more setup, I might extend parts of the next line, like `&`, `-`, and even `-=`, but an `each` works perfectly fine too. And I have to use the `store` function instead of assignment but this line works out really nicely! `store{d, i, f0}` would store one value at index `i` offset from pointer `d`, and it's equivalent to `store{., i, .}{d, f0}`, so when `d` and `f0` are lists `each{store{., i, .}, d, f0}` works.

## Using SIMD

Flipping the starting points doesn't just make `fib_fill_interleave` easier to write, it also brings it closer to a CPU-friendly vector implementation! Currently `f0` and `f1` are each tuples of four `u32` values, so they both take up four CPU registers. But modern CPUs also have *vector* registers that store multiple values and operate on all of them at once! To use them I can change this:

      def to_u32{a} = { f:u32 = a }
      f := each{each{to_u32, .}, flip{fib_starts{k, gap}}}

to this:

      def V = [k]u32
      def to_V{a} = { f:V = vec_make{V,a} }
      f := each{to_V, flip{fib_starts{k, gap}}}

Wait, I need `include 'arch/iintrinsic/basic'` to use `vec_make`! I'm using the file for x86 here because that's what my computer is, but there's `arch/neon_intrin/basic` for ARM too. [It has](../include/README.md#simd-basics) the `vec_make` function to make a register with type `[4]u32` from four `u32` parameters, and it also defines basic arithmetic and logic for us which is good because we're going to need them!

But it doesn't have anything to store every part of the register to a different place, like `each{store{., i, .}, d, f0}` does! And I mean, some CPUs can do this, it's called a scatter instruction, but it's not really good to use. Because of the way memory architecture works it's just a bunch of requests piled into one instruction.

The only way to get the most out of a store instruction is to store four values all next to each other—but the way we compute them only ever gives us four that are separated! It's not as bad as it sounds though. What we do is keep four vectors *of* four values each, and then—remember `flip`? Well there's no `flip` instruction but there's a sequence of instructions for it, and also it turns out there's a weird macro thing for exactly the one we need!

    def transpose4x4{f} = {
      def re{T, xs} = each{reinterpret{T, .}, xs}
      ft := re{[4]f32, f}
      emit{void, '_MM_TRANSPOSE4_PS', ...ft}
      re{[4]u32, ft}
    }

Okay so this isn't actually a good thing to use! Because `_MM_TRANSPOSE4_PS` modifies its arguments in place, but Singeli doesn't expect it to do that! So it could squash it together with another register that isn't supposed to be modified. Here it works because the registers in `ft` don't alias with any other registers, but it would be a lot better to write the transpose with normal instructions. And educational! I'll try doing this once there's built-in support for the unpack instructions that transpose needs I think. (And now there is and I did it! I put an explanation in the next section!)

Now what I need to do is change the loop so it makes four vectors at a time, instead of only one. To initialize it I'm just going to extend our starting points using `merge{fs, next{next{fs}}}`. Then inside the loop I want to replace all four vectors instead of just making a new one. Since the number of values I want is divisible by 16 I don't have to worry about having any leftovers at the end, but if it wasn't I'd get an error and have to fix things. Before I get into explaining it, here's all the code together!

    include 'skin/c'
    include 'arch/c'
    include 'util/tup'
    include 'util/for'
    include 'arch/iintrinsic/basic'
    include 'util/perv'
    extend perv2{__add}  # Has to go after arch includes!

    def mod = 1e9
    def pisano = 1.5e9
    def test_ind = 1e9

    def next  {{a, b}} = tup{b, a+b}
    def double{{a, b}} = tup{a*(b+b-a), a*a + b*b}
    def fib2{n} = if (n==0) iota{2} else {
      def g = double{fib2{n >> 1}}
      (if (n%2) next{g} else g) % mod
    }
    def fib_starts{num, dist} = {
      def mat = tup{fib2{dist-1}, fib2{dist}}
      def inc{v} = fold{+, mat * v} % mod
      scan{{a,_}=>inc{a}, copy{num, iota{2}}}
    }

    # Better transpose: see below!
    include 'arch/iintrinsic/select'
    def transpose4x4{f} = {
      def zip{a,b} = each{zip{a,b, .}, iota{2}}
      def zips{{a,b}} = each{zip, a,b}
      join{zips{zips{split{2, f}}}}
    }

    fn fib_fill_vector{k==4, n}(dst:*u32) : void = {
      def gap = n/k; def gv = gap/k
      def V = [k]u32
      def fs = flip{fib_starts{k, gap}}
      def f4 = merge{fs, next{next{fs}}}
      def to_V{a} = { f:V = vec_make{V,a} }
      f := each{to_V, f4}
      d := reinterpret{*V, dst} + gv*iota{k}
      m := vec_broadcast{V, mod}
      @for (i to gv) {
        each{store{., i, .}, d, transpose4x4{f}}
        @for_const (j to k) {
          def fr = select{f, j}
          fr = fold{+, select{f, j+tup{-2,-1}}}
          fr -= m & (fr >= m)
        }
      }
    }

    include 'debug/printf'
    include 'clib/malloc'
    main() = {
      fs := alloc{u32, pisano}
      fib_fill_vector{4, pisano}(fs)
      lprintf{load{fs, test_ind}}  # 560546875
      free{fs}
    }

The idea is that I only want to change each register once, so instead of shifting the register list I use an index `j` and update register `j` only. So if I started by rotating register `j` to the beginning it's kind of like I want to drop that first value, and use the last two registers to get the new one that goes at the end. The inputs to add together are the two registers that come before `j`, cyclically! `select{f, j+tup{-2,-1}}` gets these because, first it can select with multiple indices at once, and second, negative indices wrap around to the end. If `j` is `1` you get `select{f, tup{-1,0}}`, which gets the last and first ones, for example!

Another thing that changes is the modular reduction that used to look like this. In vector registers, comparison automatically gives you a bitmask of all 0 or 1, so it's just `fr -= m & (fr >= m)`!

      each{{f1} => f1 -= mod & -promote{u32, f1 >= mod}, f1}

Timing the new version I get 1.9 seconds, almost twice as fast as the best straight-line version! Okay, that's not actually a very big speedup for SIMD code. Using vectors of four numbers can make things four times faster a lot of the time! My first thought was the transpose taking up all the time, but it isn't because when I take it out nothing gets faster even though I'm not even writing in the right order. But if I take out the modular part `fr -= m & (fr >= m)` it does speed up, a little. The difference is that that the modular reduction has to be done before the next step—it's the same problem we had before with not using our instruction-level parallelism! So doing multiple sets of vector registers at once would probably be faster. Or wider ones, because 16-byte vector registers are the smallest kind!

But that won't get us that far either because even if I snip out *all* the computation and just use `each{store{., i, .}, d, f}` for the loop body it takes 1.6 seconds! This program goes over a whole 6GB of memory and never revisits any of it, so it doesn't get to use caches at all. And uncached memory is kind of slow, well 4GB in a second is pretty fast if you think about it but it's not always enough to keep up with a vector CPU!

Anyway, I think using almost all the memory bandwidth for some Fibonacci digits I didn't really need is fun but if you need to speed it up more I know Singeli can do it!

## Transposing by zipping

Since Singeli added built-in [support for selection](../include/README.md#simd-selection), we can do a nice transpose implementation that doesn't need to worry about the architecture! Again, I'm using the iintrinsic one for x86, but ARM can use neon\_intrin. Here's the code:

    include 'arch/iintrinsic/select'
    def transpose4x4{f} = {
      def zip{a,b} = each{zip{a,b, .}, iota{2}}
      def zips{{a,b}} = each{zip, a,b}
      join{zips{zips{split{2, f}}}}
    }

The whole thing only uses one select function, `zip{}`! What it does is to interleave two vectors, one element from the first one, then the same one from the other, and the next from the first, until they're all done. But this would end up as two vectors long, and vector instructions only output one vector, so I have to call `zip{}` twice! `zip{a,b,0}` is one half of the result and `zip{a,b,1}` is the other half. I always want both of these, so I use `each{zip{a,b, .}, iota{2}}` to get the list of both of those, since `iota{2}` is `tup{0,1}` you know. Oh and I just call it `zip` because it doesn't overlap with the built-in `zip`'s arguments, it's just a little local extension that won't affect anything outside of `transpose4x4`.

Actually one-means-two zips still isn't big enough, because I have *four* vectors! The function `zips{}` uses `each{zip, a,b}` like a double-size version of `zip{}`. If `a` is `tup{a0,a1}` and `b` is `tup{b0,b1}`, we get `tup{zip{a0,b0}, zip{a1,b1}}` which is the right order if you work it out. You could even say `each{}` is sort of a zip, like `join{each{tup, a,b}}` zips two lists that are the same length, actually even more interestingly if you look at [util/tup](../include/util/tup.singeli) it has `def flip{tab} = each{tup, ...tab}` so `each` is kind of a transpose thing too!

Now `zips` takes a tuple of pairs because of the extra braces around `a,b`, and it returns the same thing, but `f` is only a tuple of four vectors! So to make it two by two we have another tuple function `split{2, f}`, and to undo that and put the two halves back together we have `join{}`. And that's all the functions we need! So the actual computation `join{zips{zips{split{2, f}}}}` splits into two double-vectors, zips them together *twice*, and then un-splits.

But… why does it work exactly? Since there's not much data we can start by drawing it out to see what happens at each step. Here's what we want to happen!

    abcd      aeim
    efgh  >>  bfjn
    ijkl  >>  cgko
    mnop      dhlp

And here are the two steps, when we arrange the vectors two by two. If you look at just the first vector, `abcd` gets spaced out over the first row, and then the entire list to turn into the first result column!

    abcd efgh  //  aibj ckdl  //  aeim bfjn
    ijkl mnop  //  emfn gohp  //  cgko dhlp

      01|23          30|12          23|01

Under it I have some mysterious numbers! They're a better way to work on transposing once you get the hang of it, I think. Instead of a 2x2 list of vectors, I think of the original 4x4 matrix as a 2x2x2x2 shape, and I give each of the four axes a number! The axes start out in their original positions, which I write `01|23` so that the left of the `|` is the lower-order axes inside of a vector, and the right is the axes outside of a vector. These outside axes disappear when we run the program and it just becomes a jumble of registers, so we could swap them for free with a `flip{}` if we wanted! But the way we did the zipping means we don't have to! It takes the very outside axis and moves it to the inside by putting pairs of elements on each side next to each other, and shifts the other axes up to make room. Doing this twice is the same as swapping the inner two axes with the outer two, which is a 4x4 transpose!

And for fun, here's an earlier version I had, that does the same steps but with a different interpretation! It does pairwise zips and leaves the pairs in place so the middle step is flipped relative to what we had before. And it uses some cool features like `{...a}` to be the same as just `a` but only matching if that argument is a list! All the eaches are kinda complicated so I'm glad I found a better way, but it's good for practice still!

    def transpose4x4{f} = {
      def zip{{...a}, {...b}, i} = each{zip{..., i}, a, b}
      def zips{{a,b}} = each{zip{a,b,.}, iota{2}}
      join{each{zips, zips{split{2, f}}}}
    }

    abcd efgh  ^^  aibj emfn  <>  aeim bfjn
    ijkl mnop  vv  ckdl gohp  <>  cgko dhlp

      01|23          30|21          23|01

Oh also… I dunno why, but transposing `[4]u32` comes out just a little slower for me than when I was using `[4]f32` for `_MM_TRANSPOSE4_PS`. So you can re-add the casts from that version to get the same speed it had before.
