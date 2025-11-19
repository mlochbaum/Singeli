# Singeli standard includes

Standard includes are those built into the compiler. Each can be included with a line like `include 'arch/c'`, which uses a path relative to this directory (include/ in the Singeli sources).

- `skin/` Operator definitions
  - [`skin/c`](skin/c.singeli) C-like operators (with some tweaks)
    - [`skin/cop`](skin/cop.singeli) Non-mutating operators
    - [`skin/cmut`](skin/cmut.singeli) Mutating operators such as `*=` and `++`
  - [`skin/cext`](skin/cext.singeli) Extensions to C-like operators
- `arch/` Operation generation
  - [`arch/c`](arch/c.singeli) Platform-independent C
  - `arch/iintrinsic/` for x86 extensions or `arch/neon_intrin/` for NEON vector intrinsics (ARM)
    - [`arch/*/basic`](#simd-basics) Basic vector support and arithmetic
    - [`arch/*/select`](#simd-selection) Rearranging elements without changing type
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

## SIMD basics

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

The next table shows integer instruction availability in x86. Each entry shows the first extension to include the instructions on a given element type. Multi-instruction fills are not shown. Instructions introduced by SSE extensions are all available in AVX2, except `extract`, and those in AVX2 are all in AVX-512F or AVX-512BW (depending on type support as shown above), except `copy_sign`. AVX2 instructions are also supported on 128-bit vectors, and AVX-512 instructions are supported on 128-bit and 256-bit vectors if AVX-512VL is available.

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

## SIMD selection

Includes `arch/iintrinsic/select` and `arch/neon_intrin/select` define operations that rearrange elements from one or more vectors. An operation is supported only when it can be implemented with a single instruction and possibly a constant vector register. In each case there are some values to be manipulated (`val`, `v0`, `v1`, `a`, `b` below), which must all share an element type and also determine the type of the result—although `spec` may indicate a different temporary element type to be used internal to the computation. Vectors here are treated strictly as lists of values, and in particular **left and right shifts go in the opposite direction to arithmetic shl and shr**! Operations `vec_shuffle`, `reverse_units`, and `blend_units` work on sub-units of the vectors, which must have a length that divides the number of elements, that is, a power of two. Operations ending in `128` work on 128-bit lanes, as this is all that AVX instructions support, but the same names without the `_128` or `128` suffix are defined to be the same on 128-bit vectors and error on larger sizes. AVX-512 is not yet supported.

| Syntax                               | Arch | Description
|--------------------------------------|------|------------
| `vec_select {spec?, val, ...?ind}`   |      | Vector version of `select{val, ind}`
| `vec_shuffle{spec?, val, ...?ind}`   |      | Select within sub-units, possibly repeating the indices
| `broadcast_sel{val, i}`              |      | Vector with all elements equal to element `i` of `val`
| `reverse_units{s, val}`              |      | Reverse each length-`s` group of elements in `val`
| `vec_shift_left_128 {val, n}`        |      | Move element `i` of `val` to index `i-n`, shifting in zeros
| `vec_shift_right_128{val, n}`        |      | Move element `i` of `val` to index `i+n`, shifting in zeros
| `vec_merge_shift_left_128 {a, b, n}` |      | Left shift of combined lane placing `a` before `b`
| `vec_merge_shift_right_128{a, b, n}` |      | Right shift from end of combined lane placing `a` before `b`
| `zip128{a, b, half}`                 |      | Alternate elements from first (`half=0`) or last (`half=1`) halves of `a` and `b`
| `blend{v0, v1, ...?bools}`           |      | Element-wise choice where `0` in `bools` takes from `v0` and `1` from `v1`
| `blend_units{v0, v1, ...?bools}`     |      | Same, but tuple `bools` is repeated to the full length if short
| `blend_top{v0, v1, mask}`            | x86  | Choose using the top bit of each element of vector `mask`
| `blend_bit{v0, v1, mask}`            | ARM  | Choose bitwise, `(~mask & v0) \| (mask & v1)`
| `blend_hom{v0, v1, mask}`            |      | Choose `v0` when an element of `mask` is all 0, and `v1` when all 1

Two types of selection by indices are defined: `vec_select`, which is more like NEON `tbl` instructions, and `vec_shuffle`, which selects on sub-units, matching x86 `shuffle` and `permute` better. These have many settings so they get [their own section](#vector-select-and-shuffle) below. `reverse_units` is a special case, and is implemented as a call to `vec_shuffle` on x86 but is supported by dedicated instructions on ARM.

`vec_shift_left_128`, `vec_shift_right_128`, `vec_merge_shift_left_128`, and `vec_merge_shift_right_128` shift elements within lanes and are equivalent to `vec_shift_left`, `vec_shift_right`, `vec_merge_shift_left`, and `vec_merge_shift_right` when a vector is a single lane long.

`zip` and `zip128` interleave elements of their arguments in the sense of `zip(abcd, 0123) = a0b1c2d3`; on tuples this might be written `merge{...each{tup,a,b}}`. Because the full result wouldn't fit in a single vector, the `half` parameter specifies half 0 or 1 of each lane of the result, or equivalently zipping only half 0 or 1 of each argument lane. More formally, element `2*i` of a result lane is element `i` of the relevant half-lane of `a`, and element `2*i + 1` is element `i` from a half-lane of `b`. The complete result as a list of vectors is `each{zip128{a,b,.}, range{2}}`.

Arguments to blend functions are two vectors `v0` and `v1` of the same type, and a selector which is conceptually a list of booleans. For `blend` and `blend_units`, the selector `bools` is in fact a tuple of compile-time booleans (each is constant 0 or 1; these may also be passed as separate arguments). For `blend_hom`, `blend_top`, and `blend_bit`, the selector `mask` is another vector with the same number of elements and element width as the others. In a blend, the result value at index `i` is element `i` of either `v0` or `v1`: if element `i` of the selector is 0, `v0`, and if it's 1, `v1`. For `blend_top`, the selector is the top (sign) bit of each element of `mask`, and for `blend_bit`, all inputs are considered to be lists of bits so that the selector is simply the bits of `mask`. For `blend_hom` (short for "homogeneous"), result element `i` is defined only if element `i` of `mask` has all bits set to 0 or all set to 1. It's implemented as `blend_bit` on ARM and `blend_top`, possibly with a smaller element type than the arguments, on x86.

### Vector select and shuffle

Both selection functions `vec_select` and `vec_shuffle` take three inputs:
- `spec` is optional. It can describe the element type and width, and for `vec_shuffle`, sub-unit size.
- `val` are the values for selection. It may be a tuple of vectors, which has a different meaning for select versus shuffle.
- `ind` is the indices of the wanted values, either a vector or a tuple of constant integers (in which case they can also be passed as separate arguments). A constant index must be less than the selection length, and any negative indicates a zero result. For variables, out-of-bounds indices are not defined and will be interpreted according to the specific instruction called. `ind` is never cast, so if it's a vector its elements must be integers of the appropriate width.

For `vec_select`, `spec` may be the element width as a number, or an element type. The width `128`, supported by AVX's `permute2x128` and `permute2f128` intrinsics, can only be specified by number. If multiple arguments are passed, they are treated as a single list of elements, so that indices into the first vector are normal, those into the second are increased by the width of a vector, and so on.

`vec_shuffle` performs multiple independent selections: it corresponds to a single selection by adding an appropriate base index to each of these, although it's often the case on x86 that only some sub-unit size smaller than the entire vector is supported. If constant indices are used, they are repeated as needed to match the number of values. To run, `vec_shuffle` needs to determine both the element type and the number of elements in a sub-unit. `spec` may be a vector type like `[4]f32` to specify both, or a number like `4` to specify sub-unit length only, or an element type like `f32`. If the element type is unspecified, then the type's width comes from the indices if they're typed and the values if they're constant, and its quality (float or integer) comes from the values to be selected unless a floating-point type of the required width doesn't exist. The sub-unit size may be any divisor of the number of provided indices; if unspecified it's taken to be that number. An additional option is that `ind` may be a tuple of tuples, each having the length of a sub-unit (this specifies the sub-unit length if it would be taken from `ind`).

The definition of `vec_shuffle` where `val` is a tuple is chosen to accomodate x86's rather esoteric `shuffle_ps` and `shuffle_pd` intrinsics. In this case each selection unit is divided equally into one part for each vector of values, and the indices for a part pertain to the current selection unit of the corresponding vector.

Three extra definitions are included in iintrinsic/select to expose x86 shuffle instructions that don't fit `vec_select` or `vec_shuffle`. `vec_shuffle16_lo` and `vec_shuffle16_hi` shuffle the low and high halves of each lane of a vector with 16-bit elements, leaving the other half unchanged. `vec_shuffle_64_scaled` implements lane-wise `vec_shuffle` on `f64` elements and an index vector, except that the expected indices are 0 and 2 instead of 0 and 1: intrinsic `permutevar_pd` uses the second bit from the bottom of each index instead of the bottom bit as in `permutevar_ps`.
