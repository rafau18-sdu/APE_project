----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 05/03/2023 03:22:20 PM
-- Design Name: 
-- Module Name: imu_bram_2_uart - Behavioral
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

entity imu_bram2uart is
    Generic( bram_addr_width    : integer := 13;
             base_clk_hz        : integer := 125000000;
             uart_clk_hz        : integer := 115200
        );
    Port (  clk             : in  STD_LOGIC;
            rst             : in  STD_LOGIC;
            imu_get_data    : in  STD_LOGIC;
            data_bram       : in  STD_LOGIC_VECTOR (15 downto 0);
            addr_bram       : out STD_LOGIC_VECTOR (bram_addr_width - 1 downto 0) := (others => '0');
            en_bram         : out  STD_LOGIC := '1';
            
            tx_uart         : out  STD_LOGIC
          );
end imu_bram2uart;

architecture Behavioral of imu_bram2uart is

    component uart_tx_module is
        Port (  rst             : in  STD_LOGIC;
                clk             : in  STD_LOGIC; -- clock must be 16x baudrate
                sig             : out STD_LOGIC;
                data            : in  STD_LOGIC_VECTOR (7 downto 0);
                new_data_pulse  : in  STD_LOGIC;
                data_send       : out STD_LOGIC -- Goes high for one clock, when data has been send.
                );
    end component;
    
    component clk_divider is
        Generic ( base_freq : integer := 125000000;
                  out_freq  : integer := 1843200     -- 115200 baud        
        );  
        Port ( rst : in STD_LOGIC;
               clk : in STD_LOGIC;
               clk_div : out STD_LOGIC);
    end component;
    
    type STATE_TYPE is (
        START, 
        SET_BRAM, 
        GET_BRAM, 
        SEND_START_BYTE,
        SEND_END_BYTE,
        SEND_BRAM,
        WAIT_SEND_BRAM,
        WAIT_SEND_START,
        WAIT_SEND_END);
    signal current_state : STATE_TYPE := START;
    
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

    constant bram_len : integer := 6;
    signal bram_addr_cnt : integer range 0 to bram_len := 0;
    signal bram_data_reg : STD_LOGIC_VECTOR(15 downto 0) := (others => '0');
    signal byte_cnt      : integer range 0 to 3 := 0;
    
    constant bram_delay : integer := 2;
    signal bram_delay_cnt : integer range 0 to bram_delay + 1:= 0;
    
    signal imu_get_data_shift : STD_LOGIC_VECTOR(1 downto 0) := (others => '0');
    signal data_send_uart_shift : STD_LOGIC_VECTOR(1 downto 0) := (others => '1');
    
    signal clk_uart        : STD_LOGIC;
    signal clk_uart_bufg   : STD_LOGIC;
    signal data_send_uart  : STD_LOGIC;
    signal data_uart       : STD_LOGIC_VECTOR (7 downto 0) := (others => '0');
    signal new_data_uart   : STD_LOGIC := '0';
    
    -- Speed syncing
    constant clk_div        : natural := natural(ceil(real(base_clk_hz)/real(uart_clk_hz))) + 1;
    signal clk_div_cnt      : natural range 0 to clk_div := 0;
    
    constant send_delay     : natural := 14;
    signal delay_cnt        : natural range 0 to 2**12 - 1 :=  0;
    
    signal dummy_cnt : natural range 0 to 1 := 0;
