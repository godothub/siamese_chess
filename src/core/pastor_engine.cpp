#include "pastor_engine.hpp"
#include "chess.hpp"
#include <godot_cpp/core/error_macros.hpp>
#include <godot_cpp/classes/file_access.hpp>
#include <random>
#include <algorithm>
#include <functional>

PastorEngine::PastorEngine()
{
	state_pool.resize(1000);
	for (int i = 0; i < 1000; i++)
	{
		godot::Ref<State> new_state = memnew(State);
		state_pool[i] = new_state;
	}
	transposition_table.instantiate();
	opening_book.instantiate();
	if (godot::FileAccess::file_exists("user://standard_opening.fa"))
	{
		transposition_table->load_file("user://standard_opening.fa");
	}
	else
	{
		transposition_table->reserve(1 << 20);
	}
	if (godot::FileAccess::file_exists("user://standard_opening_document.fa"))
	{
		opening_book->load_file("user://standard_opening_document.fa");
	}
	max_depth = 100;
	piece_value = {
		{0, 0},
		{'K', 60000},
		{'Q', 929},
		{'R', 479},
		{'B', 320},
		{'N', 280},
		{'P', 100},
		{'*', 0},
		{'#', 0},
		{'Z', 0},
		{'k', -60000},
		{'q', -929},
		{'r', -479},
		{'b', -320},
		{'n', -280},
		{'p', -100},
	};
	directions_diagonal = {-17, -15, 15, 17};
	directions_straight = {-16, -1, 1, 16};
	directions_eight_way = {-17, -16, -15, -1, 1, 15, 16, 17};
	directions_horse = {33, 31, 18, 14, -33, -31, -18, -14};
	position_value_midgame = {
		{'K', {
		-65,  23,  16, -15, -56, -34,   2,  13,
		 29,  -1, -20,  -7,  -8,  -4, -38, -29,
		 -9,  24,   2, -16, -20,   6,  22, -22,
		-17, -20, -12, -27, -30, -25, -14, -36,
		-49,  -1, -27, -39, -46, -44, -33, -51,
		-14, -14, -22, -46, -44, -30, -15, -27,
		  1,   7,  -8, -64, -43, -16,   9,   8,
		-15,  36,  12, -54,   8, -28,  24,  14,
		}},
		{'Q', {
		-28,   0,  29,  12,  59,  44,  43,  45,
		-24, -39,  -5,   1, -16,  57,  28,  54,
		-13, -17,   7,   8,  29,  56,  47,  57,
		-27, -27, -16, -16,  -1,  17,  -2,   1,
		 -9, -26,  -9, -10,  -2,  -4,   3,  -3,
		-14,   2, -11,  -2,  -5,   2,  14,   5,
		-35,  -8,  11,   2,   8,  15,  -3,   1,
		 -1, -18,  -9,  10, -15, -25, -31, -50,
		}},
		{'R', {
		 32,  42,  32,  51, 63,  9,  31,  43,
		 27,  32,  58,  62, 80, 67,  26,  44,
		 -5,  19,  26,  36, 17, 45,  61,  16,
		-24, -11,   7,  26, 24, 35,  -8, -20,
		-36, -26, -12,  -1,  9, -7,   6, -23,
		-45, -25, -16, -17,  3,  0,  -5, -33,
		-44, -16, -20,  -9, -1, 11,  -6, -71,
		-19, -13,   1,  17, 16,  7, -37, -26,
		}},
		{'B', {
		-29,   4, -82, -37, -25, -42,   7,  -8,
		-26,  16, -18, -13,  30,  59,  18, -47,
		-16,  37,  43,  40,  35,  50,  37,  -2,
		 -4,   5,  19,  50,  37,  37,   7,  -2,
		 -6,  13,  13,  26,  34,  12,  10,   4,
		  0,  15,  15,  15,  14,  27,  18,  10,
		  4,  15,  16,   0,   7,  21,  33,   1,
		-33,  -3, -14, -21, -13, -12, -39, -21,
		}},
		{'N', {
		-167, -89, -34, -49,  61, -97, -15, -107,
		 -73, -41,  72,  36,  23,  62,   7,  -17,
		 -47,  60,  37,  65,  84, 129,  73,   44,
		  -9,  17,  19,  53,  37,  69,  18,   22,
		 -13,   4,  16,  13,  28,  19,  21,   -8,
		 -23,  -9,  12,  10,  19,  17,  25,  -16,
		 -29, -53, -12,  -3,  -1,  18, -14,  -19,
		-105, -21, -58, -33, -17, -28, -19,  -23,
		}},
		{'P', {
		  0,   0,   0,   0,   0,   0,  0,   0,
		 98, 134,  61,  95,  68, 126, 34, -11,
		 -6,   7,  26,  31,  65,  56, 25, -20,
		-14,  13,   6,  21,  23,  12, 17, -23,
		-27,  -2,  -5,  12,  17,   6, 10, -25,
		-26,  -4,  -4, -10,   3,   3, 33, -12,
		-35,  -1, -20, -23, -15,  24, 38, -22,
		  0,   0,   0,   0,   0,   0,  0,   0,
		}},
		{'k',{
		15, -36, -12,  54,  -8,  28, -24, -14,
		-1,  -7,   8,  64,  43,  16,  -9,  -8,
		14,  14,  22,  46,  44,  30,  15,  27,
		49,   1,  27,  39,  46,  44,  33,  51,
		17,  20,  12,  27,  30,  25,  14,  36,
		9, -24,  -2,  16,  20,  -6, -22,  22,
		-29,   1,  20,   7,   8,   4,  38,  29,
		65, -23, -16,  15,  56,  34,  -2, -13,
		}},
		{'q',{
		1,  18,   9, -10,  15,  25,  31,  50,
		35,   8, -11,  -2,  -8, -15,   3,  -1,
		14,  -2,  11,   2,   5,  -2, -14,  -5,
		9,  26,   9,  10,   2,   4,  -3,   3,
		27,  27,  16,  16,   1, -17,   2,  -1,
		13,  17,  -7,  -8, -29, -56, -47, -57,
		24,  39,   5,  -1,  16, -57, -28, -54,
		28,   0, -29, -12, -59, -44, -43, -45,
		}},
		{'r',{
		19,  13,  -1, -17, -16,  -7,  37,  26,
		44,  16,  20,   9,   1, -11,   6,  71,
		45,  25,  16,  17,  -3,   0,   5,  33,
		36,  26,  12,   1,  -9,   7,  -6,  23,
		24,  11,  -7, -26, -24, -35,   8,  20,
		5, -19, -26, -36, -17, -45, -61, -16,
		-27, -32, -58, -62, -80, -67, -26, -44,
		-32, -42, -32, -51, -63,  -9, -31, -43,
		}},
		{'b',{
		33,   3,  14,  21,  13,  12,  39,  21,
		-4, -15, -16,   0,  -7, -21, -33,  -1,
		0, -15, -15, -15, -14, -27, -18, -10,
		6, -13, -13, -26, -34, -12, -10,  -4,
		4,  -5, -19, -50, -37, -37,  -7,   2,
		16, -37, -43, -40, -35, -50, -37,   2,
		26, -16,  18,  13, -30, -59, -18,  47,
		29,  -4,  82,  37,  25,  42,  -7,   8,
		}},
		{'n',{
		105,  21,  58,  33,  17,  28,  19,  23,
		29,  53,  12,   3,   1, -18,  14,  19,
		23,   9, -12, -10, -19, -17, -25,  16,
		13,  -4, -16, -13, -28, -19, -21,   8,
		9, -17, -19, -53, -37, -69, -18, -22,
		47, -60, -37, -65, -84,-129, -73, -44,
		73,  41, -72, -36, -23, -62,  -7,  17,
		167,  89,  34,  49, -61,  97,  15, 107,
		}},
		{'p',{
		0,   0,   0,   0,   0,   0,   0,   0,
		35,   1,  20,  23,  15, -24, -38,  22,
		26,   4,   4,  10,  -3,  -3, -33,  12,
		27,   2,   5, -12, -17,  -6, -10,  25,
		14, -13,  -6, -21, -23, -12, -17,  23,
		6,  -7, -26, -31, -65, -56, -25,  20,
		-98,-134, -61, -95, -68,-126, -34,  11,
		0,   0,   0,   0,   0,   0,   0,   0,
		}},
		{'*', {
		0,   0,   0,   0,   0,   0,   0,   0,
		0,   0,   0,   0,   0,   0,   0,   0,
		0,   0,   0,   0,   0,   0,   0,   0,
		0,   0,   0,   0,   0,   0,   0,   0,
		0,   0,   0,   0,   0,   0,   0,   0,
		0,   0,   0,   0,   0,   0,   0,   0,
		0,   0,   0,   0,   0,   0,   0,   0,
		0,   0,   0,   0,   0,   0,   0,   0,
		}},
		{'#', {
		0,   0,   0,   0,   0,   0,   0,   0,
		0,   0,   0,   0,   0,   0,   0,   0,
		0,   0,   0,   0,   0,   0,   0,   0,
		0,   0,   0,   0,   0,   0,   0,   0,
		0,   0,   0,   0,   0,   0,   0,   0,
		0,   0,   0,   0,   0,   0,   0,   0,
		0,   0,   0,   0,   0,   0,   0,   0,
		0,   0,   0,   0,   0,   0,   0,   0,
		}}
	};
	position_value_endgame = {
		{'K', {
		-74, -35, -18, -18, -11,  15,   4, -17,
		-12,  17,  14,  17,  17,  38,  23,  11,
		 10,  17,  23,  15,  20,  45,  44,  13,
		 -8,  22,  24,  27,  26,  33,  26,   3,
		-18,  -4,  21,  24,  27,  23,   9, -11,
		-19,  -3,  11,  21,  23,  16,   7,  -9,
		-27, -11,   4,  13,  14,   4,  -5, -17,
		-53, -34, -21, -11, -28, -14, -24, -43
		}},
		{'Q', {
		 -9,  22,  22,  27,  27,  19,  10,  20,
		-17,  20,  32,  41,  58,  25,  30,   0,
		-20,   6,   9,  49,  47,  35,  19,   9,
		  3,  22,  24,  45,  57,  40,  57,  36,
		-18,  28,  19,  47,  31,  34,  39,  23,
		-16, -27,  15,   6,   9,  17,  10,   5,
		-22, -23, -30, -16, -16, -23, -36, -32,
		-33, -28, -22, -43,  -5, -32, -20, -41,
		}},
		{'R', {
		13, 10, 18, 15, 12,  12,   8,   5,
		11, 13, 13, 11, -3,   3,   8,   3,
		 7,  7,  7,  5,  4,  -3,  -5,  -3,
		 4,  3, 13,  1,  2,   1,  -1,   2,
		 3,  5,  8,  4, -5,  -6,  -8, -11,
		-4,  0, -5, -1, -7, -12,  -8, -16,
		-6, -6,  0,  2, -9,  -9, -11,  -3,
		-9,  2,  3, -1, -5, -13,   4, -20,
		}},
		{'B', {
		-14, -21, -11,  -8, -7,  -9, -17, -24,
		 -8,  -4,   7, -12, -3, -13,  -4, -14,
		  2,  -8,   0,  -1, -2,   6,   0,   4,
		 -3,   9,  12,   9, 14,  10,   3,   2,
		 -6,   3,  13,  19,  7,  10,  -3,  -9,
		-12,  -3,   8,  10, 13,   3,  -7, -15,
		-14, -18,  -7,  -1,  4,  -9, -15, -27,
		-23,  -9, -23,  -5, -9, -16,  -5, -17,
		}},
		{'N', {
		-58, -38, -13, -28, -31, -27, -63, -99,
		-25,  -8, -25,  -2,  -9, -25, -24, -52,
		-24, -20,  10,   9,  -1,  -9, -19, -41,
		-17,   3,  22,  22,  22,  11,   8, -18,
		-18,  -6,  16,  25,  16,  17,   4, -18,
		-23,  -3,  -1,  15,  10,  -3, -20, -22,
		-42, -20, -10,  -5,  -2, -20, -23, -44,
		-29, -51, -23, -15, -22, -18, -50, -64,
		}},
		{'P', {
		  0,   0,   0,   0,   0,   0,   0,   0,
		178, 173, 158, 134, 147, 132, 165, 187,
		 94, 100,  85,  67,  56,  53,  82,  84,
		 32,  24,  13,   5,  -2,   4,  17,  17,
		 13,   9,  -3,  -7,  -7,  -8,   3,  -1,
		  4,   7,  -6,   1,   0,  -5,  -1,  -8,
		 13,   8,   8,  10,  13,   0,   2,  -7,
		  0,   0,   0,   0,   0,   0,   0,   0,
		}},
		{'k',{
		53,  34,  21,  11,  28,  14,  24,  43,
		27,  11,  -4, -13, -14,  -4,   5,  17,
		19,   3, -11, -21, -23, -16,  -7,   9,
		18,   4, -21, -24, -27, -23,  -9,  11,
		8, -22, -24, -27, -26, -33, -26,  -3,
		-10, -17, -23, -15, -20, -45, -44, -13,
		12, -17, -14, -17, -17, -38, -23, -11,
		74,  35,  18,  18,  11, -15,  -4,  17,
		}},
		{'q',{
		33,  28,  22,  43,   5,  32,  20,  41,
		22,  23,  30,  16,  16,  23,  36,  32,
		16,  27, -15,  -6,  -9, -17, -10,  -5,
		18, -28, -19, -47, -31, -34, -39, -23,
		-3, -22, -24, -45, -57, -40, -57, -36,
		20,  -6,  -9, -49, -47, -35, -19,  -9,
		17, -20, -32, -41, -58, -25, -30,   0,
		9, -22, -22, -27, -27, -19, -10, -20,
		}},
		{'r',{
		9,  -2,  -3,   1,   5,  13,  -4,  20,
		6,   6,   0,  -2,   9,   9,  11,   3,
		4,   0,   5,   1,   7,  12,   8,  16,
		-3,  -5,  -8,  -4,   5,   6,   8,  11,
		-4,  -3, -13,  -1,  -2,  -1,   1,  -2,
		-7,  -7,  -7,  -5,  -4,   3,   5,   3,
		-11, -13, -13, -11,   3,  -3,  -8,  -3,
		-13, -10, -18, -15, -12, -12,  -8,  -5,
		}},
		{'b',{
		23,   9,  23,   5,   9,  16,   5,  17,
		14,  18,   7,   1,  -4,   9,  15,  27,
		12,   3,  -8, -10, -13,  -3,   7,  15,
		6,  -3, -13, -19,  -7, -10,   3,   9,
		3,  -9, -12,  -9, -14, -10,  -3,  -2,
		-2,   8,   0,   1,   2,  -6,   0,  -4,
		8,   4,  -7,  12,   3,  13,   4,  14,
		14,  21,  11,   8,   7,   9,  17,  24,
		}},
		{'n',{
		29,  51,  23,  15,  22,  18,  50,  64,
		42,  20,  10,   5,   2,  20,  23,  44,
		23,   3,   1, -15, -10,   3,  20,  22,
		18,   6, -16, -25, -16, -17,  -4,  18,
		17,  -3, -22, -22, -22, -11,  -8,  18,
		24,  20, -10,  -9,   1,   9,  19,  41,
		25,   8,  25,   2,   9,  25,  24,  52,
		58,  38,  13,  28,  31,  27,  63,  99,
		}},
		{'p',{
		0,   0,   0,   0,   0,   0,   0,   0,
		-13,  -8,  -8, -10, -13,   0,  -2,   7,
		-4,  -7,   6,  -1,   0,   5,   1,   8,
		-13,  -9,   3,   7,   7,   8,  -3,   1,
		-32, -24, -13,  -5,   2,  -4, -17, -17,
		-94,-100, -85, -67, -56, -53, -82, -84,
		-178,-173,-158,-134,-147,-132,-165,-187,
		0,   0,   0,   0,   0,   0,   0,   0,
		}},
		{'*', {
		0,   0,   0,   0,   0,   0,   0,   0,
		0,   0,   0,   0,   0,   0,   0,   0,
		0,   0,   0,   0,   0,   0,   0,   0,
		0,   0,   0,   0,   0,   0,   0,   0,
		0,   0,   0,   0,   0,   0,   0,   0,
		0,   0,   0,   0,   0,   0,   0,   0,
		0,   0,   0,   0,   0,   0,   0,   0,
		0,   0,   0,   0,   0,   0,   0,   0,
		}},
		{'#', {
		0,   0,   0,   0,   0,   0,   0,   0,
		0,   0,   0,   0,   0,   0,   0,   0,
		0,   0,   0,   0,   0,   0,   0,   0,
		0,   0,   0,   0,   0,   0,   0,   0,
		0,   0,   0,   0,   0,   0,   0,   0,
		0,   0,   0,   0,   0,   0,   0,   0,
		0,   0,   0,   0,   0,   0,   0,   0,
		0,   0,   0,   0,   0,   0,   0,   0,
		}}
	};
}


