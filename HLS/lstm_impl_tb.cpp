#include <stdio.h>
#include <iostream>
#include "lstm_impl.hpp"

int main() {

data_t input[layer_0_input_size] = {0.5, 0.5, 0.5, 0.5, 0.5, 0.5}; // 1

for (int i = 0; i < 10; ++i) {

int pred = nn_inference(input_img);
	std::cout << "NN Prediction: " << pred << "\n";
}

return 0;
}
