`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 05/10/2023 11:29:52 AM
// Design Name: 
// Module Name: TB_imu_bram2uart
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module TB_imu_bram2uart;

    localparam CLK_PER = 8;

    wire clk_i, rst_i, imu_get_data_i,  en_bram_o, tx_uart_o;
    
    reg clk_int, rst_int, imu_get_data_int;
    
    wire [15:0] data_bram_i;
    
    reg [15:0] data_bram_int;
    
    wire [12:0] addr_bram_o;
    
    reg [15:0] addr_bram_old;
    
    // Clock stimuli
    always #CLK_PER clk_int = ~clk_int;

    imu_bram2uart #(13, 125000000, 115200) dut(
        .clk (clk_i),
        .rst (rst_i),
        .imu_get_data (imu_get_data_i),
        .active_bit (1),
        .data_bram (data_bram_i),
        .addr_bram (addr_bram_o),
        .en_bram (en_bram_o),
        .tx_uart (tx_uart_o)
        );

    assign {clk_i, rst_i, imu_get_data_i} = {clk_int, rst_int, imu_get_data_int};
    
    assign data_bram_i = data_bram_int;
    
    initial begin
    
        {clk_int, rst_int, imu_get_data_int} <= 0;
        data_bram_int <= 'h1234;
        
        #1;
        
        #5000000;
        
        imu_get_data_int <= 1;
        
        #500000;
        
        imu_get_data_int <= 0;
        
        addr_bram_old <= addr_bram_o;
        
        forever
        begin
        
            if (addr_bram_old !== addr_bram_o) begin 
                data_bram_int <= data_bram_int + 3;
            end
            
            if (addr_bram_o == 5)
            begin
                #5000000;
        
                imu_get_data_int <= 1;
                
                #500000;
                
                imu_get_data_int <= 0;
                
                while (addr_bram_o == 5)
                    #(CLK_PER);
            end
            
            addr_bram_old <= addr_bram_o;
            
            #CLK_PER;
        end
    end
endmodule
