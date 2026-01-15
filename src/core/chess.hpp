#ifndef _CHESS_HPP_
#define _CHESS_HPP_

#include <godot_cpp/godot.hpp>
#include <godot_cpp/classes/object.hpp>
#include <state.hpp>

class Chess : public godot::Object
{
	GDCLASS(Chess, godot::Object)
	public:
		Chess();
		static int64_t mask(int n);
		static int population(int64_t bit);
		static int first_bit(int64_t bit);
		static int64_t next_bit(int64_t bit);
		static int64_t bit_flip_vertical(int64_t bit);
		static int64_t bit_flip_diag_a1h8(int64_t bit);
		static int64_t bit_rotate_90(int64_t bit);
		static int64_t bit_rotate_45(int64_t bit);
		static int64_t bit_rotate_315(int64_t bit);
		static int rotate_90(int n);
		static int rotate_90_reverse(int n);
		static int rotate_45(int n);
		static int rotate_45_reverse(int n);
		static int rotate_315(int n);
		static int rotate_315_reverse(int n);
		static int rotate_45_length(int n);
		static int rotate_315_length(int n);
		static int rotate_45_length_mask(int n);
		static int rotate_315_length_mask(int n);
		static int rotate_0_shift(int n);
		static int rotate_90_shift(int n);
		static int rotate_45_shift(int n);
		static int rotate_315_shift(int n);
		static godot::String print_bit_square(int64_t bit);
		static godot::String print_bit_diamond(int64_t bit);
		static int direction_count(int piece);
		static int direction(int piece, int index);
		static int direction_pawn_capture(int group, bool capture_dir);
		static bool pawn_on_start(int group, int by);
		static bool pawn_on_end(int group, int by);
		static int to_64(int n);
		static int to_x88(int n);
		static int group(int piece);
		static bool is_same_group(int piece_1, int piece_2);
		static int to_position_int(const godot::String &_position_name);
		static godot::String to_position_name(int _position);
		static int create(int _from, int _to, int _extra);
		static int from(int _move);
		static int to(int _move);
		static int extra(int _move);
		static Chess *get_singleton();
		static void _bind_methods();
		
		static godot::String get_end_type(const godot::Ref<State> &_state);
		static godot::Ref<State> parse(const godot::String &_str);
		static godot::Ref<State> create_initial_state();
		static godot::Ref<State> create_random_state(int piece_count);
		static godot::Ref<State> mirror_state(const godot::Ref<State> &_state);
		static godot::Ref<State> rotate_state(const godot::Ref<State> &_state);
		static godot::Ref<State> swap_group(const godot::Ref<State> &_state);
		static godot::String stringify(const godot::Ref<State> &_state);
		static bool is_move_valid(const godot::Ref<State> &_state, int _group, int _move);
		static bool is_check(const godot::Ref<State> &_state, int _group);
		static bool is_blocked(const godot::Ref<State> &_state, int _from, int _to);
		static bool is_enemy(const godot::Ref<State> &_state, int _from, int _to);
		static bool is_en_passant(const godot::Ref<State> &_state, int _from, int _to);
		static godot::PackedInt32Array generate_premove(const godot::Ref<State> &_state, int _group);
		static godot::PackedInt32Array generate_move(const godot::Ref<State> &_state, int _group);
		static void _internal_generate_move(godot::PackedInt32Array &output, const godot::Ref<State> &_state, int _group);
		static godot::PackedInt32Array generate_valid_move(const godot::Ref<State> &_state, int _group);
		static void _internal_generate_valid_move(godot::PackedInt32Array &output, const godot::Ref<State> &_state, int _group);
		static godot::PackedInt32Array generate_explore_move(const godot::Ref<State> &_state, int _group);
		static godot::PackedInt32Array generate_king_path(const godot::Ref<State> &_state, int _from, int _to);
		static godot::String get_move_name(const godot::Ref<State> &_state, int move);
		static int name_to_move(const godot::Ref<State> &_state, const godot::String &name);
		static void apply_move(const godot::Ref<State> &_state, int _move);
		static godot::Dictionary apply_move_custom(const godot::Ref<State> &_state, int _move);
		static uint64_t perft(const godot::Ref<State> &_state, int _depth, int group);

		inline static int a8() { return 0; }
		inline static int b8() { return 1; }
		inline static int c8() { return 2; }
		inline static int d8() { return 3; }
		inline static int e8() { return 4; }
		inline static int f8() { return 5; }
		inline static int g8() { return 6; }
		inline static int h8() { return 7; }
		inline static int a1() { return 16 * 7; }
		inline static int b1() { return 16 * 7 + 1; }
		inline static int c1() { return 16 * 7 + 2; }
		inline static int d1() { return 16 * 7 + 3; }
		inline static int e1() { return 16 * 7 + 4; }
		inline static int f1() { return 16 * 7 + 5; }
		inline static int g1() { return 16 * 7 + 6; }
		inline static int h1() { return 16 * 7 + 7; }
	private:
		static Chess *singleton;
		
		const static int rotate_90_table[64];
		const static int rotate_90_reverse_table[64];
		const static int rotate_45_table[64];
		const static int rotate_45_reverse_table[64];
		const static int rotate_315_table[64];
		const static int rotate_315_reverse_table[64];
		const static int rotate_45_length_table[64];
		const static int rotate_315_length_table[64];
		const static int rotate_45_length_mask_table[64];
		const static int rotate_315_length_mask_table[64];
		const static int rotate_0_shift_table[64];
		const static int rotate_90_shift_table[64];
		const static int rotate_45_shift_table[64];
		const static int rotate_315_shift_table[64];
		static int64_t rank_wall[64][256];
		static int64_t file_wall[64][256];
		static int64_t diag_a1h8_wall[64][256];
		static int64_t diag_a8h1_wall[64][256];
		static int64_t rank_attacks[64][256];
		static int64_t file_attacks[64][256];	//将棋盘转置后使用
		static int64_t diag_a1h8_attacks[64][256];
		static int64_t diag_a8h1_attacks[64][256];
		static int64_t horse_attacks[64];
		static int64_t king_attacks[64];
		static int64_t pawn_attacks[64][2];	//游戏特殊原因，兵会被设定为八种方向
		const static int directions_diagonal[4];
		const static int directions_straight[4];
		const static int directions_eight_way[8];
		const static int directions_horse[8];
		const static int direction_pawn[2][2];
		static int64_t pawn_start[2];
		static int64_t pawn_end[2];
};

#endif