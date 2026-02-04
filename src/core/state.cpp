#include "state.hpp"
#include "zobrist_hash.hpp"
#include "chess.hpp"
#include <cstring>

void State::PieceIterator::begin()
{
	bit = parent->get_bit(target_piece);
	by = Chess::to_x88(Chess::first_bit(bit));
}

void State::PieceIterator::next()
{
	bit = Chess::next_bit(bit);
	by = Chess::to_x88(Chess::first_bit(bit));
}

int State::PieceIterator::piece()
{
	return parent->pieces[by];
}

int State::PieceIterator::pos()
{
	return by;
}

bool State::PieceIterator::end()
{
	return bit == 0;
}

State::State()
{
	memset(pieces, 0, sizeof(pieces));
	bit[TURN] = 0;
	bit[CASTLE] = 0xF;
	bit[EN_PASSANT] = -1;
	bit[STEP_TO_DRAW] = 0;
	bit[ROUND] = 1;
	bit[KING_PASSANT] = -1;
}

godot::Ref<State> State::duplicate()
{
	godot::Ref<State> new_state = memnew(State);
	memcpy(new_state->pieces, pieces, sizeof(pieces));
	memcpy(new_state->bit, bit, sizeof(bit));
	return new_state;
}

void State::_internal_duplicate(godot::Ref<State> &other)
{
	memcpy(other->pieces, pieces, sizeof(pieces));
	memcpy(other->bit, bit, sizeof(bit));
}

State::PieceIterator State::piece_iterator_begin(int _piece)
{
	State::PieceIterator instance;
	instance.parent = this;
	instance.target_piece = _piece;
	instance.begin();
	return instance;
}

godot::PackedInt32Array State::get_all_pieces()
{
	godot::PackedInt32Array output;
	for (int from_1 = 0; from_1 < 8; from_1++)
	{
		for (int from_2 = 0; from_2 < 8; from_2++)
		{
			int from = (from_1 << 4) + from_2;
			if (get_piece(from))
			{
				output.push_back(from);
			}
		}
	}
	return output;
}

int State::get_piece(int _by)
{
	if (_by & 0x88)
	{
		return 0;
	}
	return pieces[_by];
}

int State::has_piece(int _by)
{
	return !(_by & 0x88) && pieces[_by];
}

void State::add_piece(int _by, int _piece)
{
	int by_64 = Chess::to_64(_by);
	int64_t by_mask = Chess::mask(by_64);
	pieces[_by] = _piece;
	bit[_piece] ^= by_mask;
	if (_piece >= 'A' && _piece <= 'Z' || _piece >= 'a' && _piece <= 'z')
	{
		bit[Chess::group(_piece) == 0 ? WHITE : BLACK] ^= by_mask;
	}
	bit[ALL_PIECE] ^= by_mask;
	bit[ZOBRIST_HASH] ^= ZobristHash::get_singleton()->hash_piece(_piece, _by);
}

void State::capture_piece(int _by)
{
	if (has_piece(_by))
	{
		int by_64 = Chess::to_64(_by);
		int piece = pieces[_by];
		DEV_ASSERT(piece != 0);
		int64_t by_mask = Chess::mask(by_64);
		bit[ZOBRIST_HASH] ^= ZobristHash::get_singleton()->hash_piece(piece, _by);
		bit[piece] ^= by_mask;
		if (piece >= 'A' && piece <= 'Z' || piece >= 'a' && piece <= 'z')
		{
			bit[Chess::group(piece) == 0 ? WHITE : BLACK] ^= by_mask;
		}
		bit[ALL_PIECE] ^= by_mask;
		pieces[_by] = 0;
		// 虽然大多数情况是攻击者移到被攻击者上，但是吃过路兵是例外，后续可能会出现类似情况，所以还是得手多一下
	}
}

void State::move_piece(int _from, int _to)
{
	int from_64 = Chess::to_64(_from);
	int to_64 = Chess::to_64(_to);
	int piece = get_piece(_from);
	DEV_ASSERT(piece >= 'A' && piece <= 'Z' || piece >= 'a' && piece <= 'z');
	int64_t from_mask = Chess::mask(from_64);
	int64_t to_mask = Chess::mask(to_64);
	bit[ZOBRIST_HASH] ^= ZobristHash::get_singleton()->hash_piece(piece, _from);
	bit[ZOBRIST_HASH] ^= ZobristHash::get_singleton()->hash_piece(piece, _to);
	bit[piece] ^= from_mask;
	bit[Chess::group(piece) == 0 ? WHITE : BLACK] ^= from_mask;
	bit[ALL_PIECE] ^= from_mask;
	bit[piece] ^= to_mask;
	bit[Chess::group(piece) == 0 ? WHITE : BLACK] ^= to_mask;
	bit[ALL_PIECE] ^= to_mask;
	pieces[_to] = pieces[_from];
	pieces[_from] = 0;
}

int64_t State::get_bit(int _piece)
{
	return bit[_piece];
}

void State::set_bit(int _piece, int64_t _bit)
{
	bit[_piece] = _bit;
}

godot::PackedInt32Array State::bit_index(int _piece)
{
	godot::PackedInt32Array output;
	for (int i = 0; i < 64; i++)
	{
		int64_t mask = 1;
		mask <<= i;
		if (bit[_piece] & mask)
		{
			output.push_back(i);
		}
	}
	return output;
}

int State::get_turn()
{
	return bit[TURN];
}

void State::set_turn(int _turn)
{
	bit[TURN] = _turn;
}

