// SPDX-FileCopyrightText: Robert Ryszard Paciorek <rrp@opcode.eu.org>
// SPDX-License-Identifier: MIT

#pragma once

#define CREATE_SETTER_AND_GETTER(varname, type) \
	void set_##varname(const type val) { varname = val; } \
	type get_##varname() const { return varname; }

#define BIND_PROPERTY(classname, varname, type) \
	godot::ClassDB::bind_method(godot::D_METHOD("set_" #varname), &classname::set_##varname); \
	godot::ClassDB::bind_method(godot::D_METHOD("get_" #varname), &classname::get_##varname); \
	godot::ClassDB::add_property(#classname, godot::PropertyInfo(godot::Variant::type, #varname), "set_" #varname, "get_" #varname);
