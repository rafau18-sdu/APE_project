#!/usr/bin/python3

import os
import serial
import struct
import argparse
from pathlib import Path
import uuid

from collections import deque
from itertools import islice

def check_file_or_directory(path):
    if os.path.isfile(path):
        return path
    elif os.path.isdir(path):
        return os.path.join(path, str(uuid.uuid4()) + ".txt")
    else:
        return ""


def receive_data(port: str, baud: int, output_path: str | Path, data_len: int=16):
   
    path = check_file_or_directory(output_path)
    
    print(f"{path = }")

    # Delete output file if it already exists
    if os.path.exists(path):
        os.remove(path)

    ser_rx = serial.Serial(port, baud,
                        serial.EIGHTBITS,
                        serial.PARITY_NONE,
                        serial.STOPBITS_ONE,
                        timeout=5)

    print(f"Starting receiving from port {port}")
    
    # Find first package
    circ_buffer = deque(maxlen=data_len)
    
    
    # Write data to file
    with open(path, 'w') as ofile:
    
        while True:
            read_data = ser_rx.read()
            
            circ_buffer.append(read_data)
            
            #print(read_data)
            
            # When buffer is full
            if len(circ_buffer) == data_len:
                
                # Are stop bytes correct?
                if (circ_buffer[-1] == bytes([0xFE])
                    and circ_buffer[-2] == bytes([0xFE])):
                    
                    values = struct.unpack('<6h', b"".join(islice(circ_buffer,2,14)))  # unpack the 12 data bytes into 6 16-bit integers
                
                    #print(values)
                    
                    # Find value from bottom
                    if (circ_buffer[0] == bytes([0x80]) 
                        and circ_buffer[1] == bytes([0x80])):
                        ofile.write(str(1) + ',')
                    elif (circ_buffer[0] == bytes([0x00]) 
                        and circ_buffer[1] == bytes([0x00])):
                        ofile.write(str(0) + ',')
                    
                    # Data is not valid
                    else:
                        continue
                    
                    for value in values:
                        ofile.write(str(value) + ',')
                    
                    ofile.write("\n")

    ser_rx.close()


def main(data_path, port, baud, data_len):
    receive_data(port, baud, data_path, data_len)

if __name__ == "__main__":
    # Run argument parser
    parser = argparse.ArgumentParser(description="Program used to receive a data over UART")
    parser.add_argument('data_path', help="Path to save data")
    parser.add_argument('-l', '--data_len', required=False, default=16, help="Number of bytes to receive")
    parser.add_argument('-p', '--port', required=False, help="Serial port to use for receiving")
    parser.add_argument('-b', '--baud', required=False, default=115200, help="Baud rate of transmit port - defaults to 115200")

    args = parser.parse_args()

    main(args.data_path, args.port, args.baud, args.data_len)