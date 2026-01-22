#ifndef _NNUE_HPP_
#define _NNUE_HPP_

#include <godot_cpp/godot.hpp>
#include <godot_cpp/classes/ref_counted.hpp>
#include <vector>
#include <state.hpp>

class NNUEInstance : godot::RefCounted
{
	GDCLASS(NNUEInstance, RefCounted)
	public:
		int64_t bit_input[128];
		double h1_sum[8];
		double h2_sum[8];
		double output_sum;
		double output_screlu;
		static void _bind_methods();
};

class NNUE : godot::RefCounted
{
	GDCLASS(NNUE, RefCounted)
	public:
		int randomized_weight();
		static int index(int piece, int by);
		static double screlu(double x);
		static double screlu_derivative(double x);
		void randomize_weight();
		godot::Ref<NNUEInstance> create_instance(const godot::Ref<State> &state);
		double feedforward(const godot::Ref<State> &state, const godot::Ref<NNUEInstance> &instance);
		void feedback(const godot::Ref<NNUEInstance> &instance, double desire_output);
		void train(const godot::Ref<State> &state, double desire_output);
		static void _bind_methods();
	private:
		const static int INPUT_SIZE = 64 * 128;
		const static int H1_SIZE = 8;
		const static int H2_SIZE = 8;
		double learn_step = 0.003;
		double weight_input_h1[INPUT_SIZE][H1_SIZE];
		double weight_h1_h2[H1_SIZE][H2_SIZE];
		double weight_h2_output[H2_SIZE];
		double bias_h1[H1_SIZE];
		double bias_h2[H2_SIZE];
		double bias_output;
		double bias_output;
};


#endif