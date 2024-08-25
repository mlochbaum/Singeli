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
| `flip{tups}`             | Transpose tuple of same-length tuples
| `table{f, ...tups}`      | Function table mapping over all combinations
| `flat_table{f, ...tups}` | Function table flattened into a single list
| `fold{gen, any?, tup+}`  | Left fold, with or without initial element
| `scan{gen, any?, tup+}`  | Inclusive left scan
| `replicate{r, tup}`      | Tuple with each input element copied the given number of times
| `indices{tup}`           | Indices of elements of `tup`, repeated that many times

Additional notes:

- `split{n, tup}`: `n` may be a number, indicating that all groups have that length except that the last may be short. It may also be a list of numbers, which is expected to sum to the length of the tuple and indicates the sequence of group lengths.
- `fold{gen, any?, tup+}` and `fold{gen, any?, tup+}`: if the initialized `any` is given, `tup` indicates any number of tuple arguments, and `gen` will be always called with one parameter from each one.
- `replicate{r, tup}`: `r` may be a tuple, where each element indicates the number of times to include the corresponding element of `tup` (for example, if it's boolean the elements in the same position as a 1 are kept and those with a 0 are filtered out). It may also be a plain number, so that every element is copied the same number of times, or a generator `f`, so that element `e` is copied `f{e}` times.

## SIMD architecture

Includes `arch/iintrinsic/basic` and `arch/neon_intrin/basic` are "basic" architecture includes that define arithmetic and a few essential vector operations. Because of x86's haphazard instruction support, the default `arch/iintrinsic/basic` includes multi-instruction implementations of many operations such as comparisons, min, and max. Use `arch/iintrinsic/basic_strict` to define only cases that are supported by a single instruction.

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

### x86 SIMD arithmetic support

The following table shows when arithmetic support was added to x86 for various vector types. For integers, only signed types (`i16`) are shown but unsigned equivalents (`u16`) are supported at the same time. AVX-512F does have the ability to create and perform conversions on 8-bit and 16-bit types, but doesn't support any arithmetic specific to them.

| Extension | `u`/`i8` | `u`/`i16` | `u`/`i32` | `u`/`i64` |     `f32` |    `f64` |
|-----------|---------:|----------:|----------:|----------:|----------:|---------:|
| SSE       |          |           |           |           |  `[4]f32` |          |
| SSE2      | `[16]i8` |  `[8]i16` |  `[4]i32` |  `[2]i64` |           | `[2]f64` |
| AVX       |          |           |           |           |  `[8]f32` | `[4]f64` |
| AVX2      | `[32]i8` | `[16]i16` |  `[8]i32` |  `[4]i64` |           |          |
| AVX-512F  |          |           | `[16]i32` |  `[8]i64` | `[16]f32` | `[8]f64` |
| AVX-512BW | `[64]i8` | `[32]i16` |           |           |           |          |

The next table shows integer instruction availability in x86. Each entry shows the first extension to include the instructions on a given element type. Multi-instruction fills are not shown. Instructions introduced by SSE extensions are all available in AVX2, except `extract`, and those in AVX2 are all in AVX-512F or AVX-512BW (depending on type support as shown above), except `copy_sign`. AVX2 instructions are also supported on 128-bit vectors, and AVX-512 instructions are supported on 128-bit and 256-bit vectors if AVX-512VL is available. But `arch/iintrinsic/basic` doesn't correctly support these extensions right now.

| Functions                     | `i8`   | `i16`  | `i32`  | `i64`   | `u8`   | `u16`  | `u32`  | `u64`
|-------------------------------|--------|--------|--------|---------|--------|--------|--------|-------
| `&` `\|` `^` `andnot` `+` `-` | SSE2   | SSE2   | SSE2   | SSE2    | SSE2   | SSE2   | SSE2   | SSE2
| `__min` `__max`               | SSE4.2 | SSE2   | SSE4.2 | A512F   | SSE2   | SSE4.2 | SSE4.2 | A512F
| `==`                          | SSE2   | SSE2   | SSE2   | SSE4.1  | SSE2   | SSE2   | SSE2   | SSE4.1
| `>` `<`                       | SSE2   | SSE2   | SSE2   | SSE4.2  |        |        |        |
| `__adds` `__subs`             | SSE2   | SSE2   |        |         | SSE2   | SSE2   |        |
| `<<` `shl_uniform`            |        | SSE2   | SSE2   | SSE2    |        | SSE2   | SSE2   | SSE2
| `>>` `shr_uniform`            |        | SSE2   | SSE2   | A512F   |        | SSE2   | SSE2   | SSE2
| `<<` (element-wise)           |        | A512F  | AVX2   | AVX2    |        | A512F  | AVX2   | AVX2
| `>>` (element-wise)           |        | A512F  | AVX2   | A512F   |        | A512F  | AVX2   | AVX2
| `*`                           |        | SSE2   | SSE4.1 | A512DQ  |        | SSE2   | SSE4.1 | A512DQ
| `__abs`                       | SSSE3  | SSSE3  | SSSE3  | A512F   |        |        |        |
| `copy_sign` (no 512-bit)      | SSSE3  | SSSE3  | SSSE3  |         |        |        |        |
| `average_int`                 |        |        |        |         |        | SSE2   | SSE2   |
| `extract` (no ≥256-bit)       | SSE4.1 | SSE2   | SSE4.1 | SSE4.1  | SSE4.1 | SSE2   | SSE4.1 | SSE4.1

Floating-point instruction availability is much simpler: all instructions are available on supported types, with the exception of `__floor`, `__ceil`, and `__round`, which weren't added until SSE4.1.

| Functions                                                                                  | `f32`  | `f64`
|--------------------------------------------------------------------------------------------|--------|-------
| `&` `\|` `^` `andnot` `+` `-` `*` `__min` `__max` `==` `>` `<` `!=` `>=` `<=` `/` `__sqrt` | SSE    | SSE2
| `__floor` `__ceil` `__round`                                                               | SSE4.1 | SSE4.1
