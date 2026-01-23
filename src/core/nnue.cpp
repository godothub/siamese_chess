#include "nnue.hpp"
#include "chess.hpp"
#include <stack>
#include <random>
#include <godot_cpp/classes/file_access.hpp>

godot::Ref<NNUEInstance> NNUEInstance::duplicate()
{
	godot::Ref<NNUEInstance> new_instance = memnew(NNUEInstance);
	_internal_duplicate(new_instance);
	return new_instance;
}

void NNUEInstance::_internal_duplicate(godot::Ref<NNUEInstance> &other)
{
	memcpy(other->bit_input, bit_input, sizeof(bit_input));
	memcpy(other->h1_sum, h1_sum, sizeof(h1_sum));
	memcpy(other->h2_sum, h2_sum, sizeof(h2_sum));
	other->output_sum = output_sum;
	other->output_activated = output_activated;
}

double NNUEInstance::get_output()
{
	return output_activated;
}

void NNUEInstance::_bind_methods()
{
	godot::ClassDB::bind_method(godot::D_METHOD("duplicate"), &NNUEInstance::duplicate);
	godot::ClassDB::bind_method(godot::D_METHOD("get_output"), &NNUEInstance::get_output);
}

int NNUE::calculate_index(int piece, int by)
{
	return piece * 64 + by;
}

double NNUE::screlu(double x)
{
	if (x >= 0 && x <= 1)
	{
		return x * x;
	}
	return x < 0 ? 0 : 1;
}

double NNUE::screlu_derivative(double x)
{
	if (x >= 0 && x <= 1)
	{
		return 2 * x;
	}
	return 0;
}

double NNUE::crelu(double x)
{
	if (x >= 0 && x <= 1)
	{
		return x;
	}
	return int(x > 1);
}

double NNUE::crelu_derivative(double x)
{
	return int(x >= 0 && x <= 1);
}

double NNUE::sigmoid(double x)
{
	return 1.0 / (1.0 + exp(-x));
}

double NNUE::sigmoid_derivative(double x)
{
	double _x = sigmoid(x);
	return _x / (1 - _x);
}

void NNUE::randomize_weight()
{
	std::mt19937 rng(0);
	for (int i = 0; i < NNUE_H1_SIZE; i++)
	{
		for (int j = 0; j < NNUE_INPUT_SIZE; j++)
		{
			weight_input_h1[j][i] = (int(rng() % 20000) - 10000) / 100000.0;
			DEV_ASSERT(!std::isnan(weight_input_h1[j][i]));
		}
		bias_h1[i] = (int(rng() % 20000) - 10000) / 100000.0;
		DEV_ASSERT(!std::isnan(bias_h1[i]));
	}
	for (int i = 0; i < NNUE_H1_SIZE; i++)
	{
		for (int j = 0; j < NNUE_H2_SIZE; j++)
		{
			weight_h1_h2[j][i] = (int(rng() % 20000) - 10000) / 100000.0;
			DEV_ASSERT(!std::isnan(weight_h1_h2[j][i]));
		}
		bias_h2[i] = (int(rng() % 20000) - 10000) / 100000.0;
		DEV_ASSERT(!std::isnan(bias_h2[i]));
	}

	for (int i = 0; i < NNUE_H2_SIZE; i++)
	{
		weight_h2_output[i] = (int(rng() % 20000) - 10000) / 100000.0;
		DEV_ASSERT(!std::isnan(weight_h2_output[i]));
	}
	bias_output = (int(rng() % 20000) - 10000) / 100000.0;
	DEV_ASSERT(!std::isnan(bias_output));
}

void NNUE::save_file(const godot::String &path)
{
	godot::Ref<godot::FileAccess> file = godot::FileAccess::open(path, godot::FileAccess::ModeFlags::WRITE);
	for (int i = 0; i < NNUE_H1_SIZE; i++)
	{
		for (int j = 0; j < NNUE_INPUT_SIZE; j++)
		{
			file->store_64(weight_input_h1[j][i]);
		}
		file->store_64(bias_h1[i]);
	}
	for (int i = 0; i < NNUE_H1_SIZE; i++)
	{
		for (int j = 0; j < NNUE_H2_SIZE; j++)
		{
			file->store_64(weight_h1_h2[j][i]);
		}
		file->store_64(bias_h2[i]);
	}

	for (int i = 0; i < NNUE_H2_SIZE; i++)
	{
		file->store_64(weight_h2_output[i]);
	}
	file->store_64(bias_output);
	file->close();
}

