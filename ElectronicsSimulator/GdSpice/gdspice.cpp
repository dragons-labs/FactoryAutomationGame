// SPDX-FileCopyrightText: Robert Ryszard Paciorek <rrp@opcode.eu.org>
// SPDX-License-Identifier: MIT

#include "gdspice.h"

#include <godot_cpp/core/class_db.hpp>
#include <godot_cpp/variant/utility_functions.hpp>

#include <ngspice/sharedspice.h>
#include <thread>
#include <iostream>
#include <math.h>

#ifdef USE_DLOPEN
#include <dlfcn.h>
#endif

GdSpice::GdSpice() {
	running = false;
	simulation_state = NOT_STARTED;
	set_process(false);
	#ifdef USE_DLOPEN
	ngSpice_dll = nullptr;
	#endif
}

GdSpice::~GdSpice() {
	#ifdef USE_DLOPEN
	if (ngSpice_dll)
		dlclose(ngSpice_dll);
	#endif
}

bool GdSpice::init(const godot::String& libngspice, int _verbose) {
	verbose = _verbose;
	
	#ifdef USE_DLOPEN
	ngSpice_dll = dlopen(libngspice.utf8().get_data(), RTLD_NOW);
	if (!ngSpice_dll) {
		godot::UtilityFunctions::printerr(("[GdSpice] ERROR: can't load libngspice: " + libngspice).utf8().get_data());
		return false;
	}
	ngSpice_Init = reinterpret_cast<ngSpice_Init_Type>(dlsym(ngSpice_dll, "ngSpice_Init"));
	ngSpice_Init_Sync = reinterpret_cast<ngSpice_Init_Sync_Type>(dlsym(ngSpice_dll, "ngSpice_Init_Sync"));
	ngSpice_Command = reinterpret_cast<ngSpice_Command_Type>(dlsym(ngSpice_dll, "ngSpice_Command"));
	ngGet_Vec_Info = reinterpret_cast<ngGet_Vec_Info_Type>(dlsym(ngSpice_dll, "ngGet_Vec_Info"));
	if (!ngSpice_Init || !ngSpice_Command) {
		godot::UtilityFunctions::printerr(("[GdSpice] ERROR: missed function in libngspice (" + libngspice + ")").utf8().get_data());
		return false;
	}
	#endif
	
	int ret = ngSpice_Init(on_getchar, /*on_getstat*/ nullptr, on_exit, /*on_data*/ nullptr, /*on_initdata*/ nullptr, on_thread_runs, this);
	if (verbose)
		godot::UtilityFunctions::print("[GdSpice] init thread returned: ", ret);
	
	ret = ngSpice_Init_Sync(on_get_voltage_current_value, on_get_voltage_current_value, on_sync, 0, this);
	if (verbose)
		godot::UtilityFunctions::print("[GdSpice] init sync thread returned: ", ret);
	
	return true;
}

void GdSpice::load(const godot::PackedStringArray& circuit) {
	for (int i=0; i<circuit.size(); ++i)
		run_command("circbyline " + circuit[i]);
	run_command("bg_op");
	
	simulation_state = STARTING;
}

void GdSpice::start(const godot::String& simulation_time_step, const godot::String& simulation_max_time) {
	if (simulation_state == READY) {
		godot::UtilityFunctions::print("[GdSpice] Start simulation ...");
		time_game = 0;
		run_command("bg_tran " + simulation_time_step + " " + simulation_max_time);
		simulation_state = RUNNING;
	} else {
		godot::UtilityFunctions::printerr("[GdSpice] Can't start ... simulation is not ready");
	}
}

bool GdSpice::try_step(double target_game_time) {
	if (simulation_state == RUNNING && time_simulation >= time_game) {
		time_game = target_game_time;
		return true;
	} else {
		return false;
	}
}

void GdSpice::stop() {
	if (simulation_state == NOT_STARTED) {
		return;
	}
	simulation_state = ENDED;
	run_command("bg_halt");
	run_command("reset");
	run_command("destroy all");
	external_voltages_currents.clear();
	if (!running) {
		call_deferred("set_process", false);
		simulation_state = NOT_STARTED;
	}
}

