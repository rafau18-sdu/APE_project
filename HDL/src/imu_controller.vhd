----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 04/19/2023 02:03:31 PM
-- Design Name: 
-- Module Name: imu_controller - Behavioral
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
use IEEE.NUMERIC_STD.ALL;
use IEEE.MATH_REAL.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity imu_controller is
    Generic (
                base_clk_mhz    : integer := 125;
                spi_clk_mhz     : integer := 2
            );
    Port ( 
            clk         : in STD_LOGIC;
            rst         : in STD_LOGIC;
            en          : in STD_LOGIC;
            data_ready  : in STD_LOGIC;
            response    : in STD_LOGIC_VECTOR(7 downto 0) := (others => '0');
            new_msg     : out STD_LOGIC := '0';
            message     : out STD_LOGIC_VECTOR(15 downto 0) := (others => '0');
            usr_bank    : out STD_LOGIC_VECTOR(1 downto 0) := (others => '0'); -- Active usr bank
            get_data    : out STD_LOGIC := '0'
          );
end imu_controller;

architecture Behavioral of imu_controller is

type config_rom_type is array (0 to 31) of std_logic_vector(15 downto 0);
constant config_rom : config_rom_type := (
                    x"0601", -- Disable low power
                    x"7F20", -- REG_BANK_SEL USR_BNK_2
                    x"000A", -- GYRO_SMPLRT_DIV 100Hz = 10
                    x"01" & "00011101", -- GYRO_CONFIG_1 +-1000 dps DLPF = 1 + DLPFCFG = 3
                    x"1000", -- ACCEL_SMPLRT_DIV_1 ACCEL_SMPLRT_DIV[11:8] = 0
                    x"110A", -- ACCEL_SMPLRT_DIV_2 ACCEL_SMPLRT_DIV[7:0] = 10
                    x"14" & "00011111", -- ACCEL_CONFIG +-16g  DLPF = 1 ACCEL_DLPFCFG = 3
                    x"8300", -- XG_OFFS_USRH
                    x"8400", -- XG_OFFS_USRL
                    x"8500", -- YG_OFFS_USRH
                    x"8600", -- YG_OFFS_USRL
                    x"8700", -- ZG_OFFS_USRH
                    x"8800", -- ZG_OFFS_USRL
                    x"7F10", -- REG_BANK_SEL USR_BNK_1
                    x"9400", -- XA_OFFS_H
                    x"9500", -- XA_OFFS_L
                    x"9700", -- YA_OFFS_H
                    x"9800", -- YA_OFFS_L
                    x"9A00", -- ZA_OFFS_H
                    x"9B00", -- ZA_OFFS_L
                    x"7F00", -- REG_BANK_SEL USR_BNK_0
                    x"1101", -- INT_ENABLE_1 RAW_DATA_0_RDY_EN = 1
                    others => (others => '0')
                  );
                  
constant config_len : integer := 22;

signal config_cnt : natural range 0 to config_len := 0;
                 
type running_rom_type is array (0 to 15) of std_logic_vector(7 downto 0);
constant running_rom : running_rom_type := (
                    x"1A", --INT_STATUS_1
                    x"00",  --WHO AM I?
                    x"2D", --ACCEL_XOUT_H
                    x"2E", --ACCEL_XOUT_L
                    x"2F", --ACCEL_YOUT_H
                    x"30", --ACCEL_YOUT_L
                    x"31", --ACCEL_ZOUT_H
                    x"32", --ACCEL_ZOUT_L
                    x"33", --GYRO_XOUT_H
                    x"34", --GYRO_XOUT_L
                    x"35", --GYRO_YOUT_H
                    x"36", --GYRO_YOUT_L
                    x"37", --GYRO_ZOUT_H
                    x"38", --GYRO_ZOUT_L
                    x"39", --TEMP_OUT_H
                    x"3A" --TEMP_OUT_L
                  );
                  
constant running_len    : natural := 16;

signal running_cnt      : natural range 0 to running_len - 1 := 0;

-- Speed syncing
constant clk_div        : natural := natural(ceil(real(base_clk_mhz)/real(spi_clk_mhz))) + 1;
signal clk_div_cnt      : natural range 0 to clk_div := 0;


constant wakeup_delay     : natural := 31;
signal delay_cnt   : natural range 0 to 2**12 - 1 :=  0;
signal delay_active : STD_LOGIC := '0';

signal data_ready_shift : STD_LOGIC_VECTOR(1 downto 0) := "11"; 

