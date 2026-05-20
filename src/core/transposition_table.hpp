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

#ifndef _TRANSPOSITION_TABLE_HPP_
#define _TRANSPOSITION_TABLE_HPP_

#include <godot_cpp/godot.hpp>
#include <godot_cpp/classes/ref_counted.hpp>
#include <vector>

enum TranspositionTableFlag	{
	UNKNOWN = 0,
	EXACT = 1,
	ALPHA = 2,
	BETA = 3
};

struct TranspositionTableItem
{
	int64_t checksum;
	int8_t depth;
	int8_t flag;
	int value;
	int best_move;
};

class TranspositionTable : public godot::RefCounted
{
	GDCLASS(TranspositionTable, RefCounted)
	public:
		void reserve(int _table_size);
		void save_file(const godot::String &path);
		void load_file(const godot::String &path);
		int probe_hash(int64_t checksum, int8_t depth, int alpha, int beta);
		int best_move(int64_t checksum);
		void record_hash(int64_t checksum, int8_t depth, int value, int8_t flag, int best_move, bool replace_by_depth = false);
		void clear();
		void print_status();
		static void _bind_methods();
	private:
		bool read_only;
		int table_size;
		int table_size_mask;
		int collide_count;
		std::vector<TranspositionTableItem> table;
};

#endif