
#include <hls_math.h>

#include "lstm_impl.hpp"

void float_to_fixed(float input[layer_0_input_size], data_t output[layer_0_input_size], const int scale) {
	for(int i = 0; i < layer_0_kernel_size_0; i++){

		resize_t temp = input[i];
		resize_t temp2 = temp / scale;

		output[i] = temp2;
	}
}

data_t hard_sigmoid(data_t input) {

    if (x < -2.5)
    	return 0;
    else if (x > 2.5)
    	return 1;
	else
		return 0.2 * x + 0.5;
}

/* Layer 0 LSTM */
void lstm_layer_0(data_t input[layer_0_input_size],
		const data_t W[layer_0_input_size][layer_0_kernel_size],
		const data_t U[layer_0_recurrent_kernel_size_0][layer_0_recurrent_kernel_size_1],
		const data_t bias[layer_0_bias_size],
		data_t output[layer_0_units]) {

	static data_t h[layer_0_units];
	static data_t c[layer_0_units];

	const int f_off = 0 * layer_0_units;
	const int i_off = 1 * layer_0_units;
	const int o_off = 2 * layer_0_units;
	const int c_off = 3 * layer_0_units;

	neuron : for (int i = 0; i < layer_0_units; ++i) {

		data_t f = 0;
		data_t i = 0;
		data_t o = 0;
		data_t c_t = 0;

		input: for (int j = 0; j < layer_0_input_size; ++j) {
			f += W[i][j] * input[j];
			i += W[i][j + i_off] * input[j];
			o += W[i][j + o_off] * input[j];
			c_t += W[i][j + c_off] * input[j];
		}

		kernel: for (int j = 0; j < layer_0_recurrent_kernel_size_0; ++j) {
			f += U[i][j] * h[i][j];
			i += U[i][j + i_off] * h[i][j];
			o += U[i][j + o_off] * h[i][j];
			c_t += U[i][j + c_off] * h[i][j];
		}

		f += bias[i];
		i += bias[i + i_off];
		o += bias[i + o_off];
		c_t += bias[i + c_off];

		f = hard_sigmoid(f);
		i = hard_sigmoid(i);
		o = hard_sigmoid(o);
		c_t = tanh<data_t>(c_t);

		c[i] = f * c[i] + i * c_t;
		h[i] = o * tanh<data_t>(c[i]);

		output[i] = h[i];
	}

	return;
}

/* Layer 1 LSTM */
void lstm_layer_1(data_t input[layer_1_input_size],
		const data_t W[layer_1_input_size][layer_1_kernel_size],
		const data_t U[layer_1_recurrent_kernel_size_0][layer_1_recurrent_kernel_size_1],
		const data_t bias[layer_1_bias_size],
		data_t output[layer_1_units]) {

	static data_t h[layer_1_units];
	static data_t c[layer_1_units];

	const int f_off = 0 * layer_1_units;
	const int i_off = 1 * layer_1_units;
	const int o_off = 2 * layer_1_units;
	const int c_off = 3 * layer_1_units;

	neuron: for (int i = 0; i < layer_1_units; ++i) {

		data_t f = 0;
		data_t i = 0;
		data_t o = 0;
		data_t c_t = 0;

		input: for (int j = 0; j < layer_1_input_size; ++j) {
			f += W[i][j] * input[j];
			i += W[i][j + i_off] * input[j];
			o += W[i][j + o_off] * input[j];
			c_t += W[i][j + c_off] * input[j];
		}

		kernel: for (int j = 0; j < layer_1_recurrent_kernel_size_0; ++j) {
			f += U[i][j] * h[i][j];
			i += U[i][j + i_off] * h[i][j];
			o += U[i][j + o_off] * h[i][j];
			c_t += U[i][j + c_off] * h[i][j];
		}

		f += bias[i];
		i += bias[i + i_off];
		o += bias[i + o_off];
		c_t += bias[i + c_off];

		f = hard_sigmoid(f);
		i = hard_sigmoid(i);
		o = hard_sigmoid(o);
		c_t = tanh<data_t>(c_t);

		c[i] = f * c[i] + i * c_t;
		h[i] = o * tanh<data_t>(c[i]);

		output[i] = h[i];
	}

	return;
}


/* Layer 2 matrix multiplication */
void dense_layer_2(data_t input[layer_2_input_size],
		const data_t weights[layer_2_input_size][layer_2_kernel_size],
		const data_t bias[layer_2_bias_size],
		data_t output[layer_2_kernel_size]) {

	col: for (int j = 0; j < layer_2_units; ++j) {
	//#pragma HLS UNROLL factor = 4
		data_t sum = 0;

	  prod: for (int k = 0; k < layer_2_input_size; ++k){
	#pragma HLS UNROLL factor=2
	        sum += input[k] * weights[k][j];
	      }

	  	  sum += bias[j];

	      output[j] = sum;
	    }

  return;
}

/* Find highest output */
void find_category(data_t input[layer_2_units], int &pred){
	int max_idx = -1;
	ap_fixed<32,24> max_val = -126;
	loop1: for (int i = 0; i < layer_2_units; i++){
//#pragma HLS UNROLL
		if (input[i] > max_val){
			max_idx = i;
			max_val = input[i];
		}
	}
	pred = max_idx;
	return;
}

/* Connect NN Layers */
int nn_inference(float input[layer_0_input_size]){
//#pragma HLS ARRAY_PARTITION dim=1 type=complete variable=input_img

	ap_fixed<32,24> fp_input[layer_0_input_size] = {1.0};

	float_to_fixed(input, fp_input, 4096);

	data_t temp_output[layer_0_units] = {1};
	data_t temp_output2[layer_1_units] = {1};
	data_t temp_output3[layer_2_units] = {1};
	int prediction = -1;


	lstm_layer_0(fp_input, layer_0_kernel_weights, layer_0_recurrent_kernel_weights, layer_0_bias_weights, temp_output);
	lstm_layer_1(temp_output, layer_1_kernel_weights, layer_1_recurrent_kernel_weights, layer_1_bias_weights, temp_output2);
	dense_layer_2(temp_output2, layer_2_weights, layer_2_bias_weights, temp_output3);

	find_category(temp_output3, prediction);

	return prediction;

}

