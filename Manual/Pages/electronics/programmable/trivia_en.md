<!--
SPDX-FileCopyrightText: Robert Ryszard Paciorek <rrp@opcode.eu.org>
SPDX-License-Identifier: MIT

AI tools (chat GPT) have been used for text translation and editing.
-->

Programmable Systems
--------------------

## Programmable Logic

[img]Manual/Pages/electronics/programmable/memory_logic_en.svg[/img]

Programmable logic circuits are based on the concept that inside such a system, we program a set of logic gates, flip-flops, and similar components, as well as their connections.

Languages like HDL (Hardware Description Language) are used to program these types of systems. The most commonly used languages are VHDL or Verilog. Instead of executing code, these languages describe the structure of the logic circuit (connections of gates, truth tables, etc.), which is then programmed into a physical chip. This allows for programming an algorithm that will be implemented purely in hardware. Such hardware implementation, due to the parallelization of many processes, is generally much faster than a software version.

The simplest conceptual way to implement something like this is through a memory-based system, which allows for realizing any logical function, i.e., any set of gates. If we take a memory that has 2ⁿ bits and is addressed by an n-bit address bus, each address corresponds to one bit, and each bit corresponds to one address. This type of memory allows storing the truth table of any function that has n inputs and one output—each input corresponds to one bit of the address, and the output value corresponding to a given combination of inputs is stored in this memory.

Such systems have substantial practical applications and allow for constructing circuits that operate faster than processor-based systems. The use of programmable logic systems is simpler and faster than constructing such solutions from individual components like gates, and for small and medium-scale production, it is also cheaper than designing and producing dedicated integrated circuits. It also allows for updating such "hardware" by programming an improved version of it.

This category includes systems like:

* SPLD
  * PLE - programmable OR gate array
  * PAL and GAL - programmable AND array with additional OR gates (often also surrounded by registers and multiplexers at the outputs)
  * PLA - programmable AND and OR arrays
* CPLD
* FPGA - programmable memory element (possibility to define any - typically 4-input - function in each logic element, programmable connections between logic elements and pins, etc.)
