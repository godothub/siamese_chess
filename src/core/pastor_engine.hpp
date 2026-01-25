#ifndef _PASTOR_ENGINE_H_
#define _PASTOR_ENGINE_H_

#include "engine.hpp"
#include "transposition_table.hpp"
#include "opening_book.hpp"
#include <unordered_map>
#include <vector>

class PastorEngine : public ChessEngine
{
	GDCLASS(PastorEngine, ChessEngine)
	public:
		PastorEngine();
		int get_piece_score(int _by, int _piece, int phase);
		int evaluate(const godot::Ref<State> &_state);
		int compare_move(int a, int b, int best_move, int killer_1, int killer_2, const godot::Ref<State> &state);
		int quies(const godot::Ref<State> &_state, int alpha, int beta, int _group = 0, int _ply = 0);
		void generate_good_capture_move(godot::PackedInt32Array &output, const godot::Ref<State> &_state, int _group);
		int alphabeta(const godot::Ref<State> &_state, int _alpha, int _beta, int _depth, int _group = 0, int _ply = 0, bool _can_null = true, bool _is_null = false, int *killer_1 = nullptr, int *killer_2 = nullptr, const godot::Callable &_debug_output = godot::Callable());
		void search(const godot::Ref<State> &_state, int _group, const godot::PackedInt64Array &history_state, const godot::Callable &_debug_output) override;
		int get_search_result() override;
		godot::PackedInt32Array get_principal_variation();
		int get_score();
		int get_deepest_ply();
		int get_deepest_depth();
		int get_evaluated_position();
		int get_beta_cutoff();
		int get_transposition_table_cutoff();
		void set_max_depth(int _max_depth);
		void set_despise_factor(int _despise_factor);
		void set_think_time(double _think_time);
		void set_transposition_table(const godot::Ref<TranspositionTable> &transposition_table);
		godot::Ref<TranspositionTable> get_transposition_table() const;
		static void _bind_methods();
	private:
		godot::Ref<TranspositionTable> transposition_table;
		godot::Ref<OpeningBook> opening_book;
		int max_depth;
		int WIN = 50000;
		int THRESHOLD = 60000;
		int MAX_PLY = 50;
		int despise_factor = -100;
		double think_time;
		int searched_move;
		int searched_score;

		//调试用
		int deepest_ply = 0;
		int deepest_depth = 0;
		int evaluated_position = 0;
		int beta_cutoff = 0;
		int transposition_table_cutoff = 0;
		
		std::vector<godot::Ref<State>> state_pool;
		std::unordered_map<int64_t, int> map_history_state;
		std::array<int, 65536> history_table;
		godot::PackedInt32Array principal_variation;
		std::unordered_map<int, int> piece_value;
		godot::PackedInt32Array directions_diagonal;
		godot::PackedInt32Array directions_straight;
		godot::PackedInt32Array directions_eight_way;
		godot::PackedInt32Array directions_horse;
		std::unordered_map<int, godot::PackedInt32Array> position_value_midgame;
		std::unordered_map<int, godot::PackedInt32Array> position_value_endgame;
};

#endif