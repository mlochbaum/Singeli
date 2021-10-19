# Singeli

Singeli is now able to compile useful programs to C, but it's very rough around the edges, with poor error reporting. We plan to use it to implement primitives in [CBQN](https://github.com/dzaima/CBQN), and are currently working to integrate it into the build system there.

Singeli is a domain-specific language for building [SIMD](https://en.wikipedia.org/wiki/SIMD) algorithms with flexible abstractions and control over every instruction emitted. It's implemented in [BQN](https://mlochbaum.github.io/BQN), with a frontend that emits IR and a backend that converts it to C. Other backends like LLVM or machine code are possible—it should be easy to support other CPU architectures but there are no plans to target GPUs.

To compile input.singeli:

```
$ singeli input.singeli [-o output.c]
```

For options see `$ singeli -h`. To run `./singeli` as an executable, ensure that CBQN is installed as `bqn` in your executable path, or call as `/path/to/bqn singeli …`.

Early design discussion for Singeli took place at [topanswers.xyz](https://topanswers.xyz/apl?q=1623); now it's in the BQN forums ([links and instructions](https://mlochbaum.github.io/BQN/index.html#where-can-i-find-bqn-users)).

## Language overview

Singeli is primarily a metaprogramming language. Its purpose is to build abstractions around CPU instructions in order to create large amounts of specialized code. Programs will tend to do complicated things at compile time to emit programs that do relatively simple things at runtime, so it's probably better to orient your thinking around what happens at compile time.

The primary tool for abstraction is the **generator**. Written with `{parameters}`, generators perform similar tasks as C macros, C++ templates, or generics, but offer more flexibility. They are expanded at runtime, and form a Turing-complete language. Generators use lexical scoping and allow recursive calls. Here's a generator that calls another one:

    def gen{fn, arg} = fn{arg, arg + 1}

In fact, `+` is also a generator, if it's defined. Singeli has no built-in operators but allows the user to define infix or prefix operator syntax for a generator. For example, the following line from [include/skin/c.singeli](include/skin/c.singeli) makes `+` a left-associative infix operator with precedence 30 (there can be one infix and one prefix definition).

    oper infix left  +  __add 30

Generators can be extended with additional definitions. Each definition overrides the previous ones on its domain, which means that applying a generator searches backwards through all definitions visible in the current scope until it finds one that fits. `gen` above applies to any two arguments, but a definition can be narrowed using types and conditions:

    def gen{x:T, n, n, S & 'number'==kind{n} & T<=S} = {
      cast{S, x} + n
    }

Here, `x` must be a typed value, and have type `T`, and the two `n` parameters must match. Furthermore, the conditions that follow each `&` must hold. Otherwise, previous definitions are tried and you get an error if there aren't any left. In this context `:` and `&` are syntax, not operators.

The end goal here is to define functions for use by some other program. Functions are declared with a parenthesis syntax at the top level, possibly with generator-like parameters. Types use `value:type` syntax rather than `type value`.

    fn{T}(a:T, len:u64) : {
      while (len > 0) {
        a = a + 1
        len = len - 1
      }
    }

Here you can see that compile-time code is written in an imperative style. `if`, `else`, and `while` control structures are provided. Statements are separated by newlines or semicolons; these two characters are equivalent.

If possible, iteration should be done with for-each loops. In SIMD programming these loops are very important and come in many varieties, taking vectorization and unrolling into account. So Singeli doesn't provide a single for loop structure, but rather a general mechanism for defining loops. Here's what a definition looks like:

    def for{vars,begin,end,block} = {
      i:u64 = begin
      while (i<end) {
        exec{i, vars,block}
        i = i+1
      }
    }

While this loop *is* an ordinary generator (allowing other loops to call it), special syntax is used to invoke it on variables and a code block. Here's an example with two pointers:

    @for (src,dst over i from 0 to len) {
      src = 1 + dst
    }

Outside the loop, these variables are pointers, and inside it, they are individual values. It's `exec` in the loops definition that performs this conversion, using the given index `i` to index into each pointer in `vars`. Each variable tracks whether its value was set inside the loop and writes to memory if this is the case.
