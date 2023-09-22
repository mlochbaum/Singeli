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
    show{tupsel{1, things}}          # 'Fibonacci'
    def {number, name, hi} = things
    show{hi, 'World!'}               # 'Hello', 'World!'

The comments with `#` say what this prints. We make a tuple with `tup{}`, and we can select one part with `tupsel{}`. See, curly braces for everything! We also have `def {…}` to break up a tuple, but it doesn't use `tup` because it's special syntax.

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
      tupsel{0, fib2{n}}
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
      tupsel{0, fib2{n}}
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
      tupsel{0, repeat{next, n, iota{2}}}
    }

Oh, I haven't shown an anonymous function before! `{a,b}=>gen{a}` is one of those, and it just wraps `gen` and ignores the `b` argument. One last thing, there's a tricky way to write `next{}` with using tuples. If we reverse `a,b` we get `b,a`, and the only difference from `b, a+b` is the added `b`. The `scan` generator can do this. `scan{+, tup{a,b,c}}` is `tup{a,a+b,a+b+c}` but we're going to use a shorter version!

    def repeat{gen, k, param} = fold{{a,b}=>gen{a}, param, iota{k}}
    def fib{n} = {
      def next{t} = scan{+, reverse{t}}
      tupsel{0, repeat{next, n, iota{2}}}
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
      tupsel{0, f}
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
      def f1 = tupsel{1, f}
      def next{t} = scan{+, reverse{t}}
      while (n>0) { n = n - 1; f = next{f}; f1 = f1%1e9 }
      tupsel{0, f}
    }

    include 'debug/printf'
    main() = lprintf{fib(1e9)}  # 560546875

I'm getting ahead of myself, there's a lot here I haven't explained! The trick for reading `fn` is that it's really a straight-line block of code, but it *defines* a loopy program. So `while` only runs the condition and block once, but it does it symbolically so then it can make C code that does it like a billion times. Exactly a billion times! And one extra on the condition. You can put `show` anywhere to see how the interpreter runs things. It runs the block before the condition, quirky!

      while (show{n}>0) { n = n - 1; f = next{f}; show{f1} = f1%1e9 }

Since `n` and `f1` don't have fixed values, `show` prints a symbolic description instead. For `f1` it shows `f:u32`, but that makes sense. We set `def f1 = tupsel{1, f}`, and why would `show{tupsel{1, f}}` use the name `f1`? Another thing, `show` works on the left of `=`! It's because `=` on its own without `def` is a regular operator. The only built-in one! Since the left-hand side is a symbol, it *makes* code that changes the value of this symbol but it doesn't actually change the symbol.

So symbols work this way because when you're writing for the CPU you want types that match what it will handle, like `u64` or `u32` here. And you want to be able to modify them in place like a register can, well not always, but here, kinda. A symbolic value like `n:u64` is actually called a *register* because of that! And it's really CPU-oriented, so it's always something that fits in one CPU register. When we define `f` to contain two values it defines two registers, each holding one value. That's why we can pick out one with `tupsel{}`! Also they're both called `f` but Singeli changes the way it names registers sometimes so maybe it can get more specific!

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
      def f1 = tupsel{1, f}
      def next{t} = scan{+, reverse{t}}
      @for (n) { f = next{f}; f1 = f1%1e9 }
      tupsel{0, f}
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
- If it's odd, write as `2*k+1, so it's `next{double{fib2{k}}}`

In both cases, `k` is half of the number we want to get, rounded down. We can write that as `n >> 1`, although `__floor{n/2}` works too! And `n` is odd if `n%2` is `1`. Lastly, we use the base case 0 from before—sometimes with exponential things you have to define 1 too, but when rounding down `1 >> 0` is `0` so it's not needed! Also I wrote `(0)` instead of `n==0` just to show another way to write it.

    include 'skin/c'
    include 'util/tup'

    def fib{n} = {
      def next  {{a, b}} = tup{b, a+b}
      def double{{a, b}} = tup{a*(b+b-a), a*a + b*b}
      def fib2{n} = {
        def g = double{fib2{n >> 1}}
        (if (n%2) next{g} else g) % 1e9
      }
      def fib2{(0)} = iota{2}
      tupsel{0, fib2{n}}
    }

    show{fib{1e9}}  # 560546875

Like I said, it's instant! 1e9 is about 2 to the 30 because 1e3 is just under 1024 which is 2 to the 10th power. So it's only 30 steps to go all the way to a billion!

Another cool thing we can see now that we can compute last digits fast is that those digits repeat! Here's the sequence starting at 1,500,000,000:

    show{each{fib, 1.5e9 + iota{5}}}  # tup{0,1,1,2,3}

Of course the actual numbers that far along in the sequence are *huge*, but the last nine digits aren't! As soon as we see 0 then 1 in the sequence we know it has to repeat exactly from the start. This is called the 1e9th [Pisano period](https://en.wikipedia.org/wiki/Pisano_period), and you can find a guaranteed multiple of it but it's a little more math than I want to go into here! But once you know the multiple you check all the divisors for that 0-1 pattern and the first one is it!

Here's an extension to `fib2{}` that takes this into account. Now if there's a really huge number you won't hit a recursion limit!

      def pis = 1.5e9  # modulo 1e9
      def fib2{n & n>=pis} = fib2{n % pis}

This could all be translated into a C loop, but why should I if it's already instant? Maybe it's a fun exercise though—try looking at the bits of the index.
