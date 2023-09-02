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
  - [`clib/malloc`](clib/malloc.singeli) malloc and free
- `util/` Utilities
  - [`util/for`](util/for.singeli) Typical @for loops
  - [`util/tup`](util/tup.singeli) Programming with tuples
  - [`util/kind`](util/kind.singeli) Short generators to test value's kind
  - [`util/perv`](util/perv.singeli) Generator pervasion
  - [`util/functionize`](util/functionize.singeli) Make function from generator
- `debug/` Debugging utilities
  - [`debug/printf`](debug/printf.singeli) Print at runtime
