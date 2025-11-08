<!--
SPDX-FileCopyrightText: Robert Ryszard Paciorek <rrp@opcode.eu.org>
SPDX-License-Identifier: MIT

Document translated automatically using AI (chat GPT). Required verification of correctness.
-->

Basic Shell Commands
====================

File system operations
----------------------

### Printing

The `echo` command is used to print arguments passed to it on the screen, e.g.:

* `echo abc   xyz` will print *abc xyz*
* `echo *` will print non-hidden files in the current directory (due to [url=guide://programming/posix_filesystem]wildcards of the shell[/url]).

To correctly print multiple spaces, new line characters, and other special characters, quotes or apostrophes must be used (the latter also protect the dollar sign `$`):

* `echo "abc   xyz"` and `echo 'abc   xyz'` will print *abc   xyz*
* `echo "*"` and `echo '*'` will print [i]*[/i]
* `echo "$abc"` will most likely print nothing, while `echo '$abc'` will print *$abc*

### Listing and searching for files

* `ls [options] [path]` – lists the contents of a directory, important options include:
    * `-a` display hidden files (starting with a dot)
    * `-l` display files in a list with detailed information (permissions, size, modification date, owner, group, size)
    * `-1` display one file per line (without additional information; default when command output is piped to another command or file)
    * `-h` use units like k, M, G instead of showing size in bytes
    * `-t` sort by modification date
    * `-S` sort by size
    * `-r` reverse the sort order
    * `-c` use creation date instead of modification date (used with `-l` and/or `-t`)
    * `-d` display directory information instead of its contents
* `find [options] [starting directory] [expression]` – searches the file system based on file name/path or file properties, important options include:
    * `-P` display information about symbolic links instead of the files they point to (default)
    * `-L` display information about the files pointed to by symbolic links
. important elements of expressions include:
    * `-name "expression"` files whose name matches the expression using shell wildcards
    * find (unlike `ls`) interprets expressions containing shell wildcards on its own, so it may be necessary to protect them from interpretation by the shell using single quotes
    * `-iname "expression"` like `-name`, but case-insensitive
    * `-path "expression"` files whose path matches the expression using shell wildcards
    * `-ipath "expression"` like `-path`, but case-insensitive
    * `-regex "expression"` files whose path matches the regular expression
    * `-iregex "expression"` like `-regex`, but case-insensitive
    * `condition -o condition` combines conditions with a logical "OR" (instead of the default logical "AND")
    * `! condition` negates the condition
    * `-mtime [+|-]n` files modified `n`*24 hours ago
    * `-mmin [+|-]n` files modified `n` minutes ago
    * `-ctime [+|-]n` files created `n`*24 hours ago
    * `-cmin [+|-]n` files created `n` minutes ago
    * `-size [+|-]n[c|k|M|G]` files whose size is `n` (c - bytes, k - kilobytes, M - megabytes, G - gigabytes)
    * in the above tests, `+` means more than, `-` means less than, note: comparison is done with integers, e.g., +1 means *\ge2*
    * `-exec command \{\} \;`: for each found file, execute `command`, substituting the file path for `\{\}` (the backslashes before curly braces and semicolon protect them from shell interpretation)
    * `-execdir command \{\} \;`: similar to `-exec`, but the command is run in the directory containing the found file
* `du [options] path1 [path2 [...]]`: shows disk space used by specified files/directories. Key options include:
    * `-s`: gives the total space used by each argument (instead of showing the size of each file)
    * `-c`: gives the total space used by all arguments
    * `-h`: uses units like k, M, G
. The size may differ (in both directions) from the `ls` result: `ls` gives the file size (how much data it contains or is declared to contain), while `du` shows how much space it occupies on the disk.
* `df [options]`: shows disk space usage on various filesystems

Note that the `find` command can expand wildcard characters itself (for some of its arguments). For options like `-name`, we generally want the wildcard characters not to be expanded by the shell but interpreted by the `find` command itself. To achieve this, we should protect them from expansion by using quotation marks. When specifying the starting directory, `find` behaves like other commands (e.g., `ls`), where wildcards must be expanded by the shell. For example, if we want to search all directories starting with *a* for files starting with *b*, we should run: `find a* -name "b*"`, not `find "a*" -name "b*"` or `find a* -name b*`, etc.

Also, note that if the `ls` command receives a directory path as an argument due to wildcard expansion, it will list its contents (this behavior can be changed with the `-d` option).

## Copying, moving, deleting, ...

* `cp [options] source1 [source2 [...]] destination`: copies the specified file(s) to the target location. When copying multiple files, the destination should be a directory. Key options include:
  * `-r`: allows (recursive) copying of directories
  * `-a`: similar to `-r`, but also preserves file attributes
  * `-l`: creates hard links instead of copying
  * `-s`: creates symbolic links to the files instead of copying them
  * `-f`: overwrites without asking
  * `-i`: always ask before overwriting
* `ln source1 [source2 [...]] destination`: creates a link (default is a "hard" link) to the specified file(s) in the target location. If multiple source files are specified, the destination should be a directory. Key options include:
  * `-s`: creates symbolic links (pointing to the original file’s path) instead of hard links (which point to the same data as the original file)
  * `-r`: uses a relative path instead of an absolute one when creating symbolic links
* `mv [options] source1 [source2 [...]] destination`: moves the specified files/directories to the target location. When moving multiple files, the destination should be a directory. Key options include:
  * `-f`: overwrites without asking
  * `-i`: always ask before overwriting
* `rm [options] path1 [path2 [...]]`: deletes the specified files. Key options include:
  * `-r`: allows (recursive) deletion of directories and their contents
  * `-f`: deletes without asking
  * `-i`: always ask before deleting
* `mkdir [options] path1 [path2 [...]]`: creates the specified directories. Key options include:
  * `-p`: allows creating the entire path, not just the final element, and does not throw an error if the directory already exists

### Remote copying

The simplest method of copying files between different systems is using SSH, typically done in one of several ways:

* `scp [options] source1 [source2 [...]] destination`, which copies the specified file(s) to the target location. When copying multiple files, the destination should be a directory. Key options include:
  * `-r`: allows (recursive) copying of directories
  * `-P port`: specifies the SSH port
. Unlike `cp`, the source or destination in the form ```[user@]host:[path]``` refers to a remote system accessible via SSH.
* `rsync [options] source destination`, which copies (syncs) files and directory trees (both locally and remotely). Key options include:
  * `-r`: allows (recursive) copying of directories
  * `-l`: copies symbolic links as symbolic links (instead of copying the file contents they point to)
  * `-t`: preserves file modification times
  * `-u`: only copies when the source file is newer than the destination
  * `-c`: only copies when the source and destination files have different checksums
  * `--delete`: deletes elements from the destination directory tree that do not exist in the source tree
  * `-e 'ssh'`: allows copying to/from remote systems via SSH; source or destination in the form ```[user@]host:[path]``` refers to a remote system
  * `--partial --partial-dir=".-tmp-"`: saves partially copied files in the `.tmp` directory (allowing transfer interruption and resumption)
  * `--progress`: shows copy progress
  * `--exclude="pattern"`: excludes (from copying and deleting) files matching the pattern (the pattern may include shell wildcard characters)
  * `-n`: simulates the operation (shows what would be copied, but does not copy)
* using `sshfs [options] host:path`, which mounts the remote filesystem using FUSE (filesystem in userspace) and SSH. Key options include:
  * `-p port`: specifies an SSH server port other than the default
  * `-o workaround=rename`: ensures correct behavior of `mv` on existing files
* a more complex command based on redirecting the output of a command to SSH, which starts a process on the remote side to receive the data on its standard input, e.g.:
  * `tar -czf - path1 [path2 [...]] | ssh [user@]host 'cat > file.tgz'`
    archives the specified files/directories directly to the remote system using `tar` and `gzip` compression to the `file.tgz`
  * `tar -cf - path1 [path2 [...]] | ssh [user@]host 'tar -xf - -C destination'`
    copies the specified files/directories to the remote system using `tar` to the `destination` directory

Operations on File Contents
-----------------------------

### grep and Regular Expressions

The command `grep [options] expression [file1 [file2 [...]]]` searches for lines in files that match the regular expression. Useful options:

* `-v` instead of matching, display non-matching lines
* `-i` ignore case sensitivity
* `-a` process binary files as text files
* `-E` use "*Extended Regular Expressions*" (ERE) instead of "*Basic Regular Expressions*" (BRE)
* `-P` use "*Perl-compatible Regular Expressions*" (PCRE) instead of "*Basic Regular Expressions*" (BRE)
* `-r` recursively process the specified directories, searching all found files
* `-R` like `-r`, but always follows symbolic links
* `--exclude="pattern"` skip files that match the pattern (can include shell wildcards)
* `-l` lists files with matching lines
* `-L` lists files without matching lines
* `-f` read patterns from the specified file
* `-e` can be used to precede the expression (especially useful when specifying multiple patterns)

Regular expressions (the following syntax applies to "*Extended Regular Expressions*"; with BRE, some control characters require escaping with a backslash) are built using the following special characters:

```
.      - any character
[a-z]  - character from the range
[^a-z] - character outside the range (to include `^` in the range, place it anywhere but the beginning)
^      - beginning of the string/line
$      - end of the string/line

*      - any number of repetitions
?      - 0 or one repetition
+      - one or more repetitions
{n,m}  - from n to m repetitions

()     - subexpression (can be used for repetitions and also for backreferences)
|      - alternative: occurrence of the expression given on the left side or the expression given on the right side
```

The use of `-E` and `-P` switches is related to the evolution of regular expression syntax while maintaining compatibility with previous versions of the `grep` command.
If something was treated as a regular character, it couldn’t simply become a special one without applying protection with a backslash or selecting a different syntax variant using an appropriate option. As a result, `grep '^.\?*'` is the same as `grep -E '^.?*'`, and `grep '^.?*'` is the same as `grep -E '^.\?*'`.

## sed and other text-processing tools

* `sed [options] [files]` – edits a file according to the given commands, useful options include:
	* `-e "command"` - execute a command on the file (can be used multiple times to pass several commands)
	* `-f "file"` - read commands from the given file
	* `-E` - use extended regular expressions
	* `-i` - modify the given file instead of printing the changed version to stdout
	* `-n` - disables default line printing, printing must be explicitly done with the `p` command
. some useful commands (sed is a fairly comprehensive tool that functions almost like a programming language interpreter with somewhat unusual syntax, and it isn't limited to just these simple cases):
	* `s@regexp@text@[g]` - search for matches to the regular expression `regexp` and replace them with `text`, providing the `g` option will replace all occurrences, not just the first one; the `@` character serves as a separator, and other characters can be used instead of it
	* `y@set1@set2@` - replace characters from `set1` with the corresponding characters from `set2`; the `@` character serves as a separator, and other characters can be used instead of it
. it is also possible to address specific lines where the operation should be performed, e.g., `0,/regexp/ s@regexp@text@` will apply the `s` command to lines from the beginning of the file up to the line matching the regular expression `regexp`, i.e., it will replace only the first occurrence in the file

* `tail [options] [file]` – displays the last lines of a file, useful options:
	* `-n x` specifies that the last `x` lines should be displayed
	* `-f` enables appending (new lines added to the file will be displayed)
* `head [options] [file]` – displays the first lines of a file, useful options:
	* `-n x` specifies that the first `x` lines should be displayed

* `diff path1 path2` – compares files or directories (in the latter case, it compares files with the same names and reports files that exist in only one of the directories), useful options:
	* `-r` process the specified directories recursively
	* `-u` outputs differences in "unified" format
	* `-c` outputs differences in "context" format
* `vimdiff path1 path2` – compares files by displaying them side by side (similar to `diff` with the `-y` option), but also allows for editing those files
* `patch` – applies a patch file (the result of a diff) to modify files, typically:
	`patch -pn < file.diff`, which applies the changes described in `file.diff` to the files in the current directory, where `n` specifies the number of path levels in the patch file to ignore

* `sort [file]` – sorts the lines in the specified file, useful options:
	* `-n` treats numbers as numeric values rather than strings
	* `-i` ignores case
	* `-r` reverses the sort order
	* `-k n` sorts by column `n`
	* `-t sep` specifies that columns are separated by the `sep` character
* `uniq` – removes duplicate lines from a sorted file, useful options:
	* `-c` prints the number of occurrences
	* `-d` prints only lines with 2 or more occurrences
	* `-u` prints only lines with 1 occurrence

* `cut [options] [files]` – selects the specified set of columns from a file, useful options:
	* `-f nnn` selects columns specified by `nnn` (e.g., 1,3-4,6- selects column 1, columns 3 to 4, and from column 6 onwards, while -3 selects the first 3 columns)
	* `-d sep` specifies that columns are separated by the `sep` character (which must be a single-byte character; to bypass this limitation, use `awk`)
* `paste` – merges (corresponding by row numbers) lines from two files
* `join` – merges lines from two files based on a comparison of the specified field
* `comm` – compares two sorted files by the uniqueness of their lines (it can print common lines or those unique to each file)

## Signals and Keyboard Shortcuts
---------------------------

### kill

The `kill` command by default sends the `SIGTERM` signal, which is a request to terminate the process (the process may respect it or not, for example, by ignoring it). So `kill` itself does not kill the process.

Many signals can be caught and handled (or ignored) by the process to which they are addressed. However, some signals cannot be handled or ignored, such as:
	`SIGKILL` (terminates the process without giving it any chance to do anything upon exit, sent with `kill -9`),
	`SIGSTOP` (pauses the process).

### Ctrl+C / Ctrl+Z / Ctrl+D

**Ctrl+C** sends the `SIGINT` signal to the process occupying the terminal where it was entered. This signal is a request to terminate the process, which the process may or may not respect (for example, it might ignore it or ask for confirmation). It is similar to `SIGTERM`, but is a different signal and may be handled differently (for example, it usually doesn’t make sense to ask for confirmation for `SIGTERM`).

**Ctrl+Z** sends the `SIGTSTP` signal to the process occupying the terminal where it was entered. This signal requests to pause the process and release the terminal; the process may ignore this request. A process paused in this way can be resumed with the `fg` command (bringing it to the foreground to occupy the terminal) or the `bg` command (resuming it as a background process, giving control of the terminal back to the previous foreground process).

**Ctrl+D** does not send any signal. It works only when the process is reading data from the terminal (usually connected to its standard input). It sends the EOT (End-of-Transmission) character to the terminal, which results in:

* (if the input buffer is non-empty) the terminal pushing the input buffer to the program (as if a newline had been entered), or
* (if the buffer is empty) the terminal closing the input stream to the program.

The program does not receive the EOT character in its input stream (it is intercepted by the terminal).
Closing the input stream generally leads to the program terminating, although (unlike Ctrl+C) it allows the program to process the entered data normally.

### Ctrl+S / Ctrl+Q

**Ctrl+S** pauses terminal scrolling (refreshing), to resume it, use **Ctrl+Q**.
