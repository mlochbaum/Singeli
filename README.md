# Singeli

Singeli is now able to compile useful programs to C, but it's very rough around the edges, with poor error reporting. We are beginning to use it for [CBQN](https://github.com/dzaima/CBQN), where it's enabled if built with `$ make o3n-singeli`.

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

## Operators

Operators are formed from the characters `!$%&*+-/<=>?\^|~`. Any number of these will stick together to form a single token unless separated by spaces. Additionally, non-ASCII characters can be used as operators, and don't stick to each other.

The `oper` statement, which can only appear at the top level in the program, defines a new operator, and applies to all code later in the program (operators are handled with a Pratt parser, which naturally allows this). Here are the two declarations of `-` taken from [include/skin/c.singeli](include/skin/c.singeli).

    oper prefix      -  __neg 30
    oper infix left  -  __sub 30

The declaration lists the operator's form (arity, and associativity for infix operators), spelling, generator, and precedence. After the declaration, applying the operator runs the associated generator.

An operator can have at most one infix and one prefix definition. Prefix operators have no associativity (as operators can't be used as operands, they always run from right to left), while infix operators can be declared `left`, `right`, or `none`. With `none`, an error occurs in ambiguous cases where the operator is applied multiple times. The precedence is any number, and higher numbers bind tighter.

## Built-in generators

The following generators are pre-defined in any program. They're placed in a parent scope of the main program, so these names can be shadowed by the program.

### Program

| Syntax                 | Result
|------------------------|--------
| `emit{type,op,args…}`  | Call instruction `op` (a symbol, to be interpreted by the backend)
| `call{fun,args…}`      | Call a function
| `return{result}`       | Return `result` (optional if return type is `void`) from current function
| `exec{ind,vars,block}` | Execute `block` on pointers `vars` at index `i`
| `load{ptr,ind}`        | Return value at `ptr+ind`
| `store{ptr,ind,val}`   | Store `val` at `ptr+ind`

### Values

| Syntax              | Result
|---------------------|--------
| `match{a,b}`        | Return 1 if the parameters match and 0 otherwise
| `hastype{val,type}` | Return 1 if `val` is a typed value of the given type
| `type{val}`         | Return the type of `val`
| `kind{val}`         | Return a symbol indicating the kind of value
| `show{vals…}`       | For debugging: print the parameters, and return it if there's exactly one

Possible `kind` results are `number`, `constant`, `symbol`, `tuple`, `generator`, `type`, `register`, `function`, and `block`.

### Types

| Syntax           | Result
|------------------|--------
| `width{type}`    | The number of bits taken up by `type`
| `eltype{type}`   | The underlying type of a vector or pointer type
| `vcount{[n]t}`   | The number of elements `n` in a vector type
| `cast{type,val}` | `val` converted to the given type
| `isfloat{type}`  | 1 if `type` is floating point and 0 otherwise
| `issigned{type}` | 1 if `type` is signed integer and 0 otherwise
| `isint{type}`    | 1 if `type` is integer and 0 otherwise
| `typekind{type}` | A symbol indicating the nature of the type
| `__pnt{t}`       | Pointer type with element `t`
| `__vec{n,t}`     | Vector type with element `t` and length `n`; equivalent to `[n]t`

Possible `typekind` results are:

| Type kind   | Example display
|-------------|--------
| `void`      | `void`
| `primitive` | `i32`
| `vector`    | `[4]i32`
| `pointer`   | `*f64`
| `function`  | `(i8,u1) -> void`
| `tuple`     | `tup{u1,[2]u32}`

### Generators

| Syntax             | Result
|--------------------|--------
| `bind{gen,param…}` | Bind/curry the given parameters to the generator

### Tuples

| Syntax              | Result
|---------------------|--------
| `tup{elems…}`       | Create a tuple of the parameters
| `tupsel{ind,tuple}` | Select the `ind`th element (0-indexed) from the tuple
| `apply{gen,tuple}`  | Apply a generator to a tuple of parameters

### Arithmetic

Arithmetic functions are named with a double underscore, as they're meant to be aliased to operators. The default definitions work on compile-time numbers, and sometimes types. The definitions for numbers are shown, with a C-like syntax but using `^` for exponentiation and `//` for floored division.

| `__neg` | `__shr`  | `__shl` | `__add` | `__sub` | `__mul` | `__div` |
|---------|----------|---------|---------|---------|---------|---------|
| `-y`    | `x//2^y `| `x*2^y `| `x+y`   | `x-y`   | `x*y`   | `x/y`   |

| `__and` | `__or`      | `__xor` | `__not` |
|---------|-------------|---------|---------|
| `x*y`   | `x*y-(x+y)` | `x!=y`  | `1-y`   |

| `__eq`  | `__ne`  | `__lt`  | `__gt`  | `__le`  | `__ge`  |
|---------|---------|---------|---------|---------|---------|
| `x==y`  | `x!=y`  | `x<y`   | `x>y`   | `x<=y`  | `x>=y`  |
