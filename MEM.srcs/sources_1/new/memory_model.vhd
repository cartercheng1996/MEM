library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity memory_model is
  port (
    clk     : in  std_logic;
    reset   : in  std_logic;
    --
    addr    : in  std_logic_vector(15 downto 0);
    wr_data : in  std_logic_vector(31 downto 0);
    wr_en   : in  std_logic;
    rd_en   : in  std_logic;
    rd_data : out std_logic_vector(31 downto 0);
    rd_ack  : out std_logic
    );
end entity memory_model;


architecture beh of memory_model is
    
    type ary_mem is array(0 to 255) of std_logic_vector(31 downto 0); -- define an 4 byte address arrary,with 32 bit width 
    signal data_mem : ary_mem; -- Memory-data array declartion
    signal ack_flag: std_logic;
    
    begin
        process (clk) begin
          if rising_edge(clk) then -- active edge clock
            if (reset = '1') then --synchronous active high reset
              -- memory initialisation
              rd_ack <= '0'; -- initialise the ack signal to 0
              ack_flag <= '0';
              data_mem(0) <= X"01234567";
              data_mem(1) <= X"89abcde7";
              data_mem(2) <= X"0a0b0c0d";
              data_mem(3) <= X"10203040";
              data_mem(231) <= X"01234567";  
            elsif (wr_en = '1') then
                data_mem (to_integer (unsigned(addr))) <= wr_data;
            elsif (rd_en = '1') then
                 rd_data<= data_mem (to_integer (unsigned(addr)));
                 ack_flag <= '1'; 
            end if;
            
            -- Next if statement is to ensure ack is asserted one cycle later when rd_data is ready 
            -- This also can be regared as delay of memory behaviour model
            if (ack_flag = '1') then
                rd_ack <= '1';
                ack_flag <= '0';
             else
                rd_ack <= '0';
            end if;
            
          end if;
        end process;
end architecture beh;
