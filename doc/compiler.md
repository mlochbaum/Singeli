# Singeli is a macro-oriented compiler

Using Singeli for your next project? Yeah, it's all right. The Rustacean numbskulls haven't gotten to it yet, it's actually useful like C. Well, there's some functional mumbo-jumbo buried in there, but it stays out of the way most of the time.

    include 'debug/printf'
    main {
      lprintf{'Hello, World!'}  # Print with newline
    }

There's the classic to start off with. You compile to C with `singeli hello.singeli -o hello.c`, then compile and run that. Ugly but at least gcc/clang generate decent code, next best thing to doing the registers by hand. Now, `main` here is special syntax and not a function, and you may want to integrate Singeli with an existing codebase, so here's how you get a function you can call from C:

    include 'debug/printf'

    fn hello() : void = {
      lprintf{'Hello, World!'}
    }

    export{'hello', hello}

You can figure out the C stub that calls `hello()` to test it I'm sure. And `singeli -h` for compilation options, I won't bore you with the details.

You'll notice that `lprintf{}` doesn't use parentheses like a function call. You do call functions with parens, but `lprintf` isn't a function. We'll get to that. And you'll notice that printing is classified as a debugging tool where it belongs. Singeli is for programming: data goes in, data goes out. Text processing? Sure, text is data. The things in quotes aren't strings though. They're called symbols and they're mostly used for stuff like names that only exists at compile time. `lprintf{}` takes them because it's convenient.

The curly brace calls. They're an eyesore but there's a reason. A function has a defined type signature, and printing just takes whatever pile of junk you give it. Even in C it's some kind of special function. Basically, the braces tell you that `lprintf{}` is a macro. It'll generate some code but you don't know what. So it's officially called a generator. I just say macro. Oh, code's in [include/debug/printf.singeli](../include/debug/printf.singeli) for your gut-viewing pleasure.

Let's at least pretend to get some work done. Reverse a string—Pascal-style, you've got to admit C's made some mistakes.

    include 'skin/c'
    include 'arch/c'

    fn reverse(str:*u8, len:u64) : void = {
      i:u64 = 0
      while (i < len) {
        --len
        c := load{str, i}
        store{str, i, load{str, len}}
        store{str, len, c}
        ++i
      }
    }

Now we are getting somewhere, `load{}` and `store{}` aside. You need skin/c and arch/c to do anything: in a fit of overengineering the authors have decided maybe you'd want something other than C operators and backend. `*u8` is a pointer. You can load and store at any index, and cast it to other pointer types. Better compile C with `-fno-strict-aliasing`, by the way. And Singeli only has prefix operators so you have `--len` to decrement but no `len--`.

Singeli's string handling sucks, so to test this out we're going to just call C stuff directly. This is how the libraries like debug/printf and arch/c are implemented. `emit{}` is a built-in that takes a result type and function name (or operator, with `'op +'` or similar) and calls the C function directly. It takes symbols, which is what lets me jam a string in with `'"%s\n"'`, but it might not work that way forever. And `require{}` gets a C header. Since its a macro you can call it anywhere, like inside `main` or another macro you run. Requiring the same header many times is fine; it'll only generate one `#include`.

    require{'stdio.h', 'string.h'}
    main(argc, argv) {
      arg := load{argv, 1}
      reverse(arg, emit{u64, 'strlen', arg})
      emit{void, 'printf', '"%s\n"', arg}
    }

You call this with `./a.out sometext` and it prints out the reversed text. Okay, now to deal with this `load` and `store` junk. As you may have guessed, Singeli doesn't support `array[index]` syntax, and it doesn't really have a concept of lvalues either. But there's a library [skin/cext](../include/skin/cext.singeli) that defines some extra operators that aren't in C, mainly for dealing with pointers and casting (which we'll see later; Singeli's anal about types). Now the syntax is `array->index` to load, same as a C struct pointer, and `array <-{index} value` to store, where the `{index}` part is optional. So this is kind of tolerable.

    include 'skin/c'
    include 'skin/cext'
    include 'arch/c'

    fn reverse(str:*u8, len:u64) : void = {
      i:u64 = 0
      while (i < len) {
        --len
        c := str->i
        str <-{i} str->len
        str <-{len} c
        ++i
      }
    }

    require{'stdio.h', 'string.h'}
    main(argc, argv) {
      arg := load{argv, 1}
      reverse(arg, emit{u64, 'strlen', arg})
      emit{void, 'printf', '"%s\n"', arg}
    }

I'm smarter than a Gopher and don't like to spend all my time writing reverse functions, so if I have a codebase with multiple types I want my `reverse` to be generic. Or generated I might say. So I add a type parameter `{T}`, and call this with `reverse{u8}(str, len)`. Whenever `reverse` is called on a type it hasn't seen before, it generates a new function for that type (has to be a type, because `*T` is in a type signature). If it sees an old type, it reuses its previous result—this is a special feature for generic functions only.

    fn reverse{T}(vec:*T, len:u64) : void = {
      i:u64 = 0
      while (i < len) {
        --len
        c := vec->i
        vec <-{i} vec->len
        vec <-{len} c
        ++i
      }
    }

Of course, if I'd used `u8` inside the function, I'd need to replace those with `T` too. One reason I don't need to do this is the declaration `c := vec->i`, which gets the type from the expression so it means the same thing as `c:T = vec->i`.
