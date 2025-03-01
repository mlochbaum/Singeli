SHELL=/usr/bin/env bash -o pipefail
ARCH=native
SINGELI=../../../singeli
SINGELI_FLAGS=-a $(ARCH)
CCFLAGS=-g $(shell bqn ../to-c-args.bqn $(ARCH))
RUN=

ALL_TESTS=

default: $(ALL_TESTS)
.SECONDARY:

%-${ARCH}.bin: %.singeli
	$(SINGELI) -os stderr $(SINGELI_FLAGS) $< > $@.c
	$(CC) $(CCFLAGS) $@.c -o $@

run-%: %-${ARCH}.bin
	$(RUN) ./$<

clean:
	rm *.bin*