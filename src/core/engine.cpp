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

#include "engine.hpp"
#include <godot_cpp/classes/time.hpp>
#include <thread>

void ChessEngine::start_search(const godot::Ref<State> &_state, int _group, const godot::PackedInt64Array &history_state, const godot::Callable &_debug_output)
{
	DEV_ASSERT(searching == false);
	searching = true;
	interrupted = false;
	start_thinking = godot::Time::get_singleton()->get_unix_time_from_system();
	std::thread thread(&ChessEngine::search_thread, this, _state->duplicate(), _group, history_state, _debug_output);
	thread.detach();
}

void ChessEngine::search_thread(const godot::Ref<State> &_state, int _group, const godot::PackedInt64Array &history_state, const godot::Callable &_debug_output)
{
	search(_state, _group, history_state, _debug_output);
	searching = false;
	call_deferred("emit_signal", "search_finished");
}

void ChessEngine::stop_search()
{
	interrupted = true;
}

bool ChessEngine::is_searching()
{
	return searching;
}

double ChessEngine::time_passed()
{
	return godot::Time::get_singleton()->get_unix_time_from_system() - start_thinking;
}

void ChessEngine::_bind_methods()
{
	ADD_SIGNAL(godot::MethodInfo("search_finished"));
	godot::ClassDB::bind_method(godot::D_METHOD("start_search"), &ChessEngine::start_search);
	godot::ClassDB::bind_method(godot::D_METHOD("stop_search"), &ChessEngine::stop_search);
	godot::ClassDB::bind_method(godot::D_METHOD("is_searching"), &ChessEngine::is_searching);
	godot::ClassDB::bind_method(godot::D_METHOD("search"), &ChessEngine::search);
	godot::ClassDB::bind_method(godot::D_METHOD("get_search_result"), &ChessEngine::get_search_result);
}
