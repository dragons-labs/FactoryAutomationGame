<!--
SPDX-FileCopyrightText: Robert Ryszard Paciorek <rrp@opcode.eu.org>
SPDX-License-Identifier: MIT

AI tools (chat GPT) have been used for text translation and editing.
-->

# Topologies and Transmission Types

Depending on the physical arrangement of connected devices, different network topologies are distinguished. The diagram below shows the main connection topologies:

* **Bus** (linear bus) -- All devices are connected to a single line (shared transmission medium), and the cabling does not have a central point.
* **Daisy Chain** -- A cabling structure similar to a bus, but the transmission medium is divided (connecting n devices involves n-1 point-to-point links between devices).
* **Ring** -- A daisy chain topology where the ends are connected, providing resilience to a single failure.
* **Star** -- All connections originate from a central node. Depending on the central node's design, it may be implemented using either a shared medium or point-to-point connections.
* **Mesh** -- Each device has a direct point-to-point connection to every other device (connecting n devices requires n(n-1)/2 point-to-point connections).

[img]Manual/Pages/electronics/transmission/topologie.svg[/img]

Additionally, mixed topologies are possible, composed of the above-described types: multiple stars (e.g., where some nodes are central points for additional stars), a bus or ring between star centers, a star with buses or rings in its nodes, etc.

Transmission types can also be distinguished:

* **Simplex** -- Allows only unidirectional transmission.
* **Half-duplex** -- Allows bidirectional transmission, but only one direction at a time.
* **Full-duplex** -- Allows simultaneous bidirectional transmission.

## Parallel Bus

[img=1000%]Manual/Pages/electronics/transmission/parallel_bus_en.svg[/img]

A parallel bus consists of multiple lines and the systems controlling them, enabling parallel data transmission (the entire n-bit word is transmitted at once in a single clock cycle). Control, address, and data buses can be distinguished. The address bus often shares transmission lines with the data bus.

Buffers are typically used to implement the bus (to allow connecting multiple systems), while open-collector circuits are often used to handle the interrupt request shared bus.

A typical implementation of a half-duplex bus with shared data and address lines is shown in the accompanying diagram.

The address decoder determines whether the address on the bus (during the high state of the "Address / Not Data" line) matches the system's address and stores this information until a new address is issued. This information is used to control the bi-directional tri-state buffer (as an enable signal).

The buffer's direction is determined by the "Read / Not Write" signal. In buses with a defined transmission protocol, the direction can depend on the executed command (after setting the address, the device reads the command from the bus and, based on it, controls the buffer's direction - reading or writing data to the bus).

Using several OC lines to receive interrupt requests allows for identifying the device or group of devices that are issuing requests based on which of these lines are low.

For simple input/output devices, instead of a bi-directional buffer, a one-directional buffer (or n-bit register) with tri-state outputs can be placed, which outputs data to the bus based on a write signal to the bus (WR) and clock, or an n-bit register that stores data from the bus based on the RD signal and clock.

## Serial Bus

[img=1000%]Manual/Pages/electronics/transmission/serial_bus_en.svg[/img]

In a serial bus, data is transmitted bit by bit over a single line. Like in parallel buses, control lines may also be present. Simple serial bus implementations are achieved using shift registers.

An example of a simplex (unidirectional) serial bus with separate data and address buses is shown in the accompanying diagram.

In this example, in addition to the address, the master issues three signals - data, clock, and strobe. Each clock cycle places the next bit on the data line, which is loaded into the shift registers. The strobe signal is used to transfer values from the shift registers to the output registers, preventing changes in the outputs during the transmission of new data via the serial bus. However, this solution is optional.

