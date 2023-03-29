----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 02/26/2023 12:04:16 PM
-- Design Name: 
-- Module Name: bram_interface - Behavioral
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
use IEEE.MATH_REAL.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity bram_interface is
    Generic ( data_len : integer := 64 -- Number of bytes to store in bram before deleting old values.
            );
    Port ( ramd_in : in STD_LOGIC_VECTOR (31 downto 0);
           ramd_out : out STD_LOGIC_VECTOR (31 downto 0);
           ram_addr : out STD_LOGIC_VECTOR (31 downto 0);
           ram_we : out STD_LOGIC_VECTOR(3 downto 0);
           ram_en : out STD_LOGIC;
           ram_rst : out STD_LOGIC;
           
           clk : in STD_LOGIC;
           rst : in STD_LOGIC;
           data : in std_logic_vector (7 downto 0);
           new_data_flag : in STD_LOGIC
           );
end bram_interface;

architecture Behavioral of bram_interface is

    type ram_enum is (WAITING, UPDATE_DATA, UPDATE_META);
    signal ram_state : ram_enum := WAITING;
    
    constant data_offset : integer := 1;
    
begin

    ram_en <= '1';
    
    process(clk, rst)
    
        variable data_flag_old : STD_LOGIC := '0';
        
        constant idx_size : integer := integer(ceil(log2(real(data_len+data_offset))));
        
        variable data_idx : unsigned(idx_size - 1 downto 0) := to_unsigned(data_offset, idx_size);
    begin
    
        if rst = '1' then
            ram_rst <= '1';
            ram_state <= WAITING;
            ram_we <= "0000";
            data_idx := to_unsigned(data_offset, data_idx'length);
            
        elsif rising_edge(clk) then
            ram_rst <= '0';
            
            case ram_state is
                when WAITING =>
                    ram_addr <= (others => '0');
                    ram_we <= "0000";
                
                    if data_flag_old = '0' and new_data_flag = '1' then
                        ram_state <= UPDATE_DATA;
                    end if;
                
                when UPDATE_DATA =>
                    ram_we <= "0001";
                    ram_addr(idx_size + 1 downto 0) <= STD_LOGIC_VECTOR(data_idx) & "00";
                    ramd_out <= (others => '0');
                    ramd_out(7 downto 0) <= data;
                    
                    ram_state <= UPDATE_META;

                when UPDATE_META =>
                
                    ram_we <= "1111";
                    ram_addr <= (others => '0');
                    ramd_out <= (others => '0');
                    ramd_out(idx_size - 1 downto 0) <= STD_LOGIC_VECTOR(data_idx);
                
                    if data_idx = to_unsigned(data_len + data_offset - 1, data_idx'length) then
                        data_idx := to_unsigned(data_offset, data_idx'length);
                    else
                        data_idx := data_idx + 1;
                    end if;
                        
                    ram_state <= WAITING;
            end case;
            
            data_flag_old := new_data_flag;
        end if;
    
    end process;


end Behavioral;
