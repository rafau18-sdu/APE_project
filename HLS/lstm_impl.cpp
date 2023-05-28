
#include <hls_math.h>

#include "lstm_impl.hpp"

void int_to_fixed(int16_t input[layer_0_input_size], data_t output[layer_0_input_size]) {
	for(int i = 0; i < layer_0_input_size; i++){

		// data_t temp = temp;
		// resize_t temp2 = temp * resize_t(4096);

		output[i] = float(input[i]) * float(1.0/4096);
	}
}

data_t hard_sigmoid(data_t input) {

    if (input < data_t(-2.5))
    	return 0;
    else if (input > data_t(2.5))
    	return 1;
	else
		return data_t(0.2) * input + data_t(0.5);
}

/* Layer 0 LSTM */
void lstm_layer_0(data_t input[layer_0_input_size],
		const data_t W[layer_0_input_size][layer_0_kernel_size],
		const data_t U[layer_0_recurrent_kernel_size_0][layer_0_recurrent_kernel_size_1],
		const data_t bias[layer_0_bias_size],
		data_t output[layer_0_units]) {

	static data_t h[layer_0_units] = {0};
	static data_t c[layer_0_units] = {0};

	const int i_off = 0 * layer_0_units;
	const int f_off = 1 * layer_0_units;
	const int c_off = 2 * layer_0_units;
	const int o_off = 3 * layer_0_units;

	neuron : for (int i = 0; i < layer_0_units; ++i) {

		data_t f_t = 0;
		data_t i_t = 0;
		data_t o_t = 0;
		data_t c_t = 0;

		input: for (int j = 0; j < layer_0_input_size; ++j) {
#pragma HLS ALLOCATION operation instances=mul limit=2
			f_t += W[j][i + f_off] * input[j];
			i_t += W[j][i + i_off] * input[j];
			o_t += W[j][i + o_off] * input[j];
			c_t += W[j][i + c_off] * input[j];
		}

		kernel: for (int j = 0; j < layer_0_recurrent_kernel_size_0; ++j) {
#pragma HLS ALLOCATION operation instances=mul limit=2
			f_t += U[j][i + f_off] * h[j];
			i_t += U[j][i + i_off] * h[j];
			o_t += U[j][i + o_off] * h[j];
			c_t += U[j][i + c_off] * h[j];
		}

		f_t += bias[i + f_off];
		i_t += bias[i + i_off];
		o_t += bias[i + o_off];
		c_t += bias[i + c_off];

		f_t = hard_sigmoid(f_t);
		i_t = hard_sigmoid(i_t);
		o_t = hard_sigmoid(o_t);
		c_t = tanh(float(c_t));

		/*std::cout << "f: " << i <<", " << f_t << "\n";
		std::cout << "i: " << i <<", " << i_t << "\n";
		std::cout << "o: " << i <<", " << o_t << "\n";
		std::cout << "c: " << i <<", " << c_t << "\n";
		 */
		c[i] = f_t * c[i] + i_t * c_t;
		h[i] = o_t * data_t(tanh(float(c[i])));

		output[i] = h[i];

		//std::cout << "c_fin: " << i <<", " << c[i] << "\n";
		//std::cout << "H: " << i <<", " << h[i] << "\n";

	}

	return;
}