Depending on the design of the address decoder, the address bus can be parallel (in the simplest case, throughout the transmission to a device, its address must be set on the bus, and the decoder consists of NOT gates and a multi-input AND gate) or serial (in this case, it should have its own clock or a signal indicating the address transmission with the main clock's cycles, and the decoder should be equipped with a shift register to receive and store the current address from the bus). If the bus is based only on connected serial registers (serial-out output to serial-in input), no address bus is needed, but writing all values to the bus each time may be necessary, with the write time increasing with the number of connected registers.

# Standard Interfaces

There are many standardized serial and parallel interfaces; the most important include:

## SPI (Serial Peripheral Interface)

[img=700%]Manual/Pages/electronics/transmission/spi.svg[/img]

SPI is a full-duplex serial bus operating in a master-slave configuration. It consists of a clock line (SCLK), master-to-slave transmission (MOSI), master-to-receiver (MISO), and lines for activating the slave device (SS / CS).

## I2C (TWI)

[img=700%]Manual/Pages/electronics/transmission/twi.svg[/img]

I2C is a half-duplex serial bus consisting of a signal line (SDA) and a clock line (SCL), with a defined frame format and addressing. Except for the start and stop bits, the data line can change states only when the clock line is low. Transmitters are of the open-drain type, resulting in a wire-AND function that allows collision detection (if a transmitter does not send a zero but the line is in a zero state, someone else is also transmitting). This also allows for multi-master configurations, though typically only one master (generating the clock and initiating transmission) exists on such a bus.

## 1 Wire (one-wire)

[img=700%]Manual/Pages/electronics/transmission/onewire.svg[/img]

1 Wire is a half-duplex serial bus consisting of a single signal line (which can also power devices) with a defined frame format and addressing. Standard transmission is open-drain (except for transmitting the so-called power-byte).

## USART

USART is a universal synchronous and asynchronous transmitter and receiver that enables serial transmission, either synchronous (clock-based) or asynchronous (frame start detected from the data line). The interface uses separate transmitter and receiver lines (TxD data output and RxD data input, allowing for full-duplex transmission) and can also utilize additional control signals (RTS output signaling readiness to receive, and CTS input indicating readiness to receive/permission to transmit). Sometimes a transmitter enable output is available, used in half-duplex mode (where TxD and RxD lines are connected via a three-state buffer).

[img=1000%]Manual/Pages/electronics/transmission/uart1_en.svg[/img]

This interface is most commonly used in asynchronous mode as UART. In UART connections, both the transmitter and receiver must have the same transmission parameters set (speed, the significance of the 9th bit – typically a parity bit, but it can also represent an address field, etc.). The main electrical standards for UART include: voltage levels for electronic circuits using these ports (3.3V, 5V), RS-232 (in its full variant uses flow control signals, where logic level 1 ranges from -15V to -3V, and logic level 0 from +3V to +15V), RS-422 (differential full-duplex transmission between two devices), and RS-485 (differential half-duplex transmission on a bus connecting multiple devices, electrically compatible with RS-422). Fiber optic and wireless transmission are also possible.

[img=1000%]Manual/Pages/electronics/transmission/uart2_en.svg[/img]


## Terminating Resistors

Some communication interface standards specify the use of a terminating resistor at the end of the bus. This resistor is intended to eliminate signal reflections that may occur at the end of a transmission line.

This phenomenon occurs with *long lines*, meaning lines whose length is close to or exceeds the wavelength of the transmitted signal. For example, if we consider a pulse with a duration of 1μs, it will occupy a cable segment about 200 meters long (depending on the speed at which electromagnetic waves travel in the medium that constitutes the cable). Thus, for a 1MHz signal (with individual pulses lasting 1μs), a cable several hundred meters long would be considered a long line.

These reflections arise because the propagation of the signal (e.g., our 5V pulse lasting 1μs) along the wire is associated with charging successive parasitic capacitances tied to the wire segment the signal reaches. This happens at the expense of discharging the capacitance of the segment the signal has already passed.

When the signal reaches the end of the conductor, it has no way to discharge this capacitance into the next segment of wire, so the charge associated with it "spreads out over the cable," causing a reflection. This reflection (running from the end of the wire toward the transmitter) superimposes on subsequent pulses of our signal (moving from the transmitter) and causes interference in their reception (interpretation).

Using an appropriate resistor at the end of the line allows this capacitance to discharge (as if there were another infinitely long segment of wire there), eliminating the reflection. The value of this resistance is characteristic of the wire and is defined by a parameter called *wave impedance*.

A terminating resistor imposes a load on the transmitter and should only be used at the ends of the bus, i.e., at the last devices connected to the bus (and not at every device connected to it).

If the length of the line is much shorter (for rectangular signals, it is assumed to be about 20-40 times) than the length of the segment occupied by a single pulse (e.g., a line 3m long for a 1MHz signal), there is no need to use terminating resistors (even when the standard generally provides for them), as the state of the entire line is consistent and forced by the transmitter (it is not considered a long line).

The I2C standard does not provide for terminating resistors (and they should not be used, especially since these are open-drain lines and a voltage divider would form with the pull-up resistor). This is because, at the maximum speed of this interface, lines would only be considered long if they were at least several tens of meters long, and for other reasons, this standard is limited to a few meters.

The RS-485 standard provides for the use of 120 Ω terminating resistors, but in the case of short connections and/or low transmission speeds, they can be omitted.
