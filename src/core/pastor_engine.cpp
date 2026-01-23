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
	nnue_instance_pool.resize(1000);
	for (int i = 0; i < 1000; i++)
	{
		godot::Ref<NNUEInstance> new_instance = memnew(NNUEInstance);
		nnue_instance_pool[i] = new_instance;
	}

	transposition_table.instantiate();
	opening_book.instantiate();
	nnue.instantiate();

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

	if (godot::FileAccess::file_exists("user://nnue_weight.fa"))
	{
		nnue->load_file("user://nnue_weight.fa");
	}
	else
	{
		nnue->randomize_weight();
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

int PastorEngine::quies(const godot::Ref<State> &_state, const godot::Ref<NNUEInstance> &_nnue_instance, int _alpha, int _beta, int _group, int _ply)
{
	deepest_ply = std::max(_ply, deepest_ply);
	int score_relative = _group == 0 ? _nnue_instance->get_output() * 1000 : -_nnue_instance->get_output() * 1000;
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
		godot::Ref<NNUEInstance> &test_nnue_instance = nnue_instance_pool[_ply + 1];
		_state->_internal_duplicate(test_state);
		_nnue_instance->_internal_duplicate(test_nnue_instance);
		Chess::apply_move(test_state, move_list[i]);
		nnue->feedforward(test_state, test_nnue_instance);
		int test_score = -quies(test_state, test_nnue_instance, -_beta, -_alpha, 1 - _group, _ply + 1);
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

int PastorEngine::alphabeta(const godot::Ref<State> &_state, const godot::Ref<NNUEInstance> &_nnue_instance, int _alpha, int _beta, int _depth, int _group, int _ply, bool _can_null, bool _is_null, int *killer_1, int *killer_2, const godot::Callable &_debug_output)
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
		return quies(_state, _nnue_instance, _alpha, _beta, _group, _ply + 1);
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
	if (_ply > 0 && (time_passed() >= think_time || interrupted))
	{
		return quies(_state, _nnue_instance, _alpha, _beta, _group, _ply + 1);
	}

	unsigned char flag = ALPHA;
	int pv_move = transposition_table->best_move(_state->get_zobrist());
	if (_depth > 2 && _ply > 1 && _can_null)
	{
		int next_score = -alphabeta(_state, _nnue_instance, -_beta, -_beta + 1, _depth - 3, 1 - _group, _ply + 1, false, true, nullptr, nullptr, _debug_output);
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
		godot::Ref<NNUEInstance> &test_nnue_instance = nnue_instance_pool[_ply + 1];
		_state->_internal_duplicate(test_state);
		_nnue_instance->_internal_duplicate(test_nnue_instance);
		Chess::apply_move(test_state, move_list[i]);
		nnue->feedforward(test_state, test_nnue_instance);
		int next_score = 0;
		if (found_pv)
		{
			next_score = -alphabeta(test_state, test_nnue_instance, -_alpha - 1, -_alpha, _depth - 1, 1 - _group, _ply + 1, _can_null, _is_null, &next_killer_1, &next_killer_2, _debug_output);
		}
		if (!found_pv || next_score > _alpha && next_score < _beta)
		{
			next_score = -alphabeta(test_state, test_nnue_instance, -_beta, -_alpha, _depth - 1, 1 - _group, _ply + 1, _can_null, _is_null, &next_killer_1, &next_killer_2, _debug_output);
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
		alphabeta(_state, nnue->create_instance(_state), -THRESHOLD, THRESHOLD, i, _group, 0, true, false, nullptr, nullptr, _debug_output);
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