/* Layer 1 LSTM */
void lstm_layer_1(data_t input[layer_1_input_size],
		const data_t W[layer_1_input_size][layer_1_kernel_size],
		const data_t U[layer_1_recurrent_kernel_size_0][layer_1_recurrent_kernel_size_1],
		const data_t bias[layer_1_bias_size],
		data_t output[layer_1_units]) {

	static data_t h[layer_1_units] = {0};
	static data_t c[layer_1_units] = {0};

	const int i_off = 0 * layer_1_units;
	const int f_off = 1 * layer_1_units;
	const int c_off = 2 * layer_1_units;
	const int o_off = 3 * layer_1_units;

	neuron: for (int i = 0; i < layer_1_units; ++i) {

		data_t f_t = 0;
		data_t i_t = 0;
		data_t o_t = 0;
		data_t c_t = 0;

		input: for (int j = 0; j < layer_1_input_size; ++j) {
#pragma HLS ALLOCATION operation instances=mul limit=2
			f_t += W[j][i + f_off] * input[j];
			i_t += W[j][i + i_off] * input[j];
			o_t += W[j][i + o_off] * input[j];
			c_t += W[j][i + c_off] * input[j];
		}

		kernel: for (int j = 0; j < layer_1_recurrent_kernel_size_0; ++j) {
#pragma HLS ALLOCATION operation instances=mul limit=2
			f_t += U[j][i + f_off] * h[j];
			i_t += U[j][i + i_off] * h[j];
			o_t += U[j][i + o_off] * h[j];
			c_t += U[j][i + c_off] * h[j];
		}

		f_t += bias[i + f_off];
		i_t += bias[i + i_off];
		o_t += bias[i + o_off];
		c_t += bias[i + c_off];

		f_t = hard_sigmoid(f_t);
		i_t = hard_sigmoid(i_t);
		o_t = hard_sigmoid(o_t);
		c_t = tanh(float(c_t));

		c[i] = f_t * c[i] + i_t * c_t;
		h[i] = o_t * data_t(tanh(float(c[i])));

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

void soft_max(data_t input[layer_2_units], data_t output[layer_2_units]) {

	float sum_max = 0;

	loop1: for (int i = 0; i < layer_2_units; i++){

		sum_max += exp(float(input[i]));
	}

	loop2: for (int i = 0; i < layer_2_units; i++){
#pragma HLS ALLOCATION operation instances=sdiv limit=2

		output[i] = exp(float(input[i])) / sum_max;
	}

}

/* Find highest output */
void find_category(data_t input[layer_2_units], int &pred){
	int max_idx = -1;

	static uint8_t cnts[layer_2_units] = {0};
	static uint8_t counter = 0;

	counter++;

	data_t max_val = -126;

	loop1: for (int i = 0; i < layer_2_units; i++){
//#pragma HLS UNROLL
		if (input[i] > max_val){
			max_idx = i;
			max_val = input[i];
		}
	}

	if (max_val > data_t(0.5)) {
		cnts[max_idx]++;
	}

	uint8_t max_cnt = 0;
	max_idx = 0;

	loop2: for (int i = 0; i < layer_2_units; i++){
//#pragma HLS UNROLL
		if (cnts[i] > max_cnt){
			max_idx = i;
			max_cnt = cnts[i];
		}
	}

	if (counter > 32) {
		loop3: for (int i = 0; i < layer_2_units; i++){
			cnts[i] = cnts[i] / 2;
		}
		counter = 0;
	}

	pred = max_idx;
	return;
}

/* Connect NN Layers */
int nn_inference(int16_t input[layer_0_input_size]){
//#pragma HLS ARRAY_PARTITION dim=1 type=complete variable=input_img

	data_t fp_input[layer_0_input_size] = {1.0};

	int_to_fixed(input, fp_input);

	data_t temp_output[layer_0_units] = {1};
	data_t temp_output2[layer_1_units] = {1};
	data_t temp_output3[layer_2_units] = {1};
	data_t temp_output4[layer_2_units] = {1};
	int prediction = -1;

	lstm_layer_0(fp_input, layer_0_kernel_weights, layer_0_recurrent_kernel_weights, layer_0_bias_weights, temp_output);
	lstm_layer_1(temp_output, layer_1_kernel_weights, layer_1_recurrent_kernel_weights, layer_1_bias_weights, temp_output2);
	dense_layer_2(temp_output2, layer_2_weights, layer_2_bias_weights, temp_output3);
	soft_max(temp_output3, temp_output4);

	#ifndef __SYNTHESIS__
	std::cout << "Vals: ";
	for (int i =0 ; i < 4; i++) {
		std::cout << temp_output4[i] << ", ";
	}
	std::cout << "\n";

	#endif

	find_category(temp_output4, prediction);

	return prediction;
}

