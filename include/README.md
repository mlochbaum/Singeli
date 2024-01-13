# Singeli standard includes

Standard includes are those built into the compiler. Each can be included with a line like `include 'arch/c'`, which uses a path relative to this directory (include/ in the Singeli sources).

- `skin/` Operator definitions
  - [`skin/c`](skin/c.singeli) C-like operators (with some tweaks)
    - [`skin/cop`](skin/cop.singeli) Non-mutating operators
    - [`skin/cmut`](skin/cmut.singeli) Mutating operators such as `*=` and `++`
  - [`skin/cext`](skin/cext.singeli) Extensions to C-like operators
- `arch/` Operation generation
  - [`arch/c`](arch/c.singeli) Platform-independent C
  - [`arch/iintrinsic/`](#simd-architecture) Intel intrinsics for x86 extensions
  - [`arch/neon_intrin/`](#simd-architecture) NEON vector intrinsics (ARM)
- `clib/` Bindings for C libraries
  - [`clib/malloc`](clib/malloc.singeli) malloc (as `alloc{}`) and free
- `util/` Utilities
  - [`util/for`](#utilfor) Typical @for loops
  - [`util/tup`](#utiltup) Programming with tuples
  - [`util/kind`](util/kind.singeli) Short generators to test value's kind
  - [`util/perv`](util/perv.singeli) Generator pervasion
  - [`util/functionize`](util/functionize.singeli) Make function from generator
- `debug/` Debugging utilities
  - [`debug/printf`](debug/printf.singeli) Print at runtime

## util/for

File [util/for.singeli](util/for.singeli).

Each loop handles the indices `i` satisfying `from <= i < to`.

| Loop               | Description
|--------------------|------------
| `@for`             | Standard forward loop
| `@for_backwards`   | Same indices in the reverse order
| `@for_const`       | Compile-time loop, requiring constant bounds
| `@for_unroll{unr}` | Loop unrolled by a factor of `unr`

The unrolled loop creates two sub-loops, one that evaluates `unr` copies of the given body and the other that evaluates only one. It runs the first as many times as possible starting at `from` (no adjustments are made for alignment), then the second until `to` is reached.

## util/tup

File [util/tup.singeli](util/tup.singeli).

| Syntax                   | Description
|--------------------------|------------
| `empty{tup}`             | Tuple is empty
| `@collect`               | Constant-time evaluation returning a list
| `iota{num}`              | Alias for `range`
| `inds{tup}`              | Tuple of all indices into tuple
| `copy{num, any}`         | Tuple of `num` copies of `any`
| `join{tups}`             | Merge a tuple of tuples
| `shiftright{l, r}`       | Shift tuple `l` into `r`, retaining length of `r`
| `shiftleft{l, r}`        | Shift tuple `r` into `l`, retaining length of `l`
| `reverse{tup}`           | Elements in reverse order
| `cycle{num, tup}`        | Repeat tuple cyclically to the given length
| `split{num, tup}`        | Split tuple into groups of the given length or less
| `flip{tups}`             | Transpose tuple of tuples, assuming each has the same length
| `table{f, ...tups}`      | Function table mapping over all combinations
| `flat_table{f, ...tups}` | Function table flattened into a single list
| `fold{gen, any?, tup}`   | Left fold, with or without initial element
| `scan{gen, any?, tup}`   | Inclusive left scan
| `replicate{r, tup}`      | Tuple with each input element copied the given number of times
| `indices{tup}`           | Indices of elements of `tup`, repeated that many times

Additional notes:

- `split{n, tup}`: `n` may be a number, indicating that all groups have that length except that the last may be short. It may also be a list of numbers, which is expected to sum to the length of the tuple and indicates the sequence of group lengths.
- `replicate{r, tup}`: `r` may be a tuple, where each element indicates the number of times to include the corresponding element of `tup` (for example, if it's boolean the elements in the same position as a 1 are kept and those with a 0 are filtered out). It may also be a plain number, so that every element is copied the same number of times, or a generator `f`, so that element `e` is copied `f{e}` times.

## SIMD architecture

Includes `arch/iintrinsic/basic` and `arch/neon_intrin/basic` are "basic" architecture includes that define arithmetic and a few essential vector operations. Because of x86's haphazard instruction support, the default `arch/iintrinsic/basic` includes multi-instruction implementations of many operations such as comparisons, min, and max. Use `arch/iintrinsic/basic_main` to define only cases that are supported by a single instruction.

All [builtin arithmetic](../README.md#arithmetic) operations are supported when available (`__mod` is the only one that's never provided), in addition to the following (architecture indicated if only one supports it):

| Syntax                     | Arch | Result
|----------------------------|------|--------
| `__adds{x, y}`             |      | Saturating add
| `__subs{x, y}`             |      | Saturating subtract
| `__sqrt{x}`                |      | Square root
| `__round{x}`               | x86  | Round to nearest
| `andnot{x, y}`             |      | `x & ~y`
| `ornot{x, y}`              | ARM  | `x \| ~y`
| `andnz{x, y}`              | ARM  | `(x & y) != 0`
| `copy_sign{x, y}`          | x86  | Absolute value of `x` with sign of `y`
| `average_int{x, y}`        | x86  | `(x + y + 1) >> 1`
| `shl_uniform{v, s:[2]u64}` | x86  | Shift each element left by element 0 of `s`
| `shr_uniform{v, s:[2]u64}` | x86  | Shift each element right by element 0 of `s`

The following non-arithmetic definitions are also defined when possible.

| Syntax                 | Result
|------------------------|--------
| `vec_make{V, ...x}`    | A vector of the values `x`
| `vec_make{V, x}`       | Same, with a tuple parameter
| `vec_broadcast{V, x}`  | A vector of copies of the value `x`
| `extract{v:V, ind}`    | The element at position `ind` of vector `v`
| `insert{v:V, x, ind}`  | Insert `x` to position `ind` of `v`, returning a new vector
| `load{ptr,ind}`        | Same as builtin
| `store{ptr,ind,val}`   | Same as builtin

x86 also includes `load_aligned` and `store_aligned` for accesses that assume the pointer has vector alignment.
