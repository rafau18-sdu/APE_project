----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 03/02/2023 10:46:17 AM
-- Design Name: 
-- Module Name: spi_imu_interface - Behavioral
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

entity spi_imu_interface is
    Port ( clk          : in STD_LOGIC;
           rst          : in STD_LOGIC;
           
           new_message  : in STD_LOGIC; --Must go high for at least 1 clk, when a message should be send.
           message      : in STD_LOGIC_VECTOR (15 downto 0);
           
           addr_out     : out STD_LOGIC_VECTOR (6 downto 0); 
           response     : out STD_LOGIC_VECTOR (7 downto 0); -- Is U if read_write_bit = '0'.
           output_valid : out STD_LOGIC := '0'; -- Is set to 1 if read_write_bit = '1', i.e. response is valid data.
           data_ready   : out STD_LOGIC; -- Goes high for 1 clock cycle when transmission is done.
           
           SCLK         : out STD_LOGIC;
           MOSI         : out STD_LOGIC;
           MISO         : in STD_LOGIC;
           CS           : out STD_LOGIC
           );
end spi_imu_interface;

architecture Behavioral of spi_imu_interface is

    -- Architecture Declarations
   signal message_reg       : STD_LOGIC_VECTOR(message'high downto message'low); -- Only 15 downto 8 are sued when read_flag = '1'.
   signal read_flag         : STD_LOGIC; -- Goes high when message expects response.
   
   signal addr_out_reg      : STD_LOGIC_VECTOR(addr_out'high downto addr_out'low);
   signal response_reg      : STD_LOGIC_VECTOR(response'high downto response'low);
   signal count             : UNSIGNED(3 downto 0);
   
   signal new_message_old   : STD_LOGIC := '1';
      
   TYPE STATE_TYPE IS (
      WAITING,
      CHIP_SELECT,
      WRITE_MSG,
      READ_MSG,
      READ_WAIT,
      READ_RX,
      SET_OUTPUT
   );

   -- Declare current and next state signals
   SIGNAL current_state : STATE_TYPE ;
   SIGNAL next_state : STATE_TYPE ;


begin

    

   ----------------------------------------------------------------------------
   clocked : PROCESS(
      clk,
      rst
   )
   ----------------------------------------------------------------------------
   BEGIN
      IF (rst = '1') THEN
         current_state <= WAITING;
         -- Reset Values
        message_reg     <= (others => '0');
        read_flag       <= '0';
        data_ready      <= '0';
                    
        addr_out_reg    <= (others => '0');
        response_reg    <= (others => '0');
        count           <= (others => '0');

      ELSIF (clk'EVENT AND clk = '1') THEN
         current_state <= next_state;
         -- Default Assignment To Internals
         
         new_message_old <= new_message;

         -- Combined Actions for non SPI signals signals only
         CASE current_state IS
         WHEN WAITING =>
            count           <= (others=>'0');
            addr_out_reg    <= (others=>'0');
            response_reg    <= (others=>'0');
            data_ready      <= '0';
            
         WHEN CHIP_SELECT =>
            read_flag <= message(15);
            message_reg <= message;
            addr_out_reg <= message(14 downto 8);
            
         WHEN WRITE_MSG =>
            message_reg <= message_reg(14 downto 0) & '0';
            count <= count +1;
            
         WHEN READ_MSG =>
            message_reg <= message_reg(14 downto 0) & '0';
            count <= count +1;
         
         WHEN READ_WAIT =>
             count <= count +1;
         
         WHEN READ_RX =>
            response_reg <= response_reg(6 downto 0) & MISO ;
            count <= count +1;
            
         WHEN SET_OUTPUT =>
            output_valid <= '0';
            if read_flag = '1' then
                response <= response_reg;
                addr_out <= addr_out_reg;
                output_valid <= '1';
            end if;
            data_ready <= '1';          
         
         WHEN OTHERS =>
            NULL;
         END CASE;

      END IF;

   END PROCESS clocked;

   ----------------------------------------------------------------------------
   nextstate : PROCESS (
      current_state,
      count,
      new_message,
      message
   )
   ----------------------------------------------------------------------------
   BEGIN
      CASE current_state IS
      WHEN WAITING =>
            if new_message_old = '0' and new_message = '1' then
                next_state <= CHIP_SELECT;
            else
                next_state <= WAITING;
            end if;
            
      WHEN CHIP_SELECT =>
            if message(15) = '1' then
                next_state <= READ_MSG;
            else
                next_state <= WRITE_MSG;
            end if;
            
      WHEN WRITE_MSG =>
         IF (count = 15) THEN
            next_state <= SET_OUTPUT;
         ELSE
            next_state <= WRITE_MSG;
         END IF;
         
      WHEN READ_MSG =>
         IF (count = 7) THEN
            next_state <= READ_WAIT;
         ELSE
            next_state <= READ_MSG;
         END IF;
       
      WHEN READ_WAIT =>
        if (count = 15) then
            next_state <= READ_RX;
        else
            next_state <= READ_WAIT;
        end if;
            
      WHEN READ_RX =>
        if (count = 7) then
            next_state <= SET_OUTPUT;
        else
            next_state <= READ_RX;
        end if;
        
      WHEN SET_OUTPUT =>
        next_state <= WAITING;
                               
      WHEN OTHERS =>
         next_state <= WAITING;
      END CASE;

   END PROCESS nextstate;


   ----------------------------------------------------------------------------
   imu_control : PROCESS (
      current_state, clk, message_reg
   )
   ----------------------------------------------------------------------------
   BEGIN
      -- Default Assignment
      --cs<= '1';
      -- Default Assignment To Internals

      -- Combined Actions
      CASE current_state IS
      WHEN WAITING =>
         cs<= '1';
         MOSI<='0';
         SCLK<='1';
         
      WHEN CHIP_SELECT =>
         cs<= '0';
         
      WHEN WRITE_MSG =>
         MOSI<= message_reg(15);
         SCLK <= not clk;
         cs<= '0';
         
      WHEN READ_MSG =>
         MOSI<= message_reg(15);
         SCLK <= not clk;
         cs<= '0';
         
      WHEN READ_WAIT =>
         SCLK<='1';
         cs<= '0';  
         
      WHEN READ_RX =>
         SCLK<= clk;
         cs<= '0';
         
      WHEN SET_OUTPUT =>
         SCLK<='1';
         
      WHEN OTHERS =>
         NULL;
      END CASE;
   
   END PROCESS;

   -- Concurrent Statements


end Behavioral;