void PastorEngine::generate_good_capture_move(godot::PackedInt32Array &output, const godot::Ref<State> &_state, int _group)
{
	//既然是good_capture_move，那么无需考虑王车易位、过路兵带来的潜在规则问题，因为上一步不是吃子着法
	for (State::PieceIterator iter = _state->piece_iterator_begin(_group == 0 ? WHITE : BLACK); !iter.end(); iter.next())
	{
		int _from = iter.pos();
		int from_piece = iter.piece();
		godot::PackedInt32Array *directions = nullptr;
		if ((from_piece & 95) == 'P')
		{
			int front_capture_left = Chess::direction_pawn_capture(_group, false);
			int front_capture_right = Chess::direction_pawn_capture(_group, true);
			bool on_start = Chess::pawn_on_start(_group, _from);
			bool on_end = Chess::pawn_on_end(_group, _from);
			if (!Chess::is_blocked(_state, _from, _from + front_capture_left) && Chess::is_enemy(_state, _from, _from + front_capture_left))
			{
				if (on_end)
				{
					output.push_back(Chess::create(_from, _from + front_capture_left, _group == 0 ? 'Q' : 'q'));
					output.push_back(Chess::create(_from, _from + front_capture_left, _group == 0 ? 'R' : 'r'));
					output.push_back(Chess::create(_from, _from + front_capture_left, _group == 0 ? 'N' : 'n'));
					output.push_back(Chess::create(_from, _from + front_capture_left, _group == 0 ? 'B' : 'b'));
				}
				else
				{
					output.push_back(Chess::create(_from, _from + front_capture_left, 0));
				}
			}
			if (!Chess::is_blocked(_state, _from, _from + front_capture_right) && Chess::is_enemy(_state, _from, _from + front_capture_right))
			{
				if (on_end)
				{
					output.push_back(Chess::create(_from, _from + front_capture_right, _group == 0 ? 'Q' : 'q'));
					output.push_back(Chess::create(_from, _from + front_capture_right, _group == 0 ? 'R' : 'r'));
					output.push_back(Chess::create(_from, _from + front_capture_right, _group == 0 ? 'N' : 'n'));
					output.push_back(Chess::create(_from, _from + front_capture_right, _group == 0 ? 'B' : 'b'));
				}
				else
				{
					output.push_back(Chess::create(_from, _from + front_capture_right, 0));
				}
			}
			continue;
		}
		else if ((from_piece & 95) == 'K' || (from_piece & 95) == 'Q')
		{
			directions = &directions_eight_way;
		}
		else if ((from_piece & 95) == 'R')
		{
			directions = &directions_straight;
		}
		else if ((from_piece & 95) == 'N')
		{
			directions = &directions_horse;
		}
		else if ((from_piece & 95) == 'B')
		{
			directions = &directions_diagonal;
		}
		if (!directions)
		{
			continue;
		}
		for (int i = 0; i < directions->size(); i++)
		{
			int to = _from;
			int to_piece = _state->get_piece(to);
			while (true)
			{
				to += (*directions)[i];
				if ((to & 0x88))
				{
					break;
				}
				to_piece = _state->get_piece(to);
				if (Chess::is_blocked(_state, _from, to))
				{
					break;
				}
				if (to_piece)
				{
					output.push_back(Chess::create(_from, to, 0));
					break;
				}
				if ((from_piece & 95) == 'K' || (from_piece & 95) == 'N')
				{
					break;
				}
			}
		}
	}
}


