<!--
SPDX-FileCopyrightText: Robert Ryszard Paciorek <rrp@opcode.eu.org>
SPDX-License-Identifier: MIT

AI tools (chat GPT) have been used for text translation and editing.
-->

Basics of Programming in the "sh" Shell
=======================================

Running Code
------------

Shell code can be written and executed in the command line of the interpreter. For longer pieces of shell code, it is often more convenient to write them in a text file than directly in the command line. Such a file can be executed using the command `./filename` as long as it has execution rights (it should also include a comment on the first line specifying the program used to interpret the executable text file, in the form of `#!/bin/bash` for Bash or accordingly for other types of sh). It can also be executed by calling `bash filename`, `zsh filename`, `sh filename` depending on which shell you want to use.

A useful alternative to the above methods of executing code contained in a file is to include it in the current Bash session using `. ./filename`. Unlike the previous methods, the code will be executed in the current shell instance, allowing the use of functions and variables defined in that file in subsequent commands.

### Scripts

A file containing shell commands is called a script. Script execution starts from the first line. The script can take any number of positional parameters. The number of parameters is found in the variable `$#`, the list of all parameters in `$@`, and individual parameters can be accessed using `$1`, `$2`, etc.

```bash
#!/bin/bash

echo "called with $# arguments, the arguments are: $@"
echo "the first argument is $1"

# the script can only return a numeric value -- the so-called return code
exit 0
```

The above code, after being saved in a script.sh file, can be run via `bash script.sh argument_A argument_B`.

* The text from `#` to the end of the line is a comment, i.e., information for the programmer (e.g., a description of the algorithm’s operation), ignored by the compiler.
	* The comment on the first line, starting with `!`, is a control comment that specifies the program to be used for interpreting the code from the text file.
* The `echo` command prints the text specified in the arguments to standard output.
* The `exit` keyword terminates the script and sets the return code, though its use at the end of a script (as in this example) is not mandatory.

Documentation
-------------

Information about commands that are separate programs can be obtained from the built-in help system using the `man` or `info` / `pinfo` commands. Information about built-in Bash commands can be accessed via the `` command (e.g., `help while`), and for zsh, through `man zshbuiltins`.


Variables
---------

In Bash, the type of variables is determined based on the value in the variable. Essentially, all variables are strings, and type interpretation occurs when they are used (rather than when they are created). Integers and strings are supported, but Bash does not have built-in support for floating-point numbers.

```bash
variableA=-91
variableB="qa   z"
variableC=98.6  # this will be treated as a string, not a number
```

Note the lack of spaces between the variable name and the equals sign in the assignment operation – this is a syntactic requirement. It results from the significance of spaces in shell syntax – they separate command names and arguments, playing a key syntactic role, similar to parentheses and commas in other programming languages used to separate function names and arguments.

A variable is referenced using the dollar sign (`$`), followed by the variable name. The name can be enclosed in curly braces, but it’s not necessary (this is useful when you don’t want to add spaces between the variable name and, for example, part of a string). Variable names in strings enclosed in double quotes are expanded. Placing a variable reference in double quotes preserves whitespace (spaces, newlines) when passing it to functions and programs (including passing it to echo for printing).

```bash
echo $variableA ${variableA}AA
echo "$variableA ${variableA}AA"
echo '$variableA ${variableA}AA'
```

If we want the variable to be visible to programs launched from this shell (including future Bash instances responsible for executing script code from a file), we need to export it using the `export variableA` command (note the lack of a dollar sign here). Such a variable becomes an environment variable accessible to all child processes of this shell.

Environment variables can also be set without using `export` for a single new program by specifying their names and values before the command name:

```bash
ABCD=678 bash -c 'echo $ABCD'
ABCD=135 EFG=098 bash -c 'echo $ABCD $EFG'
echo $ABCD
```

They are only visible in the newly launched process (and cannot be used in the current shell or as arguments in the command line). Therefore, in the above examples, a new shell is invoked, which uses the variables set this way. This method of setting variables is particularly useful when you want to run a single command in a changed environment – for example, the `date` command in a different time zone: `TZ=America/New_York date`.

### printf

To print variable values, the `printf` command, which is equivalent to the C language function of the same name, can also be used:

```bash
x=13.123
printf "%.2f\n" $x
```

### Undefined Variables

Referencing an undefined variable is not reported as an error; such a variable has the value of an empty string.

```bash
echo "AAA $undefined_variable BBB"
```

