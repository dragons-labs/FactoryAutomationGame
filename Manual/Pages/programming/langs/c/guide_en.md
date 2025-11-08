<!--
SPDX-FileCopyrightText: Robert Ryszard Paciorek <rrp@opcode.eu.org>
SPDX-License-Identifier: MIT

Document translated automatically using AI (chat GPT). Required verification of correctness.
-->

Basics of Programming in C
==========================

Compilation
-----------

Programs in C require compilation and linking to convert the source code into executable code. In a Linux environment, we can use one of several available compilers (note that the basic syntax is the same in each case):

* Default C compiler (usually one of the following): `cc -o executable_file source_file.c`
* Tiny C Compiler: `tcc -o executable_file source_file.c`
* GNU Compiler Collection's C compiler: `gcc -o executable_file source_file.c`
* clang and LLVM: `clang -o executable_file source_file.c`

In every case, a result file named as specified by the `-o` option (`executable_file`) will be created, and you can run it with the command: `./executable_file`

### Multiple source files

If a program consists of multiple source files, we can list them all in the command (e.g., `cc -o executable_file source_file_1.c source_file_2.c source_file_3.c`), but a better (faster and much more commonly used) approach is to separate the compilation of each file and linking the entire program into different stages – e.g. (note the `-c` option):

```sh
cc -o output_file_1.o -c source_file_1.c
cc -o output_file_2.o -c source_file_2.c
cc -o output_file_3.o -c source_file_3.c

cc -o executable_file output_file_1.o output_file_2.o output_file_3.o
```

This way, recompilation is only necessary for the modified files.

First Program
-------------

### Program starting point

Execution of a program written in C starts from the main function. There must be exactly one main function in the entire program (whether written in one or multiple files). The end of this function marks the end of the program, and the value it returns is responsible for the return code passed to the process that called the program.

### Program code

```c
#include <stdio.h> /* header file containing the declaration of the puts function */
int main() {
	puts("Hello from C"); // calling the puts function to print text to standard output
	return 0; // return code set to zero = success
}
```

* The text enclosed between `/*` and `*/` and the text from `//` to the end of the line are comments, meaning information for the programmer (e.g., a description of how the algorithm works) that is ignored by the compiler.
* A function definition starts with the return type (for the `main` function, this is `int`, meaning an integer), followed by a space, the function name, parentheses containing the argument list (empty in this example), and finally the function code.
* The function code, as well as other code blocks, is enclosed in curly braces (`{` and `}`).
* A semicolon `;` is used to separate consecutive commands.
* The keyword `return` terminates the function and sets the return value.
* The preprocessor directive `#include` is used to include the contents of another file, in this case, the header file of the C standard library, containing declarations of functions related to standard input and output.


Documentation
-------------

The C standard library is described in chapters 2 and 3 of the system manual. Chapter 2 describes system calls, and chapter 3 covers other elements of the C standard library. Thus, by executing the command `man 3 printf`, you can familiarize yourself with the documentation of the `printf` function.

Variables
---------

```c
#include <stdio.h>
int main() {
	char byte = 13;
	int integer = 12345;
	double floating_point = 13.111;
	
	printf("%d %x %d %f\n", byte, byte, integer, floating_point);
	
	return 0;
}
```

* A variable declaration consists of the variable type and its name.
* A variable definition also includes an assignment of a value.
* The basic types of variables are:
    * Architecture-dependent integers:
        * Signed, such as `char`, `short`, `int`, `long`, `long long`
        * Unsigned, such as `unsigned char`, `unsigned short`, `unsigned int`, `unsigned long`, `unsigned long long`
        * The number of bits (and thus the supported range of values) of such numbers depends on the architecture/compiler; the standard only defines the minimum size, e.g., 16 bits for `int`, though it most commonly has 32 bits.
    * Fixed-width integers (may require the `stdint.h` header):
        * Signed, such as: `int8_t`, `int16_t`, `int32_t`, `int64_t`
        * Unsigned, such as: `uint8_t`, `uint16_t`, `uint32_t`, `uint64_t`
    * Floating-point numbers, such as `float`, `double`
* A variable is accessed by its name.
* Uninitialized variables can have any value.

### printf

To print variable values, the `printf` function from the standard library (from the `stdio.h` header) can be used.

* The first argument it takes is a format string containing sequences starting with the percent symbol (`%`), under which the values of the following variables will be substituted.
* The sequence after `%` specifies the print format, e.g.:
    * `%d` - integer of type `int` printed in decimal
    * `%x` - unsigned integer printed in hexadecimal
    * `%f` - floating-point number
    * `%s` - string
