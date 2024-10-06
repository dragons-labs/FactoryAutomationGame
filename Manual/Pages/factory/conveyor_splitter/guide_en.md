<!--
SPDX-FileCopyrightText: Robert Ryszard Paciorek <rrp@opcode.eu.org>
SPDX-License-Identifier: MIT

AI tools (chat GPT) have been used for text translation and editing.
-->

# Conveyor Splitter

Allows splitting the conveyor belt and directing objects to other belts (right, left, straight).

#### Input signals:

* `splitter_redirect_forward` - a high state (> 2V) causes the object to be redirected forward.
* `splitter_redirect_to_left` - a high state (> 2V) causes the object to be redirected to the left.
* `splitter_redirect_to_right` - a high state (> 2V) causes the object to be redirected to the right.

Inputs have priority, meaning that applying a high state to more than one input will not cause a failure. Instead, it will act as if only the first input (in the order above) that received a high state was activated.

#### Output signals:

* `splitter_object_inside` - a high state (3.3V) indicates that an object is inside the block's action area, and (if none of the inputs is in a high state) it has been stopped.

