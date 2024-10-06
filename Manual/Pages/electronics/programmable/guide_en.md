<!--
SPDX-FileCopyrightText: Robert Ryszard Paciorek <rrp@opcode.eu.org>
SPDX-License-Identifier: MIT

AI tools (chat GPT) have been used for text translation and editing.
-->

Programmable Systems
--------------------

Programmable systems can be divided into two basic groups: systems with programmable logic structures and processor-based systems.

## Processor-based Systems

[img=1000%]Manual/Pages/electronics/programmable/cpu_en.svg[/img]

Processor-based systems are systems that execute a series of instructions fetched from memory. They consist of a processor, program memory, and data memory. The processor is responsible for interpreting and executing successive instructions, while memory stores both instructions and data. Depending on the architecture used, program code, or rather machine code generated from compiling the program code, can either be stored in the same memory as the data or in a separate, dedicated memory.

Processor-based systems include computer systems such as PCs or laptops, mobile phones (both smartphones and simpler phones), large computing systems, and various microcontrollers found in industrial controllers, alarm systems, televisions, household appliances, and so on.

The processor operates in instruction cycles, during which it processes a single instruction. Such a cycle can take from 1 to several or more clock cycles and typically consists of the following steps:

1. **Instruction fetch** – The processor places the contents of the *program counter* (containing the address of the next instruction to be executed) onto the address bus and generates a memory read cycle. After reading the data, it is stored in the *instruction register*, and the *program counter* is incremented by one. (The value in the *program counter* after a processor reset determines where the first instruction will be fetched from, typically this will be a ROM or flash memory).
2. **Instruction decoding** – The decoder unit (e.g., based on PLA) decodes the instruction stored in the *instruction register* and configures the processor according to its code and (optionally) its arguments. This might involve:
   - Setting up the multiplexers between registers and the ALU, and providing the appropriate operation code to the ALU (to perform arithmetic operations on register values).
   - Placing the contents of a specified register onto the address bus, connecting a specific register to the data bus, and configuring the read/write operation (to read or write the register value from/to memory).
3. **Instruction execution** – Carrying out the previously decoded instruction according to the processor's configuration.

Jump instructions involve loading a new value into the *program counter*, and conditional jumps depend on the state of the *flags register*, which is set based on the result of the last operation performed by the ALU.

A simplified model of processor operation might look like this: The processor places the contents of the so-called program counter on the address bus, which allows access to memory. This address corresponds to the instruction that will be fetched and executed. After the address is placed on the bus, a read cycle is generated, and the fetched instruction is stored in the instruction register. The program counter is then incremented by 1 to fetch the next instruction in the subsequent cycle.

The next step is instruction decoding – the decoder unit in the processor decodes the instruction stored in the aforementioned register and configures the processor according to its code and (optionally) arguments. This configuration might involve setting appropriate multiplexers, that is, electronic switches between registers and the ALU (the arithmetic-logic unit), issuing the appropriate operation code for the ALU (to perform an operation, for example, on the contents of specific registers), or connecting a specified register to the data bus (to communicate with memory – either to perform a read or write operation, or to load its value into the program counter for a jump), and so on. The final step in the cycle is executing these operations, i.e., carrying out the previously decoded instruction according to the processor's configuration.

The presented model of operation is simplified, and in a real processor, it may look different – for example, the instruction length may be greater than the word size used by the processor/data bus width, which extends the instruction fetch phase from memory (the instruction will be loaded in several phases because the entire instruction does not fit on the data bus at once). There may also be more complex instructions (e.g., operations performed with an argument fetched from memory rather than a register), and there may be more phases (e.g., access to memory and writing the instruction result).

The processor may also work in a pipelined fashion, meaning that phases can overlap – while one instruction is being executed, another can already be decoded. Of course, the processor must make certain assumptions about conditional jumps – for example, it may decode the instruction following a conditional jump as if the jump would not occur. If the jump does occur, the decoded instruction is invalidated, the pipeline is refilled, and the acceleration associated with pipelining is not realized. Pipelined operation underpins the so-called Hyper-Threading feature available in some processors, but as we've seen, pipelining is not equivalent to having more independent cores.

The bus between the processor and memory is often a parallel bus, which may also host other I/O devices available at different addresses. In some designs, these devices have separate address spaces, while in others, they share the same space with memory.

### Microcontrollers

An example of a microprocessor system, which is also an example of a system on chip, are microcontrollers. In a single integrated circuit, they contain a processor, RAM, flash memory for storing program code (in their case, the code is not loaded into RAM but executed directly from flash memory). Very often, these systems also include various input-output circuits, such as GPIO ports, which allow setting or reading the state of a particular pin on the chip. They may also include more advanced interfaces like USART, I2C, SPI serial ports. Other possibilities are analog-to-digital converters (allowing the measurement of some voltage – analog signal) and digital-to-analog converters (allowing the output of a voltage of a specific value).

