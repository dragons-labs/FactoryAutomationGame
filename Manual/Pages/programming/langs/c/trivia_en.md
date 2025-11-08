<!--
SPDX-FileCopyrightText: Robert Ryszard Paciorek <rrp@opcode.eu.org>
SPDX-License-Identifier: MIT

Document translated automatically using AI (chat GPT). Required verification of correctness.
-->

Basics of C Programming (More Advanced Topics)
==============================================

Preprocessor
------------

The C preprocessor can also be used for:

- defining constants
- defining macros
- conditional compilation of code and commenting out its parts (`#if 0` and `#endif`)

Preprocesor C może być użyty także do:

- definiowania stałych
- definiowania makr
- warunkowej kompilacji kodu oraz komentowania jego fragmentów (`#if 0` oraz `#endif`)

```C
// the following directive replaces EVERY occurrence of _TEXT_ 
// in the program code with "Hello World"
#define _TEXT_ "Hello World"
// similarly, we can define pseudo-functions
#define _SUM_(a,b) (a + b)
// prefixing an argument with # wraps it in ""
#define _PRINT_(a) printf(#a)
// ## concatenates ...

// due to error control at the compilation stage
// it's recommended to limit #define usage (in the above cases)
// in favor of constants and inline functions

// we can also conditionally include code fragments
#define PL

#ifdef PL
    // this block will only execute if PL is defined
    #undef _TEXT_
    // we have undefined _TEXT_
    #define _TEXT_ "Hello World"
    // and redefined it differently
#endif

#if 0
this is the third type of comment in C
#endif

#include <stdio.h>

int main() {
    printf("%s\n", _TEXT_);
    printf("%d\n", _SUM_(5,3));
    _PRINT_(hello world !!! \n);
}
```

Variable Number of Function Arguments
-------------------------------------

```C
#include <stdio.h>
#include <stdarg.h> // for handling a variable number of arguments

// function with two required arguments and any number of optional arguments
float f4(int a, int b, ...) {
    float ret = 0.0;
    
    va_list vl;
    va_start(vl, b);
    
    // here, we need to know the number 
    // and types of the arguments
    for (int i=0; i<a; i++) {
        ret += b * va_arg(vl, double);
    }
    va_end(vl);

    return ret;
}

int main() {
    float b = f4(2, 1, 2.8, 3.5);
    
    printf("%f\n", b);
}
```

Low-Level Jump Mechanisms
-------------------------

The `goto` instruction and the `setjmp`/`longjmp` functions are used for direct flow control in a program, but these mechanisms are generally avoided as they can reduce code readability.

### goto

```C
#include <stdio.h>

int main() {
	goto LABEL;
	puts("this will never execute");
	puts("because we perform an unconditional goto earlier");
	
	LABEL:
	puts("but this will execute");
}
```

The most common case for using `goto` is error handling in complex functions (so-called "cleanup" at the end of the function). `goto` to the code that performs cleanup and exits the function is used instead of return in conditions that check for an error.

### Long Jump

A long jump, performed by the functions `setjmp` and `longjmp`, allows for jumps between different functions. `setjmp` saves the program's context (e.g., stack state) and returns zero, while `longjmp` allows returning to that context (in this case, `setjmp` returns the value specified in the `longjmp` argument).

```C
#include <stdio.h>
#include <setjmp.h>

jmp_buf buffer;

void second() {
    longjmp(buffer, 1);  // jump back to the setjmp call
}

void first() {
    if (setjmp(buffer) == 0) {
        second();  // call the second function
    } else {
        printf("Return from longjmp\n");
    }
}
```


Variable and Its Address
------------------------

All data that a computer program operates on is stored in some type of memory—most commonly, in the main memory (RAM). In certain situations, some data may be stored, for instance, only in CPU registers or input-output device registers.

In programming languages higher than machine code or assembly, the concept of a variable is used, and (almost always) the decision about where it is stored is left to the compiler/interpreter. The obvious exception is groups of variables or buffers explicitly allocated in memory. Due to the limited number of CPU registers, most variables (especially those with longer lifetimes and larger sizes) will reside in memory and will be transferred to registers to perform operations on them, after which the result will be moved back to memory.

