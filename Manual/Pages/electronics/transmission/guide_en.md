<!--
SPDX-FileCopyrightText: Robert Ryszard Paciorek <rrp@opcode.eu.org>
SPDX-License-Identifier: MIT

Document translated automatically using AI (chat GPT). Required verification of correctness.
-->

# Transmission - Line Control

## Buffers

A buffer is a system that transmits a logical signal from input to output. A buffer can serve to:

* regenerate the signal,
* prevent the signal from being fed from the output back to the input,
* decide whether to pass the signal or not (tri-state),
* decide the direction of signal transmission (two tri-state or bi-directional tri-state),
* convert to open-collector / open-drain line,
* negate the signal (some buffers perform a NOT function).

## Encoders

An "n to m" encoder is a system with n inputs that outputs an m-bit number, typically representing the number of the highest active (low) input. Variants may output the first (rather than the last) active input or select the input with a high state.

Since inputs are usually numbered from zero to 2m, the system often includes an additional output to indicate if any input is active. Typically, the output number is in binary, but other encodings are possible.

The system reduces the number of inputs needed to handle an n-bit signal where only one bit can be set or where it's permissible to handle subsequent lines by clearing their bits (e.g., interrupt vectors with prioritization).

## Decoders

A "m to n" decoder is the opposite of an encoder. It activates the output corresponding to the number on its m-bit address input. Typically, it also has an enable input for output activation, which can be used to connect the information from the encoder indicating that any of the inputs was active or to connect a data signal from a multiplexed line for demultiplexing.

## Digital (De)Multiplexers

A digital multiplexer (unidirectional) copies the state of the input selected by the address provided on the address input to the output. In the absence of an enable signal, the output either remains in a low state or high impedance, depending on the design.

A digital demultiplexer (unidirectional) is typically a decoder where the enable input receives a signal from the multiplexed line. Unselected outputs remain low or high (depending on whether an inverting or non-inverting decoder is used). Tri-state digital demultiplexers are rare. Demultiplexing can also be implemented using appropriately controlled (e.g., address decoder) tri-state buffers or two-input multiplexers.

## Analog (De)Multiplexers

An analog multiplexer (bi-directional) acts as a switch connecting the selected input to the output, creating an electrical "short" (usually with a resistance of tens of ohms) that allows transmission in both directions. This enables the same system to function as both a multiplexer and a demultiplexer.

