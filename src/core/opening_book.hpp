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

#ifndef _OPENING_BOOK_HPP_
#define _OPENING_BOOK_HPP_


#include <godot_cpp/godot.hpp>
#include <godot_cpp/classes/object.hpp>
#include "state.hpp"
#include <map>

struct Opening
{
	godot::String name;
	godot::String description;
	godot::PackedInt32Array move;
};

class OpeningBook : public godot::RefCounted
{
	GDCLASS(OpeningBook, RefCounted)
	public:
		void load_file(const godot::String &_path);
		void save_file(const godot::String &_path);
		bool has_record(const godot::Ref<State> &_state);
		godot::String get_opening_name(const godot::Ref<State> &_state);
		godot::String get_opening_description(const godot::Ref<State> &_state);
		godot::PackedInt32Array get_suggest_move(const godot::Ref<State> &_state);
		void set_opening(const godot::Ref<State> &_state, const godot::String &name, const godot::String &description, const godot::PackedInt32Array &move);
		static void _bind_methods();
	private:
		std::map<int64_t, Opening> opening_book;
};


#endif