However, it’s important to remember that an empty string will be treated differently when inside quotation marks compared to when it’s not (then it is ignored as a command argument).

```bash
printf "> %s < %s\n" $undefined_variable BBB
printf "> %s < %s\n" "$undefined_variable" BBB
```

Basic Operations

To perform arithmetic operations, you need to enclose them within `$((` and `))`. Addition, multiplication, and subtraction are written and work just like in normal mathematics, while division is written using a forward slash and is always integer division:

```bash
a=12; b=3; x=5; y=6

e=$(( ($a + $b) * 4 - $y ))
c=$((  $x / $y ))

echo $e $c
```

Arithmetic operations can also be performed using the `let` command. It is most commonly used to increment a given variable, as in the example below.

```bash
echo $a
let a++
echo $a
```

Both the double parentheses operator and the `let` command can handle logical expressions. However, logical operations are most commonly handled using the `test` command or the ```[ ]``` operator, and the result is returned as a *return code*. Note the escape of parentheses with a backslash and that spaces are significant. Negation is done using `!`, though it's important to remember that the result of negating any number is FALSE.

```bash
a=12; b=3; c=4

[ \( $a -ge 0 -a $b -lt 2 \) -o $c -eq 5 ]; z=$?

echo $z
```

The value of the variable `z` is the result of the condition: `((a greater or equal to zero) AND (b less than two)) OR (c equal to 5)`. It was returned as a *return code*, which is accessible (for the last executed command) via `$?`. The value of this variable was assigned to the variable `z`. Return codes follow inverted logic: 0 means true, anything non-zero means false.

### Executing Other Programs

Basic operations also include executing other programs and retrieving their standard output and/or return code. Standard output can be captured by enclosing the command in *backquotes* or using the `$( )` operator (which allows for the nesting of such operations). The return code of the last command is stored in the `$?` variable.

```bash
a=`cat /etc/issuse`
b=$(cat /etc/issuse; cat /etc/resolv.conf)

echo  $a
echo  $b
echo "$b"
```

Note the difference when printing a variable containing newlines with and without quotes.

Bash does not support floating-point numbers; unsupported operations can be performed using another program, e.g.:

```bash
a=`echo 'print(3/2)' | python3`
b=$(echo '3/2' | bc -l)
echo $a $b
```

Shell programming largely involves calling other programs (e.g., sed, grep, find, awk). The shell itself only offers basic syntax constructs, variable handling, and some basic operations on them.