Each variable stored in memory is associated with a memory address where it resides. Some programming languages allow referencing this address through a pointer to a variable or a reference to a variable (referencing a variable's address may force it to be placed in memory, even if it would normally reside only in a CPU register).

All data is stored as numbers or sequences of numbers. The variable's type (whether explicit or not) informs us of how long the number is and how to interpret it (how to interpret a sequence of numbers).

### Scope of a Variable

The scope of variables (their visibility and existence) is limited to the block (delimited by curly braces) in which they are declared; variables from inner blocks can shadow those declared earlier.

Calling a function starts a new context in which the variables from the calling block are not visible (though they still exist). Function arguments are passed by copying, so the function cannot modify variables from the calling block, even if passed to it (the exception is passing by reference or pointer).

In the case of manual memory allocation (using `malloc`), the visibility and existence of the received pointer are limited, but not the allocated memory block. Thus, the visibility of such variables is limited, but not their lifetime, which is why they should be freed (the allocated memory) before losing the pointer to them.

### Pointers

A pointer is a variable that stores a memory address where some data (another variable) resides. Since a pointer is a variable stored somewhere in memory, you can create a pointer to a pointer, and so on. Arithmetic operations can be performed on pointers (most commonly adding an offset). A pointer can be dereferenced to access the value of the variable at the address it points to, rather than the pointer variable itself (which contains the address).

Pointers allow you to manipulate large data sets (large structures, strings, etc.) without having to copy them when passing them to functions, placing them in various data structures, sorting, etc. (only the pointer, i.e., the address, is copied), and to share the same data between different objects.

A pointer can point to an invalid address in memory (e.g., after freeing that fragment or due to an error in pointer arithmetic, such as going out of bounds). Typically, a pointer that points to nothing is assigned the value `NULL` (zero). Dereferencing pointers with a value of `NULL` or pointing to an invalid memory area leads to program errors, often terminating the program due to a memory protection violation ("Segmentation fault").

```c
#include <stdio.h>

int main() {
    int var = 13;
    int *ptr = NULL; // pointer variable (to type int)
    
    // assign the address of variable var to pointer variable ptr
    // obtain the address of var using the & operator
    ptr = &var;
    printf("%p %p\n", &var, ptr);
    
    // refer to the variable pointed to by ptr (dereference)
    // using the * operator
    printf("%d %d\n", var, *ptr);
    *ptr = 17;
    printf("%d %d\n", var, *ptr);
}
```

### Pointers and Arrays

An array variable in C is essentially a pointer to the first element of the array. Accessing array elements is based on calculating their address using the relationship: [i]ElementAddress = ArrayStartAddress + ElementIndex * ElementSize[/i].

```c
#include <stdio.h>

int main() {
  int arr[4] = {1, 8, 3, 2};
  int *p_arr = arr; // notice the absence of the address-of operator
  
  printf("%d %d\n", arr[2], p_arr[2]);
  printf("%d %d\n", *(arr + 2), *(p_arr + 2));
}
```

Note that the operator `arr[x]` works the same for both arrays and pointers and is essentially a cleaner way of writing `*(arr+x)` for a pointer.

### Pointers and Functions

Function arguments are passed by copying, so modifying a variable that is an argument inside the function will not be visible outside the function:

```c
void func(int a) {
    a = 15;
}
int main() {
    int x = 10;
    func(x);
    printf("%d\n", x); // will print 10
}
```

If we want to modify a variable passed as an argument, we can pass the variable to the function by pointer:

```c
void func(int* a) {
    *a = 15;
}
int main() {
    int x = 10;
    func(&x);
    printf("%d\n", x); // will print 15
}
```

This approach is also used when we want to avoid copying large structures. In this case, it is good practice to add `const`, so the function cannot modify what the pointer points to:
```c
struct Struct {
  int a, b;
};
void func(const struct Struct *s) {
    s->a = 15; // compilation error here, due to const in the line above
    /* note that we can access structure elements with
       object.field or (&object)->field (i.e., pointer_to_object->field) */
}
int main() {
    struct Struct s;
    func (&s);
}
```


### Pointer Arithmetic

As we have already noticed, (some) arithmetic operations can be performed on pointers. Their behavior depends on the pointer type, i.e., increasing the pointer by 1 increases the address it points to by as many bytes as the variable type the pointer points to occupies.

```c
#include <stdio.h>

int main() {
    char a;    int    b;
    char *ptr_a = &a;
    int  *ptr_b = &b;
    
    printf("char: %p %p\n", ptr_a, ptr_a+1);
    printf("int:    %p %p\n", ptr_b, ptr_b+1);
}
```



## Byte Order

Pointers and typecasting allow us to view data as individual bytes.

```c
#include <inttypes.h>
#include <stdio.h>
int main() {
    // data as an array of 16-bit numbers
    uint16_t arr[4] = {0x1234, 0x5678, 0x9abc, 0xdeff};
    
    // print the array
    printf("A0: %x %x %x %x\n", arr[0], arr[1], arr[2], arr[3]);
    // no surprise with this printf result:
    //   A0: 1234 5678 9abc deff
    
    // print the first two numbers broken into 8-bit parts
    // (individual bytes)
    printf(
        "A1: %x %x %x %x\n",
        (arr[0] >> 8) & 0xff, arr[0] & 0xff,
        (arr[1] >> 8) & 0xff, arr[1] & 0xff
    );
    // the result is also expected:  A1: 12 34 56 78
    
    // instruct the program to view the same data as 8-bit numbers
    // (individual bytes)
    uint8_t* bytes = (uint8_t*) arr;
    
    printf("B0: %x %x %x %x\n", bytes[0], bytes[1], bytes[2], bytes[3]);
    // what result do we expect now?
    //  - it will print only half of the original array
    //  - but the exact result depends on the architecture the program is run on (big endian vs little endian)
```

This code, depending on the processor architecture on which it is run, may output different results:

* On *little endian* (e.g., x86):
```
A0: 1234 5678 9abc deff
A1: 12 34 12 34
B0: 34 12 78 56
```
* On *big endian* (e.g., SPARC) – in "human-readable" order:
```
A0: 1234 5678 9abc deff
A1: 12 34 12 34
B0: 12 34 56 78
```

The fact that different computers may interpret the same binary sequence as different numbers (depending on the "big endian" vs "little endian" architecture) means that when exchanging data between systems, it is necessary to establish a method of interpretation (e.g., network protocols like IP use "big endian") or include this information in the exchanged data (Unicode encodings such as UTF-16 and UTF-32 include a BOM marker at the start of the data).

How C Code is Executed
----------------------

Jump instructions, which in programming are associated with constructs such as loops and conditions, rely on loading a new value into the program counter. In the case of conditional jumps (used by conditional instructions), this may depend on the flags register of the ALU unit, which is set as a result of the previous arithmetic operation.

```asm
# Fragment of assembly code generated by the "gcc -S" command from C code:
#    if (argc == 1)
#        puts("A");
#    else
#        puts("B");
#    puts("C");

# Comparison operation                                        --- if condition
	cmpl	$1, -4(%rbp)
# Jump if not equal to the else block
	jne	.L2
# Push the argument "A" onto the stack and call the puts function --- if block
	leaq	.LC0(%rip), %rdi
	call	puts@PLT
# Unconditional jump after the if-else block
	jmp	.L3
.L2:
# Push the argument "B" onto the stack and call the puts function --- else block
	leaq	.LC1(%rip), %rdi
	call	puts@PLT
.L3:
# Push the argument "C" onto the stack and call the puts function --- after if-else code
	leaq	.LC2(%rip), %rdi
	call	puts@PLT
```

Above is a fragment of x86 assembly code generated by the gcc compiler for the visible if-else construct. To execute the if condition, which checks if a variable equals one, an arithmetic comparison operation is first performed. Then a conditional jump instruction is executed, depending on whether or not the flag indicating equality is set. Since this if has an else block, the conditional jump (for the unfulfilled condition) goes to the first instruction of the else block, meaning the address of this instruction is loaded into the program counter. After the last instruction of the if block, there is an unconditional jump to the first instruction after the entire if-else construct, bypassing the else block. The unconditional jump simply loads the appropriate address value into the program counter.
