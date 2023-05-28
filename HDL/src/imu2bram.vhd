----------------------------------------------------------------------------------
-- Company:
-- Engineer: 
-- 
-- Create Date: 03/29/2023 12:43:40 PM
-- Design Name: 
-- Module Name: imu2bram - Behavioral
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

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity imu2bram is
    Generic( bram_addr_width : integer := 13
    );
    Port ( clk          : in  STD_LOGIC;
           new_data     : in  STD_LOGIC;
           addr_imu     : in  STD_LOGIC_VECTOR (6 downto 0);
           data_imu     : in  STD_LOGIC_VECTOR (7 downto 0);
           data_valid   : in  STD_LOGIC;
           usr_bank     : in  STD_LOGIC_VECTOR(1 downto 0) := (others => '0'); -- Active usr bank
           we           : out STD_LOGIC_VECTOR(1 downto 0) := (others => '0');
           data_bram    : out STD_LOGIC_VECTOR (15 downto 0);
           addr_bram    : out STD_LOGIC_VECTOR (bram_addr_width - 1 downto 0)
           );
end imu2bram;

architecture Behavioral of imu2bram is

    TYPE STATE_TYPE IS (WAITING, SET, RESET);

    -- Declare current and next state signals
    signal current_state    : STATE_TYPE;
    
    signal data_imu_reg     : STD_LOGIC_VECTOR (data_imu'high downto data_imu'low);
    signal addr_imu_reg     : STD_LOGIC_VECTOR (addr_imu'high downto addr_imu'low);
    
    signal addr_bram_temp   : STD_LOGIC_VECTOR (addr_bram'high downto addr_bram'low);
    signal data_bram_temp   : STD_LOGIC_VECTOR (data_bram'high downto data_bram'low);
    signal data_bram_int    : STD_LOGIC_VECTOR (data_bram'high downto data_bram'low); 
    signal we_temp          : STD_LOGIC_VECTOR (we'high downto we'low);
   
    constant acc_x_addr     : STD_LOGIC_VECTOR (addr_bram'high downto addr_bram'low) := STD_LOGIC_VECTOR(to_unsigned(0, addr_bram'length));
    constant acc_y_addr     : STD_LOGIC_VECTOR (addr_bram'high downto addr_bram'low) := STD_LOGIC_VECTOR(to_unsigned(1, addr_bram'length));
    constant acc_z_addr     : STD_LOGIC_VECTOR (addr_bram'high downto addr_bram'low) := STD_LOGIC_VECTOR(to_unsigned(2, addr_bram'length));
    constant gyro_x_addr    : STD_LOGIC_VECTOR (addr_bram'high downto addr_bram'low) := STD_LOGIC_VECTOR(to_unsigned(3, addr_bram'length));
    constant gyro_y_addr    : STD_LOGIC_VECTOR (addr_bram'high downto addr_bram'low) := STD_LOGIC_VECTOR(to_unsigned(4, addr_bram'length));
    constant gyro_z_addr    : STD_LOGIC_VECTOR (addr_bram'high downto addr_bram'low) := STD_LOGIC_VECTOR(to_unsigned(5, addr_bram'length));
    constant temp_addr      : STD_LOGIC_VECTOR (addr_bram'high downto addr_bram'low) := STD_LOGIC_VECTOR(to_unsigned(6, addr_bram'length));
    constant who_addr       : STD_LOGIC_VECTOR (addr_bram'high downto addr_bram'low) := STD_LOGIC_VECTOR(to_unsigned(7, addr_bram'length));
    
    constant acc_x_off_addr     : STD_LOGIC_VECTOR (addr_bram'high downto addr_bram'low) := STD_LOGIC_VECTOR(to_unsigned(8, addr_bram'length));
    constant acc_y_off_addr     : STD_LOGIC_VECTOR (addr_bram'high downto addr_bram'low) := STD_LOGIC_VECTOR(to_unsigned(9, addr_bram'length));
    constant acc_z_off_addr     : STD_LOGIC_VECTOR (addr_bram'high downto addr_bram'low) := STD_LOGIC_VECTOR(to_unsigned(10, addr_bram'length));
    constant gyro_x_off_addr    : STD_LOGIC_VECTOR (addr_bram'high downto addr_bram'low) := STD_LOGIC_VECTOR(to_unsigned(11, addr_bram'length));
    constant gyro_y_off_addr    : STD_LOGIC_VECTOR (addr_bram'high downto addr_bram'low) := STD_LOGIC_VECTOR(to_unsigned(12, addr_bram'length));
    constant gyro_z_off_addr    : STD_LOGIC_VECTOR (addr_bram'high downto addr_bram'low) := STD_LOGIC_VECTOR(to_unsigned(13, addr_bram'length));
    
    constant padding        : STD_LOGIC_VECTOR(data_bram'length - data_imu'length - 1 downto 0) := (others => '0');
    
begin

--    x"00",  --WHO AM I?
--    x"2D", --ACCEL_XOUT_H
--    x"2E", --ACCEL_XOUT_L
--    x"2F", --ACCEL_YOUT_H
--    x"30", --ACCEL_YOUT_L
--    x"31", --ACCEL_ZOUT_H
--    x"32", --ACCEL_ZOUT_L
--    x"33", --GYRO_XOUT_H
--    x"34", --GYRO_XOUT_L
--    x"35", --GYRO_YOUT_H
--    x"36", --GYRO_YOUT_L
--    x"37", --GYRO_ZOUT_H
--    x"38", --GYRO_ZOUT_L
--    x"39", --TEMP_OUT_H
--    x"3A", --TEMP_OUT_L

    data_bram <= data_bram_int;

    process(clk)
    begin
        if rising_edge(clk) then
            case current_state is
            when WAITING =>
                if new_data = '1' and data_valid = '1' then
                    addr_imu_reg <= addr_imu;
                    data_imu_reg <= data_imu;
                    
                    current_state <= SET;
                end if;
            when SET =>
                addr_bram  <= addr_bram_temp;
                data_bram_int  <= data_bram_temp;
                we         <= we_temp;
                
                current_state <= RESET;
            
            when RESET =>
                if new_data = '0' then
                    current_state <= WAITING;
                end if;
                
            when others =>
                current_state <= WAITING;
            end case;
        end if;
    end process;
    
    ram_addr : process(addr_imu_reg, data_imu_reg, data_bram_int)
    begin
        addr_bram_temp <= (others => '0');
        data_bram_temp <= (others => '0');
        we_temp <= (others => '0');
        
        if usr_bank = "00" then
            case '0' & addr_imu_reg is
                when x"00" => --WHO AM I?
                    addr_bram_temp <= who_addr;
                    data_bram_temp <= padding & data_imu_reg;
                    we_temp <= "01";
                    
                when x"2D" => --ACCEL_XOUT_H
                    addr_bram_temp <= acc_x_addr;
                    data_bram_temp <= (others => '0');
                    data_bram_temp(15 downto 8) <= data_imu_reg;
                    we_temp <= "00";
                    
                when x"2E" => --ACCEL_XOUT_L
                    addr_bram_temp <= acc_x_addr;
                    data_bram_temp <= data_bram_int;
                    data_bram_temp(7 downto 0) <= data_imu_reg;
                    we_temp <= "11";
                    
                when x"2F" => --ACCEL_YOUT_H
                    addr_bram_temp <= acc_y_addr;
                    data_bram_temp <= (others => '0');
                    data_bram_temp(15 downto 8) <= data_imu_reg;
                    we_temp <= "00";
                    
                when x"30" => --ACCEL_YOUT_L
                    addr_bram_temp <= acc_y_addr;
                    data_bram_temp <= data_bram_int;
                    data_bram_temp(7 downto 0) <= data_imu_reg;
                    we_temp <= "11";
                    
                when x"31" => --ACCEL_ZOUT_H
                    addr_bram_temp <= acc_z_addr;
                    data_bram_temp <= (others => '0');
                    data_bram_temp(15 downto 8) <= data_imu_reg;
                    we_temp <= "00";
                    
                when x"32" => --ACCEL_ZOUT_L
                    addr_bram_temp <= acc_z_addr;
                    data_bram_temp <= data_bram_int;
                    data_bram_temp(7 downto 0) <= data_imu_reg;
                    we_temp <= "11";
                    
                when x"33" => --GYRO_XOUT_H
                    addr_bram_temp <= gyro_x_addr;
                    data_bram_temp <= (others => '0');
                    data_bram_temp(15 downto 8) <= data_imu_reg;
                    we_temp <= "00";
                    
                when x"34" => --GYRO_XOUT_L
                    addr_bram_temp <= gyro_x_addr;
                    data_bram_temp <= data_bram_int;
                    data_bram_temp(7 downto 0) <= data_imu_reg;
                    we_temp <= "11";
                    
                when x"35" => --GYRO_YOUT_H
                    addr_bram_temp <= gyro_y_addr;
                    data_bram_temp <= (others => '0');
                    data_bram_temp(15 downto 8) <= data_imu_reg;
                    we_temp <= "00";
                    
                when x"36" => --GYRO_YOUT_L
                    addr_bram_temp <= gyro_y_addr;
                    data_bram_temp <= data_bram_int;
                    data_bram_temp(7 downto 0) <= data_imu_reg;
                    we_temp <= "11";
                    
                when x"37" => --GYRO_ZOUT_H
                    addr_bram_temp <= gyro_z_addr;
                    data_bram_temp <= (others => '0');
                    data_bram_temp(15 downto 8) <= data_imu_reg;
                    we_temp <= "00";
                    
                when x"38" => --GYRO_ZOUT_L
                    addr_bram_temp <= gyro_z_addr;
                    data_bram_temp <= data_bram_int;
                    data_bram_temp(7 downto 0) <= data_imu_reg;
                    we_temp <= "11";
                    
                when x"39" => --TEMP_OUT_H
                    addr_bram_temp <= temp_addr;
                    data_bram_temp <= (others => '0');
                    data_bram_temp(15 downto 8) <= data_imu_reg;
                    we_temp <= "00";
                    
                when x"3A" => --TEMP_OUT_L
                    addr_bram_temp <= temp_addr;
                    data_bram_temp <= data_bram_int;
                    data_bram_temp(7 downto 0) <= data_imu_reg;
                    we_temp <= "11";
                    
                when others =>
                    null;
            end case;
        elsif usr_bank = "01" then
            
            case '0' & addr_imu_reg is
                    
                when x"14" => --XA_OFFS_H
                    addr_bram_temp <= acc_x_off_addr;
                    data_bram_temp <= (others => '0');
                    data_bram_temp(15 downto 7) <= '0' & data_imu_reg;
                    we_temp <= "00";
                    
                when x"15" => --XA_OFFS_L
                    addr_bram_temp <= acc_x_off_addr;
                    data_bram_temp <= data_bram_int;
                    data_bram_temp(6 downto 0) <= data_imu_reg(7 downto 1);
                    we_temp <= "11";
                
                when x"17" => --YA_OFFS_H
                    addr_bram_temp <= acc_y_off_addr;
                    data_bram_temp <= (others => '0');
                    data_bram_temp(15 downto 7) <= '0' & data_imu_reg;
                    we_temp <= "00";
                    
                when x"18" => --YA_OFFS_L
                    addr_bram_temp <= acc_y_off_addr;
                    data_bram_temp <= data_bram_int;
                    data_bram_temp(6 downto 0) <= data_imu_reg(7 downto 1);
                    we_temp <= "11";
                    
                when x"1A" => --ZA_OFFS_H
                    addr_bram_temp <= acc_z_off_addr;
                    data_bram_temp <= (others => '0');
                    data_bram_temp(15 downto 7) <= '0' & data_imu_reg;
                    we_temp <= "00";
                    
                when x"1B" => --ZA_OFFS_L
                    addr_bram_temp <= acc_z_off_addr;
                    data_bram_temp <= data_bram_int;
                    data_bram_temp(6 downto 0) <= data_imu_reg(7 downto 1);
                    we_temp <= "11";
                    
                when others =>
                    null;
            end case;
            
        elsif usr_bank = "10" then
            
            case '0' & addr_imu_reg is
                    
                when x"03" => --XG_OFFS_USRH
                    addr_bram_temp <= gyro_x_off_addr;
                    data_bram_temp <= (others => '0');
                    data_bram_temp(15 downto 8) <= data_imu_reg;
                    we_temp <= "00";
                    
                when x"04" => --XG_OFFS_USRL
                    addr_bram_temp <= gyro_x_off_addr;
                    data_bram_temp <= data_bram_int;
                    data_bram_temp(7 downto 0) <= data_imu_reg;
                    we_temp <= "11";
                
                when x"05" => --YG_OFFS_USRH
                    addr_bram_temp <= gyro_y_off_addr;
                    data_bram_temp <= (others => '0');
                    data_bram_temp(15 downto 8) <= data_imu_reg;
                    we_temp <= "00";
                    
                when x"06" => --YG_OFFS_USRL
                    addr_bram_temp <= gyro_y_off_addr;
                    data_bram_temp <= data_bram_int;
                    data_bram_temp(7 downto 0) <= data_imu_reg;
                    we_temp <= "11";
                    
                when x"07" => --ZG_OFFS_USRH
                    addr_bram_temp <= gyro_z_off_addr;
                    data_bram_temp <= (others => '0');
                    data_bram_temp(15 downto 8) <= data_imu_reg;
                    we_temp <= "00";
                    
                when x"08" => --ZG_OFFS_USRL
                    addr_bram_temp <= acc_z_off_addr;
                    data_bram_temp <= data_bram_int;
                    data_bram_temp(7 downto 0) <= data_imu_reg;
                    we_temp <= "11";
                    
                when others =>
                    null;
            end case;
        
        end if;
    end process;

end Behavioral;
