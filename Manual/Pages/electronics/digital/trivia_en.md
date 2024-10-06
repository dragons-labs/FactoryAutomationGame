<!--
SPDX-FileCopyrightText: Robert Ryszard Paciorek <rrp@opcode.eu.org>
SPDX-License-Identifier: MIT

AI tools (chat GPT) have been used for text translation and editing.
-->

## ADC and DAC Converters

An Analog-to-Digital Converter (ADC) is used to convert an analog signal into digital form. This is done by measuring voltage, usually at regular time intervals (to obtain a signal waveform rather than just an instantaneous value). A direct comparison ADC is based on a set of analog comparators (the number of which determines the bit depth of the ADC but is not equal to it) that use different reference voltages (typically derived from a single reference voltage through a divider). The states from the comparators are sent to an encoder for conversion to binary code. Other ADC implementations use a single comparator and apply an increasing reference voltage, counting the number of steps taken, or using successive DAC outputs to find the one closest to the input voltage.

A Digital-to-Analog Converter (DAC) is used to convert a digital signal into an analog one. It is based on the principle of a voltage summator, where inputs are activated depending on the bit settings in the converted value. Typically, instead of using different voltage values and identical resistors (as in a summator), different resistor values are used with a common voltage connected to them. It can also be based on generating a PWM signal and passing it through a filter capacitor, with optional feedback (to correct the PWM value) implemented by an ADC.

### Voltage and Current Measurement

Voltage measurement is directly performed by the ADC. In cases where high voltages need to be measured, voltage transformers are used, which are essentially transformers with well-defined measurement parameters. For low voltages, amplification may be required, for example, using an operational amplifier.

Current measurement can be performed in several ways:

* As a voltage measurement across a resistor inserted into the measured circuit; this allows the measurement of both AC and DC currents.
* Using a current transformer—a transformer connected in series in the circuit or a toroidal coil through which the conductor carrying the current passes (single primary winding); this is used only for AC currents (the changing current in the conductor induces a magnetic field, causing current to flow in the measurement circuit).
* Using the Hall effect (the current may flow directly through the measurement system, through a loop of a trace on the opposite side of the PCB from the Hall sensor, or similar to a toroidal current transformer); this allows the measurement of both AC and DC currents.
