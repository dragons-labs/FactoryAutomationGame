<!--
SPDX-FileCopyrightText: Robert Ryszard Paciorek <rrp@opcode.eu.org>
SPDX-License-Identifier: MIT

AI tools (chat GPT) have been used for text translation and editing.
-->

File System
===========

The file system has a hierarchical (tree-like) structure and starts at the root, denoted by a slash: `/`. By navigating its subdirectories, their subdirectories, and so on, we can reach any file in the system. By recording the names of the directories we pass through and separating them from each other and from the file name using slashes, we create an absolute path to the file, which always starts from the root.

It is possible to express all paths from the root, but this is not always convenient. In many cases, we want to express a path relative to another directory, and for this, relative paths are used. The directory relative to which the relative path is expressed may be the directory containing the object or, more often, the current working directory.

## Working Directory

A command interpreter like *bash* operates somewhere within this file structure, and this location is called the current working directory (*Present Working Directory*). Paths not starting from the root are interpreted relative to it, and it can also be explicitly marked using a single dot.

The working directory (*Present Working Directory*) is set independently for each running program. Typically, its initial value is set to the working directory of the shell that launched the program. It can be changed by the running program using the appropriate system function.

In a shell compatible with `sh`, we can display the current working directory using the `pwd` command. It is often also shown before the prompt. We can change this directory using the `cd` command, followed by the path to the directory to be set as the working directory. This changes the directory relative to which relative paths will be interpreted in the shell and in programs launched after executing `cd`. This change does not affect programs that were previously launched and are still running in the background.

## Relative Paths

A relative path is any path that does not start from the root, i.e., does not begin with a slash.

In both absolute and relative paths, we can use a single dot (`.`) to represent the current directory and two dots (`..`) to represent the parent directory. In absolute paths, they are always redundant and therefore rarely seen, but in relative paths, they play a crucial role. Using two dots (`..`) multiple times (with a `/` separating them) allows us to navigate back up the directory tree even as far as the root and thus access any other file in our directory structure.

The single dot (`.`) is practically only useful at the beginning of a path (where it denotes the directory relative to which the relative path is interpreted, such as the current working directory). It is often used as the entire path to the current directory.

The name of a file or directory also constitutes a relative path (relative to the directory in which it is located), but sometimes the notation dot slash filename (`./filename`) is used, which more clearly suggests that we mean a path and not just a name. This is especially relevant when running programs located in the current directory because, in this case, a command name without a slash is not treated as a path.

## Hidden Files

Files (and directories) whose names begin with a dot (`.`) are treated as hidden and will not be shown by some programs by default.

## Links

Links are references to files using a different path or name. There are two types: hard links and symbolic links.

[img]Manual/Pages/programming/posix_filesystem/links_pl.svg[/img]

**Hard link** is another reference to the same data on the hard drive. There are multiple levels of access to the data on the hard drive — the physical location of the data, something simplified as a handle to the data (called an i-node), and a directory entry that specifies the file name and a reference to the appropriate handle (i-node).

The hard link `link1.txt`, shown in the illustration in red, was created with the command `ln file2.txt link1.txt` and is simply another reference to the same data as `file2.txt`. It is equivalent to the original reference to the data, meaning:

* Modifying the data using this link changes the shared data that both links point to, and the modification will also be visible through `file2.txt`. Similarly, modifying `file2.txt` will be visible through `link1.txt`.
* It can be used (and provides access to the data) even after the original file is deleted; the data will only be removed (or more precisely, marked as overwriteable) when the number of references to it drops to zero.

The number of links to a file is shown by the `ls` command with the `-l` option. Note the entries related to the dot and double dots — these are automatically created hard links to the current and parent directories, respectively. The number of links to `.` is 2 plus the number of subdirectories, and the number of links to `..` equals the number of links to the dot in the parent directory.

Because of the nature of hard links, they are limited to a single file system (device) where the data resides. Typically, hard links to directories are not allowed.

**Symbolic link** points to a specific path (relative or absolute — which can matter when moving the link) to any file or directory, even non-existent ones (in which case it's called a broken link). Because of this, symbolic links can point to files located on different devices or file systems. Symbolic links can be created to any objects in the file system, including directories.

A symbolic link, shown in blue in the illustration, is an entry in the directory structure that indicates that under a given name (in this example, `link2.txt`) there is a reference to another path (in this case, `./file1.txt`). It is essentially a reference to another path rather than the data itself.

A symbolic link functions similarly to a hard link, providing access to the same data through two different paths.

For symbolic link objects, the `ls` command will show the file type as `l`, and the reported size will reflect the length of the stored path — this is the amount of data the symbolic link contains. The disk usage (reported by `du`) for a symbolic link will be zero since the link does not occupy separate disk space; it only increases the size of the directory structure.

It’s important to note that symbolic links are not as similar to the object they point to as hard links are. Deleting the file a symbolic link points to or even changing the file’s location or name will result in the symbolic link becoming a broken link, and access to the data through the link will be lost. If the file the link points to is completely removed, meaning there are no files or hard links to it, the data will be deleted regardless of whether there were symbolic links pointing to it.

Also, keep in mind that:
* relative paths stored in a link are not interpreted relative to the current working directory or even the path used to access the link, but relative to the directory where the link is located.
* the `ln` command (used to create links) by default will record the path provided on the command line verbatim in the created link. This means we can create symbolic links to non-existent files, but we can also mistakenly create incorrect links.

## Wildcards

In a path description, we can also include certain special characters, allowing us to generalize the path to describe multiple files or a file whose exact location or name we don’t want to specify precisely. These special characters are shell wildcards (*glob*):

* `?`: any single character
* `*`: any sequence of characters (including an empty sequence)
* ```[a-z AD]```: any character from the set enclosed in square brackets, which can be defined using ranges (e.g., a-z AD means any lowercase letter from a to z, a space, or a capital letter A or D)
* ```[!a-z]```: any character except those specified in the set, which can be defined using ranges (e.g., a-z means any lowercase letter from a to z)

For example:

* `a[0-9]/*`: all (non-hidden) files and directories inside directories whose names consist of two characters, where the first character is `a` and the next is a digit.
* ```[^ad]*```: all (non-hidden) files and directories in the current directory whose names do not start with the letter a or d.
* `.[!.]*`: all hidden files and directories in the current directory (except for references to the current and parent directories).

**Note:** Wildcard characters are expanded (i.e., replaced with a list of matching paths) by the shell. Only in the case of no matches are they passed unchanged to the program being executed. However, some programs expect to receive and operate on wildcard characters. Sometimes, we also want to pass something as a command argument that is not a path but contains one of these characters. In both cases, to ensure proper command execution, regardless of whether matching files exist, the string containing these characters should be enclosed in quotes or apostrophes (or alternatively, use backslashes to escape these characters).

## Home Directory

A tilde (`~`) is often used in paths to represent the current user's home directory, or a tilde followed by a username (`~username`) to represent the home directory of the specified user. The home directory is intended for storing the user's files (both individual program configuration files and files created or collected by the user), as defined in the user's account configuration.

As with wildcard characters, if we need to pass a tilde as part of program arguments, we must protect it from being interpreted as a special character using quotes, apostrophes, or a backslash.