int PastorEngine::get_piece_score(int _by, int _piece)
{
	godot::Vector2i piece_position = godot::Vector2i(_by % 16, _by / 16);
	if (piece_value.count(_piece) && position_value_midgame.count(_piece))
	{
		return position_value_midgame[_piece][piece_position.x + piece_position.y * 8] + piece_value[_piece];
	}
	return 0;
}

int PastorEngine::evaluate_all(const godot::Ref<State> &_state)
{
	int score = 0;
	for (State::PieceIterator iter = _state->piece_iterator_begin(); !iter.end(); iter.next())
	{
		int by = iter.pos();
		int piece = iter.piece();
		score += get_piece_score(by, piece);
	}
	return score;
}

int PastorEngine::evaluate(const godot::Ref<State> &_state, int _move)
{
	int from = Chess::from(_move);
	int from_piece = _state->get_piece(from);
	int to = Chess::to(_move);
	int to_piece = _state->get_piece(to);
	int extra = Chess::extra(_move);
	int group = Chess::group(from_piece);
	int score = get_piece_score(to, from_piece) - get_piece_score(from, from_piece);
	if (to_piece && !Chess::is_same_group(from_piece, to_piece))
	{
		score -= get_piece_score(to, to_piece);
	}
	if (_state->get_king_passant() != -1 && abs(_state->get_king_passant() - Chess::to(_move)) <= 1)
	{
		score -= piece_value[group == 0 ? 'k' : 'K'];
	}
	if (from_piece == 'K' && extra != 0)
	{
		score += get_piece_score((from + to) / 2, 'R');
		score -= get_piece_score(to < from ? Chess::a1() : Chess::h1(), 'R');
	}
	if (from_piece == 'k' && extra != 0)
	{
		score += get_piece_score((from + to) / 2, 'r');
		score -= get_piece_score(to < from ? Chess::a8() : Chess::h8(), 'r');
	}
	if ((from_piece & 95) == 'P')
	{
		int front = Chess::direction(from_piece, 0);
		if (extra)
		{
			score += get_piece_score(to, extra);
			score -= get_piece_score(from, from_piece);
		}
		if (to == _state->get_en_passant())
		{
			score -= get_piece_score(to - front, group == 0 ? 'p' : 'P');
		}
	}
	return score;
}

