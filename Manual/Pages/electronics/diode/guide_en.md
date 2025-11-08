<!--
SPDX-FileCopyrightText: Robert Ryszard Paciorek <rrp@opcode.eu.org>
SPDX-License-Identifier: MIT

Document translated automatically using AI (chat GPT). Required verification of correctness.
-->

# Diode

[img]Manual/Pages/electronics/diode/diodes_en.svg[/img]

An ideal diode is a component that conducts current only in one direction. Symbols of the most popular types of diodes are shown alongside. A diode is a nonlinear element – the voltage drop across a conducting diode does not follow Ohm's law and is almost constant (independent of the current).

Real diodes conduct current much more readily in one direction than in the other (conduction in the reverse direction is usually neglected), and they exhibit characteristics dependent on their manufacturing technology, such as:

* Forward voltage drop (typically 0.6V - 0.7V for silicon diodes, and 0.3V for Schottky diodes)
* Breakdown voltage - the voltage that, when applied in reverse, causes significant conduction in this direction - in most cases, a parameter that should not be exceeded, but is used (and forms a specification) in certain types of diodes
* Maximum forward current
* Switching time (mainly related to parasitic junction capacitance) – significantly shorter (about 100 ps) in Schottky diodes than in silicon diodes.

Other types of diodes include:

* Zener diodes - utilizing the breakdown voltage (specific to the type) to achieve a voltage drop of this value in a circuit,
* Light-emitting diodes (LEDs) - emitting light when conducting current (there is a constant voltage drop across the component, and brightness depends on current intensity),
* Photodiodes - functioning as light detectors (reverse-biased conduction depends on the amount of light hitting the element, and an unbiased diode generates current under illumination).

## Resistor with LEDs

A diode is a component for which Ohm's law does not apply. It has an almost constant forward voltage drop.

Therefore, if a voltage higher than the diode's forward voltage is applied (e.g., applying 5V to a red LED with a drop of about 1.7V), a very large current will flow through the circuit (often equal to the short-circuit current of the source), leading to diode destruction.

For this reason, LEDs are almost always connected with a series resistor to limit the current (the exception being diodes powered by a current source). In other types of diodes, the current must also be limited somehow – for example, in rectifiers, the load plays the role of this resistor.

## Rectifier

A rectifier converts alternating voltage (changing polarity) into alternating voltage with a constant polarity. This function can be performed by a single diode – this is a half-wave rectifier, characterized by a voltage drop to zero for half of the cycle.

A better and more commonly used solution is a full-wave rectifier. The most common implementation is the Graetz bridge, a circuit of four diodes arranged so that two diodes always conduct (at any point in the input voltage). The downside of this setup is the significant voltage drop across the bridge, which equals twice the voltage drop of a single diode.

## Zener Diode Voltage Divider

In chapter \ref{divider}, we discussed a resistive voltage divider made up of two resistors. The drawback of such a system was the significant dependence of the output voltage on the load. This issue can be mitigated by replacing one of the resistors (the one connected in parallel with the load) with a reverse-biased Zener diode, which has a relatively constant voltage drop. See the simulation at \url{http://ln.opcode.eu.org/zener}, note that this is still not a perfect solution, but it is much more stable than the previous one.
