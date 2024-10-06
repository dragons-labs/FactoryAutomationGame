<!--
SPDX-FileCopyrightText: Robert Ryszard Paciorek <rrp@opcode.eu.org>
SPDX-License-Identifier: MIT

AI tools (chat GPT) have been used for text translation and editing.
-->

# Producer

The "Producer" block creates objects that are processed by the factory into a final product according to the specification.

Creating an object takes some time, but some production lines may work more slowly, so controlling the release moment of the object may be necessary to avoid bottlenecks on the production line.

#### Input signals:

* `producer_control_enabled` - a high state (> 2V) disables automatic release of the ready object and causes waiting for the `producer_release_object` signal to release it.
* `producer_release_object` - a high state (> 2V) causes the object to be released and the preparation of the next one to begin.

#### Output signals:

* `producer_object_ready` - a high state (3.3V) indicates that the object is ready for release.