TYPE STATE_TYPE IS (
      CONFIG_START,
      CONFIG_FLAG,
      CONFIG_WAIT,
      RUNNING_START,
      RUNNING_FLAG,
      RUNNING_WAIT
   );

   -- Declare current and next state signals
   SIGNAL current_state : STATE_TYPE;
   
    procedure wrap_inc( signal cnt : inout natural;
                        constant val   : in natural) is
    begin
        if cnt = val - 1 then
            cnt <= 0;
        else 
            cnt <= cnt + 1;
        end if;
        
    end procedure;
    
    procedure cnt_wait( signal delay_cnt            : inout natural;
                        constant delay              : in natural;
                        signal clk_div_cnt          : inout natural;
                        constant clk_div            : in natural;
                        signal inc_cnt              : inout natural;
                        signal current_state        : out   STATE_TYPE;
                        constant new_state          : in   STATE_TYPE) is
    begin
    
        wrap_inc(clk_div_cnt, clk_div);
        
        if clk_div_cnt = clk_div - 1 then
            wrap_inc(delay_cnt, delay);
            
            if delay_cnt = delay - 1 then
                current_state <= new_state;
                inc_cnt <= inc_cnt + 1;   
                
                clk_div_cnt <= 0;
                delay_cnt <= 0;
            end if;
        end if;
        
    end procedure;
    
    signal dummy_cnt : natural range 0 to 1 := 0;
   
begin

    --running_cnt_debug <= STD_LOGIC_VECTOR(to_unsigned(running_cnt, running_cnt_debug'length));

    process(rst, clk, en)
    begin
    
        if rst = '1' then
            running_cnt <= 0;
            config_cnt <= 0;
            current_state <= CONFIG_START;
            new_msg <= '0';
            message <= (others => '0');
            delay_active <= '0';
            delay_cnt <= 0;
            get_data <= '0';
            
        elsif rising_edge(clk) and en = '1' then
        
            dummy_cnt <= 0; -- Used for when neither config_cnt nor running_cnt should be incremented.
            data_ready_shift <= data_ready_shift(0) & data_ready;
            
            case current_state is
            
                when CONFIG_START =>
                    case config_cnt is 
                        
                        when config_len => 
                            current_state <= RUNNING_START;
                        
                        when others =>
                            new_msg <= '1';
                            message <= config_rom(config_cnt);
                            current_state <= CONFIG_FLAG;
                    end case;
                    
                when CONFIG_FLAG =>
                
                    cnt_wait(   delay_cnt => delay_cnt,
                                delay => 2,
                                clk_div_cnt => clk_div_cnt,
                                clk_div => clk_div,
                                inc_cnt => dummy_cnt,
                                current_state => current_state,
                                new_state => CONFIG_WAIT);
                   
                    
                when CONFIG_WAIT =>
                    new_msg <= '0';
                    
                    if config_rom(config_cnt)(14 downto 8) = "1111111" then
                        usr_bank <= config_rom(config_cnt)(5 downto 4);
                    end if;
                
                    case config_cnt is 
                        when 0 =>
                       
                            if data_ready_shift = "01" then
                                delay_active <= '1';
                                clk_div_cnt <= 0;
                                delay_cnt <= 0;
                            end if;
                            
                            if delay_active = '1' then
                            
                                cnt_wait(   delay_cnt => delay_cnt,
                                            delay => wakeup_delay,
                                            clk_div_cnt => clk_div_cnt,
                                            clk_div => clk_div,
                                            inc_cnt => config_cnt,
                                            current_state => current_state,
                                            new_state => CONFIG_START);
                            end if;
                            
                        when others =>
                            if data_ready_shift = "01" then
                                config_cnt <= config_cnt + 1;
                                current_state <= CONFIG_START;
                            end if;
                            
                    end case;
                
                when RUNNING_START =>
                
                    new_msg <= '1';
                    message <= running_rom(running_cnt) & x"00";
                    message(15) <= '1';
                    
                    current_state <= RUNNING_FLAG;
                
                when RUNNING_FLAG =>
                
                    cnt_wait(   delay_cnt => delay_cnt,
                                delay => 2,
                                clk_div_cnt => clk_div_cnt,
                                clk_div => clk_div,
                                inc_cnt => dummy_cnt,
                                current_state => current_state,
                                new_state => RUNNING_WAIT);
                
                when RUNNING_WAIT =>
                    
                    new_msg <= '0';
                
                    if data_ready_shift = "01" then
                    
                        if running_cnt = 0 then
                            get_data <= '0';
                            
                            if response(0) = '1' then            
                                wrap_inc(running_cnt, running_len);
                                
                                get_data <= '1';
                            end if;
                        else
                            wrap_inc(running_cnt, running_len);
                        end if;   
                                          
                        current_state <= RUNNING_START;
                    end if;
            
                when others =>
                    NULL;
            end case;                    
        end if;
    
    end process;

end Behavioral;
