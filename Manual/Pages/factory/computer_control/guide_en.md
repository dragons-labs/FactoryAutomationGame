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

The value from `/dev/factory_control/time` allows you to use time consistent with the factory's running speed (it is counted from the factory's startup, takes into account the game speed and pausing). When the factory is not running it has a negative value.

**Note:** The number written/read from these files corresponds to voltage (not logical state), as the factory operates with 3.3 V logic. Therefore, to set a high output state, you need to write `3` to the file, not `1`.


## Python library

To facilitate factory control in the system, the Python library `factory_control` is available, for details please use the built-in documentation:

```Python
import factory_control
help(factory_control)
```