int PastorEngine::compare_move(int a, int b, int best_move, int killer_1, int killer_2, const godot::Ref<State> &state)
{
	if (best_move == a)
		return true;
	if (best_move == b)
		return false;
	if (killer_1 == a)
		return true;
	if (killer_1 == b)
		return false;
	if (killer_2 == a)
		return true;
	if (killer_2 == b)
		return false;
	if (history_table[a & 0xFFFF] != history_table[b & 0xFFFF])
		return history_table[a & 0xFFFF] > history_table[b & 0xFFFF];
	int mvv_a = abs(piece_value[state->get_piece(Chess::to(a))]);
	int mvv_b = abs(piece_value[state->get_piece(Chess::to(b))]);
	if (mvv_a != mvv_b)
	{
		return mvv_a > mvv_b;
	}
	int lva_a = abs(piece_value[state->get_piece(Chess::from(a))]);
	int lva_b = abs(piece_value[state->get_piece(Chess::from(b))]);
	if (mvv_a != 0 && lva_a != lva_b)
	{
		return lva_a < lva_b;
	}
	return a > b;
}

int PastorEngine::quies(const godot::Ref<State> &_state, int score, int _alpha, int _beta, int _group, int _ply)
{
	deepest_ply = std::max(_ply, deepest_ply);
	int score_relative = _group == 0 ? score : -score;
	if (score_relative >= _beta)
	{
		beta_cutoff++;
		return _beta;
	}
	if (score_relative > _alpha)
	{
		_alpha = score_relative;
	}
	godot::PackedInt32Array move_list;
	generate_good_capture_move(move_list, _state, _group);
	std::sort(move_list.ptrw(), move_list.ptrw() + move_list.size(), [this, &_state](int a, int b) -> bool{
		int mvv_a = abs(piece_value[_state->get_piece(Chess::to(a))]);
		int mvv_b = abs(piece_value[_state->get_piece(Chess::to(b))]);
		if (mvv_a != mvv_b)
		{
			return mvv_a > mvv_b;
		}
		int lva_a = abs(piece_value[_state->get_piece(Chess::from(a))]);
		int lva_b = abs(piece_value[_state->get_piece(Chess::from(b))]);
		if (mvv_a != 0 && lva_a != lva_b)
		{
			return lva_a < lva_b;
		}
		return a > b;
	});
	for (int i = 0; i < move_list.size(); i++)
	{
		godot::Ref<State> &test_state = state_pool[_ply + 1];
		_state->_internal_duplicate(test_state);
		Chess::apply_move(test_state, move_list[i]);
		int test_score = -quies(test_state, score + evaluate(_state, move_list[i]), -_beta, -_alpha, 1 - _group, _ply + 1);
		if (test_score >= _beta)
		{
			beta_cutoff++;
			return _beta;
		}
		if (test_score > _alpha)
		{
			_alpha = test_score;
		}
	}
	return _alpha;
}

