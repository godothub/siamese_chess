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

#ifndef _ZOBRIST_HASH_HPP_
#define _ZOBRIST_HASH_HPP_

#include <godot_cpp/godot.hpp>
#include <godot_cpp/classes/object.hpp>

class ZobristHash : public godot::Object
{
	GDCLASS(ZobristHash, Object)
	public:
		ZobristHash();  //随机数打表
		static ZobristHash *get_singleton();
		int64_t hash_piece(int _piece, int _by);
		void print_randomized();
		static void _bind_methods();
	private:
		static ZobristHash *singleton;
		//已知棋子是32位、位置是8位……
		//棋子只取小8位，总共16位
		int64_t randomized[65536];
};

#endif