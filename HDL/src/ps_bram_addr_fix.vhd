----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 03/29/2023 01:00:50 PM
-- Design Name: 
-- Module Name: ps_bram_addr_fix - Behavioral
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

entity ps_bram_addr_fix is
    Generic (   addr_width : integer := 7;
                data_width : integer := 16
    );
    Port ( addr_in  : in  STD_LOGIC_VECTOR (addr_width - 1 downto 0);
           data_in  : in  STD_LOGIC_VECTOR (data_width - 1 downto 0);
           we_in    : in  STD_LOGIC_VECTOR ((data_width - 1) / 8 downto 0);
           addr_out : out STD_LOGIC_VECTOR (31 downto 0);
           data_out : out STD_LOGIC_VECTOR (31 downto 0);
           we_out   : out STD_LOGIC_VECTOR (3 downto 0);
           en_out   : out STD_LOGIC;
           rst_out  : out STD_LOGIC
           );
end ps_bram_addr_fix;

architecture Behavioral of ps_bram_addr_fix is

    constant addr_padding   : STD_LOGIC_VECTOR (((addr_out'length - 1) - (addr_width + 2)) downto 0) := (others => '0');
    constant data_padding   : STD_LOGIC_VECTOR ((data_out'length - data_width - 1) downto 0) := (others => '0');
    
    constant we_padding     : STD_LOGIC_VECTOR ((we_out'length - we_in'length - 1) downto 0) := (others => '0');

begin

    addr_out <= addr_padding & addr_in & "00";
    data_out <= data_padding & data_in;
    we_out <= we_padding & we_in;
    en_out <= '1';
    rst_out <= '0';
    
end Behavioral;
