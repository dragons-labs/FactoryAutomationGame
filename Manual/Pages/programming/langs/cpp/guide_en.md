<!--
SPDX-FileCopyrightText: Robert Ryszard Paciorek <rrp@opcode.eu.org>
SPDX-License-Identifier: MIT

Document translated automatically using AI (chat GPT). Required verification of correctness.
-->

Basics of C++ Programming
=========================

Most of the basic syntax of C++ is identical to [ur=guide://programming/basics/c]C basic syntax[/url]. Below are the most important extensions and differences introduced by C++.

Compilation
-----------

C++ requires compilation using a compiler that supports this language. In a Linux environment, we can use one of several available compilers (note that the basic syntax remains the same in each case):

* The default C++ compiler (usually one of the following): `c++ -o executable_file source_file.cpp`
* GNU Compiler Collection C++ compiler: `g++ -o executable_file source_file.cpp`
* clang and LLVM: `clang++ -o executable_file source_file.cpp`

C++ Standard Library vs C
-------------------------

C++ has its own standard library and also allows seamless use of the C standard library. The C++ library even provides many functions fully compatible with the C standard library (though using different header files).

### Input/Output Streams

One of the most noticeable changes is the use of input-output streams instead of functions like `printf` (although using them is still possible):

```cpp
#include <iostream>

int main() {
	int x = 13;
	std::cout << "Hello world, x=" << x << std::endl;
}
```

### Strings

C++ has its own type wrapping the null-terminated string known from C (offering, for example, information about string length without having to read the entire string, and dynamic allocation).

```cpp
#include <stdio.h>
#include <iostream>

#include <string>
#include <string.h>
#include <bitset>
#include <regex>
#include <sstream>

int main() {
	const char* x = "abcdefg";
	
	std::string xx(x);
	std::string y = "aa bb cc bb dd bb ee";
	
	// Print string length
	std::cout << xx.size() << "\n";
	// .size() is the same as .length()
	
	// Get C-style string
	puts(xx.c_str());
	
	// Print substring from position 2 to the end
	std::cout << xx.substr(2) << "\n";
	std::cout << xx.substr(2, std::string::npos) << "\n";
	// And from position 0 (start) to 3
	std::cout << xx.substr(0, 3) << "\n";
	
	// Search for substring "bb" in y starting from position 5
	std::cout << y.find("bb", 5) << "\n";
	
	// Comparisons
	if (xx == "a")
		std::cout << "x == \"a\"\n";
	if (xx.compare(0, 1, "a") == 0)
		puts("first 1 characters of x are \"a\"");
	
	if ( std::regex_match(xx, std::regex(".*[dz].*")) )
		puts("x contains d or z");
	// regex_match matches the entire string to the regular expression
	// Partial matching, along with optionally obtaining the matching part, can be done with std::regex_search()
	
	// Modifying std::string
	xx = "Ala has a dog";
	// Insertion - insert(position, what)
	xx.insert(6, " and a cat");
	std::cout << xx << std::endl;
	
	// Replacement - replace(position, how many, with what);
	xx.replace(4, 2, "had a car", 0, 6);
	// It could also be xx.replace(4, 2, "had"); and several other variations...
	std::cout << xx << std::endl;
	
	// Erasing - erase(position, how many);
	xx.erase(9, 1); // 9 instead of 8 because UTF-8 and ł takes two characters
	std::cout << xx << std::endl;
}
```

Documentation
-------------

Documentation is available in the form of *the C++ reference* accessible online at [url=https://en.cppreference.com/]https://en.cppreference.com/[/url], and often also distributed as a system package.

STL Containers
--------------

### Variable-length arrays

C++ officially does not support variable-length arrays (VLA) as in C99, although some compilers allow the use of VLA in C++. However, C++ has the std::vector type, which allows for defining arrays whose size can easily be changed even after the array is created (from a programmer's point of view, though not necessarily for the machine executing the code):

```cpp
#include <vector>

void xxx(int n) {
    std::vector<float> vals(n);
    v[0] = 21;
    /* ... */
}
```

### Lists

The C++ Standard Library (specifically the part known as STL) also provides support for lists:

```cpp
#include <iostream>
#include <list>

int main() {
    std::list<int> l;
    
    // adding an element to the end
    l.push_back(17);
    l.push_back(13);
    l.push_back(3);
    l.push_back(27);
    l.push_back(21);
    // adding an element to the front
    l.push_front(8);
    
    // printing the number of elements
    std::cout << "size=" << l.size() << "\n";
    
    // printing the first and last elements
    std::cout << "first=" << l.front() << " last=" << l.back() << "\n";
    
    // removing the last element
    l.pop_back();
    
    // sorting the list
    l.sort();
    
    // reversing the order of elements
    l.reverse();
    
    // removing the first element
    l.pop_front();
    
    for (std::list<int>::iterator i = l.begin(); i != l.end(); ++i) {
        // printing all elements
        std::cout << *i << "\n";
        // it's also possible to:
        // - remove the element pointed to by the iterator
        // - insert an element before the position pointed to by the iterator
    }
}
```

In C++, lists are implemented as linked lists rather than arrays of pointers, so operations like inserting at the beginning or in the middle are fast, but accessing the n-th element is slow.

### Maps

The C++ Standard Library also provides a container for storing data in key-value pairs, where the value is identified by a unique key (similar to Python dictionaries):

```cpp
#include <iostream>
#include <map>

int main() {
    std::map<std::string, int> m;
    
    m["a"] = 6;
    m["cd"] = 9;
    std::cout << m["a"] << " " << m["ab"] << "\n";
    
    // searching for an element by key
    std::map<std::string, int>::iterator iter = m.find("cd");
    // checking if it exists
    if (iter != m.end()) {
        // printing the key-value pair
        std::cout << iter->first << " => " << iter->second << "\n";
        // removing the element
        m.erase(iter);
    }
    
    m["a"] = 45;
    
    // printing the entire map
    for (iter = m.begin(); iter != m.end(); ++iter)
        std::cout << iter->first << " => " << iter->second << "\n";
    // as you can see, the map is internally sorted
}
```

The `std::map` container does not maintain the order of insertion, but it is always sorted. C++ also offers other types of maps (e.g., the unsorted `std::unordered_map`, or `std::multimap`, which does not require unique keys).

More C-plus-plus...
-------------------

### Iterators

In the above examples with lists and maps in C++, note the use of iterators, which allow sequential access to elements in these containers:

```cpp
void printList(std::list<int> l) {
    for (std::list<int>::iterator i = l.begin(); i != l.end(); ++i) {
        std::cout << *i << "\n";
    }
}
```

Iterators are returned by some of the methods on the container objects, e.g., `.begin()` returns an iterator to the first element. Incrementing the iterator is done using the `++` operators. Exceeding the range (incrementing the iterator past the last element) does not throw an exception, but instead, the iterator assumes a special value indicating the end. An iterator with this value is returned by the `.end()` method (or `.rend()` when iterating in reverse).

### The auto Type

Modern C++ also offers the special `auto` type, which relieves the programmer from having to explicitly define the type of a variable to which a value is being assigned. For example, you can write `auto x = 5;`, but you cannot write `auto x; x = 5;`. This type is useful for handling iterators, allowing the above loop to be written without `std::list<int>::iterator` as:

```cpp
void printList(std::list<int> l) {
    for (auto i = l.begin(); i != l.end(); ++i) {
        std::cout << *i << "\n";
    }
}
```

### for (each) Loop

C++ also provides an alternative `for` loop syntax for iterating over all elements in collections such as lists, maps, etc., similar to the *foreach* loop in some programming languages or the Python *for* loop:


```cpp
void printList(std::list<int> l) {
    for (auto i : l) {
        std::cout << i << "\n";
    }
}
```

Instead of `auto i`, you can write `auto& i` to access by reference (in this case, assigning a value to i, such as `i = 0`, will modify the element of the list).

It’s worth noting that unlike the previous loop, this one does not operate on iterators, but on the values or references to values from the container.

### Templates

C++ also allows defining function and class templates, which enable the compiler to generate functions/classes for the necessary types based on a general template. For example, the above function that prints lists is defined only for lists containing integers. However, functions for other types, such as floating-point numbers or strings (as long as they support the << operator used with cout), would look the same. Using the template mechanism, we can write:

```cpp
template <typename T> void printList(std::list<T>& l) {
    for (auto i : l) {
        std::cout << i << "\n";
    }
}
```

And then use it for different types of lists:

```cpp
int main() {
    std::list<int> x={1, 3, 7, 2, 3};
    printList(x);
    
    std::list<float> z={2.7, 5.0, 3.1, 3.9};
    printList(z);
}
```

### lambda

```cpp
#include <iostream>

int main() {
    int x = 1, y = 1;

    // this lambda will use:
    // the value of x at the time of invocation (and its changes will be visible outside)
    // the value of y at the time of creation
    auto my_lambda = [&x, y](int z) { x += z * y; return 11; };

    my_lambda(2);
    std::cout << x << std::endl; // 3 because x = 1 + 2 * 1

    x = 0;
    y = 0;

    int z = my_lambda(2);
    std::cout << x << " " << z << std::endl; // 2 because x = 0 + 2 * 1
}
```

C++ also allows defining and using lambdas. A lambda consists of a capture list, an argument list, and a function body. The capture list specifies whether variables are captured by value or by reference. In the first case, the variable’s value at the time of lambda creation is “frozen” and further changes are not visible in lambda invocations. In the second case, the lambda always sees the current value, and changes made within the lambda are also visible outside. The argument list and function body work like in regular functions. A lambda may or may not return a value using return.