void GdSpice::emergency_stop() {
	if (simulation_state & WORKING_TYPE_STATE_MASK || simulation_state == MANUAL_ERROR) {
		simulation_state = MANUAL_ERROR;
	} else {
		simulation_state = ERROR;
	}
}

int GdSpice::run_command(const godot::String& command) {
	return run_command(command.utf8().get_data());
}

int GdSpice::run_command(const char* command) {
	int ret = ngSpice_Command( const_cast<char*>(command) );
	if (verbose)
		godot::UtilityFunctions::print("[GdSpice] command \"", command, "\" returned: ", ret);
	return ret;
}


double GdSpice::get_last_value(const godot::String& point_name) {
	if (simulation_state & WORKING_TYPE_STATE_MASK) {
		auto vec = ngGet_Vec_Info(const_cast<char*>(point_name.utf8().get_data()));
		if (vec->v_length > 0)
			return vec->v_realdata[vec->v_length-1];
	}
	if (verbose)
		godot::UtilityFunctions::print("[GdSpice] get_last_value for \"", point_name, "\" returned NAN");
	return NAN;
}

int GdSpice::get_last_index() {
	if (simulation_state & WORKING_TYPE_STATE_MASK) {
		auto vec = ngGet_Vec_Info(const_cast<char*>("time"));
		return vec->v_length-1;
	}
	return -1;
}

godot::Array GdSpice::get_latest_values(const godot::String& point_name, int count, int step, int last_index) {
	godot::Array arr;
	if (simulation_state & WORKING_TYPE_STATE_MASK) {
		auto vec = ngGet_Vec_Info(const_cast<char*>(point_name.utf8().get_data()));
		
		int start_index = last_index;
		if (start_index < 0)
			start_index = vec->v_length-1;
		
		int end_index = start_index - count * step;
		if (end_index < 0) {
			end_index = -1;
			count = (start_index - end_index) / step;
		}
		
		arr.resize(count);
		
		for (int i = start_index; i > end_index && count > 0; i -= step) {
			arr[--count] = vec->v_realdata[i];
		}
	}
	return arr;
}

godot::Array GdSpice::get_latest_timed_values(const godot::PackedStringArray& points_names, int count, double time_step, double time_offset_from_last) {
	if (simulation_state & WORKING_TYPE_STATE_MASK) {
		auto time_vec = ngGet_Vec_Info(const_cast<char*>("time"));
		
		int start_index = time_vec->v_length-1;
		double time_end = time_vec->v_realdata[start_index] - time_offset_from_last;
		if (time_end < 0)
			return godot::Array();
		
		double time_start = time_end - count * time_step;
		if (time_start < 0) {
			time_start = 0;
			count = static_cast<int>(floor((time_end - time_start) / time_step));
		}
		
		return get_timed_values_for_time_step(points_names, count, time_start, time_step);
	}
	return godot::Array();
}

godot::Array GdSpice::get_timed_values_for_time_range(const godot::PackedStringArray& points_names, int count, double time_start, double time_end) {
	double time_step = (time_end - time_start) / (count-1);
	return get_timed_values_for_time_step(points_names, count, time_start, time_step);
}

