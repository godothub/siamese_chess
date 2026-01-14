#include "transposition_table.hpp"
#include <godot_cpp/classes/file_access.hpp>

void TranspositionTable::reserve(int _table_size)
{
	table_size = _table_size;
	table_size_mask = table_size - 1;
	collide_count = 0;
	table.resize(table_size);
}

void TranspositionTable::save_file(const godot::String &path)
{
	godot::Ref<godot::FileAccess> file = godot::FileAccess::open(path, godot::FileAccess::ModeFlags::WRITE);
	file->store_32(table_size);
	for (int i = 0; i < table.size(); i++)
	{
		file->store_64(table[i].checksum);
		file->store_8(table[i].depth);
		file->store_8(table[i].flag);
		file->store_32(table[i].value);
		file->store_32(table[i].best_move);
	}
	file->close();
}

void TranspositionTable::load_file(const godot::String &path)
{
	godot::Ref<godot::FileAccess> file = godot::FileAccess::open(path, godot::FileAccess::READ);
	table_size = file->get_32();
	table_size_mask = table_size - 1;
	table.resize(table_size);
	for (int i = 0; i < table.size(); i++)
	{
		table[i].checksum = file->get_64();
		table[i].depth = file->get_8();
		table[i].flag = file->get_8();
		table[i].value = file->get_32();
		table[i].best_move = file->get_32();
	}
	file->close();
}

int TranspositionTable::probe_hash(int64_t checksum, int8_t depth, int alpha, int beta)
{
	int index = checksum & table_size_mask;
	if (table[index].checksum == checksum)
	{
		if (table[index].depth >= depth)
		{
			if (table[index].flag == EXACT)
			{
				return table[index].value;
			}
			if (table[index].flag == ALPHA && table[index].value < alpha)
			{
				return alpha;
			}
			if (table[index].flag == BETA && table[index].value > beta)
			{
				return beta;
			}
		}
	}
	return 65535;
}

int TranspositionTable::best_move(int64_t checksum)
{
	int index = checksum & table_size_mask;
	return table[index].best_move;
}

void TranspositionTable::record_hash(int64_t checksum, int8_t depth, int value, int8_t flag, int best_move, bool replace_by_depth)
{
	DEV_ASSERT(best_move != 0);
	int index = checksum & table_size_mask;
	if (table[index].checksum != checksum)
	{
		collide_count++;
	}
	if (replace_by_depth && depth < table[index].depth)
	{
		return;
	}
	
	table[index].checksum = checksum;
	table[index].depth = depth;
	table[index].flag = flag;
	table[index].value = value;
	table[index].best_move = best_move;
}

void TranspositionTable::clear()
{
	table.resize(table_size, {0});
}

void TranspositionTable::print_status()
{
	int all_cnt = 0;
	int best_move_cnt = 0;
	std::vector<int> depth_cnt(100);
	std::vector<int> flag_cnt(4);
	for (int i = 0; i < table_size; i++)
	{
		if (table[i].checksum)
		{
			all_cnt++;
			depth_cnt[table[i].depth]++;
			flag_cnt[table[i].flag]++;
			if (table[i].best_move)
			{
				best_move_cnt++;
			}
		}
	}
	godot::print_line("all: ", all_cnt);
	godot::print_line("depth: ");
	for (int i = 0; i < depth_cnt.size(); i++)
	{
		if (depth_cnt[i])
		{
			godot::print_line("\t", i, ": ", depth_cnt[i]);
		}
	}
	godot::print_line("exact: ", flag_cnt[1]);
	godot::print_line("alpha: ", flag_cnt[2]);
	godot::print_line("beta: ", flag_cnt[3]);
	godot::print_line("unused: ", table_size - all_cnt);
	godot::print_line("collide: ", collide_count);
	godot::print_line("best_move: ", best_move_cnt);
}

void TranspositionTable::_bind_methods()
{
	godot::ClassDB::bind_method(godot::D_METHOD("reserve"), &TranspositionTable::reserve);
	godot::ClassDB::bind_method(godot::D_METHOD("save_file"), &TranspositionTable::save_file);
	godot::ClassDB::bind_method(godot::D_METHOD("load_file"), &TranspositionTable::load_file);
	godot::ClassDB::bind_method(godot::D_METHOD("probe_hash"), &TranspositionTable::probe_hash);
	godot::ClassDB::bind_method(godot::D_METHOD("best_move"), &TranspositionTable::best_move);
	godot::ClassDB::bind_method(godot::D_METHOD("record_hash"), &TranspositionTable::record_hash);
	godot::ClassDB::bind_method(godot::D_METHOD("clear"), &TranspositionTable::clear);
	godot::ClassDB::bind_method(godot::D_METHOD("print_status"), &TranspositionTable::print_status);
}
