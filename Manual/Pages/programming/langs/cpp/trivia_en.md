<!--
SPDX-FileCopyrightText: Robert Ryszard Paciorek <rrp@opcode.eu.org>
SPDX-License-Identifier: MIT

AI tools (chat GPT) have been used for text translation and editing.
-->

Basics of C++ Programming
=========================

## References

References are essentially pointers that we use like regular variables (without applying the `*` operator to work with the pointer value). Unlike pointers, we cannot directly manipulate the address of a reference (e.g., make it point to another variable). Continuing the example of modifying a variable passed as a function argument, using references, the code might look like this:

```cpp
void ff(int& a) { // note the & indicating this will be a reference
    a = 15;
}
int main() {
    x = 10;
    ff(x);
    printf("%d\n", x); // will print 15
}
```