godot::Array GdSpice::get_timed_values_for_time_step(const godot::PackedStringArray& points_names, int count, double time_start, double time_step) {
	std::cerr << "get_timed_values_for_time_step: " << count << " " <<  points_names.size() << " " << time_start << " " << time_step << "\n";
	godot::Array arr;
	if (simulation_state & WORKING_TYPE_STATE_MASK) {
		auto time_vec = ngGet_Vec_Info(const_cast<char*>("time"));
		
		godot::Array times;
		times.resize(count);
		
		godot::Array indexes;
		indexes.resize(count);
		
		double time = time_start;
		int i = 0;
		for (int j=0; j<count; ++j) {
			while (time_vec->v_realdata[i++] < time);
			time += time_step;
			times[j] = time_vec->v_realdata[i];
			// store indexes (not values) here because we can't use two vectors from ngspice in the same time
			indexes[j] = i;
		}
		
		int out_array_size = points_names.size() + 1;
		if (out_array_size > 1) {
			arr.resize(out_array_size);
			arr[0] = times;
			for (int i=1; i<out_array_size; ++i) {
				godot::Array values;
				values.resize(count);
				auto data_vec = ngGet_Vec_Info(const_cast<char*>(points_names[i-1].utf8().get_data()));
				for (int j=0; j<count; ++j) {
					values[j] = data_vec->v_realdata[indexes[j]];
				}
				arr[i] = values;
			}
		} else {
			arr.resize(2);
			arr[0] = times;
			arr[1] = indexes;
		}
	}
	return arr;
}

void GdSpice::set_voltages_currents(const godot::String& point_name, double value) {
	// TODO setting new value should be delayed to successful sync (`gd_spice->time_simulation >= gd_spice->time_game` condition fulfilled in `on_sync`)
	external_voltages_currents[point_name.utf8().get_data()] = value;
}

void GdSpice::_bind_methods() {
	godot::ClassDB::bind_method(godot::D_METHOD("init"), &GdSpice::init, DEFVAL("libngspice.so"), DEFVAL(2));
	godot::ClassDB::bind_method(godot::D_METHOD("load"), &GdSpice::load);
	godot::ClassDB::bind_method(godot::D_METHOD("start"), &GdSpice::start, DEFVAL(true));
	godot::ClassDB::bind_method(godot::D_METHOD("try_step"), &GdSpice::try_step);
	godot::ClassDB::bind_method(godot::D_METHOD("stop"), &GdSpice::stop);
	godot::ClassDB::bind_method(godot::D_METHOD("emergency_stop"), &GdSpice::emergency_stop);
	godot::ClassDB::bind_method(godot::D_METHOD("get_simulation_state"), &GdSpice::get_simulation_state);
	godot::ClassDB::bind_method(godot::D_METHOD("run_command"), static_cast< int(GdSpice::*)(const godot::String&) >(&GdSpice::run_command));
	godot::ClassDB::bind_method(godot::D_METHOD("get_last_value"), &GdSpice::get_last_value);
	godot::ClassDB::bind_method(godot::D_METHOD("get_last_index"), &GdSpice::get_last_index);
	godot::ClassDB::bind_method(godot::D_METHOD("get_latest_values"), &GdSpice::get_latest_values, DEFVAL(1), DEFVAL(-1));
	godot::ClassDB::bind_method(godot::D_METHOD("get_latest_timed_values"), &GdSpice::get_latest_timed_values, DEFVAL(0));
	godot::ClassDB::bind_method(godot::D_METHOD("get_timed_values_for_time_range"), &GdSpice::get_timed_values_for_time_range);
	godot::ClassDB::bind_method(godot::D_METHOD("get_timed_values_for_time_step"), &GdSpice::get_timed_values_for_time_range);
	godot::ClassDB::bind_method(godot::D_METHOD("set_voltages_currents"), &GdSpice::set_voltages_currents);
	
	godot::ClassDB::bind_method(godot::D_METHOD("is_running"), &GdSpice::is_running);
	godot::ClassDB::bind_method(godot::D_METHOD("get_time_simulation"), &GdSpice::get_time_simulation);
	
	
	BIND_PROPERTY(GdSpice, time_game, FLOAT)
	BIND_PROPERTY(GdSpice, sleep_time, INT)
	BIND_PROPERTY(GdSpice, verbose, BOOL)
	
	BIND_CONSTANT(NOT_STARTED);
	BIND_CONSTANT(STARTING);
	BIND_CONSTANT(READY);
	BIND_CONSTANT(PAUSED);
	BIND_CONSTANT(RUNNING);
	BIND_CONSTANT(ERROR);
	BIND_CONSTANT(STOPPED);
	BIND_CONSTANT(ENDED);
	BIND_CONSTANT(WORKING_TYPE_STATE_MASK);
	
	ADD_SIGNAL(godot::MethodInfo("simulation_is_ready_to_run"));
	ADD_SIGNAL(godot::MethodInfo("simulation_error"));
}

