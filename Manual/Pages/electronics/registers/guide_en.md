<!--
SPDX-FileCopyrightText: Robert Ryszard Paciorek <rrp@opcode.eu.org>
SPDX-License-Identifier: MIT

Document translated automatically using AI (chat GPT). Required verification of correctness.
-->

# Flip-flops and Registers

## Flip-flops and their Construction

The RS Flip-flop (RS Latch) is the basic circuit used for storing a single bit of information. It has two inputs (set and reset) and two outputs (Q and NOT Q). The inputs can react to a high state (marked as S and R) or a low state (marked as negated inputs S and R). One of the outputs may be internal only (not brought outside the circuit). Applying a high state to the S input (low state to S) results in a high state at the Q output, and applying a high state to the R input (low state to R) results in a low state at the Q output. The state at the Q output does not change when the S and R inputs are changed to the low state (it is remembered).

## Latch vs Flip-flop

A latch is an element that reacts to the signal level at the "enable" (E) input. In the case of a non-negated E input, when it is in the high state, the output signals (Q and NOT Q) are a function of the input signals, while the low state of the E input blocks changes in the output signal (it is remembered).

A flip-flop is an element that reacts to the edge of the signal at the "clock" (CLK) input. Depending on the design, it can react to the rising edge, the falling edge, or both (reading inputs on one edge and changing outputs on the other).

## D Latch and Flip-flop

It has one data input "data" (D) and an "enable" (E) input in the case of a latch or a "clock" (CLK) input in the case of a flip-flop. It may also have asynchronous (independent of the E/CLK input) reset and set inputs (negated or direct). Lowering the E signal or an edge of the CLK signal causes the current D input state to be remembered (and output at Q).

## Registers

An n-bit register is a set of n flip-flops (or less commonly latches), often with shared control signals (clock, set, reset, etc.), used to store an n-bit value (number). Depending on the method of writing and reading, the following types can be distinguished:

### Parallel Registers

They have the same number of inputs as outputs, with the signal at the i-th output being directly related to the signal from the i-th input (the signal remembered from that input).

### Serial-input Registers

With each clock signal, the state of the serial input is read, and the previous state is transferred to the next flip-flop within the register. This way, after n clock cycles, the n-bit register has stored new content. It often has a parallel register attached to prevent changes to the outputs while loading data from the serial input. Transferring data from the shift register to the register responsible for controlling the outputs is managed by a separate clock signal.

### Parallel-input Serial-output Registers

With each clock signal, the state of the next input register is output to the serial output. The asynchronous variant has a separate signal that causes the inputs to be read into the register (this signal works like "enable" in latches). The synchronous variant has a signal that decides whether the inputs are read at the clock edge or if the register content is shifted, allowing for reading from the serial output.

### Counters

With each clock signal, the register value is incremented by one. A simpler asynchronous counter has greater speed limitations (which increase with the bit-width of the counter) than a synchronous counter, due to the delay with which the counted signal (CLK) reaches subsequent stages of the counter.