You can think of these external commands as libraries in other programming languages – commands guaranteed by the standard form the "standard library" of Bash, while others (e.g., Python used in the floating-point arithmetic example above) are additional optional "libraries" that make solving problems easier and faster. Similarly, external program calls can be viewed within Python, C, or other languages (sometimes it's easier to do something like `system("mv file newfile")` than to code it directly in Python or C).


Loops and Conditions
--------------------

### For Loop

In Bash, we can use several variants of the for loop. One of the most commonly used is iterating over a list of items, often a list of files:

```bash
for name in /tmp/* ; do
	echo $name;
done
```

It's also possible to iterate over integers, both in a "shell style" and in a C style:

```bash
for i in `seq 0 20`; do
	echo $i;
done

for (( i=0 ; $i<=20 ; i++ )) ; do
	echo $i;
done
```

### While loop

A `while` loop repeats as long as the condition provided inside it is true:

```bash
x=0
while [ $x -le 2 ]; do
	echo $x;
	x=$(($x+1));
done
```

### while - read

A `while` loop is often used together with the `read` command, allowing line-by-line processing of some input (either from a command or file, splitting the line into words):

```bash
cat /etc/fstab | while read word rest; do
	echo $rest;
done
```

The above loop will print all lines from the `/etc/fstab` file passed through stdin (via the `cat` command) one by one, skipping the first word (which was read into the `slowo` variable).

The `read` command can also be used to read user input into a variable – for example, `read -p "Enter something >> " xyz` reads text into the variable `xyz`. The `read` command with the `-e` option can use the readline library, but it shares the history with bash, so using `rlwrap` might be more convenient. For example: `xyz=$(rlwrap -H history.txt -S "Enter something >> " head -n1)`.

#### Dead cats

Passing data to a `while-read` loop via stdout → stdin from another program is often used for filtering or sorting data. However, using `cat` in this context is redundant (referred to as a "dead cat") and should be avoided. A better solution is to pass the file by redirecting the input stream using `< file`, which should appear after the `done` keyword ending the loop. This approach saves resources and execution time by not creating an extra process for the `cat` command.

#### Stream redirections and variables

Redirecting stdout to stdin happens between two different processes. Therefore, in constructs like `while-read`, the `while` loop may run in a child process of the current shell. As a result, in some cases, variable modifications inside such a loop won’t be visible outside of it.

An example of such a situation is the following code (with the `ps` command added to show the creation of a child process):

```bash
zm=0; ps -f
cat /etc/fstab | while read x; do
	[ $zm -lt 1 ] && ps -f
	zm=13
done
echo $zm
```

However, an analogous code that uses redirection from a file will work correctly:

```bash
zm=0; ps -f
while read x; do
	[ $zm -lt 1 ] && ps -f
	zm=13
done < /etc/fstab
echo $zm
```

If the loop should receive the output of a command, we can use bash's syntax to substitute the result of a command as a file, in the form of `<(command)`, along with file redirection. For example:

```bash
zm=0; ps -f
while read x; do
	[ $zm -lt 1 ] && ps -f
	zm=13
done < <$(cat /etc/fstab)
echo $zm
```

Notice the space between the two `<` characters and the lack of space between the second `<` and the dollar sign.

Another option is to use the return code to retrieve values from inside the loop:

```bash
zm=0; ps -f
my_code() {
	while read x; do
		[ $zm -lt 1 ] && ps -f
		zm=13
	done;
	return $zm;
}
cat /etc/fstab | my_code
zm=$?
echo $zm
```

Here, a function (`my_code`) was defined. You can find more information about functions in the relevant section below.

#### Word separator

By default, words are separated by any sequence of spaces or tabs. You can change this separator using the `IFS` variable, for example:

```bash
IFS=":"
while read a b c; do echo "$a -- $c"; done < /etc/passwd
unset IFS # restores the default behavior of read by unsetting the IFS variable
```

Remember that the quotation marks around the `c` variable output are important – without them, the colon might be replaced by spaces.

Instead of modifying the `IFS` variable, you can set the value of this environment variable for a single program call (like the `read` command):

```bash
while IFS=":" read a b c; do echo "$a -- $c"; done < /etc/passwd
```


### if statement

The logical expression evaluation you learned earlier is most commonly used in the conditional `if` statement.

```bash
# if - else statement
if [ "$xx" = "cat" -o "$xx" = "dog" ]; then
  echo "cat or dog";
elif [ "$xx" = "fish" ]; then
  echo "fish"
else
  echo "something else"
fi
```

Notice that spaces around and inside the square brackets are syntax-relevant. The content inside the brackets is passed as arguments to the `test` command. Apart from typical logical conditions, you can check for file existence, file types (link, directory, etc.). A detailed description of available conditions that can be used in this construct is found in the `man test` page.

Any command can be used as a condition, where the return code is checked (0 means success/true, and a non-zero value indicates false/error).

```bash
if grep '^root:' /etc/passwd > /dev/null; then
	echo /etc/passwd contains root;
fi
```

You can use a shorter syntax for conditions by chaining commands using `&&` (execute if the previous command returned zero -- true) or `||` (execute if the previous command returned a non-zero value -- false):

```bash
[ -f /etc/issue ] && echo "The file /etc/issue exists"

grep '^root:' /etc/passwd > /dev/null && echo "/etc/passwd contains root";
```

### case statement

The `case` statement is used to consider multiple cases based on the equality of a variable to given strings.

```bash
case $xx in
  cat | dog)
    echo "cat or dog"
    ;;
  fish)
    echo "fish"
    ;;
  *)
    echo "something else"
    ;;
esac
```

Functions
---------

In `sh`, each function can take any number of positional parameters (just like command-line arguments for the entire script). The number of parameters is stored in the `$#` variable, a list of all parameters in `$@`, and you can access individual parameters using `$1`, `$2`, etc.

```bash
f1() {
	echo "called with $# parameters, the parameters are: $@"
	
	[ $# -lt 2 ] && return;
	
	echo -e "second: $2\nfirst: $1"
	
	# or iterate through the next ones in a loop
	for a in "$@"; do  echo $a;  done
	
	# or using the shift command
	for i in `seq 1 $#`; do
		echo $1
		shift # forgets $1
		      # and re-numbers positional arguments by 1
		      # affects values of $@, $#, etc.
	done
	
	# a function can only return a numerical value -- the so-called return code
	return 83
}
```

Note that you don’t specify accepted arguments in parentheses after the function name. However, these empty parentheses are part of the syntax and must be included. If you write the function definition in one line, for example, `abc() { echo "abc"; }`, remember that a space after the opening curly brace is mandatory, as is a semicolon after each command inside the function, including the last one.

Calling a function is no different from calling a program or built-in command
(you can use stream redirections or capture output into a variable). You can call the above function, for instance, like this: `f1 a "b c"   d`.

### Command grouping

Functions are an example of command grouping – a function is a named block of code, or a named group of commands. You can also group commands without defining a function. For this purpose, you can use curly braces (just like in a function definition) or parentheses.

When using curly braces, remember (just like with functions) to include a space after the opening brace and a semicolon (or a new line) before the closing brace. The commands inside curly braces will execute in the current shell, meaning they can modify variables.

Commands inside parentheses will be executed in a subshell, meaning any variables set or modified inside won’t be visible after the block ends. Parentheses don’t require spaces or the final semicolon.

```bash
a=0;
{ echo abc; a=1; }
echo $a
(echo abc; a=2)
echo $a
```

Command grouping is useful, for example, for combining commands with operators based on return codes (`&&` and `||`), as well as redirecting the output of multiple commands into a single stream.

```bash
a=0;
{ echo AbC; echo abc; echo XyZ; a=1; } | grep b
echo $a
```

Notice that in this case, curly braces behave like parentheses – the modification of variable `a` is not visible after the block ends. This is due to the stream redirection, similar to the situation discussed with the `while` loop.


### Text processing

#### grep, cut, sed, ...

Since most operations in a shell like bash involve running external programs, text processing can also be done this way. One approach to handling text in bash is to use standard POSIX commands such as `grep`, `cut`, `sed`.

```bash
# calculating the length of a string in characters, in bytes, and the number of words
echo -n "aąbcć 123" | wc -m
echo -n "aąbcć 123" | wc -c
echo -n "aąbcć 123" | wc -w

