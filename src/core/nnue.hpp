#ifndef _NNUE_HPP_
#define _NNUE_HPP_

#include <godot_cpp/godot.hpp>
#include <godot_cpp/classes/ref_counted.hpp>
#include <vector>
#include "state.hpp"

const int INPUT_SIZE = 64 * 128;
const int H1_SIZE = 8;
const int H2_SIZE = 8;

class NNUE;

class NNUEInstance : public godot::RefCounted
{
	GDCLASS(NNUEInstance, RefCounted)
	public:
		godot::Ref<NNUEInstance> duplicate();
		void _internal_duplicate(godot::Ref<NNUEInstance> &other);
		double get_output();
		static void _bind_methods();
	private:
		friend NNUE;
		int64_t bit_input[128];
		double h1_sum[8];
		double h2_sum[8];
		double output_sum;
		double output_screlu;
};

class NNUE : public godot::RefCounted
{
	GDCLASS(NNUE, RefCounted)
	public:
		static int calculate_index(int piece, int by);
		static double screlu(double x);
		static double screlu_derivative(double x);
		void randomize_weight();
		void save_file(const godot::String &path);
		void load_file(const godot::String &path);
		godot::Ref<NNUEInstance> create_instance(const godot::Ref<State> &state);
		double feedforward(const godot::Ref<State> &state, const godot::Ref<NNUEInstance> &instance);
		void feedback(const godot::Ref<NNUEInstance> &instance, double desire_output);
		void train(const godot::Ref<State> &state, double desire_output);
		static void _bind_methods();
	private:
		double learn_step = 0.003;
		double weight_input_h1[INPUT_SIZE][H1_SIZE];
		double weight_h1_h2[H1_SIZE][H2_SIZE];
		double weight_h2_output[H2_SIZE];
		double bias_h1[H1_SIZE];
		double bias_h2[H2_SIZE];
		double bias_output;
};


#endif