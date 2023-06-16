# Singeli is a (mostly) pure functional interpreter

(And [Haskell is a dynamically-typed, interpreted language](https://aphyr.com/posts/342-typing-the-technical-interview) but it's so hard to use!)

So you want to write a quick script with Singeli! Perfect, it's a functional scripting language, kind of like Erlang. It's missing some features like reading files and the interpreter's a little basic and slow, but it's fine for small tasks!

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

It prints `fib{90}` in hex, so quirky! It's not actually a special kind of number. Singeli's number's are all the same, a kind of high precision float. It fits exact integers up to 10<sup>30</sup> and even a little higher, which is pretty big!

There's another way to define the two cases for `fib2{}` that looks more functional. You first write the general case and then the specific one `n==0`. Singeli scans the cases backwards! Secretly when you write the second definition it modifies `fib2`, which means a little bit of the language isn't pure functional. But that mostly doesn't make a difference.

    def fib{n} = {
      def fib2{n} = {
        def {a, b} = fib2{n - 1}
        tup{b, a+b}
      }
      def fib2{n==0} = tup{0, 1}
      tupsel{0, fib2{n}}
    }

This recursion doesn't do that much though. It just starts with `tup{0, 1}` and does a transformation on it `n` times! Is there a simpler way to write it? Singeli has a built-in library [util/tup](../include/util/tup.singeli) with some tuple functions that help with this. It's inspired by K, how cool is that?

    include 'skin/c'
    include 'util/tup'
    show{iota{2}}           # tup{0,1}
    show{fold{+, iota{5}}}  # 10

So `iota{n}` lists the natural numbers up to `n`, and `fold{}` does a left fold or reduction or accumulate or whatever. It's 10 like bowling pins! The repeat-`n`-times thing isn't in util/tup because it's more of a generator thing, but one way to do it is with a fold that ignores the right argument!

    include 'skin/c'
    include 'util/tup'

    def repeat{gen, k, param} = fold{{a,b}=>gen{a}, param, iota{k}}
    def fib{n} = {
      # Can't def next{{a, b}} yet but it's supposed to work!
      def next{t} = {
        def {a, b} = t
        tup{b, a+b}
      }
      tupsel{0, repeat{next, n, iota{2}}}
    }

Oh, I haven't used an anonymous function yet! `{a,b}=>gen{a}` is one of those, and it just wraps `gen` and ignores the `b` argument. One last thing, there's a tricky way to write `next{}` with using tuples. If we reverse `a,b` we get `b,a`, and the only difference from `b, a+b` is the added `b`. The `scan` generator can do this. `scan{+, tup{a,b,c}}` is `tup{a,a+b,a+b+c}` but we're going to use a short version!

    def repeat{gen, k, param} = fold{{a,b}=>gen{a}, param, iota{k}}
    def fib{n} = {
      def next{t} = scan{+, reverse{t}}
      tupsel{0, repeat{next, n, iota{2}}}
    }

Lots of curly braces!
