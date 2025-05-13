# Singeli tests

Singeli testing is not terribly comprehensive. We're relying in part on testing with existing codebases as well as the relative simplicity of the language to make sure things work.

Compiler tests: `test/run` (like `singeli`, run as an executable if `bqn` is installed, or call with a BQN interpreter).

Most includes are not yet tested. For arch/ includes, run `make` from the test/arch/general directory, or from the base:

    $ make -C test/arch/general ARCH=feats

where the feature list `feats` is the same as Singeli's `-a` argument. If making changes to Singeli, run `make clean` between tests to force a new build.