int PastorEngine::alphabeta(const godot::Ref<State> &_state, int score, int _alpha, int _beta, int _depth, int _group, int _ply, bool _can_null, bool _is_null, int *killer_1, int *killer_2, const godot::Callable &_debug_output)
{
	godot::PackedInt32Array move_list;
	deepest_ply = std::max(_ply, deepest_ply);
	deepest_depth = std::max(_depth, deepest_depth);
	if (Chess::is_check(_state, 1 - _group))
	{
		Chess::_internal_generate_valid_move(move_list, _state, _group);
		if (!move_list.size())
		{
			return -WIN + _ply;
		}
	}
	if (Chess::is_check(_state, _group))
	{
		Chess::_internal_generate_valid_move(move_list, _state, 1 - _group);
		if (!move_list.size())
		{
			return WIN - _ply;
		}
	}
	Chess::_internal_generate_valid_move(move_list, _state, _group);
	if (move_list.size() == 0)
	{
		return _group == 0 ? despise_factor : -despise_factor;
	}
	if (_depth <= 0)
	{
		evaluated_position++;
		return quies(_state, score, _alpha, _beta, _group, _ply + 1);
	}
	if (_ply > 0 && map_history_state.count(_state->get_zobrist()))
	{
		return _group == 0 ? despise_factor : -despise_factor; // 视作平局，如果局面不太好，也不会选择负分的下法
	}

	bool found_pv = false;
	int transposition_table_score = transposition_table->probe_hash(_state->get_zobrist(), _depth, _alpha, _beta);
	if (_ply > 0 && transposition_table_score != 65535)
	{
		transposition_table_cutoff++;
		return transposition_table_score;
	}
	if (time_passed() >= think_time || interrupted)
	{
		return quies(_state, score, _alpha, _beta, _group, _ply + 1);
	}

	unsigned char flag = ALPHA;
	int pv_move = transposition_table->best_move(_state->get_zobrist());
	if (_depth > 2 && _ply > 1 && _can_null)
	{
		int next_score = -alphabeta(_state, score, -_beta, -_beta + 1, _depth - 3, 1 - _group, _ply + 1, false, true, nullptr, nullptr, _debug_output);
		if (next_score >= _beta)
		{
			beta_cutoff++;
			return _beta;
		}
	}
	std::sort(move_list.ptrw(), move_list.ptrw() + move_list.size(), [this, &_state, pv_move, killer_1, killer_2](int a, int b) -> bool{
		return compare_move(a, b, pv_move,  killer_1 ? *killer_1 : 0, killer_2 ? *killer_2 : 0, _state);
	});
	int move_count = move_list.size();
	int next_killer_1 = 0;
	int next_killer_2 = 0;
	pv_move = move_list[0];
	for (int i = 0; i < move_count; i++)
	{
		if (_debug_output.is_valid())
		{
			_debug_output.call(_state->get_zobrist(), _depth, i, move_list.size());
		}
		godot::Ref<State> &test_state = state_pool[_ply + 1];
		_state->_internal_duplicate(test_state);
		Chess::apply_move(test_state, move_list[i]);
		int next_score = 0;
		if (found_pv)
		{
			next_score = -alphabeta(test_state, score + evaluate(_state, move_list[i]), -_alpha - 1, -_alpha, _depth - 1, 1 - _group, _ply + 1, _can_null, _is_null, &next_killer_1, &next_killer_2, _debug_output);
		}
		if (!found_pv || next_score > _alpha && next_score < _beta)
		{
			next_score = -alphabeta(test_state, score + evaluate(_state, move_list[i]), -_beta, -_alpha, _depth - 1, 1 - _group, _ply + 1, _can_null, _is_null, &next_killer_1, &next_killer_2, _debug_output);
		}

		if (_beta <= next_score)
		{
			beta_cutoff++;
			if (!_is_null)
			{
				transposition_table->record_hash(_state->get_zobrist(), _depth, _beta, BETA, move_list[i]);
			}
			if (killer_1 && killer_2)
			{
				*killer_2 = *killer_1;
				*killer_1 = move_list[i];
			}
			return _beta;
		}
		if (_alpha < next_score)
		{
			found_pv = true;
			pv_move = move_list[i];
			_alpha = next_score;
			flag = EXACT;
			history_table[move_list[i] & 0xFFFF] += (1 << _depth);
		}
	}
	if (!_is_null)
	{
		transposition_table->record_hash(_state->get_zobrist(), _depth, _alpha, flag, pv_move);
	}
	return _alpha;
}

