<!--
SPDX-FileCopyrightText: Robert Ryszard Paciorek <rrp@opcode.eu.org>
SPDX-License-Identifier: MIT

AI tools (chat GPT) have been used for text translation and editing.
-->

# Gates

[img]Manual/Pages/electronics/digital_gates/gates_pl.svg[/img]

Gates are electronic circuits that implement basic logical functions. The adjacent diagram shows basic symbols of individual gates in a two-input variant, although symbols with negated inputs can also be encountered—for example, an AND gate can be represented by a NOR gate with negated inputs. Gates (except buffers and the NOT gate) can also appear in multi-input variants. Due to the associativity of basic operations, there is no ambiguity regarding the result of, for example, an 8-input OR gate. Typically, several identical gates are found within a single integrated circuit.

## Tri-state

A typical gate forces a high or low state (strongly) on its output, which prevents direct connection of gate outputs. Tri-state gates can configure the output into a *high-impedance* state, meaning no value is enforced on the output. The control of whether the output is enabled or disabled (switching to high impedance) is managed by an external "output enabled" ("OE") control signal, which may appear in both its positive and negated forms. This allows multiple gates to be connected to a single line, and which one controls the line is determined by the state of the OE signal.

## Open collector / drain

This is another type of gate whose outputs can be connected to a shared line. These circuits feature an output consisting of a transistor that shorts the output line to ground, meaning they can only provide a low output (they can enforce a low state but cannot enforce a high state).

The high state must be ensured by an external pull-up resistor. This setup allows using a different high-level state on the line than on the inputs to such a gate and enables multiple gates to control the shared line (i.e., connecting gate outputs without needing additional control signals, as is required with tri-state gates).

[img]Manual/Pages/electronics/digital_gates/open_drain.svg[/img]

The diagram to the right shows two open-drain circuits (U1 and U2) controlling a shared output line in a *wired-OR* configuration. If one of the circuits connected to the line has its internal output ("ctrl*{X*") in the high state, its OC output will be shorted to ground (negation via N-MOS or NPN transistor), causing the entire line to be in the low state.
