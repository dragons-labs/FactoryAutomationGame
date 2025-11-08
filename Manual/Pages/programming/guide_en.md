<!--
SPDX-FileCopyrightText: Robert Ryszard Paciorek <rrp@opcode.eu.org>
SPDX-License-Identifier: MIT

Document translated automatically using AI (chat GPT). Required verification of correctness.
-->

Programming
============

[url=guide://electronics/digital/programmable]As we know[/url], the operation of a processor (and thus computers) involves fetching and executing a sequence of instructions from a program. These instructions are in numerical form, understandable by the given processor architecture, i.e., machine code. Each machine code instruction corresponds directly to an assembly instruction for that processor.

However, when creating computer programs, we usually use higher-level programming languages and work with more abstract instructions that are independent of the processor architecture. Programming involves writing an algorithm that defines what a program should do and how, using a programming language. There are hundreds of programming languages, but most of them share mechanisms related to the same basic programming concepts:

* Arithmetic, logical, and bitwise operations – the computer is a digital electronic counting machine, so most of its actions boil down to some form of computation (on numbers represented in the binary system).
* Memory usage – referring to and modifying stored data. If a program's operation is not some kind of computation, it is almost certainly fetching or modifying data in memory (e.g., changing a letter in a text editor or the color of a pixel in a graphics program).
* Repeating and conditionally executing a group of instructions – this allows for reducing code size, automating various operations, and responding to input data and signals.
* Calling (and creating custom) library functions – defining and calling code fragments that operate on passed arguments and can return a result.
* Performing input/output operations, i.e., reading data and returning results – these can involve local input/output devices (like a keyboard and monitor), data stored on various media (like hard drives), accessing a computer network, inter-process communication mechanisms, etc.

## Functions

A function is a group of instructions that can be called from another part of the program. In simple terms, this involves jumping to the start of that group and returning once its execution is complete. The stack is used to manage storing addresses for return jumps (in addition to storing arguments, return values, and local variables).

A function can receive arguments, which are available as variables inside the function, and return a value. Variables defined inside the function are not visible outside of it, and modifying the values of arguments will not affect the variables passed as arguments – they are passed by copying their value into a new variable. Typically, functions can use (and modify) global variables, i.e., those defined outside the function's scope.

## Data Types

For the computer, all data stored in memory is simply a sequence of bits. To perform operations on them, it is necessary to define how to interpret this data. In programming, variable types are used for this purpose.

In statically typed languages, such as C or C++, the type must be explicitly defined before using the variable, and its type cannot change. However, in some languages, automatic type detection is possible based on the value assigned to the variable at the time of declaration (e.g., `auto` type in C++).

In dynamically typed languages, such as Python, data types are assigned automatically during the program's execution and can change while the program runs (the same variable can have different types at different points in the program), providing flexibility but potentially leading to errors due to unexpected variable types.

There is also an approach where a variable's type (such as always being a string) is interpreted at the moment of use, depending on the context (this is how shell variables and environment variables function in Unix systems).

The processor only performs operations on numbers of finite (architecture-dependent) bit length. All more advanced data types are implemented using these basic types and operations on them. This also applies to number types with unlimited range, and on some platforms, even floating-point numbers. The availability of such data types heavily depends on the programming language. Key types include:

* Arrays – an ordered collection of consecutive values of the same data type, accessed by the element's index, often as a contiguous memory block.
* Structures/Classes – a collection of values of different data types, accessed by name.
* Strings – sequences of characters, sometimes implemented as an array, sometimes as an independent data type.
* Lists – an ordered collection of consecutive values (of the same or different data types), accessed by reference to the next/previous element.
   * Singly linked – do not have references to the previous element.
   * Cyclic – the next element after the last is the first, and the previous element before the first is the last.
* Dictionaries/Maps/Associative arrays – a collection of key-value pairs, accessed by the unique key, depending on the implementation, all keys/values must be of the same or different types.
   * Multimaps – a variant that does not require unique keys.
   * Sets – a variant that does not store values (only unique keys).

## Variable Address

All the data operated on by a computer program is stored in some type of memory, typically RAM. In certain situations, some data may be stored, for example, only in the processor's registers or in input/output device registers.

In higher-level programming than machine code and assembly, the concept of a variable is used, and the compiler/interpreter is (almost always) left to decide where it is stored. An exception is groups of variables or buffers explicitly allocated in memory. Due to the limited number of processor registers, most variables (especially long-lived and larger ones) will be stored in memory and transferred to registers to perform operations on them, after which the result will be transferred back to memory.

Each variable stored in memory has a memory address where it is located. Some programming languages allow referencing this address via a pointer to the variable or a reference to the variable (address references may force the variable to be placed in memory even if it would normally be stored only in a processor register).

## Value vs. Reference

The main difference between using a variable directly (its value) and using a reference to a variable (its address, pointer) becomes apparent when passing such a variable by copying (e.g., as a result of assignment or passing to a function).
When using a "regular" variable, the copy cannot modify the original. When passing a reference, any changes to the value it points to will be visible through both references (the original and the copy), as long as they remain equal (point to the same memory address).
This can be used as an alternative method of returning values from a function – by modifying the values of variables for which the function received references (pointers) in its arguments.

## Compilation, Interpretation, ...

An important distinction in programming languages is between compiled and interpreted languages.

In compiled languages, it is necessary to translate the program's source code into machine code using a suitable tool (compiler). Compilation may occur in several stages – for example, a preprocessor may first be invoked (to process the source code into output code), followed by the actual compilation from a high-level language into assembly/machine code, and finally, consolidation (or linking), using libraries and determining the entry point (the location from which the program starts execution).

In interpreted (scripting) languages, the interpreter reads the source code instructions one by one and executes them. These instructions can be read from a text file (batch processing) or input directly into the interpreter's command line by the user (interactive mode).

There are also languages that are compiled into intermediate code – in this case, the source code is compiled into a binary, platform-independent intermediate code, which is then interpreted and translated into processor instructions during program execution.

Typically, the advantage of interpreted languages is the ability to work interactively and ease of modifying the code, while compiled languages offer faster program execution.
