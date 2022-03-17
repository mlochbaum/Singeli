# Singeli

Status: Singeli is now nice to use when everything works: parse and stack traces for errors, and the interactive [Singeli playground](https://github.com/dzaima/singeliPlayground) tool. I'm still fixing lots of broken error reports and some language bugs as dzaima and I spend more time programming with it. Currently it's used for some SIMD functionality in [CBQN](https://github.com/dzaima/CBQN), where it's enabled if built with `$ make o3n-singeli`.

Singeli is a domain-specific language for building [SIMD](https://en.wikipedia.org/wiki/SIMD) algorithms with flexible abstractions and control over every instruction emitted. It's implemented in [BQN](https://mlochbaum.github.io/BQN), with a frontend that emits IR and a backend that converts it to C. Other backends like LLVM or machine code are possible—it should be easy to support other CPU architectures but there are no plans to target GPUs.

To compile input.singeli:

```
$ singeli input.singeli [-o output.c]
```

For options see `$ singeli -h`. To run `./singeli` as an executable, ensure that CBQN is installed as `bqn` in your executable path, or call as `/path/to/bqn singeli …`.

Early design discussion for Singeli took place at [topanswers.xyz](https://topanswers.xyz/apl?q=1623); now it's in the [BQN forum](https://mlochbaum.github.io/BQN/community/forums.html).

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

    fn{T}(a:T, len:u64) : void = {
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

Outside the loop, these variables are pointers, and inside it, they are individual values. It's `exec` in the loop's definition that performs this conversion, using the given index `i` to index into each pointer in `vars`. Each variable tracks whether its value was set inside the loop and writes to memory if this is the case.

## Generators

A generator is essentially a compile-time function, which takes values called parameters and returns a result. There are a few ways to create generators:

    # Anonymous generator, immediately invoked
    def a_sq = ({x} => x*x){a}

    # Named generator with two cases
    def min{a, b} = a
    def min{a, b & b<a} = b

    # Generated function
    triple{T}(x:T) = x + x + x

These are all effectively the same thing: there's a parameter list in `{}`, and a definition. When invoked, the body is evaluated with the parameters set to the values provided. Depending on the definition, this evaluation might end not with a static value, but with a computation to be performed at runtime (this always happens for functions). Generators are dynamically typed, and naturally have no constraints on the parameters or result. But the parameter list can include conditions that determine whether to accept a particular set of parameters. These are described in the next section; first let's go through the syntax for each case.

An anonymous generator is written `{params} => body`. It needs to come at the beginning of a subexpression, which usually means it needs to be parenthesized. Otherwise `{params}` might be interpreted as a generator call on the previous word, for example. `body` can be either a single expression, or a block consisting of multiple expressions surrounded by `{}`.

A named generator is a statement rather than an expression: `def name{params} = body`. `name` can be followed by multiple parameter lists, defining a nested generator. This form also allows multiple definitions. When the generator is called, these definitions are scanned, beginning with the last, for one that applies to the arguments. That is, when applying the generator, it tests the arguments against all its conditions, then runs if they match and otherwise calls the previous definition.

A function can also have generator parameters. This case is discussed in the section on [functions](#functions).

### Conditions

The parameter list in a generator definition has to give the names of parameters, but it can also include some other constraints on them:

* The number of parameters
* Two parameters with the same name match
* A `par:typ` parameter must be a typed value with the given type
* A `par==val` parameter matches the given value
* Explicit conditions `& cond` must hold (result in `1`)

Each of the values `typ`, `val`, and `cond` can be an expression, which is fully evaluated whenever the condition is reached. Parameter names are all bound before evaluating any conditions, so that a condition can refer to parameter values, even ones that come after it in the source code.

The value `typ` can also be a name, which functions something like an extra parameter: the underlying parameter must be typed and the name is set to its type (like any parameter, this value is accessible to conditions). Built-in type names such as `i16` and `f64` can't be used here, but other names will be shadowed. If you have an alias like `def size = u64`, parenthesize it to use it as a value, as in `par:(size)`.

## Kinds of value

A generator is one kind of value—that is, something that's first-class at compile time. Like most values, it doesn't exist at runtime. Hopefully it's already done what's needed! In fact it's one of the more complicated kinds of value. Here's the full list:

| Kind      | Summary
|-----------|--------
| number    | A compile-time, high-precision number
| symbol    | A compile-time string
| tuple     | A compile-time list of values
| generator | Takes and returns values at compile time
| type      | A specific type that a runtime value can have
| constant  | A typed value known at compile time
| register  | A typed value, unknown until runtime
| function  | Takes and returns typed values at runtime
| block     | Used for `@for` loops

The simplest are discussed in this section, and others have dedicated sections below.

Numbers are floating-point, with enough precision to represent both double-precision floats and 64-bit integers (signed or unsigned) exactly. Specifically, they're implemented as pairs of doubles, giving about 105 bits of precision over the same exponent range as a double. A number can be written in scientific notation like `45` or `1.3e-12`, in hex like `0xf3cc0`, or in an arbitrary base with the base preceding `b`, like `2b110101` or `32b0jbm1` (digits like hex, extending past `f`). Numbers are case-insensitive and can contain underscores, which will be removed.

Symbols are Unicode strings, written as a literal using single quotes: `'symbol'`. They're used with the `emit{}` generator to emit instructions, and in export statements to identify the function name that should be exposed.

Constants consist of a value and a type. They appear when a value such as a number is cast, for example by creating a variable `v:f64 = 6` or with an explicit `cast{f64, 6}`. For programming, constants work like registers (variables), so there's never any need to consider them specifically. Just cast a compile-time value if you need it to have a particular type—say, when calling a function that could take several different types.

## Operators

Operators are formed from the characters `!$%&*+-/<=>?\^|~`. Any number of these will stick together to form a single token unless separated by spaces. Additionally, non-ASCII characters can be used as operators, and don't stick to each other.

The `oper` statement, which can only appear at the top level in the program, defines a new operator, and applies to all code later in the program (operators are handled with a Pratt parser, which naturally allows this). Here are the two declarations of `-` taken from [include/skin/c.singeli](include/skin/c.singeli).

    oper prefix      -  __neg 30
    oper infix left  -  __sub 30

The declaration lists the operator's form (arity, and associativity for infix operators), spelling, generator, and precedence. After the declaration, applying the operator runs the associated generator.

An operator can have at most one infix and one prefix definition. Prefix operators have no associativity (as operators can't be used as operands, they always run from right to left), while infix operators can be declared `left`, `right`, or `none`. With `none`, an error occurs in ambiguous cases where the operator is applied multiple times. The precedence is any number, and higher numbers bind tighter.

Parameters can be passed to operators before calling them, such as `a -{b} c`. This is converted to the generator call `__sub{b}{a,c}`. The arity is determined when it's called with operator syntax, and doesn't depend on any earlier calls with generator syntax.

## Functions

Generators are great for compile-time computation, but all run-time computation happens in functions. Functions are declared and called with parenthesis syntax:

    times{T}(a:T, b:T) = a*b  # Type-generic function

    square{T}(x:T) : T = {
      times{T}(x, x)
    }

The body of a function can be either a plain expression like `a*b` above, or can be enclosed in curly braces `{}` to allow multiple statements. It returns the value of the last expression. The return type is given with `:` following the argument list, but can often be omitted (if it's left out and the body uses braces, `=` is also optional).

## Registers

A function's arguments, and variables that it manipulates at runtime, are represented with typed slots called registers. Registers are first-class values, meaning they can be passed around and manipulated at compile time. For example, a generator can take a register as a parameter and set its value. Copies of registers, made by passing parameters or `def` statements, exhibit aliasing, like pass-by-reference.

In a function, registers can be declared using `name : type = value` syntax, where the type can be omitted if the value is already typed. The initial value is required. A function argument is also declared as a register, but it doesn't use an initial value as that's passed in when the function is called.

    x:i32 = 25   # Type specified: numbers are untyped
    y := x + 1   # Type inferred

The runtime value of a register can be changed with `name = value` syntax, with no `:`.

    x = x + 1    # Increment

This does *not* change the compile time value of `x` or `y`, which is a register. Declaration and reassignment do essentially the same thing at compile time, but at runtime they're two different things. Declaration is basically a `def` statement bundled with an assignment of the initial value. Assignment is a plain function that acts on a register and a value, and could even be wrapped in a generator `assign{name,value}` if you wanted. In fact, the left-hand side of an assignment (but not a declaration) can be a full expression, as long as it resolves to a register at compile time. Try `(if (0) a; else b) = c` for example.

At runtime, the register represents one value at a time, so whenever it's used it's the current value that will be visible. If you want to save the value somewhere, make another register, like `x0 := x`.

## Control flow

Singeli's built-in control flow statements are `if`-(`else`), and (`do`)-`while`. The semantics are just like in C, and the syntax is pretty similar too. You can use a single statement, or multiple statements enclosed in braces. Here are a few examples:

    if (a < 4) a = a + 1

    if (a > b) { c = a }
    else { c = b }

    do {
      doThing{c}
      c = c + 1
    } while (c < a)

Note that `if` can also be used as a constant-time switch: if the argument is a number, it must be 0 or 1, and compiles only one block, or none if the condition is 0 and there's no `else`.

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
| `merge{tups…}`      | Concatenate elements from multiple tuples into one tuple
| `tupsel{ind,tuple}` | Select the `ind`th element (0-indexed) from the tuple
| `apply{gen,tuple}`  | Apply a generator to a tuple of parameters
| `each{gen,tuple…}`  | Map a generator over the given tuples

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
