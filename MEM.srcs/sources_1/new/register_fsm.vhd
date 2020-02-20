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

	-- Command constants decleration and definition
	constant E7 : std_logic_vector (7 downto 0) := X"e7";
	constant READ : std_logic_vector (7 downto 0) := X"13";
	constant WRITE : std_logic_vector (7 downto 0) := X"23";
	constant READ_DATA : std_logic_vector (7 downto 0) := X"03";
	constant BREAK : std_logic_vector (7 downto 0) := X"55";
	
	type my_states is (IDLE,CMDIn_state,AddrIn_state, AddrIn_stateE7, DataIn_state, DataIn_stateE7);
	signal curr_state, next_state : my_states;
	
    signal dataReaded_buff : std_logic_vector (31 downto 0);
	signal addrReaded_buff : std_logic_vector (31 downto 0);
	signal writeFlag: std_logic;
	signal addrCounter: integer := 0;
	signal dataCounter: integer := 0;
	
		
begin
 
    -- FSM state-registers process
    process(clk, reset) begin
 	  	 if (reset = '1') then
 	  		 curr_state <= IDLE;
	   	 elsif (rising_edge(clk)) then
	   		 curr_state <= next_state;
	   	 end if;
	end process;
	    
    -- Next state process
    process (curr_state, data_in, clk) begin
        case curr_state is
            when IDLE => 
                writeFlag <= '0';
                if  (data_in_vld = '1')  then
                        if (data_in = E7) then
                            next_state <= CMDIn_state;
                        else
                             next_state <= IDLE;
                    end if;
                else 
                    next_state <= IDLE;
                end if;
            when CMDIn_state =>
                case data_in is
                    when E7 =>
                         next_state <= CMDIn_state;
                    when READ =>
                        next_state <= AddrIn_state;
                        addrCounter <= 0;
                        writeFlag <= '0';         
                    when WRITE =>
                        next_state <= AddrIn_state;
                        addrCounter <= 0;    
                        dataCounter <= 0;
                        writeFlag <= '1';  
                    when BREAK =>
                        next_state <= IDLE;
                    when others =>
                        next_state <= IDLE;
                end case;
                
            when AddrIn_state =>    
                if (addrCounter < 4 ) then
                    addrReaded_buff ((31-addrCounter*8) downto (24-addrCounter*8)) <= data_in;
                end if;
                
                if (rising_edge(clk)) then 
                    addrCounter <= addrCounter + 1;
                end if;
                       
                if (data_in = E7) then
                    next_state <= AddrIn_stateE7;
                elsif (addrCounter = 3) then
                    if (writeFlag = '0') then
                        next_state <= IDLE;
                    else 
                        next_state <= DataIn_state;
                    end if;
                else
                    next_state <= AddrIn_state;
                end if;
                
            when AddrIn_stateE7 =>
                if (data_in = E7) then
                    if (addrCounter = 3) then
                        if (addrCounter < 4 ) then
                            addrReaded_buff ((31-addrCounter*8) downto (24-addrCounter*8)) <= data_in;
                        end if;                        
                        if (writeFlag = '0') then
                            next_state <= IDLE;
                        else 
                            next_state <= DataIn_state;
                        end if;
                    else next_state <= AddrIn_state;
                    end if;
                else
                    next_state <= CMDIn_state;
                end if;                   
            when DataIn_state =>
                if (dataCounter < 4 )then
                    datareaded_buff ((31-dataCounter*8) downto (24-dataCounter*8)) <= data_in;
                end if;
                
                if (rising_edge(clk)) then 
                    dataCounter <= dataCounter + 1;
                end if;
                       
                if (data_in = E7) then
                    next_state <= DataIn_stateE7;
                elsif (dataCounter = 3) then
                    next_state <= IDLE;
                else
                    next_state <= DataIn_state;
                end if;
            when DataIn_stateE7 =>
                if (data_in = E7) then
                    if (dataCounter = 3) then
                        if (dataCounter < 4 )then
                            datareaded_buff ((31-dataCounter*8) downto (24-dataCounter*8)) <= data_in;
                        end if;                    
                        next_state <= IDLE;
                    else next_state <= dataIn_state;
                    end if;
                else
                    next_state <= CMDIn_state;
                end if;                          
            when others =>
                next_state <= IDLE;
        end case;
    end process;
	    
	    
	    
end rtl;