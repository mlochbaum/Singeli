# Singeli is a macro-oriented compiler

Using Singeli for your next project? Yeah, it's all right. The Rustacean numbskulls haven't gotten to it yet, so it's C-like and actually useful. Well, there's some functional mumbo-jumbo buried in there, but it stays out of the way most of the time.

    include 'debug/printf'
    main : void {
      lprintf{'Hello, World!'}  # Print with newline
    }

There's the classic to start off with. You compile to C with `singeli hello.singeli -o hello.c`, then compile and run that. Ugly but at least gcc/clang generate decent code, next best thing to doing the registers by hand. Now, `main` here is special syntax and not a function, and you usually integrate Singeli with an existing codebase, so here's how you get a function you can call from C:

    include 'debug/printf'

    fn hello() : void = {
      lprintf{'Hello, World!'}
    }

    export{'hello', hello}

You can figure out the C stub that calls `hello()` to test it I'm sure. And `singeli -h` for compilation options, I won't bore you with the details.

You'll notice that `lprintf{}` doesn't use parentheses like a function call. You do call functions with parens, but `lprintf` isn't a function. We'll get to that. And you'll notice that printing is classified as a debugging tool where it belongs. Singeli is for programming: data goes in, data comes out. Text processing? Sure, text is data. But the things in quotes aren't strings: they're called symbols and they're used for name-ish stuff that only exists at compile time. `lprintf{}` takes them because it's convenient.

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

Singeli's string handling sucks, so to test this out we're going to call C functions directly. This is how the libraries like debug/printf and arch/c are implemented. `emit{}` is a built-in that takes a result type and function name (or operator, with `'op +'` or similar) and calls the C function directly. It outputs symbols verbatim, which is what lets me jam a string in with `'"%s\n"'`, but it might not work that way forever. And `require{}` gets a C header. Since it's a macro you can call it anywhere, like inside `main` or another macro you run. Requiring the same header many times is fine; it'll only generate one `#include`.

    require{'stdio.h', 'string.h'}
    main(argc, argv) {
      arg := load{argv, 1}
      reverse(arg, emit{u64, 'strlen', arg})
      emit{void, 'printf', '"%s\n"', arg}
    }

Call this with `./a.out sometext` and it prints out the reversed text. And now to deal with this `load` and `store` junk. As you may have guessed, Singeli doesn't support `array[index]` syntax, and it doesn't really have a concept of lvalues either. But there's a library [skin/cext](../include/skin/cext.singeli) that defines some extra non-C operators, mainly for dealing with pointers and casting (which we'll see later; Singeli's anal about types). Now the syntax is `array->index` to load, same as a C struct pointer, and `array <-{index} value` to store, where the `{index}` part is optional. So this is kind of tolerable.

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

I'm smarter than a Gopher and don't like to spend all my time writing reverse functions, so if I have a codebase with multiple types I want my `reverse` to be generic. Generated, even. So I add a type parameter `{T}`, and call this with `reverse{u8}(str, len)`. Whenever `reverse` is called on a type it hasn't seen before, it generates a new function for that type (has to be a type, because of the `*T` in a type signature). Then it reuses that function if the same type comes up again—this is a special feature for generic functions and not other macros.

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

Of course, if I'd used `u8` inside the function, I'd need to replace those with `T` too. One reason I don't need to do this is that the declaration `c := vec->i` gets the type from the expression, so it's the same as `c:T = vec->i`.

## SIMD

You're probably here for the vector processing stuff. Is this going to save me from `__m256d v = _mm256_fmsubadd_pd...` on every line of the program? The convenience of the C++ packages without Bjarne's head games? Ha, as a programmer you'd better learn to accept the head games, but these ones can largely be shuffled off to an `include` file. Vectorizing that reverse function will take us through the basics.

Real built-in vector support would apparently harsh Singeli's minimalist vibe, so all you get out of the box are vector types, written like `[16]i8`. Which is better than C's `__m128` for every integer because now `a+b` has a clear meaning. Oh, and it knows which vector extensions exist, so you can test whether your target architecture supports one with `hasarch{'SSSE3'}`. Here I'm going to use x86 with vector extensions up to SSSE3 (released in 2006, yes you have it, unless you're on ARM). By default, Singeli picks up architecture flags from the current CPU to compile for native execution. Or you can specify with `-a SSSE3`, although if you're not on x86 of course you've got no way to run the output C code.

