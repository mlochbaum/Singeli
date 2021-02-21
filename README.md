# Singeli

Singeli is in early development: nothing here works yet.

The plan is to make a highly flexible domain-specific language for building [SIMD](https://en.wikipedia.org/wiki/SIMD) algorithms with control over every instruction emitted. It will initially target x86-64 with vector extensions, emitting C with compiler intrinsics, assembly, or machine code. It should be easy to support other CPU architectures but there are no plans to target GPUs. Our intended use case is for implementing array languages, but Singeli may prove useful for other tasks as well.

Design discussion for Singeli takes place at [topanswers.xyz](https://topanswers.xyz/apl?q=1623).
