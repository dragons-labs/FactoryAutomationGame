#!/usr/bin/env python3

# SPDX-FileCopyrightText: Robert Ryszard Paciorek <rrp@opcode.eu.org>
# SPDX-License-Identifier: MIT

# NOTE This is parser for custom format based on Markdown (it's not fully Markdown compatible)
# The most important non standard behavior:
#  - indent code blocks are not supported → use ``` block code instead
#  - empty line in list mode ends all lists ... use in-list code blocks without empty line before and after code blocks:
# 		* a1
# 			* b1
# 			* b2
# 		```
# 		block of code
# 		code
# 		```
# 			* b3
# 		* a2
#  - indent level of code blocks in list does not affect output indication level (it's always inherited from the list item where the block started)
#  - list indent is measured in chars, mixing space and tabs is allowed (tab == space)
#  - `→` and `–` are used as list item marks also
#  - `.` may be used to continue current level item after close sublist
# 		→ a1
# 			* b1
# 				* c1
# 				* c2
# 			. b1 continuation
# 			* b2
# 		→ a2
#  - `__` is used for underline (not for strong), single `_` is not markup character
#  - formatting via * ~ and _ ignore left/right-flanking delimiter run
#  - inline single ` code blocks (not inline ```) may use [lang] at begin to set code highlight in specific lang: `[python]x = 2**3`
#     - so content of square bracket opened at the very beginning of code block will be ignored in output code → use triple ` variant or add lang id, empty `[]` or space if code start with `[` 
#  - first line of multiline ``` code blocks (text between ``` and \n) is used as lang id, it may be or may be not enclosed in []
#  - quotes, link, images and tables syntax are not supported → use Godot BBCode syntax

import sys
sys.dont_write_bytecode = True

from pygments import highlight
from pygments.lexers import get_lexer_by_name
from pygments_bbcode import BBCodeGodotFormatter

import re

star = '(\x0f\\*)'
under = '(\x0f_)'
tilde = '(\x0f~)'

bold = re.compile(f'({star}{star})(.+?)\\1')
emph = re.compile(f'({star})(.+?)\\1')
underline = re.compile(f'({under}{under})(.+?)\\1')
strike = re.compile(f'({tilde})(.+?)\\1')

commnet = re.compile('<!--(.+?)-->')
commnet_not_closed = re.compile('^(.*)<!--.*')
commnet_not_opened = re.compile('.*-->(.*)$')

def copy_plain_text(text, start, end, format_chars_positions, start_in_comment, end_in_comment):
	if format_chars_positions:
		out_text = ""
		for i in range(start, end):
			if i in format_chars_positions:
				out_text += '\x0f'
			out_text += text[i]
	else:
		out_text = text[start:end]
	
	out_text = commnet.sub("", out_text)
	if end_in_comment:
		out_text = commnet_not_closed.sub("\\1", out_text)
	if start_in_comment:
		if commnet_not_opened.match(out_text):
			out_text = commnet_not_opened.sub("\\1", out_text)
		else:
			out_text = ""
	
	return out_text

