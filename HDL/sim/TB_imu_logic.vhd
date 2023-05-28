----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 04/12/2023 01:25:20 PM
-- Design Name: 
-- Module Name: TB_imu_logic - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity TB_imu_logic is
--  Port ( );
end TB_imu_logic;

architecture Behavioral of TB_imu_logic is

    component imu_logic_wrapper
      port (
        addr_bram       : out STD_LOGIC_VECTOR ( 12 downto 0 );
        ck_miso         : in STD_LOGIC;
        ck_mosi         : out STD_LOGIC;
        ck_sck          : out STD_LOGIC;
        ck_ss           : out STD_LOGIC;
        clk             : in STD_LOGIC;
        data_bram       : out STD_LOGIC_VECTOR ( 15 downto 0 );
        en              : in STD_LOGIC;
        get_data_flag   : out STD_LOGIC;
        rst             : in STD_LOGIC;
        usr_bank        : out STD_LOGIC_VECTOR ( 1 downto 0 );
        we              : out STD_LOGIC_VECTOR ( 1 downto 0 )
      );
    end component;
    
    constant CLK_FREQ   : REAL  := 125.0;    -- Clock frequency in MHz
    
        -- Derived
    constant CLK_PER    : TIME  := (1.0/CLK_FREQ)*1 us;
    constant CLK_HPER   : TIME  := CLK_PER/2;

    signal addr_bram       :  STD_LOGIC_VECTOR ( 12 downto 0 );
    signal ck_miso         :  STD_LOGIC := '0';                        
    signal ck_mosi         :  STD_LOGIC;                       
    signal ck_sck          :  STD_LOGIC;                       
    signal ck_ss           :  STD_LOGIC;                       
    signal clk             :  STD_LOGIC := '1';                        
    signal data_bram       :  STD_LOGIC_VECTOR ( 15 downto 0 );
    signal rst             :  STD_LOGIC := '0';
    signal en              :  STD_LOGIC := '1';                        
    signal we              :  STD_LOGIC_VECTOR ( 1 downto 0 );
    signal get_data_flag   :  STD_LOGIC;
    signal usr_bank        :  STD_LOGIC_VECTOR ( 1 downto 0 );
    
    signal sck_shift        : STD_LOGIC_VECTOR(1 downto 0) := "00";

    signal value_shift      : STD_LOGIC_VECTOR(131 downto 0) := x"00112233445566778899aabbccddeefff";

begin

    dut : imu_logic_wrapper
      port map (
        addr_bram       =>  addr_bram,
        ck_miso         =>  ck_miso  ,
        ck_mosi         =>  ck_mosi  ,
        ck_sck          =>  ck_sck   ,
        ck_ss           =>  ck_ss    ,
        clk             =>  clk      ,
        data_bram       =>  data_bram,
        rst             =>  rst      ,
        en              =>  en       ,
        we              =>  we       ,
        get_data_flag   =>  get_data_flag,
        usr_bank        =>  usr_bank
      );
      
      clk <= not clk after CLK_HPER;
      
      stimuli :  process
      
        
      begin
          sck_shift <= sck_shift(0) & ck_sck;
          
          if sck_shift = "10" then
            ck_miso <= value_shift(value_shift'high);
            value_shift <= value_shift(value_shift'high - 1 downto 0) & value_shift(value_shift'high);
          end if;
          
          wait for 10 ns;
      end process;

end Behavioral;
