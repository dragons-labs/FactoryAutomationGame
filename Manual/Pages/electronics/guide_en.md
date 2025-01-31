<!--
SPDX-FileCopyrightText: Robert Ryszard Paciorek <rrp@opcode.eu.org>
SPDX-License-Identifier: MIT

AI tools (chat GPT) have been used for text translation and editing.
-->

Electronics
===========

Building electronic circuits allows the processing of signals in the form of electrical currents and voltages. This enables the creation of various control systems, systems for transmitting information, or processing it.

## Basic Concepts

### Electrical Voltage

Electrical voltage *U* between points A and B (of a circuit) is the difference in electric potential at point A and point B. The sign of the voltage depends on the direction in which we traverse the electric circuit.

#### Electric Potential

Potential is the level of energy at a given point in the circuit relative to some reference (usually ground). In practice, potential indicates how much energy an electric charge has at that point.

#### Ground

Ground (marked as GND) is a conventional zero potential, relative to which other potentials in the system are expressed (which allows them to be treated as potential differences - electrical voltages). This potential may be equal to the earth's potential (protective ground, PE) or may not be related to it (in isolated systems).

There are also circuits where more than one ground is distinguished, and (more rarely) circuits where no potential is distinguished.

### Electric Current

The phenomenon of current is associated with the flow of charge (with the orderly movement of charge carriers). To occur, a potential difference (voltage) between the ends of the conductor is necessary.

#### Value of Electric Current

The current (intensity) *I* is the amount of charge that flows per unit of time. It defines the intensity of the charge flow. The conventional direction of current flow is assumed (regardless of the actual direction of flow of charge carriers) from higher to lower potential.


## Electric Circuits

An electric circuit consists of electrical components and the nodes that connect them. The graphical representation of an (model of) electrical circuit is its schematic.

### Fundamental Laws

#### Kirchhoff's First Law

A node in the system (by itself, neglecting parasitic phenomena) cannot accumulate electric charge, so:
	*The sum of currents flowing into the node equals the sum of currents flowing out of the node.*

#### Kirchhoff's Second Law

If we consider a closed circuit from point A with potential *V(A)*, summing the voltages across the circuit elements (resistances, voltage sources, etc.), considering their signs, when we return to point A, the potential must still be *V(A)*, thus:
	*The sum of voltage drops in a closed circuit equals zero.*

#### Current and Voltage Relationship

There is (characteristic for a given element) a relationship between the voltage across its terminals and the flowing current.

For a significant group of materials, it takes the form:
	*The electric current flowing between two points is directly proportional to the voltage between these points.* (**Ohm's Law**)
However, in many other cases, this relationship may take a different form.

### Schematic Conventions

There is no official standard that dictates how to draw electronic or electrical schematics and the symbols used in them. These are commonly accepted practices. It also happens that the same component has several different graphic representations.

Typically, electronics engineers do not draw voltage sources on schematics (e.g., as a battery symbol – unless emphasizing that the power supply is indeed from a battery or accumulator). Instead, they place markers for supply potentials (e.g., +5V, +3V3, Vcc, Vbus) relative to ground and ground markers (GND, ⏚).

Typically, higher potentials are placed higher on the schematic, and lower potentials lower (so 5V would be at the top, and GND at the bottom), and current flows from left to right and from top to bottom. This is a general rule that makes reading schematics easier; however, it is not absolute, and there are exceptions dictated by the need to improve the schematic’s readability. 

## Variability Over Time

The value of voltage or current generated by a given source can be constant (**DC**) or variable over time (**AC**).

It is important to note that even in DC circuits, during power-up, there is a transient state before the system reaches a steady state. During this time, currents and voltages in the circuits may surge rapidly and then stabilize at nominal values. This is crucial for circuits with capacitors and inductors, which behave differently in the steady state compared to the moment of power-up. Transient and steady states can also be discussed in the context of alternating current (AC) – in the steady state, parameters change cyclically, in line with the signal frequency.

### Power vs. Signal

The terms DC and AC are often used in the context of power supply, where they refer to either constant voltage/current supply or sinusoidal alternating voltage/current. Variable signals are those that change cyclically over time (e.g., a typical audio signal). Pulse signals are a form of variable signals, characterized by brief changes in value (e.g., square waves or narrow pulses), commonly used in digital logic and control systems.
