<!--
SPDX-FileCopyrightText: Robert Ryszard Paciorek <rrp@opcode.eu.org>
SPDX-License-Identifier: MIT

Document translated automatically using AI (chat GPT). Required verification of correctness.
-->

Program Execution
==================

When running our code directly on hardware without an operating system, it is the only code being processed by the CPU. Typically, such a program directly uses hardware mechanisms offered by the processor and platform, and its termination or interruption causes the entire system to hang or shut down.

The situation changes when using a (multitasking) operating system. Our program then becomes one of many running processes. Each process can be in one of several states, the most important of which are:

* running (the process code is actively executing on the CPU at the moment)
* waiting for CPU availability (the process code is ready to execute but is not currently executing due to no free processor/core)
* waiting for other events (e.g., waiting for user input, data from the network, expiration of a set time period, etc.)

The task of queuing processes waiting for CPU execution and switching between them (to share CPU time across different tasks) is one of the responsibilities of the operating system.

Other responsibilities of the operating system include supporting the creation of new processes, i.e., creating child processes (forking a process) and providing mechanisms for passing parameters to the newly created process and communicating with it. These mechanisms include:

* command-line arguments, which are a list of strings passed during the program's launch, typically used to specify options and arguments affecting its behavior and defining data to be processed
* environment variables, which are (specified by the parent process) key-value pairs from which values can be retrieved by the program using the key and can affect program behavior
* return code, a numerical value indicating the status of the process' termination, returned to the parent process
* standard input, output, and error streams, which enable data transfer between processes and are typically used for (textual) input/output to/from the program's user

For programs operating in a graphical environment (and utilizing its mechanisms), these mechanisms are supplemented by the passing of events and data related to that environment (such as mouse click locations, clipboard data, etc.). This functionality is often implemented by a system service responsible for the graphical environment.

Applications, Processes, Threads, and Resource Separation
---------------------------------------------------------

* In an operating system, not only can many different programs be running, but also multiple copies of the same program (even if launched from the same executable file).
* A single program can run within one or (if it uses mechanisms for creating child processes and executes its own code in them) multiple processes.
* Process:
    * Is allocated system resources (such as memory, file handles, access to devices, ...).
    * Can be suspended and/or terminated externally (without its consent, by the operating system).
    * The operating system automatically releases all allocated resources after the process terminates.
    * Processes can execute in parallel (i.e., processes related to different programs or the same program can run simultaneously on different processor cores).
    * Every process running on a computer has access to the full address space of operational memory, but does not have access to other processes' memory. Thus, process A and process B can store different data at the same address.
    * If a parent process terminates, child processes can either terminate as well or continue their execution (in which case another process assumes the parent role).
* In addition to full-fledged processes, there are also threads (lightweight processes). Threads:
    * Are closely tied to the process that created them (in particular, they are terminated together with it and are often not externally controllable).
    * Can run independently of each other, i.e., be in different parts of the program at the same time (just like normal processes).
    * Can (in most cases) execute in parallel, meaning different threads can run on different cores at the same time (even from the same process).
    * All threads within a single process share memory - meaning that modifying a value at a given memory address will be visible in all threads of that process (but will not be visible in other processes, even those executing the same code).
* To enable inter-process communication, various programming mechanisms offered by the operating system are used - one of them is **shared memory**. Synchronization mechanisms for processes and threads are also used to ensure atomicity of operations performed on shared memory (protection against simultaneous modification of the same value by several threads). These mechanisms will be discussed in more detail in the topic of parallel programming.

### Memory Management

Another function of the operating system is memory management. It involves mapping logical addresses (used by processes) to physical addresses (used by the processor), leveraging hardware support from the processor. This is most commonly implemented using the paging mechanism. The available physical memory is divided into equal-sized blocks called frames, and logical memory is divided into equal-sized blocks (of the same size as frames) called pages. Pages used by a program are mapped to arbitrary physical memory frames. When a page is not mapped - depending on the circumstances - a page fault or a protection fault occurs. This solves the issue of external fragmentation, where there is no contiguous memory block of the required length despite sufficient total free memory, but does not solve internal fragmentation, where memory fragments too large are allocated for the process (and arguably exacerbates it). This mechanism requires keeping track of a free frame table, a page table for each process (containing mappings of that process' pages to frames), and translating logical addresses (page + offset within the page). Even the page table itself can be paged (i.e., we have a table informing us that page mappings for a given address range are stored in a specific frame).

Pages and frames can be shared between processes (e.g., when forking a process, pages are copied only when necessary). When there is insufficient physical memory, selected pages of an inactive process can be placed on disk (swap). This may sometimes lead to thrashing, where too many page swaps occur. It always leads to the need to decide which pages should be moved to disk. Ideally, pages that won't be needed for the longest time would be moved (though for obvious reasons this is practically impossible). Various algorithms are used for this selection:

* FIFO - we remove the page that has been in memory the longest
* LRU - remove the page least recently used (time counter, reference bit, reference bit within a specific time, modified bit)
* LFU - remove the page with the fewest references
* MFU - remove the page with the most references

An alternative (and less demanding) method of memory management compared to paging is segmentation. In x86 architecture, it is always used but can be covered by a large segment where paging is used.
