#ifndef _NNUE_HPP_
#define _NNUE_HPP_

#include <godot_cpp/godot.hpp>
#include <godot_cpp/classes/ref_counted.hpp>
#include <vector>
#include <array>
#include "state.hpp"

#define NNUE_INPUT_SIZE (64 * 128)
#define NNUE_H1_SIZE (8)
#define NNUE_H2_SIZE (8)

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
		int64_t bit_input[NNUE_INPUT_SIZE];
		double h1_sum[NNUE_H1_SIZE];
		double h1_crelu[NNUE_H1_SIZE];
		double h2_sum[NNUE_H2_SIZE];
		double h2_crelu[NNUE_H2_SIZE];
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
		static double crelu(double x);
		static double crelu_derivative(double x);
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
		double weight_input_h1[NNUE_INPUT_SIZE][NNUE_H1_SIZE];
		double weight_h1_h2[NNUE_H1_SIZE][NNUE_H2_SIZE];
		double weight_h2_output[NNUE_H2_SIZE];
		double bias_h1[NNUE_H1_SIZE];
		double bias_h2[NNUE_H2_SIZE];
		double bias_output;
};


#endif