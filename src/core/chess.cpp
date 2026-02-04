#include "chess.hpp"
#include <godot_cpp/core/class_db.hpp>
#include <random>
#include <queue>
#include <unordered_set>

Chess *Chess::singleton = nullptr;

const int Chess::rotate_90_table[64] = {
	 7, 15, 23, 31, 39, 47, 55, 63,
	 6, 14, 22, 30, 38, 46, 54, 62,
	 5, 13, 21, 29, 37, 45, 53, 61,
	 4, 12, 20, 28, 36, 44, 52, 60,
	 3, 11, 19, 27, 35, 43, 51, 59,
	 2, 10, 18, 26, 34, 42, 50, 58,
	 1,  9, 17, 25, 33, 41, 49, 57,
	 0,  8, 16, 24, 32, 40, 48, 56
};


const int Chess::rotate_90_reverse_table[64] = {
	56, 48, 40, 32, 24, 16,  8,  0,
	57, 49, 41, 33, 25, 17,  9,  1,
	58, 50, 42, 34, 26, 18, 10,  2,
	59, 51, 43, 35, 27, 19, 11,  3,
	60, 52, 44, 36, 28, 20, 12,  4,
	61, 53, 45, 37, 29, 21, 13,  5,
	62, 54, 46, 38, 30, 22, 14,  6,
	63, 55, 47, 39, 31, 23, 15,  7
};

const int Chess::rotate_45_table[64]
{
	 8, 17, 26, 35, 44, 53, 62,  7,
	16, 25, 34, 43, 52, 61,  6, 15,
	24, 33, 42, 51, 60,  5, 14, 23,
	32, 41, 50, 59,  4, 13, 22, 31,
	40, 49, 58,  3, 12, 21, 30, 39,
	48, 57,  2, 11, 20, 29, 38, 47,
	56,  1, 10, 19, 28, 37, 46, 55,
	 0,  9, 18, 27, 36, 45, 54, 63,
};

const int Chess::rotate_45_reverse_table[64]
{
	56, 49, 42, 35, 28, 21, 14,  7,
	 0, 57, 50, 43, 36, 29, 22, 15,
	 8,  1, 58, 51, 44, 37, 30, 23,
	16,  9,  2, 59, 52, 45, 38, 31,
	24, 17, 10,  3, 60, 53, 46, 39,
	32, 25, 18, 11,  4, 61, 54, 47,
	40, 33, 26, 19, 12,  5, 62, 55,
	48, 41, 34, 27, 20, 13,  6, 63
};

const int Chess::rotate_315_table[64]
{
	 0, 57, 50, 43, 36, 29, 22, 15,
	 8,  1, 58, 51, 44, 37, 30, 23,
	16,  9,  2, 59, 52, 45, 38, 31,
	24, 17, 10,  3, 60, 53, 46, 39,
	32, 25, 18, 11,  4, 61, 54, 47,
	40, 33, 26, 19, 12,  5, 62, 55,
	48, 41, 34, 27, 20, 13,  6, 63,
	56, 49, 42, 35, 28, 21, 14,  7
};

const int Chess::rotate_315_reverse_table[64]
{
	 0,  9, 18, 27, 36, 45, 54, 63,
	 8, 17, 26, 35, 44, 53, 62,  7,
	16, 25, 34, 43, 52, 61,  6, 15,
	24, 33, 42, 51, 60,  5, 14, 23,
	32, 41, 50, 59,  4, 13, 22, 31,
	40, 49, 58,  3, 12, 21, 30, 39,
	48, 57,  2, 11, 20, 29, 38, 47,
	56,  1, 10, 19, 28, 37, 46, 55
};

const int Chess::rotate_45_length_table[64]
{
	1, 2, 3, 4, 5, 6, 7, 8,
	2, 3, 4, 5, 6, 7, 8, 7,
	3, 4, 5, 6, 7, 8, 7, 6,
	4, 5, 6, 7, 8, 7, 6, 5,
	5, 6, 7, 8, 7, 6, 5, 4,
	6, 7, 8, 7, 6, 5, 4, 3,
	7, 8, 7, 6, 5, 4, 3, 2,
	8, 7, 6, 5, 4, 3, 2, 1,
};

const int Chess::rotate_315_length_table[64]
{
	8, 7, 6, 5, 4, 3, 2, 1,
	7, 8, 7, 6, 5, 4, 3, 2,
	6, 7, 8, 7, 6, 5, 4, 3,
	5, 6, 7, 8, 7, 6, 5, 4,
	4, 5, 6, 7, 8, 7, 6, 5,
	3, 4, 5, 6, 7, 8, 7, 6,
	2, 3, 4, 5, 6, 7, 8, 7,
	1, 2, 3, 4, 5, 6, 7, 8,
};

const int Chess::rotate_45_length_mask_table[64]
{
	   1,   3,   7,  15,  31,  63, 127, 255,
	   3,   7,  15,  31,  63, 127, 255, 127,
	   7,  15,  31,  63, 127, 255, 127,  63,
	  15,  31,  63, 127, 255, 127,  63,  31,
	  31,  63, 127, 255, 127,  63,  31,  15,
	  63, 127, 255, 127,  63,  31,  15,   7,
	 127, 255, 127,  63,  31,  15,   7,   3,
	 255, 127,  63,  31,  15,   7,   3,   1
};

const int Chess::rotate_315_length_mask_table[64]
{
	255, 127,  63,  31,  15,   7,   3,   1,
	127, 255, 127,  63,  31,  15,   7,   3,
	 63, 127, 255, 127,  63,  31,  15,   7,
	 31,  63, 127, 255, 127,  63,  31,  15,
	 15,  31,  63, 127, 255, 127,  63,  31,
	  7,  15,  31,  63, 127, 255, 127,  63,
	  3,   7,  15,  31,  63, 127, 255, 127,
	  1,   3,   7,  15,  31,  63, 127, 255,
};

const int Chess::rotate_0_shift_table[64]
{
	 0,  0,  0,  0,  0,  0,  0,  0,
	 8,  8,  8,  8,  8,  8,  8,  8,
	16, 16, 16, 16, 16, 16, 16, 16,
	24, 24, 24, 24, 24, 24, 24, 24,
	32, 32, 32, 32, 32, 32, 32, 32,
	40, 40, 40, 40, 40, 40, 40, 40,
	48, 48, 48, 48, 48, 48, 48, 48,
	56, 56, 56, 56, 56, 56, 56, 56
};

const int Chess::rotate_90_shift_table[64]
{
	0, 8, 16, 24, 32, 40, 48, 56,
	0, 8, 16, 24, 32, 40, 48, 56,
	0, 8, 16, 24, 32, 40, 48, 56,
	0, 8, 16, 24, 32, 40, 48, 56,
	0, 8, 16, 24, 32, 40, 48, 56,
	0, 8, 16, 24, 32, 40, 48, 56,
	0, 8, 16, 24, 32, 40, 48, 56,
	0, 8, 16, 24, 32, 40, 48, 56
};

const int Chess::rotate_45_shift_table[64]
{
	 8, 16, 24, 32, 40, 48, 56,  0,
	16, 24, 32, 40, 48, 56,  0,  9,
	24, 32, 40, 48, 56,  0,  9, 18,
	32, 40, 48, 56,  0,  9, 18, 27, 
	40, 48, 56,  0,  9, 18, 27, 36,
	48, 56,  0,  9, 18, 27, 36, 45,
	56,  0,  9, 18, 27, 36, 45, 54,
	 0,  9, 18, 27, 36, 45, 54, 63
};

const int Chess::rotate_315_shift_table[64]
{
	 0, 57, 50, 43, 36, 29, 22, 15,
	 8,  0, 57, 50, 43, 36, 29, 22,
	16,  8,  0, 57, 50, 43, 36, 29,
	24, 16,  8,  0, 57, 50, 43, 36,
	32, 24, 16,  8,  0, 57, 50, 43,
	40, 32, 24, 16,  8,  0, 57, 50,
	48, 40, 32, 24, 16,  8,  0, 57,
	56, 48, 40, 32, 24, 16,  8,  0
};

int64_t Chess::rank_wall[64][256] = {};
int64_t Chess::file_wall[64][256] = {};
int64_t Chess::diag_a1h8_wall[64][256] = {};
int64_t Chess::diag_a8h1_wall[64][256] = {};
int64_t Chess::rank_attacks[64][256] = {};
int64_t Chess::file_attacks[64][256] = {};	//将棋盘转置后使用
int64_t Chess::diag_a1h8_attacks[64][256] = {};
int64_t Chess::diag_a8h1_attacks[64][256] = {};
int64_t Chess::horse_attacks[64] = {};
int64_t Chess::king_attacks[64] = {};
int64_t Chess::pawn_attacks[64][2] = {};	//游戏特殊原因，兵会被设定为四种方向
const int Chess::directions_diagonal[4] = {-17, -15, 15, 17};
const int Chess::directions_straight[4] = {-16, -1, 1, 16};
const int Chess::directions_eight_way[8] = {-17, -16, -15, -1, 1, 15, 16, 17};
const int Chess::directions_horse[8] = {33, 31, 18, 14, -33, -31, -18, -14};
const int Chess::direction_pawn[2][2] = {{-17, -15}, {17, 15}};
int64_t Chess::pawn_start[2] = {0x00FF000000000000, 0x000000000000FF00};
int64_t Chess::pawn_end[2] = {0x0000000000FF00, 0x00FF000000000000};