begin

    uart_clk : clk_divider
    Generic map (   base_freq => 125000000,
                    out_freq  => 16 * uart_clk_hz -- 115200 baud        
                    )
    Port map (  rst => '0',
                clk => clk,
                clk_div => clk_uart
                );

    uart : uart_tx_module
    port map(   rst             => '0',
                clk             => clk_uart,
                sig             => tx_uart,
                data            => data_uart,
                new_data_pulse  => new_data_uart,
                data_send       => data_send_uart
                );

    process(rst, clk)
    begin
        if rst = '1' then
            bram_addr_cnt <= 0;
            imu_get_data_shift <= (others => '0');
            data_uart <= (others => '0');
            new_data_uart <= '0';
            clk_div_cnt <= 0;
            delay_cnt <= 0;
            bram_delay_cnt <= 0;
            en_bram <= '1';
            byte_cnt <= 0;
            
        elsif rising_edge(clk) then
            imu_get_data_shift <= imu_get_data_shift(0) & imu_get_data;
            dummy_cnt <= 0;
            
            case current_state is 
                when START =>
                    if imu_get_data_shift = "10" then
                        current_state <= SEND_START_BYTE;
                        bram_addr_cnt <= 0;
                        bram_delay_cnt <= 0;
                    end if;
                
                when SET_BRAM =>
                    
                    bram_delay_cnt <= bram_delay_cnt + 1;
                    addr_bram <= STD_LOGIC_VECTOR(to_unsigned(bram_addr_cnt, addr_bram'length));
                    
                    if bram_delay_cnt = bram_delay then
                        bram_addr_cnt <= bram_addr_cnt + 1;
                        current_state <= GET_BRAM;
                        bram_delay_cnt <= 0;
                    end if;
                
                when GET_BRAM =>
                    bram_data_reg <= data_bram;
                    current_state <= SEND_BRAM;
                    byte_cnt <= 0;
                
                when SEND_START_BYTE =>
                
                    data_uart <= (others => '0');
                    clk_div_cnt <= 0;
                    delay_cnt <= 0;
                    current_state <= WAIT_SEND_START;
                    new_data_uart <= '1';
                    
                when SEND_END_BYTE =>
                
                    data_uart <= (others => '1');
                    clk_div_cnt <= 0;
                    delay_cnt <= 0;
                    current_state <= WAIT_SEND_END;
                    new_data_uart <= '1';
                
                when SEND_BRAM =>
                
                    if byte_cnt /= 2 then
                        data_uart <= bram_data_reg(7 downto 0);
                        bram_data_reg <= x"00" & bram_data_reg(15 downto 8);
                        
                        clk_div_cnt <= 0;
                        delay_cnt <= 0;
                        
                        current_state <= WAIT_SEND_BRAM;
                        
                        new_data_uart <= '1';
                    else
                        if bram_addr_cnt = bram_len then
                            current_state <= SEND_END_BYTE;
                        else 
                            current_state <= SET_BRAM;
                        end if;
                    end if;
                when WAIT_SEND_BRAM =>
                
                    if delay_cnt = 2 then
                        new_data_uart <= '0';
                    end if;
                
                    cnt_wait(   delay_cnt => delay_cnt,
                                delay => send_delay,
                                clk_div_cnt => clk_div_cnt,
                                clk_div => clk_div,
                                inc_cnt => byte_cnt,
                                current_state => current_state,
                                new_state => SEND_BRAM);
                                
                when WAIT_SEND_START =>
                
                    if delay_cnt = 2 then
                        new_data_uart <= '0';
                    end if;
                
                    cnt_wait(   delay_cnt => delay_cnt,
                                delay => send_delay,
                                clk_div_cnt => clk_div_cnt,
                                clk_div => clk_div,
                                inc_cnt => dummy_cnt,
                                current_state => current_state,
                                new_state => SET_BRAM);
                                
                when WAIT_SEND_END =>
                
                    if delay_cnt = 2 then
                        new_data_uart <= '0';
                    end if;
                
                    cnt_wait(   delay_cnt => delay_cnt,
                                delay => send_delay,
                                clk_div_cnt => clk_div_cnt,
                                clk_div => clk_div,
                                inc_cnt => dummy_cnt,
                                current_state => current_state,
                                new_state => START);                            

                when others =>
                    NULL;
            end case;             
            
        end if;
    end process;

end Behavioral;
