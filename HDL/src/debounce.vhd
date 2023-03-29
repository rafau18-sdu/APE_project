----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 03/08/2023 09:19:22 AM
-- Design Name: 
-- Module Name: debounce - Behavioral
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

entity debounce is
    Port ( clk : in STD_LOGIC;
           sig : in STD_LOGIC;
           debounce_sig : out STD_LOGIC);
end debounce;

architecture Behavioral of debounce is

    component clk_divider is
        Generic ( base_freq : integer := 125000000;
                  out_freq  : integer := 1843200     -- 115200 baud        
        );  
        Port ( rst : in STD_LOGIC;
               clk : in STD_LOGIC;
               clk_div : out STD_LOGIC);
    end component;
    
    signal slow_clk : STD_LOGIC;
    
    signal shift_reg : STD_LOGIC_VECTOR(7 downto 0) := (others=>'0');
    
    signal temp_sig : STD_LOGIC := '0';
    
    constant high_sig : STD_LOGIC_VECTOR(7 downto 0) := (others=>'1');
    constant low_sig  : STD_LOGIC_VECTOR(7 downto 0) := (others=>'0');
begin

    div : clk_divider
    generic map(
        base_freq => 125000000, 
        out_freq => 5000
    )
    port map (
        rst => '0',
        clk => clk,
        clk_div => slow_clk
    );
  
    debounce_sig <= temp_sig;
  
    process(slow_clk)
    begin
        if rising_edge(slow_clk) then
        
            if shift_reg = high_sig then
                temp_sig <= '1';
            elsif shift_reg = low_sig then
                temp_sig <= '0';
            end if;
            
            shift_reg <= shift_reg(6 downto 0) & sig;
        end if;
    end process;
   

end Behavioral;
