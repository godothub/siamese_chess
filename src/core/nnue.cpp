#include <nnue.hpp>
#include <chess.hpp>
#include <stack>
#include <random>

int NNUE::index(int piece, int by)
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

void NNUE::randomize_weight()
{
	std::mt19937_64 rng(0);
	for (int i = 0; i < H1_SIZE; i++)
	{
		for (int j = 0; j < INPUT_SIZE; j++)
		{
			weight_input_h1[j][i] = (rng() % 20000 - 10000) / 10000.0;
		}
		bias_h1[i] = (rng() % 20000 - 10000) / 10000.0;
	}
	for (int i = 0; i < H1_SIZE; i++)
	{
		for (int j = 0; j < H2_SIZE; j++)
		{
			weight_h1_h2[j][i] = (rng() % 20000 - 10000) / 10000.0;
		}
		bias_h2[i] = (rng() % 20000 - 10000) / 10000.0;
	}

	for (int i = 0; i < H2_SIZE; i++)
	{
		weight_h2_output[i] = (rng() % 20000 - 10000) / 10000.0;
	}
	bias_output = (rng() % 20000 - 10000) / 10000.0;
}

godot::Ref<NNUEInstance> NNUE::create_instance(const godot::Ref<State> &state)
{
	//事先准备第一层的数据，后续为增量更新
	godot::Ref<NNUEInstance> new_instance = memnew(NNUEInstance);
	for (int i = 0; i < 128; i++)
	{
		int64_t bit = state->get_bit(i);
		while (bit)
		{
			for (int j = 0; j < H1_SIZE; j++)
			{
				int neuron = index(i, Chess::first_bit(bit));
				new_instance->h1_sum[neuron] += weight_input_h1[neuron][j];
			}
			bit = Chess::next_bit(bit);
		}
	}
	for (int i = 0; i < H1_SIZE; i++)
	{
		new_instance->h1_sum[i] = bias_h1[i];
	}
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
			open.push(index(i, Chess::first_bit(bit_open)));
			bit_open = Chess::next_bit(bit_open);
		}
		while (bit_close)
		{
			close.push(index(i, Chess::first_bit(bit_close)));
			bit_close = Chess::next_bit(bit_close);
		}
		instance->bit_input[i] = state->get_bit(i);
	}
	while (open.size())
	{
		int neuron = open.top();
		open.pop();
		for (int i = 0; i < H1_SIZE; i++)
		{
			instance->h1_sum[i] += weight_input_h1[neuron][i];
		}
	}
	while (close.size())
	{
		int neuron = close.top();
		close.pop();
		for (int i = 0; i < H1_SIZE; i++)
		{
			instance->h1_sum[i] -= weight_input_h1[neuron][i];
		}
	}
	for (int i = 0; i < H2_SIZE; i++)
	{
		instance->h2_sum[i] = bias_h2[i];
		for (int j = 0; j < H1_SIZE; j++)
		{
			instance->h2_sum[i] += instance->h1_sum[j] * weight_h1_h2[j][i];
		}
	}
	instance->output_sum = bias_output;
	for (int i = 0; i < H2_SIZE; i++)
	{
		instance->output_sum += instance->h2_sum[i] * weight_h2_output[i];
	}
	instance->output_screlu = screlu(instance->output_sum);
	return instance->output_sum;
}

void NNUE::feedback(const godot::Ref<NNUEInstance> &instance, double desire_output)
{
	double weight_h1_h2_delta[H1_SIZE][H2_SIZE];
	double weight_h2_output_delta[H2_SIZE];
	double bias_h2_delta[H2_SIZE];
	double bias_output_delta;
	double error_h2[H2_SIZE];
	double error_h1[H1_SIZE];
	double error_output = (instance->output_screlu - desire_output) * screlu_derivative(instance->output_sum);
	for (int i = 0; i < H2_SIZE; i++)
	{
		weight_h2_output_delta[i] = -learn_step * error_output * instance->h2_sum[i];
	}
	bias_output_delta = -learn_step * error_output;
	
	for (int i = 0; i < H2_SIZE; i++)
	{
		error_h2[i] = error_output * weight_h2_output[i];
	}
	for (int i = 0; i < H2_SIZE; i++)
	{
		for (int j = 0; j < H1_SIZE; j++)
		{
			weight_h1_h2_delta[j][i] = -learn_step * error_h2[i] * instance->h1_sum[j];
		}
		bias_h2_delta[i] = -learn_step * error_h2[i];
	}

	//输入层到第一隐藏层
	for (int i = 0; i < H1_SIZE; i++)
	{
		error_h1[i] = 0;
		for (int j = 0; j < H2_SIZE; j++)
		{
			error_h1[i] += error_h2[j] * weight_h1_h2[i][j];
		}
	}
	for (int i = 0; i < H1_SIZE; i++)
	{
		for (int j = 0; j < 128; j++)
		{
			int64_t bit = instance->bit_input[j];
			while (bit)
			{
				int neuron = index(j, Chess::first_bit(bit));
				weight_input_h1[neuron][i] += -learn_step * error_h1[i];
				bit = Chess::next_bit(bit);
			}
		}
		bias_h1[i] += -learn_step * error_h1[i];
	}
	
	//第一、第二、输出层之间的权重梯度更新
	for (int i = 0; i < H1_SIZE; i++)
	{
		for (int j = 0; j < H2_SIZE; j++)
		{
			weight_h1_h2[i][j] += weight_h1_h2_delta[i][j];
		}
	}
	for (int i = 0; i < H2_SIZE; i++)
	{
		bias_h2[i] += bias_h2_delta[i];
	}
	for (int i = 0; i < H2_SIZE; i++)
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
