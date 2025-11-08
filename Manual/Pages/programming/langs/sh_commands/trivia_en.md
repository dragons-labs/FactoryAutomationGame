<!--
SPDX-FileCopyrightText: Robert Ryszard Paciorek <rrp@opcode.eu.org>
SPDX-License-Identifier: MIT

Document translated automatically using AI (chat GPT). Required verification of correctness.
-->

Basic Shell Commands
====================

Users, Permissions, and Processes
---------------------------------

### File Permissions

Basic Unix file permissions consist of three parts: permissions for the owner (u), group (g), and others (o).
Each part can grant read (r), write (w), and execute (x) permissions; for files, this is intuitive (execute permission is needed to run programs), while for directories, it works as follows: read permission allows listing the contents, execute allows access to the directory's contents (entering it), and write allows creating new objects within it and renaming existing ones.

An extension of the basic permissions described above is the Filesystem Access Control List (ACL, fACL) mechanism.
It is an optional mechanism that (on supported file systems) allows defining individual permissions for files for specific users and groups – the file still has its owner, group, and others, but before the rights for "others", the permissions for users and groups defined in the ACL apply. The effective rights are calculated as the sum of the rights resulting from the user and groups to which they belong.
ACL also allows defining default permissions for newly created files in a directory (these are a directory option).

All the following commands accept the `-R` option to recursively apply changes to the directory/file tree starting at the given path.

* `chown [options] owner path` – change the file's owner
* `chgrp [options] group path` – change the file's group
* `chmod [options] permissions path` – change the file(s) access permissions

* `getfacl [options] [path]` – read permissions related to Access Control Lists (fACL)
* `setfacl [options] [path]` – set permissions related to Access Control Lists (fACL)

Additionally, the following commands should also be mentioned:

* `lsattr` / `chattr` – displays/modifies file attributes related to the file system (e.g., prevents any modifications to the file)
* `getcap` / `setcap` – displays/modifies file attributes related to kernel capabilities (essentially elevated privileges for programs that have them, but more restricted than running as root via SUID)


### Users

* `id [user]` – user information (e.g., groups they belong to)
* `whoami` – information about the current user
* `w` or `who` – information about logged-in users

* `passwd [user]` – change password

* `su [user]` – switches to another user (to allow the switched user access to "our" X server, run `xhost LOCAL:user` beforehand)
* `sudo` – allows designated users to run privileged commands


### Processes and Resources

* `ps [options]` – displays currently running processes and information about them\\ e.g., `ps -Af` displays all processes in an extended format

* `top` – monitors CPU, memory usage by processes
* `iotop` – monitors processes causing I/O load

* `kill [options] pid` – sends a signal to processes with the specified PID
* `killall [options] name` – sends a signal to processes matching the name


Other commands
--------------

In addition to the previously described most popular/important commands, there are many other standard or less standard (requiring installation on many systems) command-line tools. Below are listed a few more useful examples.

Furthermore, any program in a Linux (Unix) environment can be launched from the command line by providing its name (if it is in the search path `$PATH`) or the full path to it. In many cases, such launching allows passing an argument in the form of a file to open or other options, or even using a program normally working with a graphical user interface (such as Blender, Inkscape, ...) in non-interactive mode (e.g., for automatic conversion, etc.).

* `date` – date and time; this program can also calculate date and time, e.g. `date -d @847103830 '+%Y-%m-%d %H:%M:%S'`, `date -d '1996-11-04 11:37:10' '+%s'`, `date -d '1996-11-04 11:37:10 +3week -2days'`
* `cal` – calendar
* `wget` / `curl` – downloading web pages and files
* `file` – recognizes file type (based on content)
* `convert` – converts graphic files

* `iconv` – converts text file encodings
* `konwert` – converts text file encodings, both between different encodings of the same character set and between incompatible encodings or between 8-bit character encodings and fewer bits, for example:
    * `konwert utf8-ascii` "intelligently" removes non-ASCII characters from a file encoded in UTF-8 (e.g., replacing Polish diacriticals with appropriate ASCII characters without diacriticals);
    * `konwert qp-8bit` converts quoted-printable encoding to normal 8-bit (rtf-8bit does this for RTF encoding)

* `mewencode` / `mewdecode` – part of the Mew mail client toolset for handling MIME encodings (including Quoted-Printable, base64), e.g., converts base64 encoding to 8-bit
* `qprint` – encodes and decodes "Quoted-Printable"
* `base64` – encodes and decodes base64
* `strings` – prints printable character sequences (used to determine the content of non-text files)

* `command -v command` – returns the executable path / command when executing `command`

### Task scheduling

Typically, the system provides a service to run tasks at a specified time. You can use this service with commands such as:

* `crontab` allows viewing and editing the table of scheduled cyclic tasks (for cron)
* `at` allows one-time scheduling of a task

The cron configuration files managed by `crontab` have the format: `minute hour dayMonth month dayWeek command`. The entry means the command will be executed if all conditions are met. If a condition is unnecessary, an asterisk `*` can be used. Meanwhile, `*/n` means execution if the value is divisible by `n`. For example: `*/20 3  * * 1 ls` means executing the `ls` command every Monday at 3:00, 3:20, and 3:40.

Standard output, error output, and notifications about a non-zero return code are sent by default to the local email address of the user owning the crontab. Sometimes `anacron` is also available, allowing less precise task scheduling.

Directory structure
-------------------

Unix systems have a tree-like file system starting from the root directory marked by a slash (`/`), where the root file system (rootfs) is mounted. Other file systems may be mounted in subsequent directories. The most important directories include:

* `/bin` – contains executable files of basic programs
* `/sbin` – contains executable files of basic administrative programs
* `/lib` – contains basic library files
* `/usr` – contains additional software (internally has a structure similar to the root - i.e., `/usr/bin`, `/usr/sbin`, `/usr/lib`, etc.)
* `/etc` – contains system-wide configuration files
* `/var` – contains program and service data (such as mail queue, task schedules, databases)
* `/home` – contains users' home directories (often mounted from another file system, which is why root's home directory is in `/root`, so it's accessible even if such mounting fails)
* `/tmp` – contains temporary files (typically cleaned on system startup); Linux also has `/run` for holding temporary data for running services like PID numbers, locks, etc.
* `/dev` – contains device files; Linux also has `/sys` for holding information and settings about devices, etc.
* `/proc` – contains information about running processes (on Linux also acts as a configuration interface for many kernel parameters)

From the perspective of a programmer or user, (almost) everything is a file, though there are different types (regular file, directory, character device, block device, symbolic link, FIFO queue, etc.); a notable exception is network devices (which do not have a representation in the file system, though sockets related to established connections are handled much like files).