* It can also specify the way the number is printed, e.g.:
    * `%3d` - an integer reserving 3 spaces (padding with spaces in front)
    * `%03d` - an integer reserving 3 spaces (padding with leading zeros)
    * `%.2d` - a floating-point number with two decimal places
    * `%6.2d` - a floating-point number with two decimal places, reserving 6 spaces (including the dot and the places after the dot)

Arrays
------

```C
#include <stdio.h>
int main() {
	int array[3]; // 3-element array of integers
	
	array[0] = 13; // elements of the array are accessed using [],
	               // array elements are indexed starting from zero
	array[2] = 17;
	
	printf("%d %d\n", array[0], array[1]);
	// uninitialized elements (just like uninitialized variables) will have random values
	// (however, this is not a good source of randomness)
	
	return 0;
}
```

* An array is a collection of variables of the same type, accessed using the array variable name and an index.
* An array definition specifies its size (number of elements). C does not enforce bounds checking for arrays - this is the programmer's responsibility.
    * In the above example, referencing the fifth element of an array will not be detected by the compiler as an error and may (but does not have to) cause a segmentation fault during the program's execution.
* Array elements are indexed starting from zero.

### Variable-Length Arrays

Since C99, the C language allows the use of variable-length arrays (*VLAs*), meaning arrays whose size is not a compile-time constant but a variable - e.g.:

```c
void xxx(int n) {
    float vals[n];
    v[0] = 21;
    /* ... */
}
```

Arithmetic Operations
---------------------

Basic arithmetic operations are performed using operators placed between arguments, mimicking mathematical notation.

* Addition: `+` e.g., `int a = 3 + 2;` (variable `a` will have the value 5)
* Subtraction: `-` e.g., `int a = 3 - 2;` (variable `a` will have the value 1)
* Multiplication: `*` e.g., `int a = 3 * 2;` (variable `a` will have the value 6)
    * In C, multiplication must always be written with the multiplication sign (operator). The notation known from mathematics, like [i]3a[/i], is not allowed and should be written as [i]3 * a[/i].
    * It is possible and common to add a `-` sign before a variable's name to reverse its sign (multiply by -1), e.g., `int b = -a;`.
* Division: `/` e.g., `int a = 3 / 2; float b = 3 / 2; float c = 3.0 / 2;` (variable `a` will have the value 1, as will `b`, while `c` will have 1.5 since it results from floating-point division where one argument is a floating-point number)
    * In C, the type of division (integer or floating-point) depends on the types of the arguments.
* Remainder of division: `%` e.g., `int a = 3 % 2;` (variable `a` will have the value 1)

The order of operations is maintained, and operations can be grouped using parentheses `(` and `)`, e.g., `int a = 3 + 2 * 2` will set the value of variable `a` to 7, while `int a = (3 + 2) * 2` will set the value of variable `a` to 10.

```c
#include <stdio.h>

int main() {
	double a = 12.7, b = 3, c, d, e;
	int x = 5, y = 6, z;
	
	// addition, multiplication, subtraction are written
	// and work just like in regular mathematics:
	e = (a + b) * 4 - y;
	
	// division depends on the types of the arguments
	d = a / b; // this will be floating-point division because a and b are of type float
	c = x / y; // this will be integer division because x and y are integers
	b = (int)a / (int)b; // this will be integer division
	a = (double)x / (double)y; // this will be floating-point division
	
	// remainder of division (only for integer arguments)
	z = x % y;
	
	// printing results
	printf("%d %f %f %f %f %f\n", z, e, d, c, b, a);
	
	// note: the above program may not perform calculations during runtime
	// due to optimization and the fact that the results of all operations
	// are known at the time of program compilation
}
```

Logical and Bitwise Operations
------------------------------

Logical and bitwise operations are operations that work in Boolean algebra. In the case of logical operations, they are performed on the entire variable (i.e., the whole value of the variable corresponds to a logical one or a logical zero). In contrast, bitwise operations are performed on individual bits of variables that are the arguments of the operation, meaning the bits in position zero of both arguments give the result in the bit at position zero of the result variable, the bits in position one give the result at position one, and so on.

