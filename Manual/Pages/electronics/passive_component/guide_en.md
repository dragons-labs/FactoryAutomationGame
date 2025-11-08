<!--
SPDX-FileCopyrightText: Robert Ryszard Paciorek <rrp@opcode.eu.org>
SPDX-License-Identifier: MIT

Document translated automatically using AI (chat GPT). Required verification of correctness.
-->


Passive Components
==================

## Resistor

For elements that comply with Ohm's Law, the ratio of the voltage between two points of a conductor to the current flowing between them is called resistance.

Such an element is a resistor. It introduces resistance into the circuit related to its nominal value. It is typically used to limit the current flowing through it or to achieve a voltage drop.

This is accompanied by energy dissipation (heat) due to resistance losses - the power dissipated is *P = U·I*. Using Ohm's law, we can see that with a constant voltage applied to the resistor, the higher its resistance, the less power is dissipated (as less current flows), but with a constant current flowing through the resistor, the power increases as resistance increases.

Resistor symbols: [img]Manual/Pages/electronics/passive_component/resistor-symbols.svg[/img]

### Voltage Divider

[img]Manual/Pages/electronics/passive_component/resistor-divider.svg[/img]

One of the simplest useful circuits consists of two resistors connected in series with a voltage source. This circuit is called a resistive voltage divider. It allows for obtaining a voltage lower than the source voltage in proportion to the resistors used. Note that the output voltage of such a system is highly dependent on the current drawn / the size of the connected load (you can use the switches placed in the simulated circuit for this purpose), which is why the resistive divider is mainly used when we know that the load will draw little current.

A resistive voltage divider is often used to proportionally divide (lower) an unknown (variable) input voltage (e.g., for its measurement, using a meter with a limited range), rather than to obtain an output voltage for powering other devices.

### Pull-up Resistor

[img]Manual/Pages/electronics/passive_component/resistor-pullup.svg[/img]

A resistor is also often used to enforce a default voltage level on a particular line. It is essentially a form of a divider where one of the resistors has been replaced with some type of switch, which depending on its state has either nearly zero or nearly infinite resistance.

This solution is mainly used on signal lines from which no significant current is drawn. As a result, in the circuit shown alongside, if the contact is open, no current flows, so the voltage drop across the resistor is zero and the output is the supply voltage. If the contact is closed, current flows, but due to the low resistance of the contact, almost the entire voltage drop occurs across the resistor, and the output is zero volts.

Such a setup allows, for example, the use of a simple contact instead of a switch and is very commonly used. Of course, we can swap the positions of the resistor and the switch, and then the default state (with an open contact) will be zero volts.

### Potentiometer

[img]Manual/Pages/electronics/passive_component/resistor-variable-symbols.svg[/img]

Adjustable resistors (potentiometers) have three terminals – between two of them there is a fixed nominal resistance, and the resistance to the middle terminal is adjustable, typically ranging from almost 0 to 100% of the nominal resistance.

## Contact

[img]Manual/Pages/electronics/passive_component/contacts-symbols.svg[/img]

A contact is a component used for mechanically connecting or disconnecting current. The switching factor may be manual action (switch pressed, turned, pulled, etc., by a human) or the action of an electromagnet (coil) – in which case it is an electromagnetic relay or contactor. There are:

* **Monostable** (momentary) contacts, which (after the switching factor ceases) automatically return to one of their positions:
    * non-conducting, in the case of contacts referred to as normally open (**NO**) / closing contacts
    * conducting, in the case of contacts referred to as normally closed (**NC**) / opening contacts
* **Switching** contacts (switching between two or more possible outputs),
    a special case of which are **bistable** contacts, which have two positions and remain in the selected position after switching.

It should be noted (especially in digital systems) that contacts tend to bounce – generally, when changing position, instead of generating a single pulse, they generate a whole series of pulses.

## Capacitor

A capacitor introduces capacitance into the circuit, corresponding to its nominal value. Capacitance expresses the ability of an element to store charge—the greater the capacitance, the more charge the element will store (with the same applied voltage).

A capacitor is typically used to limit voltage changes (by storing energy in the electric field) or to introduce a delay (time constant) associated with its charging/discharging. The time required for the voltage across the capacitor to change is given by the equation: *ΔT = C · ΔU / I*.

Capacitor symbols: [img]Manual/Pages/electronics/passive_component/capacitor-symbols.svg[/img]

## Inductor

An inductor (choke) introduces inductance into the circuit, corresponding to its nominal value. An inductor on its own is typically used to limit changes in current (by storing energy in the magnetic field). The time required for the current flowing through the inductor to change (an inductor resists such changes, just as a capacitor resists changes in voltage) is given by the equation: *ΔT = L · ΔI / U*.

Inductor symbols: [img]Manual/Pages/electronics/passive_component/inductor-symbols.svg[/img]

### Relays and Contactors

Coils are used in devices such as relays or contactors. Wound on an appropriate core, they act as electromagnets responsible for changing the physical position of contacts, leading to their connection or disconnection (switching).

### Transformers

Another device based on coils is the transformer. It uses multiple coils on a common core to transfer energy via a magnetic field (one coil, due to the flow of alternating current, creates a changing magnetic field, while another generates an alternating current due to this magnetic field). A transformer typically serves to change voltage or provide galvanic isolation of circuits. In the case of a two-winding transformer, the following applies: *U₁/U₂ = I₁/I₂ = n₁/n₂ = z*, where *z* is the transformer ratio, *n₁* is the number of primary winding turns (input), and *n₂* is the number of secondary winding turns (output).

### Disconnecting an Inductor

Since an inductor is an element that strives to maintain the current flowing through it, in the event of breaking the circuit containing the inductor, the voltage across it will rise and can easily exceed the supply voltage many times over. This phenomenon is useful in some circuits (e.g., step-up converters) but can often be undesirable and even very harmful—it can damage other components in the circuit (especially the switching element).

To counteract this phenomenon, a small resistance can be connected in parallel with the inductor, allowing it to discharge. The downside of this solution is the losses associated with conduction through this resistor when the inductor is powered. Note that the voltage appearing on the inductor has the opposite sign (direction) to the voltage drop across this element during operation. This allows the connection of an element in parallel with the inductor that conducts in only one direction, so that it does not conduct under normal conditions but allows the inductor to discharge after disconnecting the power.

This element is a diode.
