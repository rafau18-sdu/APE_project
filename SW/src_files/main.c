
#include <stdio.h>
#include "platform.h"
#include "xil_printf.h"
#include "xil_io.h"
#include "xuartps.h"
#include "xbram.h"
#include "xparameters.h"
#include <unistd.h>

#define BRAM(A)     ((volatile u32*)px_config->MemBaseAddress)[A]
#define NUM_INPUTS		100 					// number of pixel in input image
#define BYTES_PR_INPUT		4 					// 32 bit float = 4 bytes
#define BASE_ADDR		XPAR_AXI_BRAM_CTRL_0_S_AXI_BASEADDR	// from xparameters.h

#define ACC_SENS 	2048 //16384
#define GYRO_SENS 	32.8 //131
#define TEMP_SENS 	333.87
#define TEMP_OFF 	0
#define TEMP_ROOM 	15

#define ADDR_LEN    14

XBram             	x_bram;
XBram_Config    	*px_config;
XUartPs_Config 		*Config_0;
XUartPs 			Uart_PS_0;

uint8_t 		ucAXIInit();
int				xuartps_init();
//void 			printBits(unsigned int num);
//float 			IntBitsToFloat(long long int bits);

void print_help() {
	print("\n0: acc x\n");
	print("1: acc y\n");
	print("2: acc z\n");
	print("3: gyro x\n");
	print("4: gyro y\n");
	print("5: gyro z\n");
	print("6: temp\n");
	print("7: whoami\n");
	print("8: acc x off\n");
	print("9: acc y off\n");
	print("10: acc z off\n");
	print("11: gyro x off\n");
	print("12: gyro y off\n");
	print("13: gyro z off\n");
}

int main()
{
    init_platform();

    print("\n\rInitializing..\n\r");

    sleep(1);

	ucAXIInit();

	xuartps_init();

	//uint8_t ram_position = 0;

	//uint8_t BufferPtr_rx[NUM_INPUTS*BYTES_PR_INPUT] = {0x00};

	//int Status = 0;
	//int tempInt;
	//float tempFloat = 0.0;
	print_help();

    while(1)
    {

    	print("\nReady to give value\n");

    	uint8_t ram_position = 0;
    	uint8_t ram_valid = 1;

    	while (1) {
    		uint8_t rx_byte = XUartPs_RecvByte(XPAR_XUARTPS_0_BASEADDR); // read UART

    		if (48 <= rx_byte && 57 >= rx_byte) {
    			ram_position *= 10;
    		    ram_position += (rx_byte - 48);
    		} else if (rx_byte == 104) { //'h'
    			ram_valid = 0;
    			print_help();
    		} else if (13 == rx_byte || 10 == rx_byte) { //'\r' or '\n'
    			break;
    		} else {
    			ram_valid = 0;
    		}
    	}

    	uint8_t cnt = 0;

    	if (ADDR_LEN > ram_position && 1 == ram_valid) {

    		char str[100];

			sprintf(str, "Getting value for %d\n", ram_position);

			print(str);

    		while(++cnt < 20) {
    			usleep(250000);

				int16_t tempInt = BRAM(ram_position);

				float scaled;

				if (ram_position <=2) {
					scaled = (float)tempInt / ACC_SENS;
				} else if (ram_position <= 5) {
					scaled = (float)((int16_t)tempInt) / GYRO_SENS;
				} else if (ram_position == 6) {
					scaled = (float)(tempInt - TEMP_OFF) / TEMP_SENS + TEMP_ROOM;
				} else {
					scaled = tempInt;
				}

				sprintf(str, "Value: %.3f\n", scaled);

				print(str);

				sprintf(str, "Raw: %hX\n", tempInt);

				print(str);

			}

    	}





    	/*
		for(int i = 0; i < NUM_INPUTS; i++){
			// concatenate 8-bit input messages into 32-bit values
			tempInt = ((BufferPtr_rx[i*4+3]<<24) | (BufferPtr_rx[i*4+2]<<16) | (BufferPtr_rx[i*4+1]<<8) | BufferPtr_rx[i*4]);
			// prints current values in BRAM
			tempFloat = *((float *)&tempInt); 	// int bits to float
			char buffer2[10];
			sprintf(buffer2, "%f", tempFloat);
			xil_printf("BRAM[%d]:", i);
			xil_printf(buffer2);
			print("\n\r");

			BRAM(i) = tempInt; // write to BRAM
		}*/
    }

    print("Shutting down");
    cleanup_platform();
    return 0;
}

uint8_t 	ucAXIInit(){
	/*************************
	*  BRAM initialization   *
	*************************/
	px_config = XBram_LookupConfig(XPAR_BRAM_0_DEVICE_ID);
	if (px_config == (XBram_Config *) NULL) {
		return XST_FAILURE;
	}
	int x_status 	= 	XBram_CfgInitialize(&x_bram, px_config,
			px_config->CtrlBaseAddress);
	if (x_status != XST_SUCCESS) {
		return XST_FAILURE;
	}
	return XST_SUCCESS;
}


int xuartps_init(){
	/*************************
	 * UART 0 initialization *
	 *************************/
	Config_0 = XUartPs_LookupConfig(XPAR_XUARTPS_0_DEVICE_ID);
	if (NULL == Config_0) {
		return XST_FAILURE;
	}
	int uart_x_status = XUartPs_CfgInitialize(&Uart_PS_0, Config_0, Config_0->BaseAddress);
	if (uart_x_status != XST_SUCCESS) {
		return XST_FAILURE;
	}
	return XST_SUCCESS;
}