# counting the number of lines (more precisely the number of newline characters)
wc -l < /etc/passwd

# print the 5th field (delimited by :) from the /etc/passwd file, filtering out
# empty lines and lines consisting only of spaces and commas
cut -f5 -d: /etc/passwd | grep -v '^[ ,]*$'
# the cut command selects the specified fields, the -d option specifies the separator
```

Another very useful command is `sed`, which allows, among other things, replacing text matched by a regular expression with another text:

```bash
echo "aa bb cc bb dd bb ee" | sed -e 's@\([bc]\+\) \([bc]\+\)@X-\2-X@g'
```

The `s` command in `sed` takes three arguments (which can be separated by any character following `s`), the first is the search pattern, the second is the replacement text, and the third, if `g`, replaces all occurrences rather than just the first one.

Be aware of the difference in regular expression syntax, where parentheses `(`, `)`, and plus `+` need to be escaped with a backslash to have special meaning. If you don’t want to do this, you can enable ERE in `sed` with the `-E` option.

Other useful commands for processing text (specific to file paths) are `basename` and `dirname`.
They are used to get the name of the deepest element of a path and the path without the deepest element. See the result of the following:

### Built-in string processing in bash

Built-in string processing in bash uses variable references in the form of `${}`:

* `${variable:-"string"}` returns the string if the variable is not defined or is empty.
* `${variable:="string"}` returns the string and assigns the variable to "string" if the variable is not defined or is empty.
* `${variable:+"string"}` returns the string if the variable is defined and not empty.
* `${#str}` returns the length of the string in `str`.
* `${str:n}` returns a substring from `str` starting at index `n`.
* `${str:n:m}` returns a substring from `str` starting at index `n` with a length of `m`.
* `${str/"n1"/"n2"}` returns the value of `str` with the first occurrence of `n1` replaced by `n2`.
* `${str//"n1"/"n2"}` returns the value of `str` with all occurrences of `n1` replaced by `n2`.
* `${str#"ab"}` returns the value of `str` with "ab" removed from the start.
* `${str%"fg"}` returns the value of `str` with "fg" removed from the end.
* `${!x}` returns the value of the variable whose name is stored in `x`.

In these substring removal operations, shell wildcard characters (`*`, `?`, ```[abc]```, etc.) can be used. The `#` and `%` operators match the shortest substring to be removed, while the `##` and `%%` operators match the longest substring to be removed.
Note that many of these expressions are bash extensions, not available in standard `sh` syntax.

Example:

```bash
a=""; b=""; c=""
echo ${a:-"aa"} ${b:="bb"} ${c:+"cc"}
echo $a $b $c

a="x"; b="y"; c="z"
echo ${a:-"aa"} ${b:="bb"} ${c:+"cc"}
echo $a $b $c

x=abcdefg
echo ${#x} ${x:2} ${x:0:3} ${x:0:$((${#x}-2))}
echo ${x#"abc"} ${x%"efg"}
echo ${x#"ac"}  ${x%"eg"}

x=abcd.e.fg
echo ${x#*.} ${x##*.} ${x%.*} ${x%%.*}

y="aa bb cc bb dd bb ee"
echo ${y/"bb"/"XX"}
echo ${y//"bb"/"XX"}
```


### awk

Awk is a simple scripting language interpreter for processing text-based databases in the form of *line == record*, where fields are separated by a defined delimiter (it can be said that it combines functionalities of commands like grep, cut, sed with a simple programming language).

The above example of printing the 5th field (delimited by :) from the `/etc/passwd` file, filtering out empty lines and lines made up only of spaces and commas, achieved using `cut` and `grep` commands, can be done with just awk:

```bash
awk -F: '$5 !  "^[ ,]*$" {print $5}' /etc/passwd
```

Awk offers great flexibility when processing such text-based databases. For example, we can print the first field based on conditions applied to other fields:


```bash
awk -F: '$5 !  "^[ ,]*$" && $3 >= 1000 {print $1}' /etc/passwd
```

As shown in the examples above, we refer to specific fields by using `$n`, where `n` is the field number, and `$0` refers to the entire record.

For each record, the program processes subsequent instructions in the form of `condition { commands }`, and there can be many such instructions in the program (processed sequentially). The `next` command ends the processing of the current record.

Field separators are set with the `-F` option (or the `FS` variable). The default field separator is any string of spaces and tabs (unlike cut, the separator can be a multi-character string or a regular expression). The default record separator is the newline character (it can be changed using the `RS` variable).

Awk is a simple programming language supporting basic loops, conditional instructions, and functions for searching and modifying strings:


`echo "aba aab bab baa bba bba" | awk '`
```awk
	# for each field in record
	for (i=1; i<=NF; ++i) {
		# if its index is even
		# replace all occurrences of "b" with a single "B"
		if (i%2==0)
			gsub("b+", "B", $i);
		
		# find the position of substring "B"
		ii = index($i, "B")
		# if found
		# print the position and the substring from that position to the end
		if (ii)
			printf("# %d %s\n", ii, substr($i, ii))
		# note that AWK counts from 1, not 0
	}
	print $0
```
`'`

AWK also supports associative arrays, allowing us to count word repetitions:

`echo "aa bb aa ee dd aa dd" | awk '`
```awk
	BEGIN {RS="[ \t\n]+"; FS=""}
	{words[$0]++}
	# there may be several `{}` blocks matching a record
	# if we don't use `next`, all of them will be processed
	# {printf("record: %d done\n", NR)}
	END {for (w in words) printf("%s: %s\n", w, words[w])}
```
`'`

A similar effect can be achieved by using "uniq -c" (which prints unique lines along with their counts) on a properly prepared string (spaces replaced by newlines, and the lines sorted):

```bash
echo "aa bb aa ee dd aa dd" | tr ' ' '\n' | sort | uniq -c
```

However, the awk solution can be easily modified to print the first occurrence of a line without sorting the file.

Another useful application of AWK might be to print a file without lines matching a pattern, and without the preceding lines:

`echo -e "aa\nbb\nWZORZEC\ncc" | awk'`
```awk
	/PATTERN/ {print_last=0; next}
	print_last == 1 {print last}
	{last=$0; print_last=1}
	END {if (print_last == 1) print last}
	
	# for a line matching the pattern, set the `print_last` flag to zero and move to the next line
	/WZORZEC/ {print_last=0; next}
	# if the `print_last` flag is not zero, print the saved previous line
	print_last == 1 {print last}
	# store the current line to be printed when processing the next one (if it doesn't match the pattern)
	{last=$0; print_last=1}
	# if we've reached the end of the file and there is a line to print, print it
	END {if (print_last == 1) print last}
```
`'`

AWK also allows defining functions:
```bash
awk 'function f(x) {return 2*x} { print f($1+$2) }'
```
