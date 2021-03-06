# Makefile to build the Q3VM interpreter
# 
# Run 'make'
#
# Jan Zwiener 2018

# Custom config (optional)
-include config.mk

#We try to detect the OS we are running on, and adjust commands as needed
ifeq ($(OS),Windows_NT)
	CLEANUP = rm -f
	MKDIR = mkdir
	TARGET_EXTENSION=.exe
	LCCTOOLPATH=bin/win32/
else
	CLEANUP = rm -f
	MKDIR = mkdir -p
	TARGET_EXTENSION=
	LCCTOOLPATH=bin/linux/
endif
# Target executable configuration
TARGET_BASE=q3vm
TARGET = $(TARGET_BASE)$(TARGET_EXTENSION)

# Linker settings
LINK_FLAGS := $(LTO_FLAGS) -Wl,--gc-sections

# Compiler settings
CC=$(TOOLCHAIN)gcc
LINK := $(CC)
# add Link Time Optimization flags (LTO will treat retarget functions as unused without -fno-builtin):
# LTO_FLAGS := -flto -fno-builtin
CFLAGS += -std=c99
CFLAGS += $(LTO_FLAGS) -fdata-sections -ffunction-sections
# -MMD: to autogenerate dependencies for make
# -MP: These dummy rules work around errors make gives if you remove header files without updating the Makefile to match.
# -MF: When used with the driver options -MD or -MMD, -MF overrides the default dependency output file.
# -fno-common: This has the effect that if the same variable is declared (without extern) in two different compilations, you get a multiple-definition error when you link them
# -fmessage-length=n: If n is zero, then no line-wrapping is done; each error message appears on a single line.
CFLAGS += -fmessage-length=0 -MMD -fno-common -MP -MF"$(@:%.o=%.d)"
CFLAGS += -Wall
# CFLAGS += -Og -ggdb -fno-omit-frame-pointer
CFLAGS += -O2

# disable some warnings...
# Header files
INCLUDE_PATH := -I"src/vm"

# Source folders
SRC_SUBDIRS := ./src
SRC_SUBDIRS += ./src/vm

# Add all files from the folders in SRC_SUBDIRS to the build
OBJDIR           := build
SOURCES          = $(foreach dir, $(SRC_SUBDIRS), $(wildcard $(dir)/*.c))
C_SRCS           = $(SOURCES)
VPATH            = $(SRC_SUBDIRS)
OBJ_NAMES        = $(notdir $(C_SRCS))
OBJS             = $(addprefix $(OBJDIR)/,$(OBJ_NAMES:%.c=%.o))
C_DEPS           = $(OBJS:%.o=%.d)
C_INCLUDES       = $(INCLUDE_PATH)
LOCAL_LIBRARIES = -lm

# flag -c: Compile without linking
$(OBJDIR)/%.o: %.c
	@echo 'CC: $<'
	@$(CC) $(CFLAGS) $(C_INCLUDES) -c -o"$@" "$<"

all: $(TARGET) example/bytecode.qvm q3asm lcc test/test.qvm

$(TARGET): $(OBJDIR) $(OBJS)
	@echo 'CFLAGS: '$(CFLAGS)
	$(LINK) $(LINK_FLAGS) -o"$@" $(OBJS) $(LOCAL_LIBRARIES)
	@echo 'Executable created: '$@

clean:
	@echo 'Cleanup...'
	$(CLEANUP) $(OBJDIR)/*.d
	$(CLEANUP) $(OBJDIR)/*.o
	$(CLEANUP) $(OBJDIR)/q3vm_test/*.d
	$(CLEANUP) $(OBJDIR)/q3vm_test/*.o
	$(CLEANUP) $(OBJDIR)/q3vm_test/*.gcno
	$(CLEANUP) $(OBJDIR)/q3vm_test/*.gcda
	$(CLEANUP) $(OBJDIR)/q3vm_test/*.gcov
	$(CLEANUP) ./$(TARGET)
	$(CLEANUP) ./*.gcov
	$(MAKE) -C example clean
	$(MAKE) -C lcc clean
	$(MAKE) -C q3asm clean
	$(MAKE) -C test/q3vm_test clean

test: $(TARGET) test/q3vm_test/q3vm_test test/test.qvm example/bytecode.qvm
	./q3vm example/bytecode.qvm
	./test/q3vm_test/q3vm_test test/test.qvm

dump: $(TARGET)
	objdump -S --disassemble $(TARGET) > $(TARGET_BASE).dmp

# static code analysis with cppcheck
cppcheck:
	cppcheck --error-exitcode=-1 src/

clangcheck: clean
	scan-build make q3vm

valgrind: $(TARGET) test/test.qvm test/q3vm_test/q3vm_test example/bytecode.qvm
	valgrind --error-exitcode=-1 --leak-check=yes ./q3vm example/bytecode.qvm
	valgrind --error-exitcode=-1 --leak-check=yes ./test/q3vm_test/q3vm_test test/test.qvm

analysis: clangcheck cppcheck

# Example
example/bytecode.qvm: q3asm lcc
	$(MAKE) -C example

# Test and code coverage firmware
test/test.qvm: q3asm lcc
	$(MAKE) -C test

test/q3vm_test/q3vm_test:
	$(MAKE) -C test/q3vm_test

$(LCCTOOLPATH)lcc:
	$(MAKE) -C lcc BUILDDIR=build all
	cp lcc/build/lcc$(TARGET_EXTENSION) $(LCCTOOLPATH)
	cp lcc/build/cpp$(TARGET_EXTENSION) $(LCCTOOLPATH)q3cpp$(TARGET_EXTENSION)
	cp lcc/build/rcc$(TARGET_EXTENSION) $(LCCTOOLPATH)q3rcc$(TARGET_EXTENSION)

lcc: $(LCCTOOLPATH)lcc

q3asm/q3asm$(TARGET_EXTENSION):
	$(MAKE) -C q3asm
	cp q3asm/q3asm$(TARGET_EXTENSION) $(LCCTOOLPATH)

q3asm: q3asm/q3asm$(TARGET_EXTENSION)

doxygen:
	@echo "Creating doxygen documentation"
	@doxygen doxygen/Doxyfile

gcov: clean test
	@gcov build/q3vm_test/*.gcda

# Make sure that we recompile if a header file was changed
-include $(C_DEPS)

post-build:

.FORCE:

.PHONY: all test doxygen .FORCE

.SECONDARY: post-build