Chess::Chess()
{
	for (int i = 0; i < 64; i++)	//墙（行）
	{
		//bit所在位置设置为1时，右侧的缝隙就是墙壁了
		//和攻击范围不一样，这里标记能走的范围不能够多走一格
		//向右走时，还需要再走多一格，才能够在这一格上标记
		//向左走并不需要特别注意这些
		for (int j = 0; j < 256; j++)
		{
			uint64_t barrel = uint64_t(j) << Chess::rotate_0_shift(i);
			int64_t bit = 0;
			for (int k = Chess::to_x88(i); !(k & 0x88); k--)
			{
				bit |= Chess::mask(Chess::to_64(k));
				if (!((k - 1) & 0x88) && (Chess::mask(Chess::to_64(k - 1)) & barrel))
				{
					break;
				}
			}
			for (int k = Chess::to_x88(i); !(k & 0x88); k++)
			{
				bit |= Chess::mask(Chess::to_64(k));
				if (Chess::mask(Chess::to_64(k)) & barrel)
				{
					break;
				}
			}
			rank_wall[i][j] = bit;
		}
	}
	
	for (int i = 0; i < 64; i++)	//墙（列）
	{
		//bit所在位置设置为1时，下方的缝隙就是墙壁
		for (int j = 0; j < 256; j++)
		{
			uint64_t barrel_rotated = uint64_t(j) << Chess::rotate_90_shift(i);
			uint64_t barrel = 0;
			for (int k = 0; k < 64; k++)
			{
				if (barrel_rotated & 1)
				{
					barrel |= Chess::mask(Chess::rotate_90_reverse(k));
				}
				barrel_rotated >>= 1;
			}
			int64_t bit = 0;
			for (int k = Chess::to_x88(i); !(k & 0x88); k -= 16)
			{
				bit |= Chess::mask(Chess::to_64(k));
				if (!((k - 16) & 0x88) && (Chess::mask(Chess::to_64(k - 16)) & barrel))
				{
					break;
				}
			}
			for (int k = Chess::to_x88(i); !(k & 0x88); k += 16)
			{
				bit |= Chess::mask(Chess::to_64(k));
				if (Chess::mask(Chess::to_64(k)) & barrel)
				{
					break;
				}
			}
			file_wall[i][j] = bit;
		}
	}

	for (int i = 0; i < 64; i++)	//墙（角）（a1h8)
	{
		//bit所在位置设置为1时，右下角位置则为墙角
		//但是从左下到右上之时，能到达最远的地方，其标记在上方格子
		//从右上到左下时，能到达最远的地方，标记在左侧
		//特别小心：需要检测的位置是在上一条斜线，而不是这一条
		int last_diag = !((Chess::to_x88(i) - 1) & 0x88) ? i - 1 : 
						(!((Chess::to_x88(i) - 16) & 0x88) ? i - 8 : 63);
		for (int j = 0; j < 256; j++)
		{
			uint64_t barrel_rotated = uint64_t(j) << Chess::rotate_45_shift(last_diag);
			uint64_t barrel = 0;
			for (int k = 0; k < 64; k++)
			{
				if (barrel_rotated & 1)
				{
					barrel |= Chess::mask(Chess::rotate_45_reverse(k));
				}
				barrel_rotated >>= 1;
			}
			int64_t bit = 0;
			for (int k = Chess::to_x88(i); !(k & 0x88); k -= 15)
			{
				bit |= Chess::mask(Chess::to_64(k));
				if (!((k - 16) & 0x88) && (Chess::mask(Chess::to_64(k - 16)) & barrel))
				{
					break;
				}
			}
			for (int k = Chess::to_x88(i); !(k & 0x88); k += 15)
			{
				bit |= Chess::mask(Chess::to_64(k));
				if (!((k - 1) & 0x88) && (Chess::mask(Chess::to_64(k - 1)) & barrel))
				{
					break;
				}
			}
			diag_a1h8_wall[i][j] = bit;
		}
	}
	for (int i = 0; i < 64; i++)	//墙（角）（a8h1)
	{
		//bit所在位置设置为1时，右下角位置则为墙角
		for (int j = 0; j < 256; j++)
		{
			uint64_t barrel_rotated = uint64_t(j) << Chess::rotate_315_shift(i);
			uint64_t barrel = 0;
			for (int k = 0; k < 64; k++)
			{
				if (barrel_rotated & 1)
				{
					barrel |= Chess::mask(Chess::rotate_315_reverse(k));
				}
				barrel_rotated >>= 1;
			}
			int64_t bit = 0;
			for (int k = Chess::to_x88(i); !(k & 0x88); k -= 17)
			{
				bit |= Chess::mask(Chess::to_64(k));
				if (!((k - 17) & 0x88) && (Chess::mask(Chess::to_64(k - 17)) & barrel))
				{
					break;
				}
			}
			for (int k = Chess::to_x88(i); !(k & 0x88); k += 17)
			{
				bit |= Chess::mask(Chess::to_64(k));
				if (Chess::mask(Chess::to_64(k)) & barrel)
				{
					break;
				}
			}
			diag_a8h1_wall[i][j] = bit;
		}
	}
	for (int i = 0; i < 64; i++)	//直线行
	{
		for (int j = 0; j < 256; j++)
		{
			uint64_t barrel = uint64_t(j) << Chess::rotate_0_shift(i);
			int64_t bit = 0;
			for (int k = Chess::to_x88(i) - 1; !(k & 0x88); k--)	//试着向左走
			{
				bit |= Chess::mask(Chess::to_64(k));
				if (Chess::mask(Chess::to_64(k)) & barrel)
				{
					break;
				}
			}
			for (int k = Chess::to_x88(i) + 1; !(k & 0x88); k++)	//试着向右走
			{
				bit |= Chess::mask(Chess::to_64(k));
				if (Chess::mask(Chess::to_64(k)) & barrel)
				{
					break;
				}
			}
			rank_attacks[i][j] = bit;
		}
	}
	for (int i = 0; i < 64; i++)	//直线列
	{
		for (int j = 0; j < 256; j++)
		{
			uint64_t barrel_rotated = uint64_t(j) << Chess::rotate_90_shift(i);
			uint64_t barrel = 0;
			for (int k = 0; k < 64; k++)
			{
				if (barrel_rotated & 1)
				{
					barrel |= Chess::mask(Chess::rotate_90_reverse(k));
				}
				barrel_rotated >>= 1;
			}
			int64_t bit = 0;
			for (int k = Chess::to_x88(i) - 16; !(k & 0x88); k -= 16)	//试着向上走
			{
				bit |= Chess::mask(Chess::to_64(k));
				if (Chess::mask(Chess::to_64(k)) & barrel)
				{
					break;
				}
			}
			for (int k = Chess::to_x88(i) + 16; !(k & 0x88); k += 16)	//试着向下走
			{
				bit |= Chess::mask(Chess::to_64(k));
				if (Chess::mask(Chess::to_64(k)) & barrel)
				{
					break;
				}
			}
			file_attacks[i][j] = bit;
		}
	}
	for (int i = 0; i < 64; i++)	//斜线a1h8
	{
		for (int j = 0; j <= Chess::rotate_45_length_mask(i); j++)
		{
			uint64_t barrel_rotated = uint64_t(j) << Chess::rotate_45_shift(i);
			uint64_t barrel = 0;
			for (int k = 0; k < 64; k++)
			{
				if (barrel_rotated & 1)
				{
					barrel |= Chess::mask(Chess::rotate_45_reverse(k));
				}
				barrel_rotated >>= 1;
			}
			int64_t bit = 0;
			for (int k = Chess::to_x88(i) - 15; !(k & 0x88); k -= 15)	//不超界即可，往右上
			{
				bit |= Chess::mask(Chess::to_64(k));
				if (Chess::mask(Chess::to_64(k)) & barrel)
				{
					break;
				}
			}
			for (int k = Chess::to_x88(i) + 15; !(k & 0x88); k += 15)	//往左下
			{
				bit |= Chess::mask(Chess::to_64(k));
				if (Chess::mask(Chess::to_64(k)) & barrel)
				{
					break;
				}
			}
			diag_a1h8_attacks[i][j] = bit;
		}
	}
	for (int i = 0; i < 64; i++)	//斜线a8h1
	{
		for (int j = 0; j <= Chess::rotate_315_length_mask(i); j++)
		{
			uint64_t barrel_rotated = uint64_t(j) << Chess::rotate_315_shift(i);
			uint64_t barrel = 0;
			for (int k = 0; k < 64; k++)
			{
				if (barrel_rotated & 1)
				{
					barrel |= Chess::mask(Chess::rotate_315_reverse(k));
				}
				barrel_rotated >>= 1;
			}
			int64_t bit = 0;
			for (int k = Chess::to_x88(i) - 17; !(k & 0x88); k -= 17)	//往左上
			{
				bit |= Chess::mask(Chess::to_64(k));
				if (Chess::mask(Chess::to_64(k)) & barrel)
				{
					break;
				}
			}
			for (int k = Chess::to_x88(i) + 17; !(k & 0x88); k += 17)	//往右下
			{
				bit |= Chess::mask(Chess::to_64(k));
				if (Chess::mask(Chess::to_64(k)) & barrel)
				{
					break;
				}
			}
			diag_a8h1_attacks[i][j] = bit;
		}
	}
	for (int i = 0; i < 64; i++)	//马
	{
		int from = Chess::to_x88(i);
		for (int j = 0; j < direction_count('N'); j++)
		{
			int to = from + direction('N', j);
			if (to & 0x88)
			{
				continue;
			}
			horse_attacks[i] |= Chess::mask(Chess::to_64(to));
		}
	}
	for (int i = 0; i < 64; i++)	//王
	{
		int from = Chess::to_x88(i);
		for (int j = 0; j < direction_count('K'); j++)
		{
			int to = from + direction('K', j);
			if (to & 0x88)
			{
				continue;
			}
			king_attacks[i] |= Chess::mask(Chess::to_64(to));
		}
	}
	for (int i = 0; i < 64; i++)	//兵，且不算吃过路兵
	{
		int from = Chess::to_x88(i);
		for (int j = 0; j < 2; j++)
		{
			int to = from + direction_pawn_capture(j, false);
			if (!(to & 0x88))
			{
				pawn_attacks[i][j] |= Chess::mask(Chess::to_64(to));
			}
			to = from + direction_pawn_capture(j, true);
			if (!(to & 0x88))
			{
				pawn_attacks[i][j] |= Chess::mask(Chess::to_64(to));
			}
		}
	}
}

int Chess::rotate_90(int n)
{
	return rotate_90_table[n];
}

