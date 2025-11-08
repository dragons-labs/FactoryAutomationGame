<!--
SPDX-FileCopyrightText: Robert Ryszard Paciorek <rrp@opcode.eu.org>
SPDX-License-Identifier: MIT

Document translated automatically using AI (chat GPT). Required verification of correctness.
-->

# Introduction to Digital Electronics

The digital nature of electronics lies in the representation of signals as abstract numerical values instead of direct electrical values.

These numbers are typically written in binary form. A voltage below a certain value corresponds to a zero in a given digit, while above a certain level, it corresponds to a one. Successive digits represent voltages at various points in the circuit (“on successive wires”) or in a single wire at successive time intervals.

This allows, among other things, to increase noise resistance and replicate such digital information losslessly.

## Boolean Algebra

### Basic Operations and Neutral Elements

* Logical sum (OR, +, |, ||):
    * a OR 1 = 1
    * a OR 0 = a
    * a OR a = a
* Logical product (AND, *, &, &&)
    * a AND 1 = a
    * a AND 0 = 0
    * a AND a = a
* Negation (NOT, ~, ^, !)
    * NOT 1 = 0
    * NOT 0 = 1
    * NOT (NOT a) = a

### Properties of Operations

* Associativity:
    * (a OR b) OR c = a OR (b OR c)
    * (a AND b) AND c = a AND (b AND c)
* Commutativity:
    * a OR b = b OR a
    * a AND b = b AND a
* Distributivity:
    * a AND (b OR c) = (a AND b) OR (a AND c)
    * a OR (b AND c) = (a OR b) AND (a OR c)
* Absorption:
    * a AND (b OR a) = a
    * a OR (b AND a) = a
* De Morgan's laws:
    * NOT (a OR b) = (NOT a) AND (NOT b)
    * NOT (a AND b) = (NOT a) OR (NOT b)
* Complementarity:
    * a OR (NOT a) = 1
    * a AND (NOT a) = 0

### Additional Operations

* Exclusive OR (XOR):
    * a XOR b = (a AND (NOT b)) OR (b AND (NOT a))
    * a XOR 0 = a
    * a XOR a = 0
* a NAND b = NOT (a AND b)
    * (a NAND b) NAND (c NAND d) <!--= NOT( (NOT(a AND b)) AND (NOT(c AND d)) ) = NOT(NOT( (a AND b) OR (c AND d) ))--> = (a AND b) OR (c AND d)
* a NOR b = NOT (a OR b)
    * (a NOR b) NOR (c NOR d) <!--= NOT( (NOT(a OR b)) OR (NOT(c OR d)) ) = NOT(NOT( (a OR b) AND (c OR d) ))--> = (a OR b) AND (c OR d)
* a XNOR b = NOT (a XOR b)

## Binary System

### Number Representation

A single digit of the binary system (which takes the value of 0 or 1) is called a **bit**, and numbers are represented as sequences of such digits. The term **byte** usually refers to a sequence of 8 bits (though in some systems, it may have a different length).

The basic method for writing non-negative integers in binary is the **Natural Binary Code** (**NBC**), where, for example, a 4-bit sequence `a₃ a₂ a₁ a₀` represents the number *2⁰ · a₀ + 2¹ · a₁ + 2² · a₂ + 2³ · a₃*.

The basic method for writing integers (with a sign) is the **two’s complement** (**U2**) in which an n-bit number represented by the sequence `aₙ₋₁ ... a₃ a₂ a₁ a₀` has the value *2⁰ · a₀ + 2¹ · a₁ + 2² · a₂ + ... + 2ⁿ⁻² · aₙ₋₂ - 2ⁿ⁻¹ · aₙ₋₁*. Since the most significant bit has a negative weight, setting it to 1 indicates a negative number (though this is not a sign-and-magnitude code). Notice the compatibility with NBC.

Numbers written in these binary encodings are often denoted using the prefix "0b" or the suffix "b", e.g., `0b101 = 101b` represents the number 5 in decimal (*2⁰ · 1 + 2¹ · 0 + 2² · 1 = 5*).

In addition to these, there are several other ways to represent binary numbers, such as (for unsigned numbers): "1 out of n" code, Gray code, Johnson code, and (for signed numbers): sign-magnitude code, one's complement (U1). A different topic is floating-point number encoding.

### Hexadecimal (Hex) Notation

To shorten binary number representation, hexadecimal notation is often used. It is more convenient than decimal as each digit of the hexadecimal system maps to exactly 4 bits, allowing independent conversion of individual hexadecimal digits / 4-bit groups and combining them into longer sequences.

Digits with values above 9 are represented as consecutive lowercase or uppercase letters a, b, c, d, e, f. Numbers written in hexadecimal are denoted with the prefix "0x" or "#" or the suffix "h", e.g., `0xc7 = #c7 = c7h` represents the number 199 in decimal (*16⁰ · 7 + 16¹ · 12 = 199*). Conversion to binary can be done independently for each digit, as `0xc = 0b1100` and `0x7 = 0b0111`, so `0xc7 = 0b 1100 0111`.

### Electrical Representation

Typically, logical 1 corresponds to a high state (positive voltage), and logical 0 to a low state (ground potential). In the case of inverted (negative) logic, logical 1 corresponds to a low state, and logical 0 to a high state.
