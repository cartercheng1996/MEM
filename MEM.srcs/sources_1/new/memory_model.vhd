library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

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

begin

end architecture beh;