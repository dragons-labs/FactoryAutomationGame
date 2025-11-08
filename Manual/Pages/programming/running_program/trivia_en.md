<!--
SPDX-FileCopyrightText: Robert Ryszard Paciorek <rrp@opcode.eu.org>
SPDX-License-Identifier: MIT

Document translated automatically using AI (chat GPT). Required verification of correctness.
-->

Operating System
================

An operating system is software responsible for managing the resources of a computer system (hardware, but not only) and the applications running on it. The most important tasks of an operating system include CPU time division, task scheduling, and memory management—particularly handling virtual memory, usually through the paging mechanism.

Additionally, the system manages files, input/output (typically implemented through interrupts (IRQ), but polling-based I/O models also exist), device handling (input/output, drivers, access), network handling (network protocol stack), and so on. Some tasks are carried out with minimal CPU (and thus system) involvement, such as data transfers in DMA mode, where data is copied in entire blocks without the CPU's intervention to/from memory (the system only initiates the transmission). It's worth noting that when this technology is not used, data is also copied between the disk and CPU in blocks (at least a sector), as the disk (unlike operational memory) is not directly accessible to the CPU.

Modern systems operate on at least two levels—a privileged "supervisor" level where the operating system kernel runs and a user mode. I/O operations must occur in the privileged mode. Memory also has a protected area, where, among other things, the interrupt vector table is placed (otherwise, changing the address in this vector could lead to a system takeover in privileged mode).

Processes and Task Scheduling
-----------------------------

An essential role of the operating system in process management (besides administrative tasks like creating, duplicating, deleting, or pausing them) is to ensure memory protection (each process can only write to its own and possibly shared memory if given permission) and processor protection (a clock interrupt triggers the scheduler, which decides which process will get the next time slice of the processor). Some systems distinguish between processes and threads, which differ by shared memory (between threads of one process) and resources (e.g., open files). The operating system also provides a set of services and functions (system calls) that act as intermediaries between the user-mode interface and the hardware.

An important task of the operating system is to prevent so-called deadlocks, situations where two or more processes block each other while waiting for resources (e.g., process A has resource X, which process B needs to release resource Y, which process A needs to release X). This can be handled in several ways:

* Preventing deadlock (i.e., avoiding the necessary conditions) – for example, by requiring all resources to be declared upfront, releasing allocated resources before requesting new ones.
* Avoiding deadlock (i.e., defining maximum resource demand and allocating resources to avoid deadlock) – for instance, by controlling whether, after fulfilling a request, we will remain in a "safe" state, meaning that there is a sequence (called safe) in which the maximum resource demand of each process can be met based on resources released by processes earlier in that sequence and the free resources.
* Detecting and removing deadlock when it occurs.

The CPU scheduler, the part of the system responsible for allocating the CPU to processes, can operate in preemptive or non-preemptive mode. In the first case, a process receives a CPU time slice that it can use entirely (after which it moves from running to ready state) or release earlier (e.g., when waiting for I/O, then it moves from running to waiting state). In the second case, the process runs its code until it voluntarily releases the CPU. This form is similar to real-time scheduling, where a process is preempted only by a higher-priority process, and this happens immediately (at the next clock interrupt). There are many scheduling algorithms, such as:

* FCFS – First Come, First Served.
* SJF – The shortest job is processed first (preemptive version SRTF—when a new, shorter job appears); this algorithm is impractical as it requires predicting execution time.
* Priority-based – Always the highest priority (as mentioned above, used in real-time systems).
* Round-robin – Each process gets a time slice and then goes to the back of the queue.
* Multi-level queues – A system with priorities, time division between queues, process migration between queues, ...

The Computer Boot Process
-------------------------

After receiving a reset signal (also when starting the system—Power-on Reset), the CPU, after initializing its registers, begins executing code at a predetermined address (typically in built-in or external ROM or Flash memory). Depending on the architecture/CPU, this may be user program code, a built-in bootloader allowing further loading (e.g., from an SD card), or an external low-level bootloader (e.g., u-boot).

For x86-compatible architectures, this is the BIOS, which, after completing hardware initialization and startup tests, loads the code located in the first sector of the hard disk (boot sector starting at address zero) and executes it (transfers control to it). This contains the code (or just the beginning of it) of the bootloader, whose task is to load the operating system. For modern Linux systems, this is typically GRUB.

In MBR-type (and compatible) boot sectors, this code can be up to 446 bytes (since the partition table occupies the remaining space), and its task is to load and run the rest of the bootloader (it must know its location on the disk). The rest of the bootloader can be located right after the MBR (in the gap between the MBR and the first partition—for MBR/msdos partition tables), in a dedicated BIOS boot partition (for GPT partition tables), or in a partition marked as bootable. This part contains modules that allow access to the filesystem containing the configuration, kernel image, etc., and information about its location (disk, partition, path).

For UEFI-based computers, the firmware is responsible for interpreting the partition table (GPT) and loading the bootloader from a file located on a special EFI partition (EFI System Partition) with a FAT32 filesystem. This file contains the entire bootloader (both parts described above).

System startup begins by loading the kernel image into memory along with parameters and (optionally) initrd, and control is passed to the kernel by the bootloader (e.g., GRUB). For the Linux kernel using initrd, this image is transformed into a read-write RAM disk and mounted as rootfs, from which `/sbin/init` is run (whose main task is to mount the proper rootfs). After this (or immediately if no initrd is used), the program indicated in the kernel's `init=` option (typically `/sbin/init`) is run from the rootfs specified in the kernel's `root=` option. The `init=` option can point to any program or script (it will be run with root privileges).
