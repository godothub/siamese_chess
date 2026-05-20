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

#include "opening_book.hpp"
#include <godot_cpp/classes/file_access.hpp>
#include <godot_cpp/classes/json.hpp>

void OpeningBook::load_file(const godot::String &_path)
{
	godot::Ref<godot::FileAccess> file = godot::FileAccess::open(_path, godot::FileAccess::ModeFlags::READ);
	int size = file->get_32();
	for (int i = 0; i < size; i++)
	{
		int64_t zobrist = file->get_64();
		Opening opening = {file->get_pascal_string(), file->get_pascal_string()};
		int move_size = file->get_32();
		for (int i = 0; i < move_size; i++)
		{
			opening.move.push_back(file->get_32());
		}
		opening_book[zobrist] = opening;
	}
	file->close();
}

void OpeningBook::save_file(const godot::String &_path)
{
	godot::Ref<godot::FileAccess> file = godot::FileAccess::open(_path, godot::FileAccess::ModeFlags::WRITE);
	file->store_32(opening_book.size());
	for (std::map<int64_t, Opening>::iterator iter = opening_book.begin(); iter != opening_book.end(); iter++)
	{
		file->store_64(iter->first);
		file->store_pascal_string(iter->second.name);
		file->store_pascal_string(iter->second.description);
		file->store_32(iter->second.move.size());
		for (int i = 0; i < iter->second.move.size(); i++)
		{
			file->store_32(iter->second.move[i]);
		}
	}
	file->close();
}

bool OpeningBook::has_record(const godot::Ref<State> &_state)
{
	return opening_book.count(_state->get_zobrist());
}

godot::String OpeningBook::get_opening_name(const godot::Ref<State> &_state)
{
	if (!has_record(_state))
	{
		return "";
	}
	return opening_book[_state->get_zobrist()].name;
}

godot::String OpeningBook::get_opening_description(const godot::Ref<State> &_state)
{
	if (!has_record(_state))
	{
		return "";
	}
	return opening_book[_state->get_zobrist()].description;
}

godot::PackedInt32Array OpeningBook::get_suggest_move(const godot::Ref<State> &_state)
{
	return opening_book[_state->get_zobrist()].move;
}

void OpeningBook::set_opening(const godot::Ref<State> &_state, const godot::String &name, const godot::String &description, const godot::PackedInt32Array &move)
{
	opening_book[_state->get_zobrist()] = {name, description, move};
}

void OpeningBook::_bind_methods()
{
	godot::ClassDB::bind_method(godot::D_METHOD("load_file"), &OpeningBook::load_file);
	godot::ClassDB::bind_method(godot::D_METHOD("save_file"), &OpeningBook::save_file);
	godot::ClassDB::bind_method(godot::D_METHOD("has_record"), &OpeningBook::has_record);
	godot::ClassDB::bind_method(godot::D_METHOD("get_opening_name"), &OpeningBook::get_opening_name);
	godot::ClassDB::bind_method(godot::D_METHOD("get_opening_description"), &OpeningBook::get_opening_description);
	godot::ClassDB::bind_method(godot::D_METHOD("get_suggest_move"), &OpeningBook::get_suggest_move);
	godot::ClassDB::bind_method(godot::D_METHOD("set_opening"), &OpeningBook::set_opening);
}
