<!--
SPDX-FileCopyrightText: Robert Ryszard Paciorek <rrp@opcode.eu.org>
SPDX-License-Identifier: MIT

AI tools (chat GPT) have been used for text translation and editing.
-->

Working in the terminal
=======================

A computer is called an electronic calculating machine. This means that it mainly performs arithmetic and logical operations. Depending on the result of such operations, it can jump to another place, allowing it to execute a different set of instructions based on the data or user actions.

The computer only deals with executing such sequences of instructions, which make up a computer program. From the processor's point of view, these instructions always take the form of machine code, i.e., the number of the instruction to execute and its arguments. From a programmer's perspective, they may be represented by complex high-level language instructions or library function calls. From a user's perspective, they are often ready-made programs or specific functions within a given program.

However, a method is always needed to input such a sequence of instructions and receive the results of the program's operation. Long ago, this was done by preparing the entire program on some medium (e.g., punched cards), running the computer, and then receiving the generated results on some medium (e.g., in print form). Interaction with the computer was limited to low-level monitoring of its operation and possibly influencing the program's behavior from a technical console.

Interactive work was only made possible by text communication, allowing for a sort of dialogue with the computer during its operation. This dialogue involved sending commands and data to the computer and receiving the results of its operation. The device that enables such text communication with the computer is called a terminal.

The primary method of issuing commands in Unix-like systems is by typing them in the terminal. The terminal can work in text mode or can be launched (as a so-called terminal emulator) in graphical mode.

## Terminal

A terminal can operate in a graphical environment - as a so-called terminal emulator, running under the control of an X server. It can also work within a Linux virtual console - in text or pseudo-text mode that does not require a graphical environment or can be launched on a real, purely textual connection, such as a serial port.

The terminal handles input and output, meaning character input (typically from a keyboard) and character display, typically on the screen. The details of this operation depend on the specific terminal implementation and the hardware it runs on. The terminal will operate differently on a serial port than in an X server environment. The terminal also handles control sequences related to cursor movement, determining where information is printed, switching colors, and other text formatting.

## Shell

The commands entered are interpreted by a program running in the terminal called a shell (command interpreter). In the terminal, successive (similar or different) command interpreters can be launched. Different interpreters use different syntaxes and often differ in the prompt (the text displayed before entering commands).

### Programming Language

Working in the POSIX (Unix/Linux) command line is working in a scripting programming language interpreter. We can interactively execute individual "lines of code" (commands), and we can also save them in a file and execute them as a whole. We can define functions, use conditional instructions and loops, etc. The standard shell in POSIX systems is a specific language primarily designed to launch other programs, operate on files (more precisely, paths in the file system), etc., not for calculations. For example, launching a program, operating on its standard input and output, will be achieved with simple syntax (requiring less code than probably any other language), but simple addition will look quite exotic.

The shell is generally used either to extract things from files or to perform operations such as moving or renaming files, i.e., invoking other commands on files or appropriately prepared future file names. Programming in this language largely involves calling external programs, which can be thought of as library functions or, in the case of more complex programs, entire libraries. The shell is also treated as a language to prepare the working environment for another application, set appropriate environment variables, prepare directories, process paths, etc.

### Bash, Zsh, ...

Perhaps the most popular system shells (command interpreters) are Bash and Zsh. They are compatible with the `sh` syntax and provide, among other things, variable handling (mainly string-based), wildcards, etc.

#### Command Line Editing and History

Both programs allow command line editing and use of history, so with the up-down arrow keys, we can browse through the history of entered commands, and with the Control-R shortcut, we can search through it. The commands entered or selected from the history can also be edited by moving through them with the left-right arrow keys and run by pressing Enter.

An essential feature when entering commands is the autocomplete function using the Tab key, which completes both command names and paths and often other command arguments. In Bash, pressing the Tab key once completes the entered text if it is unambiguous. If there are several possibilities, the longest unambiguous fragment is completed. Pressing the Tab key twice will display available options. After disambiguating, we can use the Tab key again to complete, and so on. The default behavior of Zsh is slightly different.