void PastorEngine::search(const godot::Ref<State> &_state, int _group, const godot::PackedInt64Array &history_state, const godot::Callable &_debug_output)
{
	deepest_ply = 0;
	evaluated_position = 0;
	beta_cutoff = 0;
	transposition_table_cutoff = 0;

	if (opening_book->has_record(_state))
	{
		godot::PackedInt32Array suggest_move = opening_book->get_suggest_move(_state);
		if (suggest_move.size())
		{
			std::mt19937_64 rng(time(nullptr));
			searched_move = suggest_move[rng() % suggest_move.size()];
			return;
		}
	}
	map_history_state.clear();
	history_table.fill(0);
	for (int i = 0; i < history_state.size(); i++)
	{
		map_history_state[history_state[i]]++;
	}
	for (int i = 2; i <= max_depth; i += 2)
	{
		alphabeta(_state, evaluate_all(_state), -THRESHOLD, THRESHOLD, i, _group, 0, true, false, nullptr, nullptr, _debug_output);
		if (time_passed() >= think_time || interrupted)
		{
			break;
		}
	}
	searched_move = transposition_table->best_move(_state->get_zobrist());
	searched_score = transposition_table->probe_hash(_state->get_zobrist(), 1, -THRESHOLD, THRESHOLD);
}