int GdSpice::on_thread_runs(bool not_running, int /*ident*/, void* userdata) {
	auto gd_spice = static_cast<GdSpice*>(userdata);
	gd_spice->running = !not_running;
	if (gd_spice->verbose)
		godot::UtilityFunctions::print("[GdSpice] running=", gd_spice->running);
	if (not_running) {
		if (gd_spice->simulation_state == STARTING) {
			gd_spice->simulation_state = READY;
			godot::UtilityFunctions::print("[GdSpice] simulation is ready");
			gd_spice->call_deferred("emit_signal", "simulation_is_ready_to_run");
		} else if (gd_spice->simulation_state == ENDED) {
			godot::UtilityFunctions::print("[GdSpice] simulation was ended");
			gd_spice->stop();
			gd_spice->simulation_state = NOT_STARTED;
		} else if (gd_spice->simulation_state != ERROR) {
			gd_spice->simulation_state = STOPPED;
		}
	}
	return 0;
}

int GdSpice::on_exit(int retcode, bool unloaded, bool onerror, int ident, void* userdata) {
	auto gd_spice = static_cast<GdSpice*>(userdata);
	gd_spice->running = false;
	if (gd_spice->verbose)
		godot::UtilityFunctions::printerr("[GdSpice] ngspice ", ident, " (", reinterpret_cast<size_t>(userdata), "): exit retcode=", retcode, " unloaded=", unloaded, " onerror=", onerror);
	return 0;
}

int GdSpice::on_getchar(char* text, int ident, void* userdata) {
	auto gd_spice = static_cast<GdSpice*>(userdata);
	if (!strncmp(text, "stderr Fatal error", 18) || !strncmp(text, "stderr Error", 12) || !strncmp(text, "stderr Warning: singular matrix", 31) || !strncmp(text, "stderr tran simulation(s) aborted", 33)) {
		if (gd_spice->simulation_state >= STARTING && gd_spice->simulation_state < ERROR)
			gd_spice->call_deferred("emit_signal", "simulation_error");
		gd_spice->simulation_state = ERROR;
		godot::UtilityFunctions::printerr("[GdSpice] ERROR: detected issue in circuit or simulation. Simulation will be stopped!");
	}
	if (gd_spice->verbose) {
		if (gd_spice->verbose > 2 || strncmp(text, " Reference value", 16)) {
			godot::UtilityFunctions::print("[GdSpice] ngspice ", ident, " (", reinterpret_cast<size_t>(userdata), "): ", text);
		}
	}
	return 0;
}

int GdSpice::on_get_voltage_current_value(double* value, double time, char* node_name, int /*ident*/, void* userdata) {
	auto gd_spice = static_cast<GdSpice*>(userdata);
	double val = 0;
	auto val_iter = gd_spice->external_voltages_currents.find(node_name);
	if (val_iter != gd_spice->external_voltages_currents.end())
		val = val_iter->second;
	*value = val;
	return 0; 
}

int GdSpice::on_sync(double time, double* /*deltatime*/, double /*olddeltatime*/, int /*redostep*/, int /*ident*/, int /*location*/, void* userdata) {
	auto gd_spice = static_cast<GdSpice*>(userdata);
	
	gd_spice->time_simulation = time;
	while (gd_spice->simulation_state != RUNNING || gd_spice->time_simulation >= gd_spice->time_game) {
		std::this_thread::sleep_for(std::chrono::milliseconds(gd_spice->sleep_time)); // this is OK → we are sleeping in ngspice background thread, not in godot thread
		if ((gd_spice->simulation_state & WORKING_TYPE_STATE_MASK) == 0x00) // not PAUSED, READY nor RUNNING
			return 0;
	}
	return 0;
}