void NNUE::load_file(const godot::String &path)
{
	godot::Ref<godot::FileAccess> file = godot::FileAccess::open(path, godot::FileAccess::READ);
	std::mt19937_64 rng(0);
	for (int i = 0; i < NNUE_H1_SIZE; i++)
	{
		for (int j = 0; j < NNUE_INPUT_SIZE; j++)
		{
			weight_input_h1[j][i] = file->get_64();
		}
		bias_h1[i] = file->get_64();
	}
	for (int i = 0; i < NNUE_H1_SIZE; i++)
	{
		for (int j = 0; j < NNUE_H2_SIZE; j++)
		{
			weight_h1_h2[j][i] = file->get_64();
		}
		bias_h2[i] = file->get_64();
	}

	for (int i = 0; i < NNUE_H2_SIZE; i++)
	{
		weight_h2_output[i] = file->get_64();
	}
	bias_output = file->get_64();
	file->close();
}

godot::Ref<NNUEInstance> NNUE::create_instance(const godot::Ref<State> &state)
{
	//事先准备第一层的数据，后续为增量更新
	godot::Ref<NNUEInstance> new_instance = memnew(NNUEInstance);
	for (int i = 0; i < NNUE_H1_SIZE; i++)
	{
		new_instance->h1_sum[i] = bias_h1[i];
	}
	for (int i = 0; i < 128; i++)
	{
		int64_t bit = state->get_bit(i);
		new_instance->bit_input[i] = bit;
		while (bit)
		{
			for (int j = 0; j < NNUE_H1_SIZE; j++)
			{
				int neuron = calculate_index(i, Chess::first_bit(bit));
				new_instance->h1_sum[j] += weight_input_h1[neuron][j];
			}
			bit = Chess::next_bit(bit);
		}
	}
	for (int i = 0; i < NNUE_H2_SIZE; i++)
	{
		new_instance->h2_sum[i] = bias_h2[i];
		for (int j = 0; j < NNUE_H1_SIZE; j++)
		{
			new_instance->h2_sum[i] += new_instance->h1_sum[j] * weight_h1_h2[j][i];
		}
	}
	new_instance->output_sum = bias_output;
	for (int i = 0; i < NNUE_H2_SIZE; i++)
	{
		new_instance->output_sum += new_instance->h2_sum[i] * weight_h2_output[i];
	}
	new_instance->output_activated = sigmoid(new_instance->output_sum);
	DEV_ASSERT(new_instance->output_activated >= 0 && new_instance->output_activated <= 1);
	return new_instance;
}

double NNUE::feedforward(const godot::Ref<State> &state, const godot::Ref<NNUEInstance> &instance)
{
	std::stack<int> open;
	std::stack<int> close;
	for (int i = 0; i < 128; i++)
	{
		int64_t bit_diff = state->get_bit(i) ^ instance->bit_input[i];
		int64_t bit_open = bit_diff & state->get_bit(i);
		int64_t bit_close = bit_diff & instance->bit_input[i];
		while (bit_open)
		{
			open.push(calculate_index(i, Chess::first_bit(bit_open)));
			bit_open = Chess::next_bit(bit_open);
		}
		while (bit_close)
		{
			close.push(calculate_index(i, Chess::first_bit(bit_close)));
			bit_close = Chess::next_bit(bit_close);
		}
		instance->bit_input[i] = state->get_bit(i);
	}
	while (open.size())
	{
		int neuron = open.top();
		open.pop();
		for (int i = 0; i < NNUE_H1_SIZE; i++)
		{
			instance->h1_sum[i] += weight_input_h1[neuron][i];
		}
	}
	while (close.size())
	{
		int neuron = close.top();
		close.pop();
		for (int i = 0; i < NNUE_H1_SIZE; i++)
		{
			instance->h1_sum[i] -= weight_input_h1[neuron][i];
		}
	}
	for (int i = 0; i < NNUE_H2_SIZE; i++)
	{
		instance->h2_sum[i] = bias_h2[i];
		for (int j = 0; j < NNUE_H1_SIZE; j++)
		{
			instance->h2_sum[i] += instance->h1_sum[j] * weight_h1_h2[j][i];
		}
	}
	instance->output_sum = bias_output;
	for (int i = 0; i < NNUE_H2_SIZE; i++)
	{
		instance->output_sum += instance->h2_sum[i] * weight_h2_output[i];
	}
	instance->output_activated = sigmoid(instance->output_sum);
	return instance->output_activated;
}

