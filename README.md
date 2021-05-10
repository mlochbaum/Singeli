# Singeli

Singeli is now able to compile useful programs to C, but the lack of documentation or error reporting after parsing means it's still tough to work with.

This iteration consists of a frontend in [dzaima/BQN](https://github.com/dzaima/BQN) and a backend in Java. Run `$ ./build` to build the backend. To compile file.singeli:

```
$ java -jar si.jar <(dbqn singeli.bqn file.singeli)
```

The plan is to make a highly flexible domain-specific language for building [SIMD](https://en.wikipedia.org/wiki/SIMD) algorithms with control over every instruction emitted. It will initially target x86-64 with vector extensions, emitting C with compiler intrinsics, assembly, or machine code. It should be easy to support other CPU architectures but there are no plans to target GPUs. Our intended use case is for implementing array languages, but Singeli may prove useful for other tasks as well.

Early design discussion for Singeli took place at [topanswers.xyz](https://topanswers.xyz/apl?q=1623); now it's in the BQN forums ([links and instructions](https://mlochbaum.github.io/BQN/index.html#where-can-i-find-bqn-users)).
