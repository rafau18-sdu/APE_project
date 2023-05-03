`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 04/26/2023 09:29:27 AM
// Design Name: 
// Module Name: TB_imu_controller
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

module TB_imu_controller;

    localparam CLK_PER = 8;
    localparam IMU_PER = CLK_PER * 64;

    wire clk_i, rst_i, en_i, data_ready_i, new_msg_o;
    
    reg clk_int, rst_int, en_int, data_ready_int;
    
    wire [15:0] message_o;
    
    // Clock stimuli
    always #CLK_PER clk_int = ~clk_int;

    imu_controller #(125, 2) dut(
        .clk (clk_i),
        .rst (rst_i),
        .en (en_i),
        .data_ready (data_ready_i),
        .new_msg (new_msg_o),
        .message (message_o)
        );

    assign {clk_i, rst_i, en_i, data_ready_i} = {clk_int, rst_int, en_int, data_ready_int};
    
    integer ii = 0;

    initial begin
    
        {clk_int, rst_int, en_int, data_ready_int} <= 0;
        
        #1;
        
        #(5*CLK_PER);
        
        en_int <= 1;
        
        repeat(20)
        begin
        
            @(posedge new_msg_o);
        
            #(20*IMU_PER)
            
            data_ready_int <= 1;
            
            #IMU_PER
            
            data_ready_int <= 0;
          
        end
        
        #(IMU_PER*20) $finish;
    
    end
endmodule
