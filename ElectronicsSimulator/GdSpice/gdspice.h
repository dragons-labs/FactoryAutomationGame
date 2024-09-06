// SPDX-FileCopyrightText: Robert Ryszard Paciorek <rrp@opcode.eu.org>
// SPDX-License-Identifier: MIT

#include <ngspice/sharedspice.h>
#include <godot_cpp/classes/node.hpp>
#include <godot_cpp/variant/string.hpp>
#include <map>

#include "../../Base/godot_api_utils.h"

#ifdef USE_DLOPEN
extern "C" {
	typedef int (*ngSpice_Init_Type) (SendChar*, SendStat*, ControlledExit*, SendData*, SendInitData*, BGThreadRunning*, void*);
	typedef int (*ngSpice_Init_Sync_Type) (GetVSRCData*, GetISRCData*, GetSyncData*, int*, void*);
	typedef int (*ngSpice_Command_Type) (char*);
	typedef pvector_info (*ngGet_Vec_Info_Type) (char*);
}
#endif

class GdSpice : public godot::Node {
	GDCLASS(GdSpice, godot::Node);
	
	static void _bind_methods();
	
public:
	/// create ngSpice simulator
	GdSpice();
	
	/// destroy ngSpice simulator, if dlopen was used call dlclose
	~GdSpice();
	
	/// init ngSpice simulator
	/// @note for parallel run each instance should be loaded with own copy of library
	bool init(const godot::String& libngspice, int _verbose);
	
	/// load circuit from array of strings (first element should be circuit title, last element should be ".end")
	/// and prepare simulation (do dc step)
	void load(const godot::PackedStringArray& circuit);
	
	/// start (synchronous) simulation
	/// if @a real_start is false only time calculation will be started
	void start(bool real_start, const godot::String& simulation_time_step, const godot::String& simulation_max_time);
	
	/// stop (terminate) simulation
	void stop();
	
	/// stop simulation but allow data access for debugging
	void emergency_stop();
	
	/// pause simulation
	void pause();
	
	/// resume simulation
	void resume();
	
	/// execute ngSpice command
	int run_command(const godot::String& command);
	int run_command(const char* command);
	
	/// get last (current) value for point @a point_name
	double get_last_value(const godot::String& point_name);
	
	/// get last data index
	/// (this allow do multiple calls of get_values in sync)
	int get_last_index();
	
	/// get (not more than @a count) of (latest) values for point @a point_name
	godot::Array get_latest_values(const godot::String& point_name, int count, int step = 1, int last_index = -1);
	
	/// get (not more than @a count) of (latest) time positions and values for point from @a points_names
	godot::Array get_latest_timed_values(const godot::PackedStringArray& points_names, int count, double time_step, double time_offset_from_last = 0);
	
	/// get @a count of time positions and values for points from @a points_names between @a time_start and @a time_end
	godot::Array get_timed_values_for_time_range(const godot::PackedStringArray& points_names, int count, double time_start, double time_end);
	
	/// get @a count of time positions and values for points from @a points_names after @a time_start with step @a time_step
	godot::Array get_timed_values_for_time_step(const godot::PackedStringArray& points_names, int count, double time_start, double time_step);
	
	/// set value for external control voltage/current sources
	void set_voltages_currents(const godot::String& point_name, double value);
	
	/// simulation states
	enum SimulationState {
		NOT_STARTED = 0x00,
		STARTING = 0x10, // circuit is loaded, "op" is executing
		READY = 0x21, // "op" is (successfully) calculated, ready to run "tran"
		RUNNING = 0x32,
		PAUSED = 0x44,
		ERROR = 0x50,
		MANUAL_ERROR = 0x51,
		STOPPED = 0x60,
		ENDED = 0x70,
		
		WORKING_TYPE_STATE_MASK = 0x0f
	};
	
	/// return true if simulation is running
	SimulationState get_simulation_state() { return simulation_state; }
	
	/// return true if simulation is running (low level info from ngspice)
	bool is_running() { return running; }
	
	/// return difference between simulation and game time at last simulation sync
	/// (if negative, game is too fast for simulation)
	double get_time_diff() { return time_diff; }
	
	/// return value of game time at last simulation sync
	double get_time_game() { return time_game; }
	
	/// return value of game time at last simulation sync
	double get_raw_time_game() { return last_game_time; }
	
	/// return value of simulation time at last simulation sync
	double get_time_simulation() { return time_simulation; }
	
	/// return sum of sleep time in current simulation
	double get_cumulative_sleep_time() { return cumulative_sleep_time; }
	
	/// value used to compare with @ref time_diff to emit simulation_too_slow signal
	double simulation_too_slow_level = -0.1;
	CREATE_SETTER_AND_GETTER(simulation_too_slow_level, double)
	
	/// value used to compare with @ref time_diff to start sleep
	double sleep_start_level = 0.05;
	CREATE_SETTER_AND_GETTER(sleep_start_level, double)
	
	/// value used to compare with @ref time_diff to end sleep
	double sleep_end_level = 0.01;
	CREATE_SETTER_AND_GETTER(sleep_end_level, double)
	
	/// single sleep time in milliseconds
	int sleep_time = 8;
	CREATE_SETTER_AND_GETTER(sleep_time, int)
	
	/// control printing information from simulation
	int verbose;
	CREATE_SETTER_AND_GETTER(verbose, int)
	
	#ifdef USE_DLOPEN
	/// @{
	/// ngSpice function from loaded lib
	ngSpice_Init_Type ngSpice_Init;
	ngSpice_Init_Sync_Type ngSpice_Init_Sync;
	ngSpice_Command_Type ngSpice_Command;
	ngGet_Vec_Info_Type ngGet_Vec_Info;
	/// @}
	#endif
	
	/// Godot per-frame callback (for time game time acquisition)
	void _process(double delta) override;
	
private:
	#ifdef USE_DLOPEN
	/// pointer to ngSpice dynamic library opened via dlopen
	void* ngSpice_dll = nullptr;
	#endif
	
	/// @{
	/// ngSpice callbacks
	static int on_thread_runs(bool not_running, int ident, void* userdata);
	static int on_exit(int retcode, bool unloaded, bool onerror, int ident, void* userdata);
	static int on_getchar(char* text, int ident, void* userdata);
	static int on_get_voltage_current_value(double* value, double time, char* node_name, int ident, void* userdata);
	static int on_sync(double time, double* deltatime, double olddeltatime, int redostep, int ident, int location, void* userdata);
	/// @}
	
	/// non static callback function used by @ref on_sync
	void on_sync2(double time);
	double update_times();
	
	SimulationState simulation_state;
	
	/// running flag
	bool running;
	
	/// dictionary with voltage/current values for external control voltage/current sources
	std::map<std::string, double> external_voltages_currents;
	
	/// simulation start time
	double start_time;
	/// delta time between simulation pause time and simulation start time, non zero only when simulation is paused
	double working_time;
	/// game time on last frame
	double last_game_time;
	
	/// game time from simulation start
	double time_game;
	/// simulation time (from simulation start)
	double time_simulation;
	/// simulation vs game time difference (time_simulation - time_game)
	double time_diff;
	/// cumulative sleep time in simulation thread
	double cumulative_sleep_time;
	
	/// last too slow signal game time (used to prevent send multiple signal in one frame / too often send signal)
	double last_alarm_time;
};

VARIANT_ENUM_CAST(GdSpice::SimulationState);
