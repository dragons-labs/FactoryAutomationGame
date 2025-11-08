<!--
SPDX-FileCopyrightText: Robert Ryszard Paciorek <rrp@opcode.eu.org>
SPDX-License-Identifier: MIT

Document translated automatically using AI (chat GPT). Required verification of correctness.
-->

# Transistors

A transistor is a component with electrically controllable conduction (resistance), often used for amplifying signals or as an electronic switch (transistor switch).
A switch is a circuit that uses two extreme transistor operating states – cut-off (the transistor does not conduct) and saturation (the transistor conducts with minimal restrictions).

## NPN

The current flowing between the collector and emitter is a function of the current flowing between the base and emitter: *I(C) = β · I(B)*.
The voltage between the collector and emitter is: *U(CE) = U(supply) - I(C) · R(load)*.
However, this voltage cannot drop below a minimum value of about 0.2V; if such a drop is indicated by the above equations, the transistor is in saturation, and *U(CE) ≈ 0.2V*.

[img]Manual/Pages/electronics/transistors/npn_pnp.svg[/img]

To bring an NPN transistor into cut-off, the base must be at a potential less than or equal to the emitter potential (assuming the collector potential is not less than the emitter – typical for NPN transistor polarization conditions), i.e., *U(BE) ≤ 0*.

To bring an NPN transistor into saturation, the base potential must be higher than both the emitter and collector potentials, achieved by applying a base current *I(B) >> U(supply) / ( β · R(load))*.

See what happens when the transistor base is connected to a potential much higher than the emitter – the base-emitter junction behaves like a diode, with a constant voltage drop (Ohm's law does not apply here). Therefore, a resistor is necessary to limit the current through this branch and prevent transistor damage.

## PNP

Similar to NPN, but the current flowing between the emitter and collector is a function of the current flowing between the emitter and base.

To cut off a PNP transistor, the base potential must be greater than or equal to the emitter potential (assuming the emitter potential is not less than the collector potential – typical for PNP transistor polarization conditions), i.e., *U(BE) ≥ 0*.

To saturate a PNP transistor, the base potential must be lower than both the emitter and collector potentials, achieved by drawing a base current *I(B) >> U(supply) / ( β · R(load))*.

Observe the similarities and differences with NPN transistors:

* In both cases, the transistor conducts when base current flows, but the direction differs (in NPN, the current flows into the base, while in PNP, it flows out).
* In both cases, the transistor is cut off when the base potential equals the emitter potential (in NPN, the emitter is usually the lowest potential in the circuit, often ground, while in PNP, it is the highest potential, often the supply voltage).

Notice that here too, a resistor is needed to limit the base current.

## N-MOSFET

[img][MOSFET Image](Manual/Pages/electronics/transistors/mosfet.svg[/img]

The current flowing between the drain and source is a function of the voltage between the gate and source (*U(GS)*), with the gate being insulated (no current flows through it).

The transistor conducts in the drain → source direction when *U(GS) > U(GS (th))*, while in the reverse direction, it always conducts. For N-MOSFETs with an enhancement channel, *U(GS (th)) > 0*, and for depletion channel, *U(GS (th)) < 0*.

The specific value of *U(GS (th))* depends on the particular transistor model, and other important parameters include the maximum and minimum allowable *U(GS)*.

To turn off an N-MOSFET, *U(GS) < U(GS (th))* is needed. For transistors:

* With an enhancement channel, lowering the gate potential to the source potential (or slightly above) suffices.
* With a depletion channel, the gate potential must be below the source potential.

To turn on an N-MOSFET, *U(GS) >> U(GS (th))* is required.

## P-MOSFET

Similar to N-MOSFET, but:

* Conductivity is regulated in the source → drain direction (while the drain → source direction always conducts).
* Conductivity in the source → drain direction occurs when *U(GS) < U(GS (th))*.
* For enhancement channel, *U(GS (th)) < 0*, and for depletion channel, *U(GS (th)) > 0*.

To turn off a P-MOSFET, *U(GS) > U(GS (th))* is required. For transistors:

* With an enhancement channel, raising the gate potential to the source potential (or slightly lower) suffices.
* With a depletion channel, the gate potential must be above the source potential.

To turn on a P-MOSFET, *U(GS) >> U(GS (th))* is needed.

Notice the similarities to NPN and PNP transistors:

* N-MOSFET conducts when the gate potential is significantly higher than the drain, P-MOSFET conducts when it is significantly lower.
* N-MOSFET loads are connected similarly to NPN, and P-MOSFET to PNP.

Note the difference: the gate is insulated, so no current flows through it (ignoring the current needed to charge parasitic capacitance), and its voltage alone determines the transistor's operating state.

## H-Bridge

[img]Manual/Pages/electronics/transistors/mostek_H_switche.svg[/img]

The H-Bridge is a circuit (based on 4 switches, which can be implemented using transistor switches) that allows for changing the polarity of the power supply connected to it. Such a circuit consists of two identical branches (S1 + S2 and S3 + S4, each connected between two power supply terminals). A single branch like this is called a half-bridge and consists of two switches that should be controlled oppositely (to eliminate the possibility of shorting the power supply to ground). The half-bridge circuit can also be used independently as a universal switch system, allowing the connection of the load either from the positive voltage side or from the ground side (depending on the connection method) or for switching two loads (one placed between the power supply and the bridge output, and the other between the output and ground).

The role of the switches in the bridge can be fulfilled by PNP transistors (as S1, S3) and NPN transistors (as S2, S4) or similarly by P-MOSFET and N-MOSFET transistors.
