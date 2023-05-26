from tensorflow import keras
from tensorflow.keras import layers

import numpy as np
import cv2
import os
import time
import tensorflow as tf
import struct
from tensorflow.keras.models import Sequential
from tensorflow.keras.layers import Flatten, Dense, Activation
from sklearn.utils import shuffle
import sys
import csv
import pandas as pd

def main():
	args = sys.argv[1:]
	if len(args) == 2 and args[0] == '-dataset_dir':
		dataset_dir = str(args[1])	

	## Use CPU only
	os.environ['CUDA_VISIBLE_DEVICES'] = '-1'

	## Load MNIST dataset
	print("Loading dataset")
	train_data = []
	train_labels = []
	test_data = []
	test_labels = []

	dims = (10,10) # dimensions of images to train/test with

	for j in range(2): # train and test	
		for i in range(4): # 0 to 9
			if j == 0:
				read_folder = dataset_dir + '/training_data/' + str(i) + '/'
			if j == 1:
				read_folder = dataset_dir + 'testing_data/' + str(i) + '/'
			for filename in os.listdir(read_folder):
				data = pd.read_csv(os.path.join(read_folder,filename),header=None)
				data_nona = data.dropna(how='all', axis=1)
				data_suit = data_nona.reindex(range(10000), fill_value=0)
				print (type (data_suit))
				print (data_suit)
				if data_suit is not None:
					if j == 0:
						train_data.append(data_suit/32768) # normalize pixel vals to be between 0 - 1
						train_labels.append(i)
						
					if j == 1:
						test_data.append(data_suit/32768)
						test_labels.append(i)

	## Convert to numpy arrays, flatten images - change dimensions from Nx10x10 to Nx100
	print (train_data)
	print (type (train_data))
	print (isinstance(train_data,pd.DataFrame))
	train_data = np.asarray(train_data).astype('float32')
	test_data = np.asarray(test_data).astype('float32')
	train_labels = np.asarray(train_labels).astype('uint8')
	test_labels = np.asarray(test_labels).astype('uint8')

	## Shuffle dataset
	train_data, train_labels = shuffle(train_data, train_labels)
	test_data, test_labels = shuffle(test_data, test_labels)
	model = keras.Sequential()
	# Add a LSTM layer with 128 internal units.
	model.add(layers.LSTM(128))

	# Add a Dense layer with 10 units.
	model.add(layers.Dense(10))
	
	model.compile(optimizer='adam',
				  loss='sparse_categorical_crossentropy',
				  metrics=['accuracy'])

	## Train network  
	model.fit(train_data, train_labels, epochs=50, batch_size=2000, validation_split = 0.1)

	model.summary()

	start_t = time.time()
	results = model.evaluate(test_data, test_labels, verbose=0)
	totalt_t = time.time() - start_t
	print("Inference time for ", len(test_data), " test image: " , totalt_t, " seconds")


	print("test loss, test acc: ", results)

	#print(model.layers[1].weights[0].numpy().shape)
	#print(model.layers[2].weights[0].numpy().shape)
	#print(model.layers[3].weights[0].numpy().shape)

	## Retrieve network weights after training. Skip layer 0 (input layer)
	for w in range(0, len(model.layers)):
		weight_filename = "layer_" + str(w) + "_weights.txt" 
		open(weight_filename, 'w').close() # clear file
		file = open(weight_filename,"a") 
		file.write('{')
		for i in range(model.layers[w].weights[0].numpy().shape[0]):
			file.write('{')
			for j in range(model.layers[w].weights[0].numpy().shape[1]):
				file.write(str(model.layers[w].weights[0].numpy()[i][j]))
				if j != model.layers[w].weights[0].numpy().shape[1]-1:
					file.write(', ')
			file.write('}')
			if i != model.layers[w].weights[0].numpy().shape[0]-1:
				file.write(', \n')
		file.write('}')
		file.close()

	network_weights = model.layers[1].weights
	#print(network_weights)
	layer_1_W = network_weights[0].numpy()
	#print(layer_1_W)


	print("test_image[0] label: ", test_labels[0])

	x = test_data[0]
	x = np.expand_dims(x, axis=0)
	print("NN Prediction: ", np.argmax(model.predict(x)))


	print("Finished")
	
	
	
if __name__=="__main__":
    main()




