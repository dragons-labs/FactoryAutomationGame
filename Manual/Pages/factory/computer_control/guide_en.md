<!--
SPDX-FileCopyrightText: Robert Ryszard Paciorek <rrp@opcode.eu.org>
SPDX-License-Identifier: MIT

AI tools (chat GPT) have been used for text translation and editing.
-->

# Computer Control

The "Computer Control" block allows the creation of computer programs controlling the factory. The placement of this block does not matter. Typically, there will be only one such block (and only the first block will have a connection to the factory), but some factories may have more.

Factory control is possible through:
* Reading input signal values by reading the contents of files in `/dev/factory_control/inputs`
* Setting output signal values by writing values to files in `/dev/factory_control/outputs`

**Note:** The number written/read from these files corresponds to voltage (not logical state), as the factory operates with 3.3 V logic. Therefore, to set a high output state, you need to write `3` to the file, not `1`.
