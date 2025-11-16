# SPDX-FileCopyrightText: Robert Ryszard Paciorek <rrp@opcode.eu.org>
# SPDX-License-Identifier: MIT

"""Simple lib for factory input / output and time synchronization"""

# TODO migrate to C library

import time

def get_factory_time():
	"""return current factory time (factory running time) as float"""
	with open("/dev/factory_control/time", 'r') as file:
		return float(file.read())

def get_factory_value(value_name):
	"""return control block input value as float"""
	with open("/dev/factory_control/inputs/" + value_name, 'r') as file:
		return float(file.read())

def set_factory_value(value_name, value):
	"""set control block output value, use empty string as value to unset output (switch in high impedance mode)"""
	with open("/dev/factory_control/output/" + value_name, 'w') as file:
		file.write(str(value))

def factory_sleep(value):
	"""sleep `value` second using factory time, return oversleep time"""
	
	end_time = get_factory_time()
	if end_time < 0: # factory is no running
		end_time = 0 # so use 0 (factory start time) as current time
	end_time = end_time + value
	
	while get_factory_time() < end_time:
		time.sleep(0.002)
	
	return end_time - get_factory_time()
