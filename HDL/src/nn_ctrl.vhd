----------------------------------------------------------------------------------
-- Company: SDU, UAS, DIII
-- Engineer: Nicolaj Malle
-- 
-- Create Date: 10/08/2021 12:17:41 PM
-- Project Name: FPGA_AI
-- Target Devices: PYNQ-Z2
-- Tool Versions: 2021.1
-- Description: Starts nn_inference IP module and outputs inference results
-- on  PYNQ-Z2 board LEDs.
----------------------------------------------------------------------------------



library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity nn_ctrl is
    Port (  clk : in STD_LOGIC;
            ap_ready : in STD_LOGIC;
            ap_start : out STD_LOGIC;
            ap_done  : in std_logic;
            ap_idle  : in std_logic;
            ap_rst   : out std_logic;
            rstb_busy: in std_logic;
            
            imu_get_data : in std_logic; 
            
            led_ctrl: out std_logic_vector(3 downto 0) := (others => '0');
            
            nn_res_in: in  std_logic_vector(31 downto 0);
            nn_res_out: out  std_logic_vector(31 downto 0) := (others => '0')
           
           );
end nn_ctrl;

architecture Behavioral of nn_ctrl is

    signal start_signal :   std_logic := '0';
    
    signal pred         :   integer := 0;
    
    signal imu_get_data_shift : STD_LOGIC_VECTOR(1 downto 0) := (others => '0');
    
begin

    ------------------  Start NN  ------------------
    PROCESS(clk)
    BEGIN
        if rising_edge(clk) then
            imu_get_data_shift <= imu_get_data_shift(0) & imu_get_data;
            
            if imu_get_data_shift = "10" then
                if ap_ready = '1' or ap_idle = '1' then
                    if rstb_busy = '0' then
                        start_signal <= '1';
                    else 
                        start_signal <= '0';
                    end if;
                end if;
            end if;
        end if;
    END PROCESS;
    
    -- Get output
    PROCESS(clk)
    BEGIN
        if rising_edge(clk) then
            if ap_done = '1' then
                pred <= to_integer(signed(nn_res_in));
                nn_res_out <= nn_res_in;
            end if;
        end if;
    END PROCESS;

    with pred select led_ctrl <=
        "0001" when 0,
        "0010" when 1,
        "0011" when 7,
        "0100" when 2,
        "0101" when 4,
        "0110" when 5,
        "0111" when 6,
        "1000" when 3,
        "1001" when 8,
        "1010" when 9,
        "0000" when others;
        

    ap_start <= start_signal;

    ap_rst <= '1';
    
end Behavioral;
