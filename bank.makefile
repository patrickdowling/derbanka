# Common makefile for building Dervish-annotated banks
#
# Copyright (c) 2022 Patrick Dowling
# See project LICENSE file.
#
# Actual bank directories require only a minimal makefile that
# - defines BANK_NAME (if not defined, defaults to directory name)
# - includes this makefile
#
# Optionally it may also define (or pass via command line)
# - BANK_SLOT which is the slot/bank number to upload to.
#
# For each source file we not only want to run the assembler, but also generate
# the pot/program labels. So there are two steps required, one to generate the
# .masm file (which also runs the assembler, since we're assembling into the
# target directly) and the other generates .bin (which is the labels).
#
.POSIX:
.SUFFIXES:

BANK_NAME ?= $(shell basename $$(pwd))
BANK_SLOT ?= 0

BUILD_DIR  = ./build
SCRIPT_DIR ?= ../derbanka
# Bank name may contain spaces which will confuse make
BANK_FILE  = $(addsuffix .bank,$(BUILD_DIR)/$(shell echo '$(BANK_NAME)' | tr ' ' '_'))
BANK_BIN   = $(BANK_FILE:.bank=.bin)
# Brute force support for .spn as well
ASM_FILES  = $(wildcard [01234567]_*.asm)
SPN_FILES  = $(wildcard [01234567]_*.spn)
BIN_FILES  = $(patsubst %,$(BUILD_DIR)/%, $(notdir $(ASM_FILES:.asm=.bin) $(SPN_FILES:.spn=.bin)))

# COUNT=$(words $(BIN_FILES))
# ifneq (8, $(COUNT))
# $(warning "Didn't find 8 source files, be warned")
# endif

AS = asfv1
ASFLAGS = -b -q $(EXTRA_ASFLAGS)

ifdef VERBOSE
Q :=
ECHO := @true
UPLOAD_OPTS=-v
else
Q := @
ECHO := @echo
endif

.PHONY: all
all: bank

.PHONY: bank
bank: $(BANK_FILE)

.PHONY: clean
clean:
	$(Q)rm -rf $(BUILD_DIR)

.PHONY: upload
upload: $(BANK_FILE)
	$(Q)UPLOAD_OPTS=$(UPLOAD_OPTS) $(SCRIPT_DIR)/dervish_upload $(BANK_SLOT) $(BANK_FILE)

define program_number
$(shell echo $(notdir $(1)) | cut -d_ -f1)
endef

$(BANK_BIN): | $(BUILD_DIR)
$(BANK_BIN): $(BIN_FILES) $(BIN_FILES:.bin=.masm) Makefile

$(BANK_FILE): $(BANK_BIN)
	$(ECHO) "Building $@..."
	$(Q)dd if=$(BANK_BIN) of=$@ >/dev/null 2>&1
	$(Q)printf '%-20.20b\n' '$(BANK_NAME)' | dd bs=1 count=21 seek=4096 conv=notrunc of=$(BANK_FILE) >/dev/null 2>&1

$(BUILD_DIR):
	@mkdir -p $(BUILD_DIR)

$(BUILD_DIR)/%.masm: %.asm
	$(ECHO) "MASM $<..."
	$(Q)cat $< | $(SCRIPT_DIR)/macroasm.py > $(BUILD_DIR)/$(@F:.bin=.masm)
	$(Q)$(AS) $(ASFLAGS) -p $(call program_number,$<) $(BUILD_DIR)/$(@F:.bin=.masm) $(BANK_BIN)

$(BUILD_DIR)/%.masm: %.spn
	$(ECHO) "MASM $<..."
	$(Q)cat $< | $(SCRIPT_DIR)/macroasm.py > $(BUILD_DIR)/$(@F:.bin=.masm)
	$(Q)$(AS) $(ASFLAGS) -s -p $(call program_number,$<) $(BUILD_DIR)/$(@F:.bin=.masm) $(BANK_BIN)

$(BUILD_DIR)/%.bin: $(BUILD_DIR)/%.masm
	$(ECHO) "INFO $(BUILD_DIR)/$(@F:.bin=.masm)"
	$(Q)$(SCRIPT_DIR)/extractinfo.py $(BUILD_DIR)/$(@F:.bin=.masm) $@
	$(Q)dd if=$@ bs=1 count=84 seek=$(shell echo $$(( 4117 + $(call program_number,$<) * 84 ))) conv=notrunc of=$(BANK_BIN) >/dev/null 2>&1
