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

#include "zobrist_hash.hpp"
#include <godot_cpp/classes/random_number_generator.hpp>
#include <random>

ZobristHash *ZobristHash::singleton = nullptr;

ZobristHash::ZobristHash()
{
	std::mt19937_64 rng(0);
	for (int i = 0; i < 65536; i++)
	{
		randomized[i] = rng();
	}
}

ZobristHash *ZobristHash::get_singleton()
{
	if (!singleton)
	{
		singleton = memnew(ZobristHash);
	}
	return singleton;
}

int64_t ZobristHash::hash_piece(int _piece, int _by)
{
	return randomized[((_piece & 0xFF) + (_by << 8)) & 0xFFFF];
}

void ZobristHash::print_randomized()
{
	for (int i = 0; i < 64; i += 4)
	{
		godot::print_line(i, ": ");
		std::vector<int> cnt(16);
		for (int j = 0; j < 65536; j++)
		{
			int index = (uint64_t(randomized[j]) >> i) & 0xF;
			cnt[index]++;
		}
		for (int j = 0; j < 16; j++)
		{
			godot::print_line("\t", j, ": ", cnt[j]);
		}
	}
}

void ZobristHash::_bind_methods()
{
	godot::ClassDB::bind_method(godot::D_METHOD("hash_piece"), &ZobristHash::hash_piece);
	godot::ClassDB::bind_method(godot::D_METHOD("print_randomized"), &ZobristHash::print_randomized);
}