# Singeli standard includes

Standard includes are those built into the compiler. Each can be included with a line like `include 'arch/c'`, which uses a path relative to this directory (include/ in the Singeli sources).

- `skin/` Operator definitions
  - [`skin/c`](skin/c.singeli) C-like operators (with some tweaks)
    - [`skin/cop`](skin/cop.singeli) Non-mutating operators
    - [`skin/cmut`](skin/cmut.singeli) Mutating operators such as `*=` and `++`
  - [`skin/cext`](skin/cext.singeli) Extensions to C-like operators
- `arch/` Operation generation
  - [`arch/c`](arch/c.singeli) Platform-independent C
  - `arch/iintrinsic/` Intel intrinsics for x86 extensions
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
