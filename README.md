# Singeli

Singeli is a domain-specific language for building [SIMD](https://en.wikipedia.org/wiki/SIMD) algorithms with flexible abstractions and control over every instruction emitted. It's implemented in [BQN](https://mlochbaum.github.io/BQN), with a frontend that emits IR and a backend that converts it to C. Other backends like LLVM or machine code are possible—it should be easy to support other CPU architectures but there are no plans to target GPUs.

I'd call it usable at this point, although there will surely be some implementation bugs, mostly in error reporting. As for debugging your own code, there are parse and stack traces for compilation errors, and `show{}` prints whatever you want at compile time. Runtime errors are harder, as the emitted C code is opaque so you're basically stuck emitting `printf()` calls to see anything. Prototyping with the interactive [Singeli playground](https://github.com/dzaima/singeliPlayground) tool is very helpful in avoiding the need to do this.

To compile input.singeli:

```
$ singeli input.singeli [-o output.c]
```

For options see `$ singeli -h`. To run `./singeli` as an executable, ensure that [CBQN](https://github.com/dzaima/CBQN) is installed as `bqn` in your executable path, or call as `/path/to/bqn singeli …`.

Singeli [is used](https://github.com/dzaima/CBQN/tree/master/src/singeli/src) for CBQN's SIMD primitive implementations when built with `$ make o3n-singeli` (requires AVX2). It's also the implementation language for [SingeliSort](https://github.com/mlochbaum/SingeliSort).

Early design discussion for Singeli took place at [topanswers.xyz](https://topanswers.xyz/apl?q=1623); now it's in the [BQN forum](https://mlochbaum.github.io/BQN/community/forums.html).

## Language overview

Singeli is primarily a metaprogramming language. Its purpose is to build abstractions around CPU instructions in order to create large amounts of specialized code. Programs will tend to do complicated things at compile time to emit programs that do relatively simple things at runtime, so it's probably better to orient your thinking around what happens at compile time.

The primary tool for abstraction is the **generator**. Written with `{parameters}`, generators perform similar tasks as C macros, C++ templates, or generics, but offer more flexibility. They are expanded during compilation, and form a Turing-complete language. Generators use lexical scoping and allow recursive calls. Here's a generator that calls another one:

    def gen{fn, arg} = fn{arg, arg + 1}

In fact, `+` is also a generator, if it's defined. Singeli has no built-in operators but allows the user to define infix or prefix operator syntax for a generator. For example, the following line from [include/skin/cop.singeli](include/skin/cop.singeli) makes `+` a left-associative infix operator with precedence 30 (there can be one infix and one prefix definition).

    oper +  __add infix left  30

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

Here you can see that code to be executed at runtime is written in an imperative style. `if`, `else`, and `while` control structures are provided. Statements are separated by newlines or semicolons; these two characters are equivalent.

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

### Variable-length parameters

Up to one parameter slot can be variable-length if marked with a leading `...`. This parameter corresponds to any number (0 or more) of inputs, and its value is the tuple of those values. For example `def tup{...t} = t` returns the tuple of all parameters, replicating the functionality of the builtin `tup`.

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
| label     | Target for `goto{}`
| block     | Used for `@for` loops

The simplest are discussed in this section, and others have dedicated sections below.

Numbers are floating-point, with enough precision to represent both double-precision floats and 64-bit integers (signed or unsigned) exactly. Specifically, they're implemented as pairs of doubles, giving about 105 bits of precision over the same exponent range as a double. A number can be written in scientific notation like `45` or `1.3e-12`, in hex like `0xf3cc0`, or in an arbitrary base with the base preceding `b`, like `2b110101` or `32b0jbm1` (digits like hex, extending past `f`). Numbers are case-insensitive and can contain underscores, which will be removed.

Symbols are Unicode strings, written as a literal using single quotes: `'symbol'`. They're used with the `emit{}` generator to emit instructions, and in export statements to identify the function name that should be exposed.

Constants consist of a value and a type. They appear when a value such as a number is cast, for example by creating a variable `v:f64 = 6` or with an explicit `cast{f64, 6}`. For programming, constants work like registers (variables), so there's never any need to consider them specifically. Just cast a compile-time value if you need it to have a particular type—say, when calling a function that could take several different types.

Labels are for `goto{}` and related builtins described [here](#program).

## Operators

Operators are formed from the characters `!$%&*+-/<=>?\^|~`. Any number of these will stick together to form a single token unless separated by spaces. Additionally, non-ASCII characters can be used as operators, and don't stick to each other.

The `oper` statement, which can only appear at the top level in the program, defines a new operator, and applies to all code later in the program (operators are handled with a Pratt parser, which naturally allows this). Here are the two declarations of `-` taken from [include/skin/cop.singeli](include/skin/cop.singeli).

    oper -  __neg prefix      30
    oper -  __sub infix left  30

The declaration lists the operator's form (arity, and associativity for infix operators), spelling, generator, and precedence. After the declaration, applying the operator runs the associated generator.

An operator can have at most one infix and one prefix definition. Prefix operators have no associativity (as operators can't be used as operands, they always run from right to left), while infix operators can be declared `left`, `right`, or `none`. With `none`, an error occurs in ambiguous cases where the operator is applied multiple times. The precedence is any number, and higher numbers bind tighter.

Parameters can be passed to operators before calling them, such as `a -{b} c`. This is converted to the generator call `__sub{b}{a,c}`. The arity is determined when it's called with operator syntax, and doesn't depend on any earlier calls with generator syntax.

## Types

Singeli's type system consists of the following type-kinds: basic `void` and primitive types as well as compound types constructed from several underlying types.

| Type kind   | Description                | Example display
|-------------|----------------------------|--------
| `void`      | Nothing                    | `void`
| `primitive` | A number                   | `i32`
| `vector`    | A list of same-type values | `[4]i32`
| `pointer`   | A pointer to memory        | `*f64`
| `function`  | A pointer to code          | `(i8,u1) -> void`
| `tuple`     | Multiple values            | `tup{u1,[2]u32}`

The display isn't always valid Singeli code. Void and primitive types are built-in names but can be overwritten. The notation `[4]i32` resolves to `__vec{4,i32}`, where `__vec{}` is also a built-in name. And `*` indicates the built-in `__pnt{}`, which isn't defined automatically but is part of `skin/c`. The notation given for functions can't be used, and the tuple `tup{u1,[2]u32}` is technically a different value from an actual tuple type but can be used as one where a type is expected.

Primitive types are written with a letter indicating the quality followed by the width in bits. The list of supported types is given below. Note the use of `u1` for boolean data. A vector of booleans such as `[128]u1` is one important use.

    unsigned:   u1 u8 u16 u32 u64
    signed int:    i8 i16 i32 i64
    float:                f32 f64

A vector type indicates that the value should be stored in a vector or SIMD register, and the backend limits which vector sizes can be used based on the target architecture.

## Functions

Generators are great for compile-time computation, but all run-time computation happens in functions. Functions are declared and called with parenthesis syntax:

    times{T}(a:T, b:T) = a*b  # Type-generic function

    square{T}(x:T) : T = {
      times{T}(x, x)
    }

The body of a function can be either a plain expression like `a*b` above, or can be enclosed in curly braces `{}` to allow multiple statements. It returns the value of the last expression. The return type is given with `:` following the argument list, but can often be omitted (if it's left out and the body uses braces, `=` is also optional).

Function parameters like the `{T}` above are slightly different from arbitrary generator parameters: the function is only ever generated once for each unique set of parameters. Once generated, its handle is saved so that later calls return the saved function immediately (in contrast, a generator that declares a variable would make a new one each time). This avoids creating source code with lots of copies of functions, and also makes it possible for a function like `square{T}` to include recursion.

## Export

A top-level statement beginning with a literal symbol is an export. The entire statement consists of a symbol or list of symbols, followed by `=` and an expression, which needs to resolve to a function at compile time. The function is then exported with all the names given before `=`. In C this means a non-`static` function with that name is defined in the output file.

    'some_function' = fn{i32}  # Export as some_function()

    'fn', 'alias' = fn{i16}    # Export with two names

## Registers

A function's arguments, and variables that it manipulates at runtime, are represented with typed slots called registers. Registers are first-class values, meaning they can be passed around and manipulated at compile time. For example, a generator can take a register as a parameter and set its value. Copies of registers, made by passing parameters or `def` statements, exhibit aliasing, like pass-by-reference.

In a function, registers can be declared using `name : type = value` syntax, where the type can be omitted if the value is already typed. The initial value is required. A function argument is also declared as a register, but it doesn't use an initial value as that's passed in when the function is called.

    x:i32 = 25   # Type specified: numbers are untyped
    y := x + 1   # Type inferred

The runtime value of a register can be changed with `name = value` syntax, with no `:`.

    x = x + 1    # Increment

This does *not* change the compile time value of `x` or `y`, which is a register. Declaration and reassignment do essentially the same thing at runtime, but at compile time they're two different things. Declaration is basically a `def` statement bundled with an assignment of the initial value. Assignment is a plain function that acts on a register and a value, and can be used in generator calls. The left-hand side can be a full expression, as long as it resolves to a register at compile time—try `(if (0) a; else b) = c` for example. The built-in [file](include/skin/cmut.singeli) `skin/cmut` (part of `skin/c`) defines generators for C operators `+=`, `/=`, `>>=`, and so on, so you can write:

    x += 1
    ++x

At runtime, a register represents one value at a time, so whenever it's used it's the current value that will be visible. If you want to save the value somewhere, make another register, like `x0 := x`. This can be done even in a generator, so that `def clone{old} = { new:=old }` copies any typed value. So while `skin/cmut` doesn't define `x++` because Singeli has no postfix operators, it's possible to make a generator that copies the parameter, increments it, and returns the copy.

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

In any `if` or `while` condition, the pseudo-operators `and`, `or`, and `not` can be used to make a compound condition. These are implemented by manipulating jumps, never with logic instructions. `and` and `or` are short-circuiting, meaning that they don't evaluate the second part of the condition if the result is determined by the first.

### For loops

A for "loop" looks a lot like the for-each loops that are becoming common in high-level as well as low-level languages. Appearances are decieving, since it's really a special kind of generator call that can evaluate the block when it executes. But it covers the for-each functionality pretty well, with the right `for` generator.

    # Loop over three pointers with a specific range
    # Expressions in the descriptor like len/2 are only evaluated once
    @for (dst, a, b over i from len/2 to len) {
      dst = a + b + i
    }

    # Use "in" to give the element a different name from the pointer
    @other_for (x in src over n) x = 2*x

The name after `@` is just a name, and is called as a generator. The following definition of `for` gives a typical C-like loop. It's passed a block and evaluates it with `exec`; the details are discussed below.

    def for{vars,begin,end,block} = {
      i:u64 = begin
      while (i<end) {
        exec{i, vars,block}
        i = i+1
      }
    }

#### Descriptor

The *descriptor* is the part in parentheses, and lists the variables and range to use for the loop. It provides the `vars` (a tuple of pointers), `begin`, and `end` parameters to the `for` generator above, and it defines which names are used in the main block of the loop, which then forms the `block` parameter.

Here's the pattern. Square brackets `[]` indicate an optional part, and the `…` means more pointers can appear, separated by commas.

    [name ["in" pointer], … "over"]
      [index ["from" begin] "to"]
        end

That's a lot of options! You can have any number of pointers, and can leave the index out—although an oddity is that you have to include it if you want a starting value different from the default of `0`. Some possibilities with the typical interpretations are listed below.

- `@for (num)`: repeat `num` times
- `@for (x in arr over len)`: iterate over elements
- `@for (i to num)`: iterate over a range
- `@for (i from a to b)`: same, with a half-open range `[a,b)`
- `@for (dst, src over i to len)`: iterate over two pointers with an index

Other than the fixed default starting point of `0`, the interpretation of the start and endpoint is all done by the generator that's used for the loop. It could ignore those values and always run exactly once, run backwards, or something else.

#### For generator

Once the descriptor and body are parsed, the following values are passed to whatever generator is named after `@`, and the result of the loop is whatever comes out. The names `vars` and so on are only for explanation, as they are nameless in Singeli compilation.

- `vars`: a tuple, the values of all pointers listed before "over"
- `begin`: the value of the expression after "from"
- `end`: the value of the expression at the end, (after "to" if it's there)
- `block`: a special value produced from the for loop's body

Most of the time the generator will evaluate the block—otherwise what's the point? This is done with the built-in generator `exec{}`, which is where the magic happens. It's called with `exec{index, ptrs, block}`, where `ptrs` is a tuple of pointers (it doesn't have match `vars` created by the for loop), `block` is a for loop block value, and `index` is an index. Then it:

- loads a value from each pointer with `load{p, index}`,
- evaluates the block using these loaded values and `index`,
- stores any modified values with `store{p, index, new_value}`, and
- returns the result of block evaluation (probably to be ignored)

Here are some examples.

    # The standard for loop, yet again
    def for{vars,begin,end,block} = {
      i:u64 = begin
      while (i<end) {
        exec{i, vars,block}
        i = i+1
      }
    }

    # Loop expanded at compile time, implemented with recursion
    # Assumes begin and end are constant, to use compile-time if
    # Each exec{} compiles to code with a constant index
    def for_const{vars,begin,end,block} = {
      if (begin<end) {
        for_const{vars,begin,end-1,block}
        exec{end-1, vars,block}
      }
    }

    # Loop over vectors of length vlen
    def for_vec{vlen}{vars,begin,end,block} = {
      # Cast each pointer to a vector
      def vptr{ptr:P} = reinterpret{*[vlen]eltype{P}, ptr}
      def vvars = each{vptr, vars}

      # Endpoints for vector part
      def vb = (begin+(vlen-1))/vlen  # Round up
      def ve = end/vlen               # Round down

      # Do the loops
      for{ vars, begin,   vlen*vb, block}
      for{vvars, vb,      ve,      block}
      for{ vars, vlen*ve, end,     block}
    }

`for_vec` showcases the flexibility of this approach. Since `for` is a normal generator, it can be called to avoid rewriting the same `while`-based logic everywhere. And since any pointer can be passed to `exec`, modified pointers `vvars` with a different type are fair game. This means `block` will need to handle two different variable types, `T` and `[vlen]T`—fortunately Singeli is designed to support exactly this kind of polymorphism. And it's a requirement you control since you can decide what kind of for loop to use. Finally, `for_vec` takes another parameter *before* being called as a loop. It's invoked with, say, `@for_vec{8} (…)`.

## Including files

The `include` statement can be used at the top level of a program. It evaluates the specified file as though it were part of the current one. The filename is a symbol, which loads from a relative path if it starts with `.` and from Singeli's built-in scripts (kept in the [include/](include/) source folder) otherwise.

    include 'arch/c'    # Built-in library
    include './things'  # Relative path

As a result, an included file's definitions affect the file that includes it, any files that include *that* file, and other files included after that one. These far reaching consequences might not be wanted for all definitions, so the `local` keyword restricts a top-level definition to apply only to the current file, and not anything else that includes it.

    local def fn{a,b} = b              # Local generator
    local b:u8 = 3                     # Local typed constant
    local oper ++ merge infix left 30  # Local operator
    local include 'skin/c'             # Local lots of operators

The `local` keyword restricts the scope of compile-time value and operator definitions. It doesn't do anything at runtime: all the functions and so on are still placed together in one big output file (and `local` can be placed before an export but does nothing).

For larger sets of definitions, `local` also allows a block syntax. The contents of the block behave like a separate file included with `local include`, and more `local` statements are allowed inside—they'll apply inside the block but not to the rest of the file.

    local {
      # All this stuff can be seen by the rest of the file,
      # but not outside it
      include 'skin/c'
      def t = 5
      def s = t + 1
    }

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
| `makelabel{}`          | Create a label value
| `setlabel{label}`      | Set label to the current position
| `setlabel{}`           | Short for `setlabel{makelabel{}}`
| `goto{label}`          | Jump to the position set for a label

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

### Generators

| Syntax             | Result
|--------------------|--------
| `bind{gen,param…}` | Bind/curry the given parameters to the generator

### Tuples

| Syntax                 | Result
|------------------------|--------
| `tup{elems…}`          | Create a tuple of the parameters
| `merge{tups…}`         | Concatenate elements from multiple tuples into one tuple
| `tuplen{tuple}`        | Return the length of a tuple
| `tupsel{ind,tuple}`    | Select the `ind`th element (0-indexed) from the tuple
| `slice{tup,start,end}` | Take slice from `start` to (optional) `end`, like Javascript
| `apply{gen,tuple}`     | Apply a generator to a tuple of parameters
| `each{gen,tuple…}`     | Map a generator over the given tuples

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
