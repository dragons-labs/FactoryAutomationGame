<!--
SPDX-FileCopyrightText: Robert Ryszard Paciorek <rrp@opcode.eu.org>
SPDX-License-Identifier: MIT

Document translated automatically using AI (chat GPT). Required verification of correctness.
-->

Passive Elements
================

Real Components
---------------

### Resistor

A real resistor, in addition to its electrical resistance value, is characterized by other parameters, including:

* maximum power that can be dissipated in the component,
* accuracy, which indicates how far the resistance of a component can deviate from its nominal value,
* stability of resistance as a function of temperature and the voltage applied to the component.

### Contacts

Even contacts have their parameters, the main ones include:

* current carrying capacity
* resistance of the closed contact
* mechanical durability (number of operating cycles)

In some cases (especially in automation), within groups of contacts activated by the same mechanical factor, leading (activating before the others) and delayed (acting last) contacts are distinguished and marked with modified symbols.

In power engineering, the ability to interrupt operational and short-circuit currents by a given contact is also noted.

### Capacitor

The most significant parameter of real capacitors, aside from nominal capacitance, is the maximum voltage at which they can operate. Other important parameters may include internal resistance, maximum operating temperature, lifespan of the component, etc.

### Inductor

The main (but not the only) parameter of a real inductor, aside from inductance, is the maximum current it can carry.

### Relays and Contactors

Real relays and contactors are characterized by parameters such as:
- current conduction
- power consumed by the coil
- coil voltage and operation on direct or alternating current

It should be noted that relays and contactors are fundamentally the same type of device; however, a distinction is made in terminology—relays switch smaller currents than contactors.

### Transformers

The most common use of transformers is to step up and step down voltage in power engineering. For example, in power plants, we have step-up transformers because the generators typically operate at a voltage of several kilovolts (e.g., 6 kV), while transmission networks operate at several hundred kilovolts (e.g., 220 kV). As we get closer to the electricity consumer, there are additional transformers, this time stepping down the voltage first to several kilovolts and then to 230 volts, which is what we have in our homes. This voltage step-up helps reduce transmission losses and allows for smaller wire diameters.

Additionally, transformers can serve to provide galvanic isolation between circuits, meaning they separate the primary circuit from the secondary circuit in such a way that current cannot flow directly between them. This can even be done while operating at the same voltage, meaning there are transformers with a one-to-one turn ratio that are also used.

Such separation is based on the principle that if we do not somehow short one terminal of the primary side to one terminal of the secondary side, the output voltage (which is between the terminals of the secondary side) has no reference to the voltages of the primary side. It can be observed that these voltages fluctuate with respect to each other.

Typically, this connection between the primary and secondary sides is made by grounding one of the terminals on each side. In the case of electrical networks that use three-phase current, the neutral point of the transformer is typically connected to the ground potential. As a result, in most of our household outlets, we have a neutral wire (connected to the ground potential) and a phase wire (which has voltage with respect to the ground). Therefore, if we want the voltages behind the transformer to relate to the ground potential, we also ground one of the terminals; if we want the transformer to provide isolation, we do not do this. The first approach is used in most (correctly powered) desktop computers, while the second is common in many laptops.

DC vs. AC Circuits
------------------

Capacitance and inductance introduced into a circuit matter only when there is a change in the current flowing through the circuit or a change in the voltages across its components. In a steady-state DC circuit, capacitance and inductance do not play a role, because:

* Capacitors have already accumulated charge (appropriate to the applied voltage) and do not draw current from the circuit,
* Inductors have generated a magnetic field (appropriate to the current passing through them) and do not present resistance to the current flow.

In such cases, capacitors can be treated as open circuits, and inductors as short circuits. This concept is also linked to one common use of capacitors—filtering out DC components. This is due to the fact that a capacitor acts as an open circuit for DC current but conducts AC current (due to charging and discharging).

* **Impedance** – is a quantity that describes the relationship between current and voltage, considering the circuit’s reactance. *Z = R+jX*
* **Reactance** – is a measure of passive resistance in capacitive (*X = −1ωC*) and inductive (*X = ωL*) elements.
* **Angular frequency** (*ω*) – characterizes the rate of change (it is proportional to the inverse of the period of the change). *ω = 2πT*