void NNUE::feedback(const godot::Ref<NNUEInstance> &instance, double desire_output)
{
	double weight_h1_h2_delta[NNUE_H1_SIZE][NNUE_H2_SIZE];
	double weight_h2_output_delta[NNUE_H2_SIZE];
	double bias_h2_delta[NNUE_H2_SIZE];
	double bias_output_delta;
	double error_h2[NNUE_H2_SIZE];
	double error_h1[NNUE_H1_SIZE];
	double error_output = (instance->output_activated - desire_output) * sigmoid_derivative(instance->output_sum);
	for (int i = 0; i < NNUE_H2_SIZE; i++)
	{
		weight_h2_output_delta[i] = -learn_step * error_output * instance->h2_sum[i];
		DEV_ASSERT(!std::isnan(weight_h2_output_delta[i]));
	}
	bias_output_delta = -learn_step * error_output;
	DEV_ASSERT(!std::isnan(bias_output_delta));
	
	for (int i = 0; i < NNUE_H2_SIZE; i++)
	{
		error_h2[i] = error_output * weight_h2_output[i];
	}
	for (int i = 0; i < NNUE_H2_SIZE; i++)
	{
		for (int j = 0; j < NNUE_H1_SIZE; j++)
		{
			weight_h1_h2_delta[j][i] = -learn_step * error_h2[i] * instance->h1_sum[j];
			DEV_ASSERT(!std::isnan(weight_h1_h2_delta[j][i]));
		}
		bias_h2_delta[i] = -learn_step * error_h2[i];
		DEV_ASSERT(!std::isnan(bias_h2_delta[i]));
	}

	//输入层到第一隐藏层
	for (int i = 0; i < NNUE_H1_SIZE; i++)
	{
		error_h1[i] = 0;
		for (int j = 0; j < NNUE_H2_SIZE; j++)
		{
			error_h1[i] += error_h2[j] * weight_h1_h2[i][j];
		}
	}
	for (int i = 0; i < NNUE_H1_SIZE; i++)
	{
		for (int j = 0; j < 128; j++)
		{
			int64_t bit = instance->bit_input[j];
			while (bit)
			{
				int neuron = calculate_index(j, Chess::first_bit(bit));
				weight_input_h1[neuron][i] += -learn_step * error_h1[i];
				DEV_ASSERT(!std::isnan(weight_input_h1[neuron][i]));
				bit = Chess::next_bit(bit);
			}
		}
		bias_h1[i] += -learn_step * error_h1[i];
		DEV_ASSERT(!std::isnan(bias_h1[i]));
	}
	
	//第一、第二、输出层之间的权重梯度更新
	for (int i = 0; i < NNUE_H1_SIZE; i++)
	{
		for (int j = 0; j < NNUE_H2_SIZE; j++)
		{
			weight_h1_h2[i][j] += weight_h1_h2_delta[i][j];
		}
	}
	for (int i = 0; i < NNUE_H2_SIZE; i++)
	{
		bias_h2[i] += bias_h2_delta[i];
	}
	for (int i = 0; i < NNUE_H2_SIZE; i++)
	{
		weight_h2_output[i] += weight_h2_output_delta[i];
	}
	bias_output += bias_output_delta;
}

void NNUE::train(const godot::Ref<State> &state, double desire_output)
{
	godot::Ref<NNUEInstance> instance = create_instance(state);
	feedforward(state, instance);
	feedback(instance, desire_output);
}

void NNUE::_bind_methods()
{
	godot::ClassDB::bind_method(godot::D_METHOD("randomize_weight"), &NNUE::randomize_weight);
	godot::ClassDB::bind_method(godot::D_METHOD("save_file"), &NNUE::save_file);
	godot::ClassDB::bind_method(godot::D_METHOD("load_file"), &NNUE::load_file);
	godot::ClassDB::bind_method(godot::D_METHOD("create_instance"), &NNUE::create_instance);
	godot::ClassDB::bind_method(godot::D_METHOD("feedforward"), &NNUE::feedforward);
	godot::ClassDB::bind_method(godot::D_METHOD("feedback"), &NNUE::feedback);
	godot::ClassDB::bind_method(godot::D_METHOD("train"), &NNUE::train);
}