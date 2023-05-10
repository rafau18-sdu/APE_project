#!/usr/bin/python3

import os
import serial
import struct
import argparse
from pathlib import Path

from collections import deque


def receive_data(port: str, baud: int, output_path: str | Path, data_len: int=14):
   
    print(f"Output path: {output_path}")

    # Delete output file if it already exists
    if os.path.exists(output_path):
        os.remove(output_path)

    ser_rx = serial.Serial(port, baud,
                        serial.EIGHTBITS,
                        serial.PARITY_NONE,
                        serial.STOPBITS_ONE,
                        timeout=5)

    print(f"Starting receiving from port {port}")
    
    # Find first package
    circ_buffer = deque(maxlen=data_len)
    
    while True:
        read_data = ser_rx.read(data_len)

        circ_buffer.append(read_data)
        
        if len(circ_buffer) == data_len:
            if circ_buffer[0] == 0x00 and circ_buffer[-1] == 0xFF:
                break
    
    # Write data to file
    with open(output_path, 'w') as ofile:

        while True:
            read_data = ser_rx.read(14)
            if read_data[0] == 0x00 and read_data[-1] == 0xFF:  # check if start and stop bytes are correct
                values = struct.unpack('<6h', read_data[1:-1])  # unpack the 12 data bytes into 6 16-bit integers
                
                #print(values)
                
                for value in values:
                    ofile.write(str(value) + ',')
            else:
                print("Start/Stop did not match")
                break

    ser_rx.close()


def main(data_path, port, baud, data_len):
    receive_data(port, baud, data_path, data_len)

if __name__ == "__main__":
    # Run argument parser
    parser = argparse.ArgumentParser(description="Program used to transmit a .ppm image over UART")
    parser.add_argument('data_path', help="Path to save data")
    parser.add_argument('-l', '--data_len', required=False, default=14, help="Number of bytes to receive")
    parser.add_argument('-p', '--port', required=False, help="Serial port to use for receiving")
    parser.add_argument('-b', '--baud', required=False, default=115200, help="Baud rate of transmit port - defaults to 115200")

    args = parser.parse_args()

    main(args.data_path, args.port, args.baud, args.data_len)