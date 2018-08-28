Q3VM Readme
===========

A lightweight embeddable interpreter/Virtual Machine (VM) for compiled bytecode files (`.qvm`) based on good old C-language input (`.c`). A complete C compiler to generate `.qvm` files is included (LCC). The interpreter is based on the Quake III Arena virtual machine (hence the name q3vm) but the interpreter is not tied to Quake III Arena and can be used for any kind of project. For example code that needs to run in a sandbox.

      ___   _______     ____  __
     / _ \ |___ /\ \   / /  \/  |
    | | | |  |_ \ \ \ / /| |\/| |
    | |_| |____) | \ V / | |  | |
     \__\_______/   \_/  |_|  |_|

[![Build Status](https://travis-ci.org/jnz/q3vm.svg?branch=master)](https://travis-ci.org/jnz/q3vm)
[![codecov](https://codecov.io/gh/jnz/q3vm/branch/master/graph/badge.svg)](https://codecov.io/gh/jnz/q3vm)
[![Coverity](https://scan.coverity.com/projects/16570/badge.svg)](https://scan.coverity.com/projects/jnz-q3vm)

Jan Zwiener, 2018. Mail: jan@zwiener.org

Features
--------

 * Small and lightweight (one .c file to include without dependencies)
 * Battle-tested (20 years of use in Quake III Arena)
 * Tool tested (static code analysis, test coverage)
 * No need to learn a new scripting language (e.g. Lua)
 * Strong typing in the scripting language (C)
 * Static memory allocation in C, no unpredictable garbage collector
 * Plan B: you can always go back to native code, as .c files are the input
 * Great tool landscape for C. Use the tools that are available for C
 * Computed gotos are used to speed up the interpreter if you compile with GCC

Quick Intro
-----------

Two things are required:

 * The interpreter
 * A bytecode binary .qvm file

Run:

    > q3vm.exe bytecode.qvm

The q3vm.exe standalone interpreter is not required. You can
easily add the interpreter as a single .c file to your project (`vm.c` and the header `vm.h`).
Call `VM_Create` and `VM_Call` to run the bytecode in your
application:

    #include "vm.h"

    vm_t vm;
    
    VM_Create(&vm, "my test", pointerToByteCodeBuffer, sysCall);
    VM_Call(&vm, 0);
    VM_Free(&vm);
    
The `pointerToByteCodeBuffer` is some memory location where the
bytecode is located. You can e.g. load it from a file and store it
in a byte array. See `main.c` for an example implementation.

The `sysCall` is a callback function that you define so that
the interpreter can call native functions from your code. E.g. a
logging function or some time critical function that you don't want
to implement in the bytecode. Again, check `main.c` for an example.

Folder structure
----------------

    ├─ bin/
    │  ├─ linux/        Target folder for Linux lcc and q3asm builds
    │  └─ win32/        Precompiled lcc.exe and q3asm.exe for Windows
    ├─ build/           Target folder for q3vm build
    ├─ doxygen/         Doxygen config and output
    ├─ example/         Example bytecode.qvm
    ├─ lcc/             The LCC compiler (compile .c files to .asm files)
    ├─ msvc/            Microsoft Visual Studio 2015 project file for q3vm
    ├─ q3asm/           Link the LCC .asm to a .qvm bytecode file
    ├─ src/             q3vm standalone application source code
    │  └─ vm/           The core VM source, copy that folder into your project
    └─ test/            test bytecode qvm

API Documentation
-----------------

Call `make doxygen` to autogenerate the API documentation in the `doxygen/html`
directory. Doxygen and dot command (part of graphviz) is required.
Install it with `sudo apt-get install doxygen graphviz` on Debian or Ubuntu.

    > make doxygen

But you can also read `vm.h` directly for the API documentation.


Build VM/interpreter
--------------------

On **Linux**:

    > make

On **Windows**:

Use the **Visual Studio 2015** project `q3vm.sln` in the `msvc` subfolder.

Or install MinGW64 and add the MinGW64 bin\ directory to your path.
So that you have gcc.exe and mingw32-make.exe available at the command prompt.

 * http://mingw-w64.org/doku.php/download/mingw-builds

Compile with:

    > mingw32-make

Build example bytecode firmware
-------------------------------

**Windows**:

The LCC compiler (lcc.exe) is included in the ./bin/win32 directory.
You need make (mingw32-make) from the MinGW64 installation in
your path.

    cd example
    mingw32-make
    cp bytecode.qvm ..
    cd ..

If you don't want to use make, you can do the steps from the make file
manually at the command line. Compile every `.c` source code with `LCC`:

    > lcc -S -Wf-target=bytecode -Wf-g YOUR_C_CODE.c

This will create .asm output files. Then link the .asm files with `q3asm` (based on a bytecode.q3asm
linker script):

    > q3asm -f bytecode

The output of q3asm is a `.qvm` file that you can run with q3vm.


**Linux**:

Build LCC (and copy the executables to ./bin/linux directory).

    > cd lcc
    > make BUILDDIR=build all
    > cd build
    > cp lcc ../../bin/linux/lcc
    > cp cpp ../../bin/linux/q3cpp
    > cp rcc ../../bin/linux/q3rcc
    > cd ../..

Build q3asm

    > cd q3asm
    > make
    > cp q3asm ../bin/linux/
    > cd ..

Build the example bytecode:

    > cd example
    > make
    > cp bytecode.qvm ..
    > cd ..

Run the bytecode firmware
-------------------------

    > q3vm bytecode.qvm


Static code analysis
--------------------

Call `make analysis` and `make valgrind` to check the VM with:

 * clang static code analysis (scan-build)
 * cppcheck
 * Valgrind

clang-format
------------

Run the following command to reformat a file according to the coding style:

    > clang-format -i -style=file input.c

TODO
----

Known limitations, bugs, missing features.

 * The Quake III Arena JIT compiler (e.g. for x86) is not added.
 * Some 16 bit int operations won't compile with LCC (op code not supported).
 * Static memory allocation support for embedded targets is missing (if you
   don't want malloc).

Credits
=======

This project is based on the Quake 3 and ioquake3 source:

 * https://github.com/id-Software/Quake-III-Arena (id Software)
 * https://github.com/ioquake/ioq3

Computed gotos are used:

 * https://eli.thegreenplace.net/2012/07/12/computed-goto-for-efficient-dispatch-tables
 
