<!--
SPDX-FileCopyrightText: Robert Ryszard Paciorek <rrp@opcode.eu.org>
SPDX-License-Identifier: MIT

Document translated automatically using AI (chat GPT). Required verification of correctness.
-->

Programming
============

## The Multiplicity of Programming Languages

The existence of more than one programming language makes sense because it allows the language to be tailored to its specific use – a language designed for working with files and launching other programs will require different mechanisms than a high-level general-purpose scripting language, and even more so a relatively low-level, efficient, compiled language. It's also worthwhile to learn more than one programming language to cover different applications. However, it is not necessary to learn a dozen or more languages "just in case," as unused languages and their syntactical details tend to be forgotten, and once one knows how to program, learning another (especially a non-exotic) language is a matter of a few to several hours of programming with the help of its documentation and standard libraries.

## Input/Output Implementation

Depending on the system for which our program is created, or whether it will run under an operating system or directly on hardware, I/O implementation may differ. When creating a program that operates under an operating system, almost all I/O operations are handled through system mechanisms via standard library functions. However, in direct hardware programming, it is often necessary to write entire such functions, or at least "system" functions, that perform the actual I/O operation used by standard library functions.

For example, using the `printf` function from the C standard library. On Linux systems, it uses the system's standard output mechanism, which is displayed on the terminal or redirected to another process. If we want to use this function on the STM32 platform, we must implement a function that physically sends the data through the chosen serial port or displays it on an alphanumeric LCD.

## Object-Oriented Programming

Object-oriented programming is an approach that involves associating data with functions that operate on it within classes/objects. A class defines the data type that objects of that class will have by specifying the attributes (member fields storing data) and methods (functions provided by the object and operating on it). An object is a specific instance of a class that contains actual data. Classes differ from complex non-object types (e.g., structures or arrays) in that they define both data and related behavior, making it easier to model real-world entities in code. As a result, instead of a group of functions operating on some data structure and separate instances of that structure (e.g., a `char*` string and functions from the `string.h` family), objects containing both data and methods operating on them are used (e.g., a `std::string` string).

### Methods

Functions defined in a class are called methods of that class. Typically, such functions require an object of the given class to operate, which is passed to them as an (explicit or implicit) argument. Static methods are distinguished by the fact that they do not require an object of the class to operate (or at least do not receive it as a special argument like regular methods). They allow treating the class as a namespace for logically related functions (but not operating on an object), e.g., functions that create objects of the class and other helper functions.

### Inheritance

The inheritance mechanism allows creating new classes based on existing ones by utilizing their attributes and methods. This enables extending existing types and creating more specific types (e.g., the classes "triangle" and "square" inheriting from the "polygon" class).

Additionally, it is often possible to redefine in a derived (inheriting) class methods that already exist in the base class. When using the virtual method mechanism, this allows executing a method from the appropriate derived class, even when at compile time we only know that the object is of the base class type (and do not know the specific derived class). For example:

- The "polygon" class provides a virtual method "calculate area."
- The classes inheriting from it ("triangle" and "square") provide different versions of this method.
- A function receiving a list or array of objects of type "polygon" (which are actually objects of type "triangle" or "square") can call the "calculate area" function on each of them (without explicitly checking the specific type), and the correct function will be used.

This allows creating class interfaces that expose only what should be visible about the objects of the class and hide implementation details.

## Function and Operator Overloading

Many programming languages allow defining functions with the same name but different sets of arguments — this could be the number of arguments or just the type (even a single argument) — this mechanism is known as function overloading. Similarly, in some languages, it is possible to define custom behaviors for standard operators (e.g., addition) when they are used on objects of a custom class.

## Lambda

Lambda functions are anonymous functions that do not have a name assigned to them, and their definition is typically concise and single-line. They are often used for short operations, especially when functions are passed as arguments to other functions. Typically, the values of arguments and variables are mapped only at the moment of function execution, not at the moment of its definition, meaning that the environment in which the function is executed can affect the result (e.g., through global variables or variables from the surrounding scope).

However, in some languages, it is possible to force the use of values from the moment of definition, i.e., so-called capture by value.

In Python, this can be achieved, for example, using default argument values in lambdas:

```python
x = 10
lambda_function = lambda y, x=x: x + y  # x is now frozen as 10
```

In C++, lambdas have a mechanism for capturing variables by value or by reference. Variables can be explicitly frozen by capturing them by value:

```cpp
int x = 10;
auto lambda_function = [x](int y) { return x + y; };  // x is frozen as 10
```

## Templates

Strong, static typing, despite its advantages, also has drawbacks. One of them is leading to code duplication, e.g., in situations where we expect the same behavior of a function for different data types. For example, a function that calculates a mathematical expression, which should work for different types of fixed and floating-point numbers without converting these types, should be defined separately for each of them in an identical way. The solution to this problem is using the template mechanism (provided by some languages). It allows defining templates for functions and/or classes, which the compiler can use to generate functions/classes for the required types based on this template (defined for a general placeholder type).

Example in C++:

```cpp
// template definition
template <typename T> T expression(T a, T b) {
    // T is a template parameter (placeholder type) and will be replaced by the argument type
    return a + 2*b*a + 3*b;
}

// usage examples:

// 1. arguments are of type int, and the result is of type int
int fun1(int a) { return expression(a, 13); }

// 2. arguments are of type double, and the result is of type double
double fun2(double a) { return expression(a, 1.3); }

// 3. arguments are of different types (double and int),
// we explicitly enforce the expression function to operate on double (as T),
// the value of `a` will be cast from int to double, and the result is of type double
double fun3(int a) { return expression<double>(a, 1.3); }
```
