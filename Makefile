# ICDIR=~/xzintbit MSBASICDIR=~/msbasic FUNCTESTDIR=~/6502_65C02_functional_tests make

ICVM_TYPE ?= c

ICDIR ?= $(abspath ../xzintbit)
MSBASICDIR ?= $(abspath ../msbasic)
FUNCTESTDIR ?= $(abspath ../6502_65C02_functional_tests)

ifeq ($(shell test -d $(ICDIR) || echo error),error)
	$(error ICDIR variable is invalid; point it where https://github.com/matushorvath/xzintbit is built)
endif

ifeq ($(shell test -d $(MSBASICDIR) || echo error),error)
	$(error MSBASICDIR variable is invalid; point it where https://github.com/matushorvath/msbasic is built)
endif

ifeq ($(shell test -d $(FUNCTESTDIR) || echo error),error)
	$(error FUNCTESTDIR variable is invalid; point it where https://github.com/Klaus2m5/6502_65C02_functional_tests is cloned)
endif

ICVM ?= $(abspath $(ICDIR)/vms)/$(ICVM_TYPE)/ic
ICAS ?= $(abspath $(ICDIR)/bin/as.input)
ICBIN2OBJ ?= $(abspath $(ICDIR)/bin/bin2obj.input)
ICLD ?= $(abspath $(ICDIR)/bin/ld.input)
ICLDMAP ?= $(abspath $(ICDIR)/bin/ldmap.input)
LIBXIB ?= $(abspath $(ICDIR)/bin/libxib.a)

SRCDIR = src
BINDIR ?= bin
OBJDIR ?= obj

define run-as
	cat $^ | $(ICVM) $(ICAS) > $@ || ( cat $@ ; false )
endef

define run-ar
	cat $^ | sed 's/^.C$$/.L/g' > $@ || ( cat $@ ; false )
endef

define run-ld
	echo .$$ | cat $^ - | $(ICVM) $(ICLD) > $@ || ( cat $@ ; false )
	echo .$$ | cat $^ - | $(ICVM) $(ICLDMAP) > $@.map.yaml || ( cat $@.map.yaml ; false )
endef

define run-bin2obj
	wc -c $< | cat - $< | $(ICVM) $(ICBIN2OBJ) > $@ || ( cat $@ ; false )
endef

# Build
.PHONY: build
build: build-prep $(BINDIR)/vm6502.input $(BINDIR)/msbasic.input $(BINDIR)/func_test.input

.PHONY: build-prep
build-prep:
	mkdir -p "$(BINDIR)" "$(OBJDIR)"

# Test
.PHONY: test
test: build msbasic_test func_test

.PHONY: msbasic_test
msbasic_test: $(BINDIR)/msbasic.input
	< $(SRCDIR)/msbasic_test.in $(ICVM) $(BINDIR)/msbasic.input 2> /dev/null | diff -r - $(SRCDIR)/msbasic_test.out

.PHONY: func_test
func_test: $(BINDIR)/func_test.input
	$(ICVM) $(BINDIR)/func_test.input < /dev/null

# The order of the object files matters: First include all the code in any order, then binary.o,
# then the (optional) 6502 image header and data.

BASE_OBJS = vm6502.o arithmetic.o bits.o bitwise.o branch.o error.o exec.o flags.o incdec.o \
	instructions.o loadstore.o memory.o params.o pushpull.o shift.o state.o trace.o util.o

VM6502_OBJS = $(BASE_OBJS) $(LIBXIB) binary.o

$(BINDIR)/vm6502.input: $(VM6502_OBJS:%.o=$(OBJDIR)/%.o)
	$(run-ld)

$(OBJDIR)/%.o: $(SRCDIR)/%.s
	$(run-as)

# Intcode does not have a convenient way to access individual bits of a byte.
# For speed and convenience we will sacrifice 256 * 8 = 2048 bytes and memoize the operation.
# The table for that is generated using gen_bits.s and can be found in file $(OBJDIR)/bits.s.

.PRECIOUS: $(OBJDIR)/%.o
$(OBJDIR)/%.o: $(OBJDIR)/%.s
	$(run-as)

.PRECIOUS: $(OBJDIR)/%.s
$(OBJDIR)/%.s: $(OBJDIR)/gen_%.input
	$(ICVM) $< > $@ || ( cat $@ ; false )

.PRECIOUS: $(OBJDIR)/gen_%.input
$(OBJDIR)/gen_%.input: $(OBJDIR)/gen_%.o $(LIBXIB)
	$(run-ld)

# Microsoft Basic
MSBASIC_OBJS = $(BASE_OBJS) $(LIBXIB) msbasic_header.o msbasic_binary.o

$(BINDIR)/msbasic.input: $(MSBASIC_OBJS:%.o=$(OBJDIR)/%.o)
	$(run-ld)

$(OBJDIR)/msbasic_binary.o: $(MSBASICDIR)/tmp/vm6502.bin
	$(run-bin2obj)

# 6502 functional tests
FUNC_TEST_OBJS = $(BASE_OBJS) func_test_callback.o $(LIBXIB) func_test_header.o func_test_binary.o

$(BINDIR)/func_test.input: $(FUNC_TEST_OBJS:%.o=$(OBJDIR)/%.o)
	$(run-ld)

$(OBJDIR)/func_test_binary.o: $(FUNCTESTDIR)/bin_files/6502_functional_test.bin
	$(run-bin2obj)

# Clean
.PHONY: clean
clean:
	rm -rf $(BINDIR) $(OBJDIR)