def process_line(line, comment_is_open = False):
	##
	## - remove comments, and detect unclosed comments
	## - split line into text and code parts + detect un-escaped format chars
	##
	
	# we need not markdown format character at end of the line ... so add some
	if len(line) == 0 or line[-1] != '\n':
		line = line + '\x03'
	
	is_esc, code = False, False
	part_start = 0
	code_level, opened_code_level = 0, 0
	format_chars_positions = []
	line_splited = []
	code_mode = []
	start_in_comment = comment_is_open
	for i in range(len(line)):
		# block split into code in comment mode → comment will be single text part and will be removed in copy_plain_text
		if comment_is_open:
			if line[i-3:i] == "-->":
				comment_is_open = False
			continue
		elif not code and line[i:i+4] == "<!--":
			comment_is_open = True
			continue
		
		if not is_esc:
			# code - plain text split logic
			if code_level > 0 and line[i] != '`':
				if code and opened_code_level == code_level:
					# end of inline code block ... process plain text before code and code
					code = False
					line_splited.append( copy_plain_text(line, text_start, text_end-code_level, format_chars_positions, start_in_comment, comment_is_open) )
					line_splited.append( line[part_start:i-code_level] )
					code_mode.append(code_level-1)
					# start new part
					start_in_comment = comment_is_open
					part_start = i
					format_chars_positions.clear()
				elif not code:
					# begin of inline code block ...
					code = True
					opened_code_level = code_level
					# only remember previous plain text begin and current position (for future usage)
					# it will be extended if block is not closed
					text_start = part_start
					text_end = i
					# start new part
					part_start = i
			if line[i] == '`' and not is_esc:
				code_level += 1
			else:
				code_level = 0
			
			# remembering the position of formatting tags
			if line[i] in "~*_":
				format_chars_positions.append(i)
		
		# escape character logic
		if line[i] == '\\':
			is_esc = not is_esc
		else:
			is_esc = False
	if code:
		# line ended with not closed inline code block process all as plain
		part_start = text_start
	line_splited.append( copy_plain_text(line, part_start, len(line), format_chars_positions, start_in_comment, comment_is_open) )
	
	# we don't need remove '\x03' from end of last segment ... it will be removed in join/split operation in "process format sequences"
	# if len(line_splited) > 0 and len(line_splited[-1][-1]) > 0 and line_splited[-1][-1] == '\x03':
	# 	line_splited[-1] = line_splited[-1][:-1]
	
	##
	## process format sequences in text parts
	##
	
	# process * and ** into [i] and [b]
	text = "\x03".join(line_splited[0::2])
	text = bold.sub("\x0f[b]\x0f\\4\x0f[/b]\x0f", text)
	text = emph.sub("\x0f[i]\x0f\\3\x0f[/i]\x0f", text)
	# process __ into [u]
	text = underline.sub("[u]\\4[/u]", text)
	# process ~~ into [s]
	text = strike.sub("[s]\\3[/s]", text)
	
	# fix opening/closing order for [i] / [b]
	text = text.split("\x0f")
	b_open, i_open, b_close, i_close = -15, -15, -15, -15,
	for i in range(len(text)):
		if text[i] == "[b]":
			b_open = i
		elif text[i] == "[i]":
			i_open = i
		elif text[i] == "[/b]":
			b_close = i
		elif text[i] == "[/i]":
			i_close = i
		
		if b_close > 0 and i_close > 0:
			fix = 0
			if (b_open > i_open and b_close > i_close and i_close > b_open): # [i]_empty→fix=1_[b][/i]_empty→fix=2_[/b]
				if text[i_open+1] == "":
					fix = 1
				elif text[i_close+1] == "":
					fix = 2
			elif (b_open < i_open and b_close < i_close and b_close > i_open): # [b]_empty→fix=1_[i][/b]_empty→fix=2_[/i]
				if text[b_open+1] == "":
					fix = 1
				elif text[b_close+1] == "":
					fix = 2
			
			if fix == 1:
				text[i_open], text[b_open] = text[b_open], text[i_open]
				i_open, b_open = b_open, i_open
			elif fix == 2:
				text[i_close], text[b_close] = text[b_close], text[i_close]
				i_close, b_close = b_close, i_close
	
	# re-join text ... this (split/join) also remove non escape mark ("\x0f")
	text = "".join(text).replace('\\\\', '\\')
	
	# split line text into parts again (separated by code fragments)
	text = text.split("\x03")
	
	##
	## re-join line from text and code parts
	##
	output = ""
	for part_index in range(len(text)):
		output += text[part_index]
		code_part_index = 2*part_index+1
		if code_part_index < len(line_splited):
			output += code_higlight(line_splited[code_part_index].replace('\\\\', '\\'), code_mode[part_index])
	
	return output, comment_is_open


code_block_re = re.compile('^(\s*)```([^`]*)$')
first_world_format = re.compile('(\s*)(\\*|-|–|→|\\+|\\.|_|[0-9]+\\.|#{1,6})(\s+)(.*)$')
header = re.compile('^(---|===)')