```c
#include <stdio.h>

int main() {
	// logical operations:
	// ((a greater than or equal to 0) AND (b less than 2)) OR (z equals 5)
	z = (a >= 0 && b < 2) || z == 5;
	// logical negation of z
	x = !z;
	
	printf("%d %d\n", z, x);
	
	// bitwise operations:
	// bitwise OR of 0x0f and 0x11 and left shift of the result by 1
	x = (0x0f | 0x11) << 1;
	// bitwise XOR of 0x0f and 0x11
	y = (0x0f ^ 0x11);
	// bitwise negation of the result of bitwise AND of 0xfff and 0x0f0
	z = ~(0xfff & 0x0f0);
	
	printf("%x %x %x\n", x, y, z);
	
	// note: the above program may not perform calculations during runtime
	// due to optimization and the fact that the results of all operations
	// are known at the time of program compilation
}
```

Command-line arguments
----------------------

Command-line arguments (including the name under which the program was executed) are passed to the main function as two arguments:

* An integer specifying the number of arguments, typically called *argc*.
* An array of strings, typically called *argv*.

```C
#include <stdio.h>
int main(int argc, char *argv[]) {
	printf("%d %s\n", argc, argv[0]);
	return 0;
}
```

Loops and Conditions
--------------------

```c
#include <stdio.h>

int main(int argc, char *argv[]) {
	int i = 1, j = argc, k = 4;
	
	// if - else conditional statement
	if (i < j) {
		puts("i < j");
	} else if (j < k) {
		puts("i >= j AND j < k");
	} else {
		puts("i >= j AND j >= k");
	}
	
	// basic logical operators
	if (i < j || j < k)
		puts("i < j OR j < k");
	// other logical operators include && (AND), ! (NOT)
	
	// for loop
	for (i = 2; i <= 9; ++i) {
		if (i == 3) {
			// skip this loop iteration
			continue;
		}
		if (i == 7) {
			// exit the loop
			break;
		}
		printf(" a: %d\n", i);
	}
	
	// while loop
	while (i > 0) {
		printf(" b: %d\n", --i);
	}
	
	// do - while loop
	do {
		printf(" c: %d\n", ++i);
	} while (i < 2);
	
	// switch statement
	switch(i) {
		case 1:
			puts("i == 1");
			break;
		default:
			puts("i != 1");
			break;
	}
}
```

Strings
-------

Strings in C are arrays of bytes (arrays of type `char`) terminated by a byte with a value of zero (NULL), which serves as the end-of-string marker.

```c
#include <stdio.h>

// function without arguments and no return value
void f1() {
	puts("ABC");
}

// two-argument function with a return value
int f2(int a, int b) {
	return a * 2.5 + b;
}

// function with one mandatory argument and one optional argument
float f3(int a, int b = 1) {
	puts("F3");
	return a * 2.5 + b;
}

int main() {
	f1();
	
	int a = f2(3, 6);
	// the return value can be used (as above) or ignored:
	f3(0);
	
	printf("%d\n", a);
}
```

Files
-----

```C
#include <stdio.h>

int main() {
    // opening the file specified in the first argument,
    // in the mode specified by the second argument:
    // r - read, w - write, a - append,
    // + - bidirectional (used after r, w or a)
    FILE *file = fopen("/tmp/file1.txt", "w+");
    
    // writing to the file
    fputs("Hello World !!!\n", file);
    fprintf(file, "%.3f\n", 13.13131);
    
    // since these are buffered operations, to ensure
    // that the data is actually written to the file, 
    // you should use fflush(), although this is not
    // necessary when closing the file (as it happens automatically)
    fflush(file);
    
    int pos = ftell(file);
    printf("current position in the file is %d\n", pos);
    
    // rewinding to the beginning
    // equivalent to rewind(file);
    fseek(file, 0, SEEK_SET);
    
    // reading from the file
    char text[10];
    fgets(text, 10, file);
    // the read string will contain 9 characters + NULL-terminator
    
    puts(text);
    
    // returning to the previous position
    fseek(file, pos, SEEK_SET);
    
    // binary operations - this way we can write
    // and read entire buffers from memory, including strings
    // writing to the file
    double x = 731.54112, y = 12.2;
    fwrite(&x, 1, sizeof(double), file);
    fflush(file);
    
    // seeking the position where we wrote
    fseek(file, pos, SEEK_SET);
    // and reading from the file ...
    fread(&y, 1, sizeof(double), file);
    
    printf("written: %f, read: %f\n", x, y);
    
    // there are also read() and write() functions that operate 
    // using numeric file descriptors obtained from functions like open(),
    // rather than the FILE object from fopen()
    
    fclose(file);
}
```
