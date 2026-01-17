// SPDX-FileCopyrightText: Robert Ryszard Paciorek <rrp@opcode.eu.org>
// SPDX-License-Identifier: MIT

#include <unistd.h>
#include <fcntl.h>
#include <termios.h>
#include <stdio.h>

#include <thread>
#include <mutex>
#include <atomic>
#include <condition_variable>
#include <chrono>
#include <string>
#include <map>
#include <vector>
#include <iostream>

#define FUSE_USE_VERSION 31
#include <fuse.h>
#include <string.h>

std::atomic_int ping_timer = 0;
std::map<std::string, std::string> input_values;
std::map<std::string, std::string> output_values;
std::string time_value = "-2";

std::condition_variable ready;
bool configured = false;

void send(const std::string& data);

void execute_command(const std::string& data) {
	// std::cout << "received command: >>>" << data << "<<<\n";
	
	std::string command;
	std::string all_args;
	std::vector<std::string> args_vector;
	
	static const std::string delimeter(" ");
	std::string::size_type start = 0, end = 0;
	while (end != std::string::npos) {
		end = data.find(delimeter, start);
		if (start == 0) {
			command = data.substr(0, end);
			all_args = data.substr(end + delimeter.size());
		} else {
			args_vector.push_back(data.substr(start, end - start));
			// this will work for strings no longer than 0.5 * std::string::npos (~ 8EB)
		}
		start = end + delimeter.size();
	};
	
	try {
		if (command == "pong") {
			ping_timer = 0;
		} else if (command == "request_poweroff") {
			system("sync; poweroff -f");
		} else if (command == "before_save") {
			system("fsfreeze --freeze /.overlayrootfs/rw; sync");
			send("ready_to_save\n");
		} else if (command == "after_save") {
			system("fsfreeze --unfreeze /.overlayrootfs/rw");
		} else if (command == "terminal_size_changed") {
			system(("stty -F /dev/ttyS0 rows " + args_vector[0] + " cols " + args_vector[1]).c_str());
		} else if (command == "time") {
			time_value = args_vector[0];
		} else if (command == "set_input_value") {
			input_values[args_vector[0]] = args_vector[1];
		} else if (command == "input_names") {
			input_values.clear();
			for (auto& name : args_vector)
				input_values[name] = "";
		} else if (command == "output_names") {
			output_values.clear();
			for (auto& name : args_vector)
				output_values[name] = "";
		} else if (command == "add_output") {
			output_values[args_vector[0]] = "";
		} else if (command == "remove_output") {
			output_values.erase(args_vector[0]);
		} else if (command == "remove_input") {
			input_values.erase(args_vector[0]);
		} else if (command == "configuration_done") {
			configured = true;
			ready.notify_all();
		} else if (command == "execute_command") {
			system(all_args.c_str());
		}
	} catch(std::exception e) {
		std::cout << "error while executing message bus command: " << data << ": " << e.what() << "\n";
	} catch(...) {
		std::cout << "error while executing message bus command: " << data << "\n";
	}
}

//                        //
//  Serial communication  //
//                        //

int serial_port = -1;
std::mutex write_mutex;

int init_serial_port(const char* device, bool verbose = true) {
	serial_port = open(device, O_RDWR);
	if (serial_port < 0) {
		if (verbose)
			perror("Error open serial deviace");
		return -10;
	}
	
	struct termios tty;
	if(tcgetattr(serial_port, &tty) != 0) {
		if (verbose)
			perror("tcgetattr");
		return -11;
	}
	
	cfsetispeed(&tty, B115200); // set input baud rate
	cfsetospeed(&tty, B115200); // set output baud rate
	
	tty.c_oflag = 0; // "raw" output - no output processing (e.g. new line conversion)
	
	tty.c_lflag |= ICANON; // input revived by lines
	tty.c_lflag &= ~ECHO; // disable echo
	tty.c_lflag &= ~(ECHOE | ECHOK | ECHONL); // disable line editing characters
	tty.c_lflag &= ~ISIG; // no signals on INTR, QUIT, SUSP, or DSUSP characters
	tty.c_lflag &= ~ISTRIP; // do not strip off eighth bit
	tty.c_lflag &= ~(INLCR|IGNCR|ICRNL); // do not new line conversion
	
	// apply port settings
	if (tcsetattr(serial_port, TCSANOW, &tty) != 0) {
		if (verbose)
			perror("tcsetattr");
		return -12;
	}
	
	return serial_port;
}

void send(const std::string& data) {
	write_mutex.lock();
	write(serial_port, data.c_str(), data.length());
	write_mutex.unlock();
}

void listener() {
	constexpr const int buf_size = 1024;
	char data[buf_size];
	
	bool collecting_line = false;
	std::string line;
	
	while (true) {
		int data_count = read(serial_port, data, buf_size);
		if (data_count < 0) {
			perror("daemon");
		} else if (data_count == 0) {
			printf("read return zero");
		} else {
			if (collecting_line) {
				line += std::string(data, data_count);
			} else {
				line = std::string(data, data_count);
			}
			
			if (line[line.length()-1] != '\n') {
				collecting_line = true;
			} else {
				collecting_line = false;
				line.pop_back(); // remove new line character
				
				#ifdef RUN_COMMAND_IN_BACKGROUND
				std::thread command_thread(execute_command, line);
				command_thread.detach();
				#else
				execute_command(line);
				#endif
			}
		}
	}
}

void pinger() {
	while (true) {
		++ping_timer;
		send("ping\n");
		std::this_thread::sleep_for(std::chrono::seconds(1));
		if (ping_timer > 5) {
			std::cout << "no replay to ping from Godot ... call poweroff\n";
			system("sleep 0.2; poweroff -f");
		}
	}
}


