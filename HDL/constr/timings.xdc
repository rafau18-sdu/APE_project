create_clock -period 8.000 -name clk -waveform {0.000 4.000} [get_ports clk]
create_generated_clock -name imu2nn_i/imu_logic_0/enable_debounce/U0/div/I -source [get_ports clk] -divide_by 25000 [get_pins imu2nn_i/imu_logic_0/enable_debounce/U0/div/clk_temp_reg/Q]
create_generated_clock -name imu2nn_i/imu_logic_0/reset_debounce/U0/div/I -source [get_ports clk] -divide_by 25000 [get_pins imu2nn_i/imu_logic_0/reset_debounce/U0/div/clk_temp_reg/Q]
