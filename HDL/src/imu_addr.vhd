----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 03/08/2023 09:09:38 AM
-- Design Name: 
-- Module Name: imu_addr - Behavioral
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

entity imu_addr is
    port(
        clk : in STD_LOGIC;
        inc : in STD_LOGIC;
        rst : in STD_LOGIC;
        addr : out STD_LOGIC_VECTOR(7 downto 0)
        );
end imu_addr;

architecture Behavioral of imu_addr is

    component addr_mapping
    Port ( clk  : in STD_LOGIC;
           addr : in std_logic_vector(3 downto 0);
           dout : out std_logic_vector(7 downto 0));
    end component;

    signal addr_cnt : unsigned(3 downto 0) := (others=>'0');
    signal old_inc : STD_LOGIC := '0';

begin

    mapper : addr_mapping
        port map(
        clk  => clk,
        addr => STD_LOGIC_VECTOR(addr_cnt),
        dout => addr
        );
        
        process(clk,rst)
            
        begin
        if(rst='1')then
            addr_cnt <= (others=>'0');
        elsif (rising_edge(clk)) then
            if (inc = '1' and old_inc = '0')then
                 addr_cnt <= addr_cnt + 1;
            end if;
        end if;
        
        old_inc <= inc;
        
    end process;


end Behavioral;