int State::get_castle()
{
	return bit[CASTLE];
}

void State::set_castle(int _castle)
{
	bit[CASTLE] = _castle;
}

int State::get_en_passant()
{
	return bit[EN_PASSANT];
}

void State::set_en_passant(int _en_passant)
{
	bit[EN_PASSANT] = _en_passant;
}

int State::get_step_to_draw()
{
	return bit[STEP_TO_DRAW];
}

void State::set_step_to_draw(int _step_to_draw)
{
	bit[STEP_TO_DRAW] = _step_to_draw;
}

int State::get_round()
{
	return bit[ROUND];
}

void State::set_round(int _round)
{
	bit[ROUND] = _round;
}

int64_t State::get_king_passant()
{
	return bit[KING_PASSANT];
}

void State::set_king_passant(int64_t _king_passant)
{
	bit[KING_PASSANT] = _king_passant;
}

int64_t State::get_storage_piece()
{
	return bit[STORAGE_PIECE];
}

void State::set_storage_piece(int64_t _storage_piece)
{
	bit[STORAGE_PIECE] = _storage_piece;
}

int64_t State::get_zobrist()
{
	return bit[ZOBRIST_HASH];
}

godot::String State::print_board()
{
	godot::String output;
	for (int i = 0; i < 64; i++)
	{
		int by = Chess::to_x88(i);
		if (has_piece(by))
		{
			output += char(get_piece(by));
		}
		else
		{
			output += '.';
		}
		if (i % 8 == 7)
		{
			output += '\n';
		}
	}
	return output;
}

godot::String State::print_bit_square(int _piece)
{
	godot::String output;
	uint64_t current_bit = bit[_piece];
	for (int i = 0; i < 8; i++)
	{
		for (int j = 0; j < 8; j++)
		{
			output += (current_bit & 1) ? '#' : '.';
			output += ' ';
			current_bit >>= 1;
		}
		output += '\n';
	}
	return output;
}

godot::String State::print_bit_diamond(int _piece)
{
	godot::String output;
	uint64_t current_bit = bit[_piece];
	for (int i = 0; i < 8; i++)
	{
		for (int j = 0; j < 8 - i; j++)
		{
			output += ' ';
		}
		for (int j = 0; j < i + 1; j++)
		{
			output += (current_bit & 1) ? '#' : '.';
			output += ' ';
			current_bit >>= 1;
		}
		output += '\n';
	}
	for (int i = 6; i >= 0; i--)
	{
		for (int j = 0; j < 8 - i; j++)
		{
			output += ' ';
		}
		for (int j = 0; j < i + 1; j++)
		{
			output += (current_bit & 1) ? '#' : '.';
			output += ' ';
			current_bit >>= 1;
		}
		output += '\n';
	}
	return output;
}

void State::_bind_methods()
{
	godot::ClassDB::bind_method(godot::D_METHOD("duplicate"), &State::duplicate);
	godot::ClassDB::bind_method(godot::D_METHOD("get_all_pieces"), &State::get_all_pieces);
	godot::ClassDB::bind_method(godot::D_METHOD("get_piece"), &State::get_piece);
	godot::ClassDB::bind_method(godot::D_METHOD("has_piece"), &State::has_piece);
	godot::ClassDB::bind_method(godot::D_METHOD("add_piece"), &State::add_piece);
	godot::ClassDB::bind_method(godot::D_METHOD("capture_piece"), &State::capture_piece);
	godot::ClassDB::bind_method(godot::D_METHOD("move_piece"), &State::move_piece);
	godot::ClassDB::bind_method(godot::D_METHOD("get_bit"), &State::get_bit);
	godot::ClassDB::bind_method(godot::D_METHOD("set_bit"), &State::set_bit);
	godot::ClassDB::bind_method(godot::D_METHOD("bit_index"), &State::bit_index);
	godot::ClassDB::bind_method(godot::D_METHOD("get_turn"), &State::get_turn);
	godot::ClassDB::bind_method(godot::D_METHOD("set_turn"), &State::set_turn);
	godot::ClassDB::bind_method(godot::D_METHOD("get_castle"), &State::get_castle);
	godot::ClassDB::bind_method(godot::D_METHOD("set_castle"), &State::set_castle);
	godot::ClassDB::bind_method(godot::D_METHOD("get_en_passant"), &State::get_en_passant);
	godot::ClassDB::bind_method(godot::D_METHOD("set_en_passant"), &State::set_en_passant);
	godot::ClassDB::bind_method(godot::D_METHOD("get_step_to_draw"), &State::get_step_to_draw);
	godot::ClassDB::bind_method(godot::D_METHOD("set_step_to_draw"), &State::set_step_to_draw);
	godot::ClassDB::bind_method(godot::D_METHOD("get_round"), &State::get_round);
	godot::ClassDB::bind_method(godot::D_METHOD("set_round"), &State::set_round);
	godot::ClassDB::bind_method(godot::D_METHOD("get_king_passant"), &State::get_king_passant);
	godot::ClassDB::bind_method(godot::D_METHOD("set_king_passant"), &State::set_king_passant);
	godot::ClassDB::bind_method(godot::D_METHOD("get_zobrist"), &State::get_zobrist);
	godot::ClassDB::bind_method(godot::D_METHOD("print_board"), &State::print_board);
	godot::ClassDB::bind_method(godot::D_METHOD("print_bit_square"), &State::print_bit_square);
	godot::ClassDB::bind_method(godot::D_METHOD("print_bit_diamond"), &State::print_bit_diamond);
}
