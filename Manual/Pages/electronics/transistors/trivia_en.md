<!--
SPDX-FileCopyrightText: Robert Ryszard Paciorek <rrp@opcode.eu.org>
SPDX-License-Identifier: MIT

Document translated automatically using AI (chat GPT). Required verification of correctness.
-->

# Transistors

## Amplifier

When discussing different types of transistors, we focused on their role as switches, operating in two states – conduction (saturation) and cutoff.
However, since a transistor is an element with controllable conduction, it can also be used for signal amplification, meaning producing an output signal proportional to the input signal but amplified.
The amplified signal can be either voltage or current (the simplest case being base current amplification as collector current *I(C) = β · I(B)* in a bipolar transistor).

[img]Manual/Pages/electronics/transistors/opamp.svg[/img]

Often, instead of a single transistor, we use integrated circuits (composed of many transistors) called operational amplifiers to amplify the signal.
They are characterized by very high amplification of the voltage difference between their inputs, and the desired amplification is obtained by selecting external components of the negative feedback loop
  (in the simplest case, the input signal is applied to one input, and a properly scaled output signal via a resistive divider is applied to the other input).

## AC Switching

Transistors are widely used for switching in DC circuits. There are also semiconductor elements capable of switching in AC circuits – primarily, these are triacs.
