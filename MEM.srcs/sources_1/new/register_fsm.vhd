library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity register_fsm is
  port (
    clk          : in  std_logic;
    reset        : in  std_logic;
    --
    data_in      : in  std_logic_vector(7 downto 0);
    data_in_vld  : in  std_logic;
    data_out     : out std_logic_vector(7 downto 0);
    data_out_vld : out std_logic;
    --
    addr         : out std_logic_vector(15 downto 0);
    wr_data      : out std_logic_vector(31 downto 0);
    wr_en        : out std_logic;
    rd_en        : out std_logic;
    rd_data      : in  std_logic_vector(31 downto 0);
    rd_ack       : in  std_logic);
end register_fsm;

architecture rtl of register_fsm is

begin

end rtl;