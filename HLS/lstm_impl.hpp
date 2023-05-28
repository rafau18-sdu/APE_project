
#ifndef LSTM_IMPL_H
#define LSTM_IMPL_H

//#include "ap_int.h"
#include <cstdint>
#include "ap_fixed.h"

//typedef ap_fixed<32, 8> data_t;
typedef float data_t;

// Include weights.
#include "weights/layer_0_weights.txt"
#include "weights/layer_1_weights.txt"
#include "weights/layer_2_weights.txt"

#define layer_0_units layer_0_recurrent_kernel_size_0
#define layer_1_units layer_1_recurrent_kernel_size_0
#define layer_2_units layer_2_kernel_size

/**
 * @brief	Convert from integer to fixed point with descaling.
 */
void int_to_fixed(int16_t input[layer_0_input_size], data_t output[layer_0_input_size]);

/**
 * @brief	Hard sigmoid see: https://www.tensorflow.org/api_docs/python/tf/keras/activations/hard_sigmoid
 */
data_t hard_sigmoid(data_t input);

/* Layer 0 LSTM */
void lstm_layer_0(data_t input[layer_0_input_size],
		const data_t W[layer_0_input_size][layer_0_kernel_size],
		const data_t U[layer_0_recurrent_kernel_size_0][layer_0_recurrent_kernel_size_1],
		const data_t bias[layer_0_bias_size],
		data_t output[layer_0_units]);

/* Layer 1 LSTM */
void lstm_layer_1(data_t input[layer_1_input_size],
		const data_t W[layer_1_input_size][layer_1_kernel_size],
		const data_t U[layer_1_recurrent_kernel_size_0][layer_1_recurrent_kernel_size_1],
		const data_t bias[layer_1_bias_size],
		data_t output[layer_1_units]);

/* Layer 2 Dense */
void dense_layer_2(data_t input[layer_2_input_size],
		const data_t weights[layer_2_input_size][layer_2_kernel_size],
		const data_t bias[layer_2_bias_size],
		data_t output[layer_2_kernel_size]);

void soft_max(data_t input[layer_2_units], data_t output[layer_2_units]);

/* Find highest output */
void find_category(data_t input[layer_2_units], int &pred);

/* Connect NN Layers */
int nn_inference(int16_t input[layer_0_input_size]);

#endif




