<!--
SPDX-FileCopyrightText: Robert Ryszard Paciorek <rrp@opcode.eu.org>
SPDX-License-Identifier: MIT

Document translated automatically using AI (chat GPT). Required verification of correctness.
-->

## Running code

Python code can be created and executed in the command line of the interpreter. Longer Python code fragments are often more conveniently written in a text file rather than directly in the command line. Such a file can be executed using the command: `./filename` provided it has execution rights (it should also contain a comment in the first line specifying the program used to interpret the executable text file, in the form of: `#!/usr/bin/python3` or `#!/usr/bin/env python3`). It can also be executed using: `python3 filename`.

The command `python3 -i filename` (option `-i`_ allows access to the interpreter in the state after executing the commands from the file `filename`).

### Scripts

A file containing shell commands is called a script. Executing a shell script starts from its first line. A script can accept any number of positional parameters, which are available in the `sys.argv` array.

```Python
#!/usr/bin/env python3

import sys

print("Hello World")
print(sys.argv)

exit(0)
```

* Text from `#` to the end of the line constitutes a comment, i.e., information for the programmer (e.g., a description of the algorithm's operation) ignored by the compiler
	* A comment in the first line starting with `!` is a controlling comment specifying the program to be used to interpret the code from the text file
* The `import` command is used to import a Python module (these are parts of the standard library and other libraries also created by us)
	* In this case, a part of the standard library is being imported
* The `print` function prints the text specified in the arguments to the standard output
* The `exit` function terminates the script, setting the value provided in the argument as the return code. Using it at the end of the script (as in this example) is not mandatory


## Documentation

Python has a built-in documentation system, to use it you should call the `help` function on the function, type, etc., whose documentation you want to see, e.g., `help(print)` will print the documentation for the `print` function, `help(sys)` (after `import sys`) will print the documentation for the `sys` module.


## Variables

```Python
# dynamic typing - the type is determined
# based on the value assigned to the variable

number_variable = -91.7
string_variable = "qa z"
```

Basic operations
-------------------

```Python
a = 12.7
b = 3
x = 5
y = 6

# addition, multiplication, subtraction are written
# and operate as in normal mathematics:
e = (a + b) * 4 - y

# floating point division
c = x / y

# integer division
b = a // b

# remainder of division
z = x % y;

# printing the results
print(e, c, b, z)

# logical operations:
# ((a greater than or equal to 0) AND (b less than 2)) OR (z equals 5)
z = (a>=0 and b<2) or z == 5;
# logical negation of z
x = not z;

print(z, x);

# binary operations:
# bitwise OR 0x0f with 0x11 and shift the result left by 1
x = (0x0f | 0x11) << 1;
# bitwise XOR 0x0f with 0x11
y = (0x0f ^ 0x11);
# bitwise negation of the bitwise AND result of 0xfff and 0x0f0
z = ~(0xfff & 0x0f0);

print(hex(x), hex(y), hex(z & 0xffff));
# when printing z we need to specify its bitness

# multi-argument assignment operation
# can be used to swap values between two variables
# without explicitly using a temporary variable
print(a, b)
a, b = b, a
print(a, b)
# of course, it can handle more than two variables
```

Loops and Conditions
--------------------

Code blocks in Python are distinguished using indentation.

```Python

```Python
i, k, j = 0, 0, 0 # multiple assignment
# it first evaluates the expressions on the right, then assigns.
# Allows for a, b = b, a for swapping variable values

# conditional if - else statement
if i<j :
	print("i<j")
elif j<k :
	print("i>=j AND j<k")
else:
	print("i>=j AND j>=k")

# basic logical operators
if i<j or j<k:
	print("i<j OR j<k");
# other logical operators include and and not

# for loop
for i in range(2, 9):
	if i==3:
		# skip this iteration of the loop
		continue;
	if i==7:
		# exit the loop
		break;
	print(" a:", i)

# while loop
while i>0 :
	i = i - 1;
	print(" b:", i)
```


Functions
---------

```Python
# function without arguments, returning a value
def f1():
	print("AA")
	return 5

a = f1()
print(a)

# function accepting one mandatory
# argument and two optional ones
def f2(a, b=2, c=0):
	print(a**b+c)

f2(3)
f2(3, 3)
# any of the arguments with a default value can be omitted
# by referring to the remaining ones by name
f2(2, c=1)
# arguments can be provided in any order
# by referring to them by name
f2(b=3, a=2)


# undefined number of positional arguments
def f(*a):
	for aa in a:
		print(aa)

f(1, "y", 6)
# but not: f(1, "y", u="p")

# undefined number of named arguments
def f(**a):
	for aa in a:
		print(aa, "=", a[aa])

f(a="y", u="p")
# but not: f(1, u="p")

# undefined number of positional and named arguments
def f(*a1, **a2):
	print(a1)
	print(a2)

f(1, "y", 6)
f(a="y", u="p")
f(1, "y", u="p")

# you can also enforce a number of explicit arguments
def f(x, *a1, y="8", **a2):
	print(x, y)
	print(a1)
	print(a2)

f(1, "y", 6)
f(1, "y", u="p")
f(1, "z", y="y", u="p")
# but not: f(a="y", u="p")
```


Containers
----------

### Lists (arrays)


```Python
l = [ 3, 5, 8 ]

# append an element to the end
l.append(1)

# insert an element at position 2
l.insert(2, 13)

print("number of elements =", len(l))
print("first =", l[0])
print("next two =", l[1:3])

# printing all elements
for e in l:
	# we can modify the variable "e",
	# but it will not affect the list
	print(e)

# alternative iteration through the elements
# (allows modifying them)
for i in range(len(l)):
	l[i] = l[i] + 1
	print(l[i])

# we can also obtain a list based on performing some
# operations on a given list as a one-liner:
l = [a * 2 for a in l]
# such a list can be assigned to another
# or (as above) to the same variable

# get and remove the last element
print("the last one was:", l.pop())
print("the last one was:", l.pop())

# get and remove an element at a specific position
print("the second element was:", l.pop(1))

# print the entire list
print(l)
```

### Dictionaries

```Python
m = { "ab" : 11, "cd" : "xx" }
x = "e"
m[x] = True;

# get keys only
for k in m:
	print (k, "=>", m[k])

# check existence 
if "ab" is in m:
	print ("ab exists")
	# remove element
	del m['ab']

# modify value
m["cd"] = "oi"

# get key-value pairs
for k,v in m.items():
	print (k, "=>", v)
```

Strings
-------

A string in Python is a sequence of characters enclosed in either double or single quotes (there is no difference between the two). Triple quotes allow for the definition of multiline strings (which can also contain single or double quotes within the text).

```Python
x = "abcdefg"
y = "aa bb cc bb dd bb ee"
z = "qw=rt"

# print the length of the string
print(len(x))

# print the substring from index 2 to the end
# and from the start to index 3
print(x[2:], x[0:3])

# print the last character and the last three characters
print(x[-1], x[-3:])

# print every third character from the string and the string in reverse
print(y[::3], x[::-1])

# search for the substring "bb" in y starting at index 5
print(y.find("bb", 5))

# comparison
if x == "a":
	print("x == \"a\"")

# check if "ab" is a substring of x
if "ab" in x:
	print ("'ab' is a substring of:", x)

# check if "ba" is a substring of x
if "ba" in x:
	print ("'ba' is a substring of:", x)

# in Python modifying a string using indexing, e.g.
# x[2]="X" 
# does not work

# you can, however, convert it to a list:
l = list(x)
# alternatively:
# l = []
# for c in x:
#     l.append(c)
# or:
# l = [c for c in x]

l[1] = "X"
l[3] = "qqq"
del l[5]
print("".join(l))

# or, if there are fewer modifications:
print(x[:2] + "XXX" + x[3:])

# you can also modify and append to a new string
s = ""
for c in x:
	if c == "a":
		s += "AA"
	else:
		s += c

print(s)

# using the split() method, you can split a string
# into a list of strings with any separator
print(y.split(" "))
print(y.split(" cc "))
```

### Converting Numbers to Strings

```Python
# convert numbers to strings in binary, octal, decimal, and hexadecimal systems
print(bin(7), oct(0xf), str(0o10), hex(0b11))

# numbers are displayed in:
# decimal, hexadecimal, octal, and binary systems
# denoted by the absence of a prefix and the prefixes "0x", "0o", "0b"

# alternatively, you can use printf-style formatting (without binary):
s = "0o%o %d 0x%x" % (0xf, 0o10, 0b11)
print(s)
```

### Character-to-Number Conversion and Character Encoding

```Python
# getting characters using their Unicode code points
# - the chr() function returns a string made up of the character at the given code point
# within strings, you can also use \uNNNN where NNNN is the character code
# or simply place the character in a UTF8-encoded file
print(chr(0x21c4) + " == \u21c4 == ⇄")

# the ord() function converts a one-character string to its Unicode code point
print(hex(ord("⇄")), hex(ord("\u21c4")), hex(ord(chr(0x21c4))))

# Python uses Unicode for string handling, but before
# sending a string to the outside world, it may be necessary
# to convert it to a specific byte form (using the appropriate encoding)
# this is done using the encode() method, e.g.
a = "aąbcć ... ⇄"
inUTF7 = a.encode('utf7')
inUTF8 =  a.encode() # or a.encode('utf8')
print("'" + a + "' in UTF7 is: " + str(inUTF7))
print(" and is of type: " + str(type(inUTF7)))

# 'bytes' objects can be decoded back into strings
print("decoded UTF7: " + inUTF7.decode('utf7'))

# or further converted, e.g. to base64 encoding:
import codecs
b64 = codecs.encode(inUTF8, 'base64')
print("the UTF8 string encoded in base64 is: " + str(b64))
```

### Regular Expressions

In string processing, regular expressions are often used to match strings to a pattern they describe, search for, or replace that pattern. The typical, basic syntax of regular expressions includes the following operators:

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

```Python
import re

if re.search("[dz]", x):
	print(x, "contains 'd' or 'z'")

# replacing (any non-empty sequence of 'b' or 'c' letters with "XX")
print(re.sub('[bc]+', "XX", y))

# the fourth (optional) argument specifies how many replacements to make
print(re.sub('[bc]+', "XX", y, 2))

# substitution using backreferences
# \\2 will be replaced by the second sub-expression,
# i.e., the part in parentheses
print(re.sub('([bc]+) ([bc]+)', "X-\\2-X", y))

# we also control the greediness of regular expressions:

print(re.sub('bb (.*) bb', "X \\1 X", y))
# "bb (.*) bb" matched the longest possible fragment: "cc bb dd"

print(re.sub('.*bb (.*) bb.*', "\\1", y))
# "bb (.*) bb" matched only "dd", as the longest possible fragment
# was matched by the preceding ".*"

print(re.sub('.*?bb (.*) bb.*', "\\1", y))
# "bb (.*) bb" matched the longest possible fragment,
# as it was preceded by the non-greedy version of ".*?"

# After each repetition operator (. ? + {n,m}), you can add
# a question mark (.? ?? +? {n,m}?) to indicate that it should match
# the smallest possible fragment, i.e., to act non-greedily.
```


Files
-----

```Python
# opening a file for reading
f = open("/etc/passwd", "r")
# the function allows specifying the file's encoding via the
# "encoding" named argument (e.g., encoding='utf8'),
# the default encoding depends on the system's locale settings
# which can be checked with locale.getpreferredencoding()
#
# if the file is to be opened in binary mode instead of text mode,
# it is necessary to add the 'b' flag as part of the second argument

# read a single line
l1 = f.readline()
l2 = f.readline()

# you can also read using explicit iterators:
li = iter(f)
l3 = next(li)
l4 = next(li)

print("l1: " + l1 + "l2: " + l2 + "l3: " + l3 + "l4: " + l4)

# or in a loop
i = 5
for l in f:
	print(str(i) + ": " + l)
	i += 1

# return to the beginning of the file
f.seek(0)

# read all lines into a list
ll = f.readlines()

print(ll)

# once again ... as a single text
f.seek(0)
print(f.read())

f.close()
```

### Creating and Appending to File

```Python
import os.path

# if the file exists:
if os.path.isfile("/tmp/plik3.txt"):
	# open in read-write mode and seek to the end to append
	f = open("/tmp/plik3.txt", "r+")
	f.seek(0, 2)
else:
	f = open("/tmp/plik3.txt", "w")

# get the current position in the file
# (which in this case is equal to the length of the file)
pos = f.tell()

# if the file has more than 5 bytes
if pos > 5:
	# move back 3 bytes
	f.seek(pos - 3)

f.write("0123456789")

f.close()
```

### Binary Files

```Python
# handling binary files
# requires adding the 'b' flag to the open() function flags:
f = open("/tmp/plik1.txt", "rb")

# read byte by byte
while True:
	b = f.read(1)
	if b == b"":
		break
	print(b)

f.close()
```
