/*

Copyright (c) 2026 FaMuLan
SiameseChess is licensed under Mulan PSL v2.
You can use this software according to the terms and conditions of the Mulan
PSL v2.
You may obtain a copy of Mulan PSL v2 at:
         http://license.coscl.org.cn/MulanPSL2
THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY
KIND, EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO
NON-INFRINGEMENT, MERCHANTABILITY OR FIT FOR A PARTICULAR PURPOSE.
See the Mulan PSL v2 for more details.

*/

#ifndef _ENGINE_H_
#define _ENGINE_H_

#include <godot_cpp/godot.hpp>
#include <godot_cpp/classes/ref_counted.hpp>
#include "state.hpp"
#include "transposition_table.hpp"
#include <thread>

class ChessEngine : public godot::RefCounted
{
	GDCLASS(ChessEngine, godot::RefCounted)
	public:
		void start_search(const godot::Ref<State> &_state, int _group, const godot::PackedInt64Array &history_state);
		void search_thread(const godot::Ref<State> &_state, int _group, const godot::PackedInt64Array &history_state);
		void stop_search();
		bool is_searching();
		double time_passed();
		virtual void search(const godot::Ref<State> &_state, int _group, const godot::PackedInt64Array &history_state) = 0;
		virtual int get_search_result() = 0;
		static void _bind_methods();
	protected:
		double start_thinking;
		bool interrupted = false;
		bool searching = false;
};

#endif