int Chess::rotate_90_reverse(int n)
{
	return rotate_90_reverse_table[n];
}

int Chess::rotate_45(int n)
{
	return rotate_45_table[n];
}
int Chess::rotate_45_reverse(int n)
{
	return rotate_45_reverse_table[n];
}

int Chess::rotate_315(int n)
{
	return rotate_315_table[n];
}

int Chess::rotate_315_reverse(int n)
{
	return rotate_315_reverse_table[n];
}
int Chess::rotate_45_length(int n)
{
	return rotate_45_length_table[n];
}

int Chess::rotate_315_length(int n)
{
	return rotate_315_length_table[n];
}

int Chess::rotate_45_length_mask(int n)
{
	return rotate_45_length_mask_table[n];
}

int Chess::rotate_315_length_mask(int n)
{
	return rotate_315_length_mask_table[n];
}

int Chess::rotate_0_shift(int n)
{
	return rotate_0_shift_table[n];
}

int Chess::rotate_90_shift(int n)
{
	return rotate_90_shift_table[n];
}

int Chess::rotate_45_shift(int n)
{
	return rotate_45_shift_table[n];
}

int Chess::rotate_315_shift(int n)
{
	return rotate_315_shift_table[n];
}

godot::String Chess::print_bit_square(int64_t bit)
{
	godot::String output;
	uint64_t current_bit = bit;
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

godot::String Chess::print_bit_diamond(int64_t bit)
{
	godot::String output;
	uint64_t current_bit = bit;
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

int Chess::direction_count(int piece)
{
	switch (piece)
	{
		case 'K':
		case 'k':
		case 'Q':
		case 'q':
		case 'N':
		case 'n':
			return 8;
		break;
		case 'R':
		case 'r':
		case 'B':
		case 'b':
			return 4;
		break;
	}
	return 0;
}

int Chess::direction(int piece, int index)
{
	switch (piece)
	{
		case 'K':
		case 'k':
		case 'Q':
		case 'q':
			return directions_eight_way[index];
		break;
		case 'N':
		case 'n':
			return directions_horse[index];
		break;
		case 'R':
		case 'r':
			return directions_straight[index];
		break;
		case 'B':
		case 'b':
			return directions_diagonal[index];
		break;
		case 'P':
			return -16;
		break;
		case 'p':
			return 16;
		break;
	}
	return 0;
}

int Chess::direction_pawn_capture(int group, bool capture_dir)
{
	return direction_pawn[group][capture_dir];

}

bool Chess::pawn_on_start(int group, int by)
{
	return pawn_start[group] & Chess::mask(Chess::to_64(by));
}

bool Chess::pawn_on_end(int group, int by)
{
	return pawn_end[group] & Chess::mask(Chess::to_64(by));
}

int64_t Chess::mask(int n)
{
	return 1LL << n;
}

int Chess::population(int64_t bit)
{
	const uint64_t k1 = 0x5555555555555555;
	const uint64_t k2 = 0x3333333333333333;
	const uint64_t k4 = 0x0f0f0f0f0f0f0f0f;
	const uint64_t kf = 0x0101010101010101;
	uint64_t x = bit;	//不声明uint64_t是因为Godot的数据类型限制
	x = x - ((x >> 1) & k1);
	x = (x & k2) + ((x >> 2) & k2);
	x = (x + (x >> 4)) & k4;
	x = (x * kf) >> 56;
	return (int)x;
}

int Chess::first_bit(int64_t bit)
{
	static const int table[64] = {
		 0,  1, 48,  2, 57, 49, 28,  3,
		61, 58, 50, 42, 38, 29, 17,  4,
		62, 55, 59, 36, 53, 51, 43, 22,
		45, 39, 33, 30, 24, 18, 12,  5,
		63, 47, 56, 27, 60, 41, 37, 16,
		54, 35, 52, 21, 44, 32, 23, 11,
		46, 26, 40, 15, 34, 20, 31, 10,
		25, 14, 19,  9, 13,  8,  7,  6
	};
	const uint64_t debruijn64 = 0x03f79d71b4cb0a89;	//这是个magic number
	uint64_t x = bit;
	if (x == 0)
	{
		return -1;	//存在找不到的情况
	}
	return table[((x & -x) * debruijn64) >> 58];
}

int64_t Chess::next_bit(int64_t bit)
{
	uint64_t x = bit;
	return x & (x - 1);
}

int64_t Chess::bit_flip_vertical(int64_t bit)
{
	uint64_t x = bit;
	return ((x << 56)) |
		   ((x << 40) & 0x00ff000000000000) |
		   ((x << 24) & 0x0000ff0000000000) |
		   ((x <<  8) & 0x000000ff00000000) |
		   ((x >>  8) & 0x00000000ff000000) |
		   ((x >> 24) & 0x0000000000ff0000) |
		   ((x >> 40) & 0x000000000000ff00) |
		   ((x >> 56));
}

int64_t Chess::bit_flip_diag_a1h8(int64_t bit)
{
	uint64_t x = bit;
	uint64_t t;
	const uint64_t k1 = 0x5500550055005500;
	const uint64_t k2 = 0x3333000033330000;
	const uint64_t k4 = 0x0f0f0f0f00000000;
	t  = k4 & (x ^ (x << 28));
	x ^=       t ^ (t >> 28) ;
	t  = k2 & (x ^ (x << 14));
	x ^=       t ^ (t >> 14) ;
	t  = k1 & (x ^ (x <<  7));
	x ^=       t ^ (t >>  7) ;
	return x;
}

int64_t Chess::bit_rotate_90(int64_t bit)
{
	return bit_flip_diag_a1h8(bit_flip_vertical(bit));
}

int64_t Chess::bit_rotate_45(int64_t bit)
{
	uint64_t x = bit;
	const uint64_t k1 = 0x5555555555555555;
	const uint64_t k2 = 0x3333333333333333;
	const uint64_t k4 = 0x0f0f0f0f0f0f0f0f;
	x ^= k1 & (x ^ ((x >> 8) | (x << (64 - 8))));
	x ^= k2 & (x ^ ((x >> 16) | (x << (64 - 16))));
	x ^= k4 & (x ^ ((x >> 32) | (x << (64 - 32))));
	return x;
}

int64_t Chess::bit_rotate_315(int64_t bit)
{
	uint64_t x = bit;
	const uint64_t k1 = 0xAAAAAAAAAAAAAAAA;
	const uint64_t k2 = 0xCCCCCCCCCCCCCCCC;
	const uint64_t k4 = 0xF0F0F0F0F0F0F0F0;
	x ^= k1 & (x ^ ((x >> 8) | (x << (64 - 8))));
	x ^= k2 & (x ^ ((x >> 16) | (x << (64 - 16))));
	x ^= k4 & (x ^ ((x >> 32) | (x << (64 - 32))));
	return x;
}

int Chess::to_64(int n)
{
	return (n >> 4 << 3) | (n & 0xF);
}

int Chess::to_x88(int n)
{
	return (n >> 3 << 4) | (n & 7);
}

int Chess::group(int piece)
{
	return piece >= 'a' && piece <= 'z';
}

bool Chess::is_same_group(int piece_1, int piece_2)
{
	return (piece_1 >= 'A' && piece_1 <= 'Z') == (piece_2 >= 'A' && piece_2 <= 'Z');
}

int Chess::to_position_int(const godot::String &_position_name)
{
	return ((7 - (_position_name[1] - '1')) << 4) + _position_name[0] - 'a';
}

godot::String Chess::to_position_name(int _position)
{
	return godot::String::chr((_position & 15) + 'a') + godot::String::chr((7 - (_position >> 4)) + '1');
}

int Chess::create(int _from, int _to, int _extra)
{
	return _from + (_to << 8) + (_extra << 16);
}

int Chess::from(int _move)
{
	return _move & 0xFF;
}

int Chess::to(int _move)
{
	return (_move >> 8) & 0xFF;
}

int Chess::extra(int _move)
{
	return (_move >> 16) & 0xFF;
}

Chess *Chess::get_singleton()
{
	if (!singleton)
	{
		singleton = memnew(Chess);
	}
	return singleton;
}

godot::String Chess::get_end_type(const godot::Ref<State> &_state)
{
	int group = _state->get_turn();
	if (generate_valid_move(_state, group).size() == 0)
	{
		if (is_check(_state, 1 - group))
		{
			return group == 0 ? "checkmate_black" : "checkmate_white";
		}
		else
		{
			return group == 0 ? "stalemate_black" : "stalemate_white";
		}
	}
	if (_state->get_step_to_draw() == 50)
	{
		return "50_moves";
	}
	if (population(_state->get_bit('Q')) == 0 && population(_state->get_bit('q')) == 0 && 
		population(_state->get_bit('R')) == 0 && population(_state->get_bit('r')) == 0 && 
		population(_state->get_bit('P')) == 0 && population(_state->get_bit('p')) == 0 && 
		(population(_state->get_bit('B')) == 1 && population(_state->get_bit('N')) == 0 || population(_state->get_bit('B')) == 0) && 
		(population(_state->get_bit('b')) == 1 && population(_state->get_bit('n')) == 0 || population(_state->get_bit('b')) == 0))
	{
		return "not_enough_piece";
	}
	return "";
}

godot::Ref<State> Chess::parse(const godot::String &_str)
{
	godot::Ref<State>state = memnew(State);
	godot::Vector2i pointer = godot::Vector2i(0, 0);
	godot::PackedStringArray fen_splited = _str.split(" ");
	for (int i = 0; i < fen_splited[0].length(); i++)
	{
		if (fen_splited[0][i] == '/')	//太先进了竟然是char32
		{
			pointer.x = 0;
			pointer.y += 1;
		}
		else if (fen_splited[0][i] >= '1' && fen_splited[0][i] <= '9')
		{
			pointer.x += fen_splited[0][i] - '0';
		}
		else
		{
			state->add_piece(pointer.x + pointer.y * 16, fen_splited[0][i]);
			pointer.x += 1;
		}
	}
	if (pointer.x != 8 || pointer.y != 7)
	{
		return nullptr;
	}
	if (fen_splited[1] != "w" && fen_splited[1] != "b")
	{
		return nullptr;
	}
	if (fen_splited.size() >= 5 && !fen_splited[4].is_valid_int())
	{
		return nullptr;
	}
	if (fen_splited.size() >= 6 && !fen_splited[5].is_valid_int())
	{
		return nullptr;
	}
	state->set_turn(fen_splited[1] == "w" ? 0 : 1);
	state->set_castle((int(fen_splited[2].contains("K")) << 3) + (int(fen_splited[2].contains("Q")) << 2) + (int(fen_splited[2].contains("k")) << 1) + int(fen_splited[2].contains("q")));
	state->set_en_passant(Chess::to_position_int(fen_splited[3]));
	if (fen_splited.size() >= 5)
	{
		state->set_step_to_draw(fen_splited[4].to_int());
	}
	else
	{
		state->set_step_to_draw(0);
	}
	if (fen_splited.size() >= 6)
	{
		state->set_round(fen_splited[5].to_int());
	}
	else
	{
		state->set_round(1);
	}
	
	for (int i = 6; i < fen_splited.size(); i++)
	{
		int type = fen_splited[i][0];
		int64_t bit = fen_splited[i].substr(1).hex_to_int();
		state->set_bit(type, bit);
	}
	return state;
}

godot::Ref<State> Chess::create_initial_state()
{
	return parse("rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1");
}

godot::Ref<State> Chess::create_random_state(int piece_count)
{
	std::mt19937_64 rng(time(nullptr));
	godot::PackedInt32Array type = {'P', 'N', 'B', 'R', 'Q', '*', '#'};
	godot::PackedInt32Array pieces;
	pieces.push_back('K');
	pieces.push_back('k');
	for (int i = 2; i < piece_count; i++)
	{
		int piece = type[rng() % type.size()];
		pieces.push_back(piece);
		pieces.push_back(piece + 32);	// 黑方
	}
	pieces.resize(64);
	while (true)
	{
		godot::Ref<State> new_state = parse("8/8/8/8/8/8/8/8 w - - 0 1");
		bool valid_pawn = true;
		for (int i = 0; i < pieces.size(); i++)
		{
			int k = rng() % (i + 1);
			std::swap(pieces[i], pieces[k]);
		}
		for (int i = 0; i < 64; i++)
		{
			if ((pieces[i] & 95) == 'P' && (i <= 7 || i >= 56))
			{
				valid_pawn = false;
				break;
			}
			if (pieces[i] != 0)
			{
				new_state->add_piece(i % 8 + i / 8 * 16, pieces[i]);
			}
		}
		if (!valid_pawn)
		{
			continue;
		}
		if (is_check(new_state, 0) || is_check(new_state, 1))
		{
			continue;
		}

		return new_state;
	}
	return nullptr;
}

godot::Ref<State> Chess::mirror_state(const godot::Ref<State> &_state)
{
	godot::Ref<State> output = memnew(State);
	for (State::PieceIterator iter = _state->piece_iterator_begin(); !iter.end(); iter.next())
	{
		int _from = iter.pos();
		int from_mirrored = (_from >> 4 << 4) | (7 - (_from & 0xF));
		int from_piece = iter.piece();
		output->add_piece(from_mirrored, from_piece);
	}
	output->set_turn(_state->get_turn());
	output->set_castle(_state->get_castle());
	output->set_en_passant(_state->get_en_passant());
	output->set_step_to_draw(_state->get_step_to_draw());
	output->set_round(_state->get_round());
	output->set_king_passant(_state->get_king_passant());
	return output;
}

godot::Ref<State> Chess::rotate_state(const godot::Ref<State> &_state)
{
	godot::Ref<State> output = memnew(State);
	for (State::PieceIterator iter = _state->piece_iterator_begin(); !iter.end(); iter.next())
	{
		int _from = iter.pos();
		int from_rotated = Chess::to_x88(63 - Chess::to_64(_from));
		int from_piece = iter.piece();
		output->add_piece(from_rotated, from_piece);
	}
	output->set_turn(_state->get_turn());
	output->set_castle(_state->get_castle());
	output->set_en_passant(_state->get_en_passant());
	output->set_step_to_draw(_state->get_step_to_draw());
	output->set_round(_state->get_round());
	output->set_king_passant(_state->get_king_passant());
	return output;
}

godot::Ref<State> Chess::swap_group(const godot::Ref<State> &_state)
{
	
	godot::Ref<State> output = memnew(State);
	for (State::PieceIterator iter = _state->piece_iterator_begin(); !iter.end(); iter.next())
	{
		int _from = iter.pos();
		int from_piece = iter.piece();
		int from_piece_fliped = Chess::group(from_piece) == 0 ? from_piece + 32 : from_piece - 32;
		output->add_piece(_from, from_piece_fliped);
	}
	output->set_turn(1 - _state->get_turn());
	output->set_castle(_state->get_castle());
	output->set_en_passant(_state->get_en_passant());
	output->set_step_to_draw(_state->get_step_to_draw());
	output->set_round(_state->get_round());
	output->set_king_passant(_state->get_king_passant());
	return output;
}

godot::String Chess::stringify(const godot::Ref<State> &_state)
{
	int null_counter = 0;
	godot::PackedStringArray chessboard;
	for (int i = 0; i < 8; i++)
	{
		godot::String line = "";
		for (int j = 0; j < 8; j++)
		{
			if (_state->get_piece((i << 4) + j))
			{
				if (null_counter)
				{
					line += null_counter + '0';
					null_counter = 0;
				}
				line += _state->get_piece((i << 4) + j);
			}
			else
			{
				null_counter += 1;
			}
		}
		if (null_counter)
		{
			line += null_counter + '0';
			null_counter = 0;
		}
		chessboard.append(line);
	}
	godot::PackedStringArray output = {godot::String("/").join(chessboard)};
	output.push_back(_state->get_turn() == 0 ? "w" : "b");
	output.push_back("");
	output[2] += (_state->get_castle() & 8) ? "K" : "";
	output[2] += (_state->get_castle() & 4) ? "Q" : "";
	output[2] += (_state->get_castle() & 2) ? "k" : "";
	output[2] += (_state->get_castle() & 1) ? "q" : "";
	if (!output[2])
	{
		output[2] = "-";
	}
	output.push_back(_state->get_en_passant() ? Chess::to_position_name(_state->get_en_passant()) : "-");
	output.push_back(godot::String::num(_state->get_step_to_draw(), 0));
	output.push_back(godot::String::num(_state->get_round(), 0));
	// king_passant是为了判定是否违规走子，临时记录的，这里不做转换
	return godot::String(" ").join(output);
}

//针对置换表着法/杀手着法中某种状态下着法合法，但其他状态不一定合法的情况
bool Chess::is_move_valid(const godot::Ref<State> &_state, int _group, int _move)
{
	int from = Chess::from(_move);
	int from_64 = Chess::to_64(from);
	int from_piece = _state->get_piece(from);
	if (!from_piece || _group != Chess::group(from_piece))
	{
		return false;
	}
	int to = Chess::to(_move);
	int to_64 = Chess::to_64(to);
	int to_piece = _state->get_piece(to);
	if ((from_piece & 95) == 'P')
	{
		int front = direction(from_piece, 0);
		int front_capture_left = direction_pawn_capture(_group, false);
		int front_capture_right = direction_pawn_capture(_group, true);
		bool on_start = pawn_on_start(_group, from);
		if (to == from + front && _state->has_piece(from + front))
		{
			return false;
		}
		if (to == from + front + front && _state->has_piece(from + front + front))
		{
			return false;
		}
		if (to == from + front_capture_left && (!_state->has_piece(to) || !(!on_start && _state->get_en_passant() == to)))
		{
			return false;
		}
		if (to == from + front_capture_right && (!_state->has_piece(to) || !(!on_start && _state->get_en_passant() == to)))
		{
			return false;
		}
	}
	if ((from_piece & 95) == 'B')
	{
		uint64_t occupied = _state->get_bit(ALL_PIECE);
		uint64_t occupied_rotate_45 = bit_rotate_45(occupied);
		uint64_t occupied_rotate_315 = bit_rotate_315(occupied);
		int64_t diag_a1h8 = (occupied_rotate_45 >> Chess::rotate_45_shift(from_64)) & Chess::rotate_45_length_mask(from_64);
		int64_t diag_a8h1 = (occupied_rotate_315 >> Chess::rotate_315_shift(from_64)) & Chess::rotate_315_length_mask(from_64);
		int64_t bishop_attacks = diag_a1h8_attacks[from_64][diag_a1h8] | diag_a8h1_attacks[from_64][diag_a8h1];
		if (!(bishop_attacks & Chess::mask(to_64)))
		{
			return false;
		}
	}
	if ((from_piece & 95) == 'R')
	{
		uint64_t occupied = _state->get_bit(ALL_PIECE);
		uint64_t occupied_rotate_90 = bit_rotate_90(occupied);
		int64_t rank = (occupied >> Chess::rotate_0_shift(from_64)) & 255;
		int64_t file = (occupied_rotate_90 >> Chess::rotate_90_shift(from_64)) & 255;
		int64_t rook_attacks = rank_attacks[from_64][rank] | file_attacks[from_64][file];
		if (!(rook_attacks & Chess::mask(to_64)))
		{
			return false;
		}
	}
	if ((from_piece & 95) == 'Q')
	{
		uint64_t occupied = _state->get_bit(ALL_PIECE);
		uint64_t occupied_rotate_90 = bit_rotate_90(occupied);
		uint64_t occupied_rotate_45 = bit_rotate_45(occupied);
		uint64_t occupied_rotate_315 = bit_rotate_315(occupied);
		int64_t diag_a1h8 = (occupied_rotate_45 >> Chess::rotate_45_shift(from_64)) & Chess::rotate_45_length_mask(from_64);
		int64_t diag_a8h1 = (occupied_rotate_315 >> Chess::rotate_315_shift(from_64)) & Chess::rotate_315_length_mask(from_64);
		int64_t rank = (occupied >> Chess::rotate_0_shift(from_64)) & 255;
		int64_t file = (occupied_rotate_90 >> Chess::rotate_90_shift(from_64)) & 255;
		int64_t queen_attacks = diag_a1h8_attacks[from_64][diag_a1h8] | diag_a8h1_attacks[from_64][diag_a8h1] | rank_attacks[from_64][rank] | file_attacks[from_64][file];
		if (!(queen_attacks & Chess::mask(to_64)))
		{
			return false;
		}
	}
	godot::Ref<State>test_state = _state->duplicate();
	apply_move(test_state, _move);
	return !is_check(test_state, 1 - _group);
}

bool Chess::is_check(const godot::Ref<State> &_state, int _group)
{
	DEV_ASSERT(_state.is_valid());
	int enemy_king = _group == 0 ? 'k' : 'K';
	uint64_t enemy_king_mask = _state->get_bit(enemy_king);
	if (_state->get_king_passant() != -1)
	{
		enemy_king_mask |= Chess::mask(Chess::to_64(_state->get_king_passant()));
		enemy_king_mask |= Chess::mask(Chess::to_64(_state->get_king_passant() - 1));
		enemy_king_mask |= Chess::mask(Chess::to_64(_state->get_king_passant() + 1));
	}
	
	for (State::PieceIterator iter = _state->piece_iterator_begin(_group == 0 ? WHITE : BLACK); !iter.end(); iter.next())
	{
		int from = iter.pos();
		int from_64 = Chess::to_64(from);
		int from_piece = iter.piece();
		if ((from_piece & 95) == 'P')
		{
			if (pawn_attacks[from_64][_group] & enemy_king_mask)
			{
				
				int last_diag_45 = !((from - 1) & 0x88) ? from_64 - 1 : (!((from - 16) & 0x88) ? from_64 - 8 : 63);
				uint64_t wall_45 = Chess::bit_rotate_45(_state->get_bit('+'));
				uint64_t can_walk_45 = diag_a1h8_wall[from_64][(wall_45 >> Chess::rotate_45_shift(last_diag_45)) & Chess::rotate_45_length_mask(last_diag_45)];
				uint64_t wall_315 = Chess::bit_rotate_315(_state->get_bit('+'));
				uint64_t can_walk_315 = diag_a8h1_wall[from_64][(wall_315 >> Chess::rotate_315_shift(from_64)) & Chess::rotate_315_length_mask(from_64)];
				return (can_walk_45 | can_walk_315) & enemy_king_mask;
			}
			continue;
		}
		if ((from_piece & 95) == 'K')
		{
			if ((king_attacks[from_64] & enemy_king_mask))
			{
				uint64_t wall_file = Chess::bit_rotate_90(_state->get_bit('-'));
				uint64_t can_walk_file = file_wall[from_64][(wall_file >> Chess::rotate_90_shift(from_64)) & 0xFF];
				uint64_t wall_rank = _state->get_bit('|');
				uint64_t can_walk_rank = rank_wall[from_64][(wall_rank >> Chess::rotate_0_shift(from_64)) & 0xFF];
				int last_diag_45 = !((from - 1) & 0x88) ? from_64 - 1 : (!((from - 16) & 0x88) ? from_64 - 8 : 63);
				uint64_t wall_45 = Chess::bit_rotate_45(_state->get_bit('+'));
				uint64_t can_walk_45 = diag_a1h8_wall[from_64][(wall_45 >> Chess::rotate_45_shift(last_diag_45)) & Chess::rotate_45_length_mask(last_diag_45)];
				uint64_t wall_315 = Chess::bit_rotate_315(_state->get_bit('+'));
				uint64_t can_walk_315 = diag_a8h1_wall[from_64][(wall_315 >> Chess::rotate_315_shift(from_64)) & Chess::rotate_315_length_mask(from_64)];
				return (can_walk_file | can_walk_rank | can_walk_45 | can_walk_315) & enemy_king_mask;
			}
			continue;
		}
		if ((from_piece & 95) == 'N')
		{
			if (horse_attacks[from_64] & enemy_king_mask)
			{
				return true;
			}
			continue;
		}
		if ((from_piece & 95) == 'Q' || (from_piece & 95) == 'B')
		{
			int last_diag_45 = !((from - 1) & 0x88) ? from_64 - 1 : (!((from - 16) & 0x88) ? from_64 - 8 : 63);
			uint64_t wall_45 = Chess::bit_rotate_45(_state->get_bit('+'));
			uint64_t can_walk_45 = diag_a1h8_wall[from_64][(wall_45 >> Chess::rotate_45_shift(last_diag_45)) & Chess::rotate_45_length_mask(last_diag_45)];
			uint64_t wall_315 = Chess::bit_rotate_315(_state->get_bit('+'));
			uint64_t can_walk_315 = diag_a8h1_wall[from_64][(wall_315 >> Chess::rotate_315_shift(from_64)) & Chess::rotate_315_length_mask(from_64)];
			uint64_t occupied = _state->get_bit(ALL_PIECE);
			uint64_t occupied_rotate_45 = bit_rotate_45(occupied);
			uint64_t occupied_rotate_315 = bit_rotate_315(occupied);
			int64_t diag_a1h8 = (occupied_rotate_45 >> Chess::rotate_45_shift(from_64)) & Chess::rotate_45_length_mask(from_64);
			int64_t diag_a8h1 = (occupied_rotate_315 >> Chess::rotate_315_shift(from_64)) & Chess::rotate_315_length_mask(from_64);
			int64_t bishop_attacks = (diag_a1h8_attacks[from_64][diag_a1h8] & can_walk_45) | (diag_a8h1_attacks[from_64][diag_a8h1] & can_walk_315);
			if (bishop_attacks & enemy_king_mask)
			{
				return true;
			}
		}
		if ((from_piece & 95) == 'Q' || (from_piece & 95) == 'R')
		{
			uint64_t wall_file = Chess::bit_rotate_90(_state->get_bit('-'));
			uint64_t can_walk_file = file_wall[from_64][(wall_file >> Chess::rotate_90_shift(from_64)) & 0xFF];
			uint64_t wall_rank = _state->get_bit('|');
			uint64_t can_walk_rank = rank_wall[from_64][(wall_rank >> Chess::rotate_0_shift(from_64)) & 0xFF];
			uint64_t occupied = _state->get_bit(ALL_PIECE);
			uint64_t occupied_rotate_90 = bit_rotate_90(occupied);
			int64_t rank = (occupied >> Chess::rotate_0_shift(from_64)) & 255;
			int64_t file = (occupied_rotate_90 >> Chess::rotate_90_shift(from_64)) & 255;
			int64_t rook_attacks = (rank_attacks[from_64][rank] & can_walk_rank) | (file_attacks[from_64][file] & can_walk_file);
			if (rook_attacks & enemy_king_mask)
			{
				return true;
			}
		}
	}
	return false;
}

bool Chess::is_blocked(const godot::Ref<State> &_state, int _from, int _to)
{
	if (_to & 0x88)
	{
		return true;
	}
	int from_piece = _state->get_piece(_from);
	int from_group = Chess::group(from_piece);
	int from_64 = Chess::to_64(_from);
	uint64_t to_mask = Chess::mask(Chess::to_64(_to));
	if (_state->get_piece(_to) == '*')
	{
		return false;
	}
	if (_state->has_piece(_to) && Chess::is_same_group(from_piece, _state->get_piece(_to)))
	{
		return true;
	}
	if (_state->get_bit('#') & to_mask)
	{
		return true;
	}
	if ((_from >> 4) == (_to >> 4))
	{
		uint64_t wall = _state->get_bit('|');
		uint64_t can_walk = rank_wall[from_64][(wall >> Chess::rotate_0_shift(from_64)) & 0xFF];
		if (!(can_walk & to_mask))
		{
			return true;
		}
	}
	if ((_from & 15) == (_to & 15))
	{
		uint64_t wall = Chess::bit_rotate_90(_state->get_bit('-'));
		uint64_t can_walk = file_wall[from_64][(wall >> Chess::rotate_90_shift(from_64)) & 0xFF];
		if (!(can_walk & to_mask))
		{
			return true;
		}
	}
	if ((_from >> 4) + (_from & 15) == (_to >> 4) + (_to & 15))
	{
		int last_diag = !((_from - 1) & 0x88) ? from_64 - 1 : 
						(!((_from - 16) & 0x88) ? from_64 - 8 : 63);
		uint64_t wall = Chess::bit_rotate_45(_state->get_bit('+'));
		uint64_t can_walk = diag_a1h8_wall[from_64][(wall >> Chess::rotate_45_shift(last_diag)) & Chess::rotate_45_length_mask(last_diag)];
		if (!(can_walk & to_mask))
		{
			return true;
		}
	}
	if ((_from >> 4) - (_from & 15) == (_to >> 4) - (_to & 15))
	{
		uint64_t wall = Chess::bit_rotate_315(_state->get_bit('+'));
		uint64_t can_walk = diag_a8h1_wall[from_64][(wall >> Chess::rotate_315_shift(from_64)) & Chess::rotate_315_length_mask(from_64)];
		if (!(can_walk & to_mask))
		{
			return true;
		}
	}
	return false;
}

bool Chess::is_enemy(const godot::Ref<State> &_state, int _from, int _to)
{
	return _state->has_piece(_to) && (!Chess::is_same_group(_state->get_piece(_from), _state->get_piece(_to)) || _state->get_piece(_to) == '*');
}

bool Chess::is_en_passant(const godot::Ref<State> &_state, int _from, int _to)
{
	return ((_from >> 4) == 3 || (_from >> 4) == 4) && _state->get_en_passant() == _to;
}

godot::PackedInt32Array Chess::generate_premove(const godot::Ref<State> &_state, int _group)
{
	DEV_ASSERT(_state.is_valid());
	godot::PackedInt32Array output;
	for (State::PieceIterator iter = _state->piece_iterator_begin(_group == 0 ? WHITE : BLACK); !iter.end(); iter.next())
	{
		int _from = iter.pos();
		int from_piece = iter.piece();
		if ((from_piece & 95) == 'P')
		{
			int front = direction(from_piece, 0);
			int front_capture_left = direction_pawn_capture(_group, false);
			int front_capture_right = direction_pawn_capture(_group, true);
			bool on_start = pawn_on_start(_group, _from);
			bool on_end = pawn_on_end(_group, _from);
			if (on_end)
			{
				output.push_back(Chess::create(_from, _from + front, _group == 0 ? 'Q' : 'q'));
				output.push_back(Chess::create(_from, _from + front, _group == 0 ? 'R' : 'r'));
				output.push_back(Chess::create(_from, _from + front, _group == 0 ? 'N' : 'n'));
				output.push_back(Chess::create(_from, _from + front, _group == 0 ? 'B' : 'b'));
				if (!((_from + front_capture_left) & 0x88))
				{
					output.push_back(Chess::create(_from, _from + front_capture_left, _group == 0 ? 'Q' : 'q'));
					output.push_back(Chess::create(_from, _from + front_capture_left, _group == 0 ? 'R' : 'r'));
					output.push_back(Chess::create(_from, _from + front_capture_left, _group == 0 ? 'N' : 'n'));
					output.push_back(Chess::create(_from, _from + front_capture_left, _group == 0 ? 'B' : 'b'));
				}
				if (!((_from + front_capture_right) & 0x88))
				{
					output.push_back(Chess::create(_from, _from + front_capture_right, _group == 0 ? 'Q' : 'q'));
					output.push_back(Chess::create(_from, _from + front_capture_right, _group == 0 ? 'R' : 'r'));
					output.push_back(Chess::create(_from, _from + front_capture_right, _group == 0 ? 'N' : 'n'));
					output.push_back(Chess::create(_from, _from + front_capture_right, _group == 0 ? 'B' : 'b'));
				}
			}
			else
			{
				output.push_back(Chess::create(_from, _from + front, 0));
				if (!((_from + front_capture_left) & 0x88))
				{
					output.push_back(Chess::create(_from, _from + front_capture_left, 0));
				}
				if (!((_from + front_capture_right) & 0x88))
				{
					output.push_back(Chess::create(_from, _from + front_capture_right, 0));
				}
				if (on_start)
				{
					output.push_back(Chess::create(_from, _from + front + front, 0));
				}
			}
			continue;
		}
		for (int i = 0; i < direction_count(from_piece); i++)
		{
			int to = _from + direction(from_piece, i);
			while (!(to & 0x88))
			{
				output.push_back(Chess::create(_from, to, 0));
				if ((from_piece & 95) == 'K' || (from_piece & 95) == 'N')
				{
					break;
				}
				to += direction(from_piece, i);
			}
		}
	}
	if (_group == 0 && (_state->get_castle() & 8))
	{
		output.push_back(Chess::create(Chess::e1(), Chess::g1(), 'K'));
	}
	if (_group == 0 && (_state->get_castle() & 4) && !_state->has_piece(Chess::c1()) && !_state->has_piece(Chess::d1()))
	{
		output.push_back(Chess::create(Chess::e1(), Chess::c1(), 'Q'));
	}
	if (_group == 1 && (_state->get_castle() & 2))
	{
		output.push_back(Chess::create(Chess::e8(), Chess::g8(), 'k'));
	}
	if (_group == 1 && (_state->get_castle() & 1))
	{
		output.push_back(Chess::create(Chess::e8(), Chess::c8(), 'q'));
	}
	return output;
}

godot::PackedInt32Array Chess::generate_move(const godot::Ref<State> &_state, int _group)
{
	DEV_ASSERT(_state.is_valid());
	godot::PackedInt32Array output;
	_internal_generate_move(output, _state, _group);
	return output;
}

void Chess::_internal_generate_move(godot::PackedInt32Array &output, const godot::Ref<State> &_state, int _group)
{
	DEV_ASSERT(_state.is_valid());
	for (State::PieceIterator iter = _state->piece_iterator_begin(_group == 0 ? WHITE : BLACK); !iter.end(); iter.next())
	{
		int _from = iter.pos();
		int from_piece = iter.piece();
		DEV_ASSERT(from_piece >= 'A' && from_piece <= 'Z' || from_piece >= 'a' && from_piece <= 'z');
		DEV_ASSERT(Chess::group(from_piece) == _group);
		if ((from_piece & 95) == 'P')
		{
			int front = direction(from_piece, 0);
			int front_capture_left = direction_pawn_capture(_group, false);
			int front_capture_right = direction_pawn_capture(_group, true);
			bool on_start = pawn_on_start(_group, _from);
			bool on_end = pawn_on_end(_group, _from);
			int to_1 = _from + front;
			int to_2 = _from + front_capture_left;
			int to_3 = _from + front_capture_right;
			if (!is_blocked(_state, _from, to_1) && !is_enemy(_state, _from, to_1))
			{
				if (on_end)
				{
					output.push_back(Chess::create(_from, to_1, _group == 0 ? 'Q' : 'q'));
					output.push_back(Chess::create(_from, to_1, _group == 0 ? 'R' : 'r'));
					output.push_back(Chess::create(_from, to_1, _group == 0 ? 'N' : 'n'));
					output.push_back(Chess::create(_from, to_1, _group == 0 ? 'B' : 'b'));
				}
				else
				{
					output.push_back(Chess::create(_from, to_1, 0));
					if (!_state->has_piece(to_1 + front) && on_start)
					{
						output.push_back(Chess::create(_from, to_1 + front, 0));
					}
				}
			}
			if (!is_blocked(_state, _from, to_2) && (is_enemy(_state, _from, to_2) || is_en_passant(_state, _from, to_2)))
			{
				if (on_end)
				{
					output.push_back(Chess::create(_from, to_2, _group == 0 ? 'Q' : 'q'));
					output.push_back(Chess::create(_from, to_2, _group == 0 ? 'R' : 'r'));
					output.push_back(Chess::create(_from, to_2, _group == 0 ? 'N' : 'n'));
					output.push_back(Chess::create(_from, to_2, _group == 0 ? 'B' : 'b'));
				}
				else
				{
					output.push_back(Chess::create(_from, to_2, 0));
				}
			}
			if (!is_blocked(_state, _from, to_3) && (is_enemy(_state, _from, to_3) || is_en_passant(_state, _from, to_3)))
			{
				if (on_end)
				{
					output.push_back(Chess::create(_from, to_3, _group == 0 ? 'Q' : 'q'));
					output.push_back(Chess::create(_from, to_3, _group == 0 ? 'R' : 'r'));
					output.push_back(Chess::create(_from, to_3, _group == 0 ? 'N' : 'n'));
					output.push_back(Chess::create(_from, to_3, _group == 0 ? 'B' : 'b'));
				}
				else
				{
					output.push_back(Chess::create(_from, to_3, 0));
				}
			}
			continue;
		}
		for (int i = 0; i < direction_count(from_piece); i++)
		{
			int to = _from;
			int to_piece = _state->get_piece(to);
			while (true)
			{
				to += direction(from_piece, i);
				if (to & 0x88)
				{
					break;
				}
				to_piece = _state->get_piece(to);
				if (is_blocked(_state, _from, to))
				{
					if ((from_piece & 95) == 'R' && (to_piece & 95) == 'K')
					{
						if ((_from & 15) >= 4 && (_group == 0 && (_state->get_castle() & 8) || _group == 1 && (_state->get_castle() & 2)))
						{
							output.push_back(Chess::create(to, _group == 0 ? Chess::g1() : Chess::g8(), 'K'));
						}
						else if ((_from & 15) <= 3 && (_group == 0 && (_state->get_castle() & 4) || _group == 1 && (_state->get_castle() & 1)))
						{
							output.push_back(Chess::create(to, _group == 0 ? Chess::c1() : Chess::c8(), 'Q'));
						}
					}
					break;
				}
				output.push_back(Chess::create(_from, to, 0));
				if ((from_piece & 95) == 'K' || (from_piece & 95) == 'N' || to_piece)
				{
					break;
				}
			}
		}
	}
	//摆放棋子部分
	int64_t empty_bit = ~_state->get_bit(ALL_PIECE);
	int64_t storage_piece = _state->get_storage_piece();
	//每种棋子存放最多8颗，意味着每种棋子占4位，那就需要4 * 5 * 2 = 40位
	//棋子的顺序：QRBNPqrbnp
	int storage_piece_order[10] = {'Q', 'R', 'B', 'N', 'P', 'q', 'r', 'b', 'n', 'p'};
	while (empty_bit)
	{
		int by_64 = Chess::first_bit(by_64);
		int by = Chess::to_x88(by_64);
		for (int i = 0; i < 5; i++)
		{
			int shift = _group == 0 ? i : i + 5;
			if ((storage_piece >> (4 * shift)) & 0xF)
			{
				output.push_back(Chess::create(by, by, storage_piece_order[shift]));
			}
		}
		empty_bit = Chess::next_bit(empty_bit);
	}
}

godot::PackedInt32Array Chess::generate_valid_move(const godot::Ref<State> &_state, int _group)
{
	godot::PackedInt32Array output;
	_internal_generate_valid_move(output, _state, _group);
	return output;
}

void Chess::_internal_generate_valid_move(godot::PackedInt32Array &output, const godot::Ref<State> &_state, int _group)
{
	godot::PackedInt32Array move_list;
	_internal_generate_move(move_list, _state, _group);
	for (int i = 0; i < move_list.size(); i++)
	{
		godot::Ref<State>test_state = _state->duplicate();
		apply_move(test_state, move_list[i]);
		if (!is_check(test_state, 1 - _group))
		{
			output.push_back(move_list[i]);
		}
	}
}

godot::PackedInt32Array Chess::generate_explore_move(const godot::Ref<State> &_state, int _group)
{
	godot::PackedInt32Array move_list = generate_valid_move(_state, _group);
	if (_state->get_bit(_group == 0 ? 'K' : 'k'))
	{
		uint64_t from_bit = _state->get_bit(_group == 0 ? 'K' : 'k');
		int from = 0;
		while (from_bit != 1 && from_bit != 0)
		{
			from_bit >>= 1;
			from += 1;
		}
		from = from % 8 + from / 8 * 16;
		godot::PackedInt32Array king_move;

		std::queue<int> q;
		std::unordered_set<int> closed;
		closed.insert(from);
		q.push(from);
		while (!q.empty())
		{
			int cur = q.front();
			q.pop();
			for (int i = 0; i < direction_count('k'); i++)
			{
				int next = cur + direction('k', i);
				int move = Chess::create(from, next, 0);
				int move_with_extra = Chess::create(from, next, 'E');
				if (!closed.count(next) && !is_blocked(_state, cur, next) && !is_enemy(_state, cur, next))
				{
					godot::Ref<State> test_state = _state->duplicate();
					apply_move(test_state, move);
					if (!is_check(test_state, 1 - _group))
					{
						if (!move_list.has(move))
						{
							king_move.push_back(move_with_extra);
						}
						q.push(next);
					}
					closed.insert(next);
				}
			}
		}
		move_list.append_array(king_move);
	}
	return move_list;
}

godot::PackedInt32Array Chess::generate_king_path(const godot::Ref<State> &_state, int _from, int _to)
{
	std::vector<std::pair<int, godot::PackedInt32Array>> dp(64, std::make_pair(0x7FFFFFFF, godot::PackedInt32Array()));
	std::vector<bool> shortest(64, false);
	dp[Chess::to_64(_from)].first = 0;
	for (int i = 0; i < 64; i++)
	{
		int min_node = 0;
		int min_step = 0x7FFFFFFF;
		for (int j = 0; j < 64; j++)
		{
			if (dp[j].first < min_step && !shortest[j])
			{
				min_node = j;
				min_step = dp[j].first;
			}
		}
		shortest[min_node] = true;
		for (int j = 0; j < direction_count('k'); j++)
		{
			bool is_diagonal = abs(direction('k', j)) != 1 && abs(direction('k', j)) != 16;
			int step = is_diagonal ? 11 : 10;
			int next_x88 = Chess::to_x88(min_node) + direction('k', j);

			if ((next_x88 & 0x88) || is_blocked(_state, Chess::to_x88(min_node), next_x88) || is_enemy(_state, Chess::to_x88(min_node), next_x88))
			{
				continue;
			}
			godot::Ref<State> test_state = _state->duplicate();
			apply_move(test_state, Chess::create(_from, next_x88, 0));
			if (is_check(test_state, 1 - Chess::group(_state->get_piece(_from))))
			{
				continue;
			}
			int next = Chess::to_64(next_x88);
			if (!shortest[next])
			{
				if (min_step + step < dp[next].first)
				{
					dp[next].first = min_step + step;
					dp[next].second = dp[min_node].second.duplicate();
					dp[next].second.push_back(Chess::to_x88(next));
				}
			}
		}
	}
	return dp[Chess::to_64(_to)].second;
}

godot::String Chess::get_move_name(const godot::Ref<State> &_state, int move)
{
	int from = Chess::get_singleton()->from(move);
	int to = Chess::get_singleton()->to(move);
	int from_piece = _state->get_piece(from);
	int extra = Chess::get_singleton()->extra(move);
	int group = Chess::group(from_piece);
	if ((from_piece & 95) == 'K' && extra)
	{
		if ((extra & 95) == 'K')
		{
			return "O-O";
		}
		else if ((extra & 95) == 'Q')
		{
			return "O-O-O";
		}
	}
	godot::String ans;
	if ((from_piece & 95) != 'P')
	{
		ans += (from_piece & 95);
	}
	else if (_state->get_piece(to) || to == _state->get_en_passant())
	{
		ans += (from & 0x0F) + 'a';
	}

	godot::PackedInt32Array move_list = generate_valid_move(_state, group);
	godot::PackedInt32Array same_to;
	bool has_same_piece = false;
	bool has_same_col = false;
	bool has_same_row = false;
	for (int i = 0; i < move_list.size(); i++)
	{
		int _from = Chess::get_singleton()->from(move_list[i]);
		if (_from != from && _state->get_piece(_from) == from_piece && Chess::get_singleton()->to(move_list[i]) == to)
		{
			has_same_piece = true;
			if ((_from & 0xF0) == (from & 0xF0))
			{
				has_same_row = true;
			}
			if ((_from & 0x0F) == (from & 0x0F))
			{
				has_same_col = true;
			}
		}
	}
	if (has_same_piece && (from_piece & 95) != 'P')	//兵走到同一地方只有吃子时才出现这种情况，而这种情况标记法早已标注列名
	{
		if (has_same_row || !has_same_row && !has_same_col)
		{
			ans += (from & 0x0F) + 'a';
		}
		if (has_same_col)
		{
			ans +=  7 - (from >> 4) + '1';
		}
	}
	if (_state->get_piece(to) || ((from_piece & 95) == 'P' && to == _state->get_en_passant()))
	{
		ans += 'x';
	}
	ans += (to & 0x0F) + 'a';
	ans +=  7 - (to >> 4) + '1';
	if (extra)
	{
		ans += '=';
		ans += (extra & 95);
	}
	godot::Ref<State> next_state = _state->duplicate();
	apply_move(next_state, move);
	if (is_check(next_state, group))
	{
		if (generate_valid_move(next_state, 1 - group).size() == 0)
		{
			ans += '#';
		}
		else
		{
			ans += '+';
		}
	}
	return ans;
}

int Chess::name_to_move(const godot::Ref<State> &_state, const godot::String &_name)
{
	godot::PackedInt32Array move_list = generate_move(_state, _state->get_turn());
	for (int i = 0; i < move_list.size(); i++)
	{
		godot::String name = get_move_name(_state, move_list[i]);
		if (name == _name)
		{
			return move_list[i];
		}
	}
	return -1;
}

void Chess::apply_move(const godot::Ref<State> &_state, int _move)
{
	if (_state->get_turn() == 1)
	{
		_state->set_round(_state->get_round() + 1);
		_state->set_turn(0);
	}
	else if (_state->get_turn() == 0)
	{
		_state->set_turn(1);
	}
	_state->set_step_to_draw(_state->get_step_to_draw() + 1);
	int from = Chess::from(_move);
	int from_piece = _state->get_piece(from);
	int from_group = Chess::group(from_piece);
	int to = Chess::to(_move);
	int to_piece = _state->get_piece(to);
	int extra = Chess::extra(_move);
	if (from == to)
	{
		if (from_piece)
		{
			_state->capture_piece(from);
		}
		if (extra)
		{
			_state->add_piece(to, extra);
			int64_t storage_piece = _state->get_storage_piece();
			switch (extra)
			{
				case 'Q': storage_piece -= 1ll; break;
				case 'R': storage_piece -= 1ll << 4; break;
				case 'B': storage_piece -= 1ll << 8; break;
				case 'N': storage_piece -= 1ll << 12; break;
				case 'P': storage_piece -= 1ll << 16; break;
				case 'q': storage_piece -= 1ll << 20; break;
				case 'r': storage_piece -= 1ll << 24; break;
				case 'b': storage_piece -= 1ll << 28; break;
				case 'n': storage_piece -= 1ll << 32; break;
				case 'p': storage_piece -= 1ll << 36; break;
			}
			_state->set_storage_piece(storage_piece);
		}
		return;
	}

	bool dont_move = false;
	bool has_en_passant = false;
	bool has_king_passant = false;
	if (to_piece)	//在apply_move阶段其实就默许了吃同阵营棋子的情况。
	{
		_state->capture_piece(to);
		_state->set_step_to_draw(0);	// 吃子时重置50步和棋
	}
	if (_state->get_king_passant() != -1 && abs(_state->get_king_passant() - to) <= 1)
	{
		if (from_group == 0)
		{
			if (_state->get_piece(Chess::c8()) == 'k')
			{
				_state->capture_piece(Chess::c8());
			}
			if (_state->get_piece(Chess::g8()) == 'k')
			{
				_state->capture_piece(Chess::g8());
			}
		}
		else
		{
			if (_state->get_piece(Chess::c1()) == 'K')
			{
				_state->capture_piece(Chess::c1());
			}
			if (_state->get_piece(Chess::g1()) == 'K')
			{
				_state->capture_piece(Chess::g1());
			}
		}
	}
	if ((from_piece & 95) == 'R')	// 哪边的车动过，就不能往那个方向易位
	{
		if ((from & 15) >= 4)
		{
			if (from_group == 0)
			{
				_state->set_castle(_state->get_castle() & 7);
			}
			else
			{
				_state->set_castle(_state->get_castle() & 13);
			}
		}
		else if ((from & 15) <= 3)
		{
			if (from_group == 0)
			{
				_state->set_castle(_state->get_castle() & 11);
			}
			else
			{
				_state->set_castle(_state->get_castle() & 14);
			}
		}
	}
	if ((from_piece & 95) == 'K')
	{
		if (from_group == 0)
		{
			_state->set_castle(_state->get_castle() & 3);
		}
		else
		{
			_state->set_castle(_state->get_castle() & 12);
		}
		if (extra)
		{
			if (to == Chess::g1())
			{
				_state->move_piece(Chess::h1(), Chess::f1());
				_state->set_king_passant(Chess::f1());
			}
			if (to == Chess::c1())
			{
				_state->move_piece(Chess::a1(), Chess::d1());
				_state->set_king_passant(Chess::d1());
			}
			if (to == Chess::g8())
			{
				_state->move_piece(Chess::h8(), Chess::f8());
				_state->set_king_passant(Chess::f8());
			}
			if (to == Chess::c8())
			{
				_state->move_piece(Chess::a8(), Chess::d8());
				_state->set_king_passant(Chess::d8());
			}
			has_king_passant = true;
		}
	}
	if ((from_piece & 95) == 'P')
	{
		int front = direction(from_piece, 0);
		_state->set_step_to_draw(0);	// 移动兵时重置50步和棋
		if (to - from == front * 2)
		{
			has_en_passant = true;
			_state->set_en_passant(from + front);
		}
		if (to == _state->get_en_passant() && !is_same_group(from_piece, _state->get_piece(to - front)))
		{
			_state->capture_piece(to - front);
		}
		if (extra)
		{
			dont_move = true;
			_state->capture_piece(from);
			_state->add_piece(to, extra);
		}
	}
	if (!dont_move)
	{
		_state->move_piece(from, to);
	}

	if (!has_en_passant)
	{
		_state->set_en_passant(-1);
	}
	if (!has_king_passant)
	{
		_state->set_king_passant(-1);
	}
}


godot::Dictionary Chess::apply_move_custom(const godot::Ref<State> &_state, int _move)
{
	godot::Dictionary output;
	int from = Chess::from(_move);
	int from_piece = _state->get_piece(from);
	int from_group = Chess::group(from_piece);
	int to = Chess::to(_move);
	int to_piece = _state->get_piece(to);
	int extra = Chess::extra(_move);
	if (from == to)
	{
		if (from_piece)
		{
			output["type"] = "leave";
			output["by"] = from;
			output["piece"] = from_piece;
			return output;
		} 
		if (extra)
		{
			output["type"] = "introduce";
			output["by"] = from;
			output["piece"] = extra;
			return output;
		}
		return output;
	}
	if ((from_piece & 95) == 'P')
	{
		int front = direction(from_piece, 0);
		if (((from >> 4) == 3 || (from >> 4) == 4) && to == _state->get_en_passant())
		{
			int captured = to - front;
			output["type"] = "en_passant";
			output["from"] = from;
			output["to"] = to;
			output["captured"] = captured;
			return output;
		}
		if (extra)
		{
			if (to_piece)
			{
				output["type"] = "promotion&capture";
				output["from"] = from;
				output["to"] = to;
				output["piece"] = extra;
				return output;
			}
			output["type"] = "promotion";
			output["from"] = from;
			output["to"] = to;
			output["piece"] = extra;
			return output;
		}
	}
	if (to_piece)
	{
		output["type"] = "capture";
		output["from"] = from;
		output["to"] = to;
		return output;	//双方共同进行演出
	}
	if ((from_piece & 95) == 'K')
	{
		if (extra)
		{
			if (extra == 'E')
			{
				output["type"] = "king_explore";
				output["from"] = from;
				output["path"] = generate_king_path(_state, from, to);
				return output;
			}
			if (to == Chess::g1())
			{
				output["type"] = "castle";
				output["from_king"] = Chess::e1();
				output["to_king"] = Chess::g1();
				output["from_rook"] = Chess::h1();
				output["to_rook"] = Chess::f1();
				return output; //王车易位，王和车分开进行
			}
			if (to == Chess::c1())
			{
				output["type"] = "castle";
				output["from_king"] = Chess::e1();
				output["to_king"] = Chess::c1();
				output["from_rook"] = Chess::a1();
				output["to_rook"] = Chess::d1();
				return output;
			}
			if (to == Chess::g8())
			{
				output["type"] = "castle";
				output["from_king"] = Chess::e8();
				output["to_king"] = Chess::g8();
				output["from_rook"] = Chess::h8();
				output["to_rook"] = Chess::f8();
				return output;
			}
			if (to == Chess::c8())
			{
				output["type"] = "castle";
				output["from_king"] = Chess::e8();
				output["to_king"] = Chess::c8();
				output["from_rook"] = Chess::a8();
				output["to_rook"] = Chess::d8();
				return output;
			}
		}
	}
	output["type"] = "move";
	output["from"] = from;
	output["to"] = to;
	return output;
}

uint64_t Chess::perft(const godot::Ref<State> &_state, int _depth, int group)
{
	if (_depth == 0)
	{
		return 1ULL;
	}
	godot::PackedInt32Array move_list = generate_valid_move(_state, group);
	uint64_t cnt = 0;
	if (_depth == 1)
	{
		return move_list.size();
	}
	for (int i = 0; i < move_list.size(); i++)
	{
		godot::Ref<State> test_state = _state->duplicate();
		apply_move(test_state, move_list[i]);
		cnt += perft(test_state, _depth - 1, 1 - group);
	}
	return cnt;
}

void Chess::_bind_methods()
{
	godot::ClassDB::bind_static_method(get_class_static(), godot::D_METHOD("rotate_90"), &Chess::rotate_90);
	godot::ClassDB::bind_static_method(get_class_static(), godot::D_METHOD("rotate_45"), &Chess::rotate_45);
	godot::ClassDB::bind_static_method(get_class_static(), godot::D_METHOD("rotate_315"), &Chess::rotate_315);
	godot::ClassDB::bind_static_method(get_class_static(), godot::D_METHOD("rotate_45_length"), &Chess::rotate_45_length);
	godot::ClassDB::bind_static_method(get_class_static(), godot::D_METHOD("rotate_315_length"), &Chess::rotate_315_length);
	godot::ClassDB::bind_static_method(get_class_static(), godot::D_METHOD("rotate_45_length_mask"), &Chess::rotate_45_length_mask);
	godot::ClassDB::bind_static_method(get_class_static(), godot::D_METHOD("rotate_315_length_mask"), &Chess::rotate_315_length_mask);
	godot::ClassDB::bind_static_method(get_class_static(), godot::D_METHOD("rotate_0_shift"), &Chess::rotate_0_shift);
	godot::ClassDB::bind_static_method(get_class_static(), godot::D_METHOD("rotate_90_shift"), &Chess::rotate_90_shift);
	godot::ClassDB::bind_static_method(get_class_static(), godot::D_METHOD("rotate_45_shift"), &Chess::rotate_45_shift);
	godot::ClassDB::bind_static_method(get_class_static(), godot::D_METHOD("rotate_315_shift"), &Chess::rotate_315_shift);
	godot::ClassDB::bind_static_method(get_class_static(), godot::D_METHOD("to_64"), &Chess::to_64);
	godot::ClassDB::bind_static_method(get_class_static(), godot::D_METHOD("to_x88"), &Chess::to_x88);
	godot::ClassDB::bind_static_method(get_class_static(), godot::D_METHOD("mask"), &Chess::mask);
	godot::ClassDB::bind_static_method(get_class_static(), godot::D_METHOD("population"), &Chess::population);
	godot::ClassDB::bind_static_method(get_class_static(), godot::D_METHOD("first_bit"), &Chess::first_bit);
	godot::ClassDB::bind_static_method(get_class_static(), godot::D_METHOD("next_bit"), &Chess::next_bit);
	godot::ClassDB::bind_static_method(get_class_static(), godot::D_METHOD("group"), &Chess::group);
	godot::ClassDB::bind_static_method(get_class_static(), godot::D_METHOD("is_same_group"), &Chess::is_same_group);
	godot::ClassDB::bind_static_method(get_class_static(), godot::D_METHOD("to_position_int"), &Chess::to_position_int);
	godot::ClassDB::bind_static_method(get_class_static(), godot::D_METHOD("to_position_name"), &Chess::to_position_name);
	godot::ClassDB::bind_static_method(get_class_static(), godot::D_METHOD("create"), &Chess::create);
	godot::ClassDB::bind_static_method(get_class_static(), godot::D_METHOD("from"), &Chess::from);
	godot::ClassDB::bind_static_method(get_class_static(), godot::D_METHOD("to"), &Chess::to);
	godot::ClassDB::bind_static_method(get_class_static(), godot::D_METHOD("extra"), &Chess::extra);

	godot::ClassDB::bind_static_method(get_class_static(), godot::D_METHOD("get_end_type"), &Chess::get_end_type);
	godot::ClassDB::bind_static_method(get_class_static(), godot::D_METHOD("parse"), &Chess::parse);
	godot::ClassDB::bind_static_method(get_class_static(), godot::D_METHOD("create_initial_state"), &Chess::create_initial_state);
	godot::ClassDB::bind_static_method(get_class_static(), godot::D_METHOD("create_random_state"), &Chess::create_random_state);
	godot::ClassDB::bind_static_method(get_class_static(), godot::D_METHOD("mirror_state"), &Chess::mirror_state);
	godot::ClassDB::bind_static_method(get_class_static(), godot::D_METHOD("rotate_state"), &Chess::rotate_state);
	godot::ClassDB::bind_static_method(get_class_static(), godot::D_METHOD("swap_group"), &Chess::swap_group);
	godot::ClassDB::bind_static_method(get_class_static(), godot::D_METHOD("stringify"), &Chess::stringify);
	godot::ClassDB::bind_static_method(get_class_static(), godot::D_METHOD("is_check"), &Chess::is_check);
	godot::ClassDB::bind_static_method(get_class_static(), godot::D_METHOD("is_move_valid"), &Chess::is_move_valid);
	godot::ClassDB::bind_static_method(get_class_static(), godot::D_METHOD("generate_premove"), &Chess::generate_premove);
	godot::ClassDB::bind_static_method(get_class_static(), godot::D_METHOD("generate_move"), &Chess::generate_move);
	godot::ClassDB::bind_static_method(get_class_static(), godot::D_METHOD("generate_valid_move"), &Chess::generate_valid_move);
	godot::ClassDB::bind_static_method(get_class_static(), godot::D_METHOD("generate_explore_move"), &Chess::generate_explore_move);
	godot::ClassDB::bind_static_method(get_class_static(), godot::D_METHOD("generate_king_path"), &Chess::generate_king_path);
	godot::ClassDB::bind_static_method(get_class_static(), godot::D_METHOD("get_move_name"), &Chess::get_move_name);
	godot::ClassDB::bind_static_method(get_class_static(), godot::D_METHOD("name_to_move"), &Chess::name_to_move);
	godot::ClassDB::bind_static_method(get_class_static(), godot::D_METHOD("apply_move"), &Chess::apply_move); 
	godot::ClassDB::bind_static_method(get_class_static(), godot::D_METHOD("apply_move_custom"), &Chess::apply_move_custom);
	godot::ClassDB::bind_static_method(get_class_static(), godot::D_METHOD("perft"), &Chess::perft);
}