def process_lines(lines):
	output, prev_line = "", ""
	comment_is_open = False
	
	code_block = None 
	list_types = []
	list_indent = 0
	hold_list_indent = False
	for line in lines:
		split_info = None
		if not comment_is_open:
			# process code blocks
			if code_block is None:
				code_block_info = code_block_re.match(line)
				if code_block_info:
					code_block_info = code_block_info.groups()
					output += prev_line
					prev_line = ""
					code_block = code_block_info[1]
					continue
			else:
				line = line[len(code_block_info[0]):]
				if line == "```\n":
					# if put block code inside list then hold change list indent level
					if list_indent > 0 and not hold_list_indent:
						hold_list_indent = True
						output += "[ul bullet=]"
					# put code to output
					output += code_higlight(code_block, 3)
					code_block = None
				else:
					code_block += line
				continue
			
			# check if last line is header
			if header.match(line) and prev_line:
				head_level = 1 if line[0] == "=" else 2
				output += make_head(prev_line, head_level)
				prev_line = ""
				continue
			
			# split first word (for first word formatted elements - headers, lists, etc)
			split_info = first_world_format.match(line)
			if split_info:
				split_info = split_info.groups()
				line = split_info[3]
		
		# add previous line to output
		output += prev_line
		prev_line = ""
		
		# process in-line formatting and remove comments
		line, comment_is_open_after = process_line(line, comment_is_open)
		if comment_is_open and line == "\n":
			# do not add new line at end comment-only lines
			line = ""
		if comment_is_open_after:
			# do not add new line at end line  when end line is in comment
			if len(line) > 0 and line[-1] == "\n":
				line = line[:-1]
		comment_is_open = comment_is_open_after
		
		# process first word formatting - lists
		if split_info and split_info[1][0] != "#":
			# end of multi lines list item mode
			if hold_list_indent:
				output += "[/ul]"
				hold_list_indent = False
			
			# list level changes
			new_list_indent = len(split_info[0]) + 1
			if new_list_indent > list_indent:
				if split_info[1] == "*":
					output += "[ul]"
					list_types.append("ul")
				elif split_info[1] in "0123456789":
					output += "[ol]"
					list_types.append("ol")
				else:
					output += f"[ul bullet={split_info[1]}]"
					list_types.append("ul")
			if new_list_indent < list_indent:
				output += "[/" + list_types.pop() + "]"
			list_indent = new_list_indent
			
			# continue on current level mark
			if split_info[1] == ".":
				output += "[ul bullet=]" + line + "[/ul]"
			else:
				output += "\n " + line
			continue
		
		# start multi lines list item mode
		if list_indent > 0 and not hold_list_indent:
			hold_list_indent = True
			output += "[ul bullet=]"
		
		# process first word formatting - headers
		if split_info and list_indent == 0 and split_info[1][0] == "#":
			output += make_head(line, len(split_info[1]), "\n")
			continue
		
		if split_info:
			prev_line = split_info[0] + split_info[1] + split_info[2] + line + "\n"
		else:
			prev_line = line
		
		# end list mode
		if prev_line == "\n" and list_indent > 0:
			if hold_list_indent:
				output += "[/ul]"
				hold_list_indent = False
			for i in range(len(list_types)):
				output += "[/" + list_types.pop() + "]"
			list_indent = 0
	
	# add last line from input to output
	output += prev_line
	
	return output

def code_higlight(text, mode):
	# mode: 0 → inline `, 2 → inline ```, 3 → multiline ```
	try:
		if text[-1] == "\n":
			text = text[:-1]
		
		lexer_name = ""
		if mode != 2 and text[0] == '[':
			lexer_end = text.find(']')
			lexer_name = text[1:lexer_end]
			lexer_end += 1
			if text[lexer_end] == '\n':
				lexer_end += 1
			text = text[lexer_end:]
		elif mode == 3:
			lexer_end = text.find('\n')
			lexer_name = text[0:lexer_end]
			text = text[lexer_end:]
		
		if lexer_name:
			text = highlight(text, get_lexer_by_name(lexer_name), BBCodeGodotFormatter(style='github-dark'))
		else:
			text = "[color=#8b949e]" + text.replace('[', '[lb]') + "[/color]"
		
		return "[code]" + text + "[/code]"
	except Exception as err:
		print("Error in code_higlight for: »", text, "« mode=", mode, sep="", file=sys.stderr)
		raise err

def make_head(line, head_level, postfix=""):
	if line[-1] == '\n':
		line = line[:-1]
		postfix = "\n"
	match head_level:
		case 1:
			return f"[center][font_size=35][b]{line}[/b][/font_size][/center]{postfix}"
		case 2:
			return f"[center][font_size=30][b]{line}[/b][/font_size][/center]{postfix}"
		case 3:
			return f"[font_size=27]{line}[/font_size]{postfix}"
		case 4:
			return f"[font_size=24]{line}[/font_size]{postfix}"
		case 5:
			return f"[font_size=21]{line}[/font_size]{postfix}"
		case 6:
			return f"[font_size=18]{line}[/font_size]{postfix}"
		case _:
			return line + postfix

if __name__ == "__main__":
	import sys
	if len(sys.argv) < 2:
		print("USAGE: " + sys.argv[0] + " input_file")
		exit()
	
	with open(sys.argv[1], "rt") as f:
		print(process_lines(f))