To make use of my `[16]i8`s instead of leaving them to sit around and look pretty I need some definitions, which will compile to C intrinsics. There are two libraries for these right now. [arch/iintrinsic/basic](../include/README.md#simd-basics) is a curated set of "nice" operations like load, store, and arithmetic, and arch/iintrinsic/misc is a dump of the rest (iintrinsic is "intel intrinsics", which is the target the same way C is for arch/c). I only need one macro from misc, so I'm just going to copy it over.

    include 'arch/iintrinsic/basic'
    def shuffle{a:T==[16]i8, b:T} = emit{T, '_mm_shuffle_epi8', a, b}

EDIT: That was good to build character and all, but now there's a [usable wrapper](../include/README.md#simd-selection) for shuffling (blending too, eh, let's ignore it because the instructions weren't added until after SSSE3), so I'll just patch this in:

    include 'arch/iintrinsic/select'
    def shuffle{a:T==[16]i8, b:T} = vec_shuffle{a, b}

Looks like `#define`, but these `def` macros are smart: you can check compile-time conditions to decide whether it applies. If not it'll try the previous definition if any, meaning it's an overload. `shuffle` doesn't overload anything, so just errors if `a` and `b` don't have type `T` which is `[16]i8`. On the other hand, there's something we do want to overload:

    fn reverse{T==i8 if hasarch{'SSSE3'}}(arr:*T, len:u64) : void = {
      def V = [16]T
      r := vec_make{V, 15 - range{16}}
      av := *V~~arr
      av <- shuffle{av->0, r}
    }

Not a full implementation—for now it's ignoring `len` and reversing 16 elements. But there are a few new things, besides the conditions added to `reverse`. The macro `def V = [16]T` is basically a typedef. Macros are scoped so that it only applies inside `reverse`. The casting operator `~~` is defined by skin/cext as `reinterpret`, which converts between types of the same width. `range{16}` gives the integers from 0 to 15 inclusive, and I subtract from 15 to reverse the order. All this happens at compile time, and `-` working on a list is showing some APL influence. Somehow we got one of the good bits here.

And it makes sense that `-` should be able to act on multiple numbers at compile time because (with arch/iintrinsic/basic) it applies to vectors at runtime. Instead of `vec_make{V, 15 - range{16}}` it could be `vec_broadcast{V, 15} - vec_make{V, range{16}}`. These two vector-building macros come from arch/iintrinsic/basic, and if you haven't heard of it, "broadcasting" is one name for spreading a single value to all elements of a vector. A better use of vector arithmetic is to extend `reverse` to deal with 16 elements or less:

    fn reverse{T==i8 if hasarch{'SSSE3'}}(arr:*T, len:u64) : void = {
      def V = [16]T
      f := vec_make{V, range{16}}       # forward
      r := vec_make{V, 15 - range{16}}  # reverse
      l := vec_broadcast{V, T<~len}
      m := V~~(f < l)
      s := ((l - f - vec_broadcast{V, 1}) & m) | andnot{f, m}
      av := *V~~arr
      av <- shuffle{av->0, s}
    }

The basic idea is to read an entire vector regardless of length, reverse only the first `len` elements, and put it back. So this reads from and writes to memory beyond the actual vector argument. Obviously you need to know you have access to that memory, but that's easy to ensure if you control the allocations. But C and other compilers can't figure it out so it's one way writing your own SIMD is better.

The specific idea is to blend a vector that starts at `len-1` and goes down with the identity vector `f`. We choose the descending vector for the first `len` elements, using the mask `f < l`. The result of an SSE comparison is all 0 bits or all 1, and it has an unsigned type but `V` is signed, so slap on `V~~`. Next section I'll show a blend utility that keeps this mess out of sight.

And another cast `<~` in there. The three casts skin/cext defines are `~~` for reinterpret, `^~` for promoting from a type to a superset, and `<~`. At the moment this one just always does a C cast, but the idea is to use it for a narrowing integer conversion. Get familiar with these because Singeli requires a lot of casting. Or at least the standard definitions do, nothing preventing you from extending those.

So now we can put together a function that works on any length. Language-wise there's nothing new here unless you consider an `if` statement to be a surprise. But there's a trick for handling when the two vector pointers meet in the middle. If there's one vector or less between them, we have the code for that. If there are two vectors or less, we could reverse one full and one partial vector, but that's ugly. Instead we're going to reverse two overlapping full vectors. This actually doesn't take any changes other than the loop bound. The main loop was going to read the two vectors and then write two reversed ones anyway, so the writes don't interfere with the reads.

    include 'arch/iintrinsic/basic'
    include 'arch/iintrinsic/select'
    def shuffle{a:T==[16]i8, b:T} = vec_shuffle{a, b}
    fn reverse{T==i8 if hasarch{'SSSE3'}}(arr:*T, len:u64) : void = {
      def V = [16]T
      f := vec_make{V, range{16}}
      r := vec_make{V, 15 - range{16}}
      av := *V~~arr        # beginning of part not yet reversed
      bv := *V~~(arr+len)  # just after the end of that part
      while (av+1 < bv) {
        --bv
        c  := shuffle{av->0, r}
        av <- shuffle{bv->0, r}
        bv <- c
        ++av
      }
      if (av < bv) {
        rem := *T~~bv - *T~~av
        l := vec_broadcast{V, T<~rem}
        m := V~~(f < l)
        s := ((l - f - vec_broadcast{V, 1}) & m) | andnot{f, m}
        av <- shuffle{av->0, s}
      }
    }

There you have it, reversing bytes at SSE speed. AVX2 ought to be twice as fast but it's got this ridiculous design where it only shuffles within 16-byte lanes—it's not that much overhead but it's more of a headache than I'm willing to put up with right now.

## Generics

I already said I don't like repeating myself. Instead of copy-pasting, I'll make this vector reverse work on multiple types, which will take a little more macro usage. First some cleanup.

    oper &~ andnot infix none 35

This defines the and-not operator so that `a &~ b` is `a & ~b`. The C backend could probably work the second one out, but it's nice to know you're generating one `andnot` intrinsic. And even if an `&~` operator isn't defined, `&~` with no space won't split into `&` and `~` for consistency. Or maybe because developers are scared of working on the lexer, take your pick. The `infix none 35` thing is the parsing information, which I just copied from `&` in cop.singeli.

    def blend{m:M, t:T, f:T} = (t & T~~m) | (f &~ T~~m)

And this is a macro for blend, the vector equivalent of `if (m) t else f`. Again we've got the smart macro, where the inputs all have to be typed and `t` and `f` have to have the same type. What it does is to get all their types and then check that the ones with the same name are consistent. Another thing, we use `m` twice, which should have a C programmer twitching. But it's safe: `blend` isn't operating on source tokens, but instead saying what to do with values. Which is also how it can check types, because by the time the macro gets processed its inputs have been handled by the compiler and their types are known. And the story is the same at runtime: all macro inputs are evaluated, and then the code in the macro runs.

Now the hard part, which is to make this work on other types. For a lot of simpler vector algorithms you mostly just have to change the vector type, so you'd write something like `def V = [128/width{T}]T` to make a 128-bit vector and you're done. Here that doesn't work because SSSE3 only has this one shuffle instruction, which works on 1-byte units. So we're going to define `V` as `[16]i8`. Then it's bit-bashing time to reverse the `T`-width units in those vectors. Here, I'll dump it all out so you can see what I'm talking about.

    include 'arch/iintrinsic/basic'
    include 'arch/iintrinsic/select'
    oper &~ andnot infix none 35
    def blend{m:M, t:T, f:T} = (t & T~~m) | (f &~ T~~m)
    def shuffle{a:T==[16]i8, b:T} = vec_shuffle{a, b}

    fn reverse{T if hasarch{'SSSE3'}}(arr:*T, len:u64) : void = {
      def b = width{T} / 8  # width of T in bytes
      def vb = 16
      def vi = range{vb}
      def V = [vb]i8
      def scal{x} = vec_broadcast{V, x}
      f := vec_make{V, vi}
      r := vec_make{V, vb-b - vi + 2*(vi%b)}
      av := *V~~arr
      bv := *V~~(arr+len)
      while (av+1 < bv) {
        --bv
        c  := shuffle{av->0, r}
        av <- shuffle{bv->0, r}
        bv <- c
        ++av
      }
      if (av < bv) {
        rem := *T~~bv - *T~~av
        l := scal{i8<~(b*rem)}
        m := V~~(f < l)
        s := blend{m, r + l - scal{vb}, f}
        av <- shuffle{av->0, s}
      }
    }

The main loop always does the same permutation, analogous to `vec_make{V, 15 - range{16}}` from before but with more arithmetic. I've defined `vi = range{vb}` to make this a little simpler—if you haven't noticed, just about anything can go in a `def`. Still, `r` is a real head-scratcher. But it's a compile-time head scratcher, and that means I can stick `show` calls all over the place before compiling to see what's going on. `show` just returns its input so it doesn't affect the compiler output, but it also prints that input. See below. These are for the `i32` case, and since I don't actually call it I just added a line `reverse{i32}` which is enough to make sure the function is compiled.

      r := vec_make{V, show{vb-b} - vi + 2*(vi%b)}
    # 12
      r := vec_make{V, show{vb-b - vi} + 2*(vi%b)}
    # tup{12,11,10,9,8,7,6,5,4,3,2,1,0,-1,-2,-3}
      r := vec_make{V, show{vb-b - vi + show{2*(vi%b)}}}
    # tup{0,2,4,6,0,2,4,6,0,2,4,6,0,2,4,6}
    # tup{12,13,14,15,8,9,10,11,4,5,6,7,0,1,2,3}

First line shows `vb-b`, which is the first byte after reversing, or the start of the last element before. And the elements go down from there so I subtract `vi`. But this means bytes go down within an element when I want them going up, so I add twice the byte index `vi%b` within each element.

And then the last vector is a minor variation on what we did before. Work it out yourself if you really care. Can't get reverse by subtracting the forward vector from a constant any more, so I added the reverse one to a different constant. This arithmetic all happens at runtime, so you won't get anything useful out of `show`, but `lprintf` does handle vectors.

What about AVX2, or other architectures? It's all possible. NEON support is going to be pretty easy here since it has just about the same instructions: use `hasarch{'SSSE3'} or hasarch{'AARCH64'}` for the condition, qualify the `shuffle` we have here with `hasarch{'SSSE3'}`, and add a NEON one too (EDIT: now arch/neon\_intrin/basic has you covered, load conditionally with `if_inline`). Then as `reverse` is compiled it'll check the architecture when it calls `shuffle` and use the right one. For AVX2 you have a few options. First thing I'd try is to change `def vb = 16` to `def vb = if (hasarch{'AVX2'}) 32 else 16`, and then make other things check `vb` as necessary. Have fun dealing with that within-lane shuffle.