It's important to note that this command line and history handling is a feature of the shell, not the terminal. And since this functionality is often provided by a dedicated library, it can also be available in many other programs.

### screen and tmux

`screen` and `tmux` are terminal multiplexers – they allow multiple console windows (even displayed side by side) on a single terminal. Moreover, they allow detaching and reattaching sessions, making it easy to leave a running program after logging out and return to it later.

## Commands

Unix commands (i.e., commands understood by Bash or another sh-compatible interpreter) consist of a command name, options, and arguments. The command name can be the name of a built-in function, the name of a program (located in the program search path), or the full path to a program. After the command name, options and/or arguments may follow. These are separated from the command name and from each other by spaces (essentially any sequence of whitespace: spaces, tabs, etc.).

There is no strict distinction between options and arguments. The typical convention is that options start with a single dash (short options - one letter) or two dashes (long options). When using this convention, a single dash can be followed by several single-letter options without arguments. Typically, option arguments are separated from them by a space (for short options) or an equals sign (for long options). If one of the command components (e.g., an argument) contains spaces, they must be escaped with a backslash (`\\`) or the string containing them enclosed in single (`'`) or double (`"`) quotes.

## Redirects

[img=800%]Manual/Pages/programming/posix_command_line/streams_pl.svg[/img]

Typically, a program has three data streams: one input (stdin) and two outputs (stdout and stderr). We can redirect the standard output to the standard input of another program using `|`, e.g., `ls --help | less`. This construction redirects the output of the `ls` command run with the `--help` option to the `less` command.

We can also redirect the standard output to a file (using `>` or `>>` if we want to append to the file) or retrieve standard input from a file (using `<`). `2>` allows redirecting the standard error output to a file.

If there is a need to combine both streams, we can use `2>&1` to redirect the second stream to the first one. Then we can use `|` to redirect the combined stream to the next command. If we want to redirect it to a file, the stream combination should occur after redirecting the first stream to the file, e.g.: `ls . "Nonexistent File" >log.txt 2>&1`. Bash allows using `>&` and `|&`, which redirect both streams to a file or the standard input of another command, but this is an extension beyond the standard `sh` syntax.

## Command Exit Code and Command Chaining

Each command returns a numeric exit code when it finishes (in the case of C programs, this is the return value from the `main` function). Zero means the command succeeded (e.g., the desired files were found), while a non-zero value means it failed (e.g., no matching files were found) or there was an error (e.g., the syntax of the command was incorrect).

Commands can be chained in various ways – with or without using this information:

* `a && b` – command b will run if a succeeded (returned code 0)
* `a || b` – command b will run if a failed or errored (returned code other than 0)
* `a ; b` – command b will run after a finishes (regardless of its exit code)
* `a & b` – command b will run concurrently with a (more precisely, command a will run in the background, and the terminal will be ready for command b)

Spaces in the above constructions are optional. The semicolon and single `&` can also be added to a command even when there is no next command in the sequence:

* `a&` will run command a in the background and return the command line,
* `a;` will run command a (just as if the semicolon weren't there).

## Getting Help

Information about how a command works and its options can be obtained in the built-in help system using the `man` or `info` / `pinfo` commands.
Most commands also support the `--help` or `-h` options, which display usage information.

### Notation

In both help texts and this document, the convention of marking optional arguments by enclosing them in square brackets is used (if we provide this argument to a command, we do not include the brackets), and alternative options are separated using `|`. For example, `a [b] c|d` means that the command `a` requires an argument of either `c` or `d`, which may optionally be preceded by the argument `b`.

## more and less

If the output of a command doesn't fit on the screen, we can use the `more` or `less` commands to view it. These are programs that allow viewing text page by page. `less` has more features than `more` (in particular, it allows scrolling backwards). Both programs exit after pressing the `q` key. `less` also enables searching — the `/` key allows entering a search term, and `n` finds the next occurrence. These programs can also display files passed as arguments. Some useful options for the `less` command include:

* `-X`: does not clear the screen upon exiting `less` (the entire file history remains in the terminal’s history)
* `-F`: automatically exits if the displayed text fits on one screen
* `-R`: passes raw terminal control sequences regarding colors
