// SPDX-FileCopyrightText: Robert Ryszard Paciorek <rrp@opcode.eu.org>
// SPDX-License-Identifier: MIT
// Based on public domain code from "godot-cpp integration testing project"

#include "gdspice.h"

#include <godot_cpp/core/class_db.hpp>

using namespace godot;

void initialize_gdspice_module(ModuleInitializationLevel p_level) {
	if (p_level != MODULE_INITIALIZATION_LEVEL_SCENE) {
		return;
	}
	GDREGISTER_CLASS(GdSpice);
}

void uninitialize_gdspice_module(ModuleInitializationLevel p_level) {
	if (p_level != MODULE_INITIALIZATION_LEVEL_SCENE) {
		return;
	}
}

extern "C" {
// Initialization.
GDExtensionBool GDE_EXPORT gdspice_library_init(GDExtensionInterfaceGetProcAddress p_get_proc_address, GDExtensionClassLibraryPtr p_library, GDExtensionInitialization *r_initialization) {
	GDExtensionBinding::InitObject init_obj(p_get_proc_address, p_library, r_initialization);

	init_obj.register_initializer(initialize_gdspice_module);
	init_obj.register_terminator(uninitialize_gdspice_module);
	init_obj.set_minimum_library_initialization_level(MODULE_INITIALIZATION_LEVEL_SCENE);

	return init_obj.init();
}
}
