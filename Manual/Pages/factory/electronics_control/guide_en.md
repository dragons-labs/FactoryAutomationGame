<!--
SPDX-FileCopyrightText: Robert Ryszard Paciorek <rrp@opcode.eu.org>
SPDX-License-Identifier: MIT

Document translated automatically using AI (chat GPT). Required verification of correctness.
-->

# Electronic Control

The "Electronic Control" block allows the creation of an electronic circuit schematic controlling the factory. The factory can contain only one such block, and the placement of this block does not matter.

The created circuit should include elements like "Net Connector," which represent connections allowing communication between the electronic circuit and the factory. Adding and removing blocks from the factory will affect the available/supported connections—the full list can be checked in the dropdown menu for selecting connection names. You can use custom names (the "custom" option) to create internal connections within the electrical schematic (instead of/in addition to drawing lines).

Connections represent three types of signals:

* Power supply voltages, such as Vcc, 5V, GND (ground also has its own connection symbol: ⏚)
* Input signals (marked as ```@in```) provide information about the factory's state to the electronic circuit. They are low impedance (in the miliohms). They should not be connected to each other or to power lines.
* Output signals (marked as ```@out```) are used to control factory elements by providing the appropriate voltage value. They are high impedance (in the gigaohms).

The names of input and output signals are prefixed with the block name from which they originate (if it's not empty).
