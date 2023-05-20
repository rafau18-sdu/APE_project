create_clock -period 8.000 -name clk -waveform {0.000 4.000} [get_ports clk]

create_generated_clock -name imu2nn_i/en_debounce/U0/div/I -source [get_ports clk] -divide_by 25000 [get_pins imu2nn_i/en_debounce/U0/div/clk_temp_reg/Q]
create_generated_clock -name imu2nn_i/imu_bram2uart_0/U0/uart_clk/I -source [get_ports clk] -divide_by 68 [get_pins imu2nn_i/imu_bram2uart_0/U0/uart_clk/clk_temp_reg/Q]
create_generated_clock -name imu2nn_i/imu_logic_0/spi_clk/U0/clk_div_inst/I -source [get_ports clk] -divide_by 62 [get_pins imu2nn_i/imu_logic_0/spi_clk/U0/clk_div_inst/clk_temp_reg/Q]
create_generated_clock -name imu2nn_i/rst_debounce/U0/div/I -source [get_ports clk] -divide_by 25000 [get_pins imu2nn_i/rst_debounce/U0/div/clk_temp_reg/Q]