//                        //
//  FUSE local interface  //
//                        //

#define DIR_DEFAULT_FLAGS (fuse_fill_dir_flags)0

std::map<std::string, std::string>::iterator get_file_data(const std::string& path, int& mode) {
	mode = 0;
	auto end = path.find("/", 1);
	if (end != std::string::npos) {
		auto dirname = path.substr(1, end-1);
		auto filename = path.substr(end + 1);
		if (dirname == "inputs") {
			auto file = input_values.find(filename);
			if (file != input_values.end()) {
				mode = 0444;
				return file;
			}
		}
		if (dirname == "outputs") {
			auto file = output_values.find(filename);
			if (file != output_values.end()) {
				mode = 0666;
				return file;
			}
		}
	}
	return output_values.end(); // return something ... this will be ignored due to mode == 0
}
static int ctrl_fs_getattr(const char *path, struct stat *buf, struct fuse_file_info*) {
	std::string path2(path);
	
	memset(buf, 0, sizeof(struct stat));
	
	if (path2 == "/" || path2 == "/inputs" || path2 == "/outputs") {
		buf->st_mode = S_IFDIR | 0755;
		buf->st_nlink = 2;
		return 0;
	}
	
	if (path2 == "/ready" && configured) {
		buf->st_mode = S_IFREG | 0222;
		buf->st_nlink = 1;
		return 0;
	}
	
	if (path2 == "/time") {
		buf->st_mode = S_IFREG | 0444;
		buf->st_nlink = 1;
		buf->st_size = time_value.length();
		return 0;
	}
	
	int mode;
	auto file_content = get_file_data(path2, mode);
	if (mode) {
		buf->st_mode = S_IFREG | mode;
		buf->st_nlink = 1;
		buf->st_size = file_content->second.length();
		return 0;
	}
	
	return -ENOENT;
}

static int ctrl_fs_readdir(const char* path, void* buf, fuse_fill_dir_t entry_add, off_t, struct fuse_file_info*, enum fuse_readdir_flags) {
	std::string_view dir_path(path);
	
	if (dir_path == "/") {
		entry_add(buf, "inputs", NULL, 0, DIR_DEFAULT_FLAGS);
		entry_add(buf, "outputs", NULL, 0, DIR_DEFAULT_FLAGS);
		entry_add(buf, "time", NULL, 0, DIR_DEFAULT_FLAGS);
	} else if (dir_path == "/inputs") {
		for (auto& file : input_values) {
			entry_add(buf, file.first.c_str(), NULL, 0, DIR_DEFAULT_FLAGS);
		}
	} else if (dir_path == "/outputs") {
		for (auto& file : output_values) {
			entry_add(buf, file.first.c_str(), NULL, 0, DIR_DEFAULT_FLAGS);
		}
	} else {
		return -ENOENT;
	}
	
	entry_add(buf, ".", NULL, 0, DIR_DEFAULT_FLAGS);
	entry_add(buf, "..", NULL, 0, DIR_DEFAULT_FLAGS);
	
	return 0;
}

static int ctrl_fs_read(const char *path, char *buf, size_t size, off_t offset, struct fuse_file_info*) {
	std::string file_path(path);
	
	if (file_path == "/time") {
		size = time_value.length() - offset;
		memcpy(buf, time_value.c_str() + offset, size);
		return size;
	}
	
	int mode;
	auto file_content = get_file_data(file_path, mode);
	if (mode) {
		if (offset + size > file_content->second.length()) {
			size = file_content->second.length() - offset;
			if (size <= 0)
				return 0;
		}
		memcpy(buf, file_content->second.c_str() + offset, size);
		return size;
	}
	return -ENOENT;
}

static int ctrl_fs_write(const char *file_path, const char *buf, size_t size, off_t offset, struct fuse_file_info*) {
	std::string path(file_path);
	if (path == "/ready") {
		send("computer_system_ready\n");
		return size;
	}
	int mode;
	auto file_content = get_file_data(path, mode);
	if (mode == 0666) {
		file_content->second = std::string(buf, size);
		send("set_output_value " + file_content->first + " " + file_content->second + "\n");
		return size;
	}
	return -ENOENT;
}

void start_fuse(const char* path) {
	const char* fuse_argv[] = {"ctrl_fs", "-f", path};
	const struct fuse_operations ctrl_fs_oper = {
		.getattr = ctrl_fs_getattr,
		.read    = ctrl_fs_read,
		.write   = ctrl_fs_write,
		.readdir = ctrl_fs_readdir,
	};
	fuse_main(3, const_cast<char**>(fuse_argv), &ctrl_fs_oper, NULL);
}


//                        //
//      Main function     //
//                        //


int main(int argc, char** argv) {
	std::cout << "Starting factory controller ... please wait\n";
	
	init_serial_port("/dev/ttyS1");
	if (serial_port < 0) {
		return -serial_port;
	}
	
	if (! (argc > 1 && argv[1] == std::string("no_daemon")) ) {
		if (daemon(1, 1) != 0) {
			perror("daemon");
			return 21;
		}
	}
	
	std::thread listener_thread(listener);
	std::thread pinger_thread(pinger);
	std::thread fuse_thread(start_fuse, "/dev/factory_control");
	
	send("controller_ready\n");
	
	std::mutex ready_mutex;
	std::unique_lock<std::mutex> lock(ready_mutex);
	ready.wait(lock, []{return configured;}); // wait for "configuration_done"
	
	std::cout << "Factory controller is ready\n";
	
	listener_thread.join();
	pinger_thread.join();
	fuse_thread.join();
}
