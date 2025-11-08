<!--
SPDX-FileCopyrightText: Robert Ryszard Paciorek <rrp@opcode.eu.org>
SPDX-License-Identifier: MIT

Document translated automatically using AI (chat GPT). Required verification of correctness.
-->

# Gates

## Internal structure

[img]Manual/Pages/electronics/digital_gates/gates_cmos.svg[/img]

The wired-OR circuit presented above is a very simple (single-transistor) implementation of a logic gate that performs the NOT OR function (from the perspective of the *ctrl1* and *ctrl2* inputs and the *Out* output). Similarly, an AND gate can be implemented by negating the inputs (e.g., with a single transistor). An even simpler implementation can be achieved using diodes, allowing current to flow into the node (OR function) or out of the node (AND function).

On the right are schematic diagrams of an inverter, two basic gates (NOR and NAND), and a transmission gate (a tri-state buffer) in CMOS technology.

The operation of these gates (except for the transmission gate) involves opening transistors connected to the voltage we want to appear at the output and closing those leading to the opposite voltage. Specifically, the NOT gate forms a half-H bridge between the high and low states.

Thanks to the use of PMOS transistors polarized by Vdd and NMOS transistors polarized by GND, both branches operate on the same input signal (negation is not required). Serially connected transistors ensure that both must be open to enable a particular path, while parallel connections ensure that opening a path requires only one transistor to be open. Due to MOS technology and connecting gate inputs only to the gate terminals of transistors, inputs draw virtually no current (except during signal transitions).

The operation of the transmission gate involves either passing or not passing (depending on the control input state) the signal from input to output. Such a gate does not regenerate the signal. Additionally, in a simplified (single-transistor) solution, it causes signal degradation to approximately the threshold voltage of the transistor. Therefore, it is usually paired with a NOT gate (a tri-state buffer with inversion) or two serially connected NOT gates (a tri-state buffer without inversion).