int PastorEngine::get_search_result()
{
	return searched_move;
}

godot::PackedInt32Array PastorEngine::get_principal_variation()
{
	return principal_variation;
}

int PastorEngine::get_score()
{
	return searched_score;
}

int PastorEngine::get_deepest_ply()
{
	return deepest_ply;
}

int PastorEngine::get_deepest_depth()
{
	return deepest_depth;
}

int PastorEngine::get_evaluated_position()
{
	return evaluated_position;
}

int PastorEngine::get_beta_cutoff()
{
	return beta_cutoff;
}

int PastorEngine::get_transposition_table_cutoff()
{
	return transposition_table_cutoff;
}

void PastorEngine::set_max_depth(int _max_depth)
{
	max_depth = _max_depth;
}

void PastorEngine::set_despise_factor(int _despise_factor)
{
	despise_factor = _despise_factor;
}

void PastorEngine::set_transposition_table(const godot::Ref<TranspositionTable> &_transposition_table)
{
	transposition_table = _transposition_table;
}

void PastorEngine::set_think_time(double _think_time)
{
	think_time = _think_time;
}

godot::Ref<TranspositionTable> PastorEngine::get_transposition_table() const
{
	return this->transposition_table;
}

void PastorEngine::_bind_methods()
{
	godot::ClassDB::bind_method(godot::D_METHOD("search"), &PastorEngine::search);
	godot::ClassDB::bind_method(godot::D_METHOD("get_search_result"), &PastorEngine::get_search_result);
	godot::ClassDB::bind_method(godot::D_METHOD("get_score"), &PastorEngine::get_score);
	godot::ClassDB::bind_method(godot::D_METHOD("get_deepest_ply"), &PastorEngine::get_deepest_ply);
	godot::ClassDB::bind_method(godot::D_METHOD("get_deepest_depth"), &PastorEngine::get_deepest_depth);
	godot::ClassDB::bind_method(godot::D_METHOD("get_evaluated_position"), &PastorEngine::get_evaluated_position);
	godot::ClassDB::bind_method(godot::D_METHOD("get_beta_cutoff"), &PastorEngine::get_beta_cutoff);
	godot::ClassDB::bind_method(godot::D_METHOD("get_transposition_table_cutoff"), &PastorEngine::get_transposition_table_cutoff);
	godot::ClassDB::bind_method(godot::D_METHOD("get_principal_variation"), &PastorEngine::get_principal_variation);
	godot::ClassDB::bind_method(godot::D_METHOD("set_max_depth"), &PastorEngine::set_max_depth);
	godot::ClassDB::bind_method(godot::D_METHOD("set_despise_factor"), &PastorEngine::set_despise_factor);
	godot::ClassDB::bind_method(godot::D_METHOD("set_think_time"), &PastorEngine::set_think_time);
	// godot::ClassDB::bind_method(godot::D_METHOD("set_transposition_table", "transposition_table"), &PastorEngine::set_transposition_table);
	godot::ClassDB::bind_method(godot::D_METHOD("get_transposition_table"), &PastorEngine::get_transposition_table);
	// ADD_PROPERTY(PropertyInfo(Variant::INT, "max_depth"), "set_max_depth", "get_max_depth");
	// ADD_PROPERTY(PropertyInfo(Variant::OBJECT, "transposition_table"), "set_transposition_table", "get_transposition_table");
}
