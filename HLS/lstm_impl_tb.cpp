#include <stdio.h>
#include <iostream>
#include "lstm_impl.hpp"

int main() {

	int16_t input[layer_0_input_size] = {5, 5, 5, 5, 5, 5}; // 1

	for (int i = 0; i < 10; ++i) {

		int pred = nn_inference(input);
		std::cout << "NN Prediction: " << pred << "\n";
	}

	return 0;
}
