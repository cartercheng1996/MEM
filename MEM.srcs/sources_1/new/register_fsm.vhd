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
	
	type my_states is (IDLE,CMDIn_state,AddrIn_state, AddrIn_stateE7, DataIn_state, DataIn_stateE7, MEM_read, MEM_sample,Read_out,Break_state,
	                       Read_out_CMD, Read_out_DATA, Read_out_DATA_E7,DataWrite_state);
	signal curr_state, next_state : my_states;
	
    signal dataReaded_buff : std_logic_vector (31 downto 0) := X"00000000" ;
	signal addrReaded_buff : std_logic_vector (31 downto 0) := X"00000000" ;
    signal memRespondData : std_logic_vector (31 downto 0) := X"00000000" ;
    signal tmp : std_logic_vector (7 downto 0) := X"00" ;
	signal writeFlag: std_logic := '0' ;
	signal addrCounter: integer := 0;
	signal dataCounter: integer := 0;
	signal sampleCounter: integer := 0;
	signal ReadOutCounter: integer := 0;	
begin
 
    -- FSM state-registers process
    process(clk, reset) begin
	   	 if (rising_edge(clk)) then
	   	   if (reset = '1') then
 	  		 curr_state <= IDLE;
 	  	   else
	   		 curr_state <= next_state;
	   		end if;
	   	 end if;
	end process;
	    
    -- Next state process
    process (curr_state, data_in, clk,ReadOutCounter) begin
        case curr_state is
            when IDLE => 
                rd_en <='0';
                wr_en <='0';
                addr <= X"0000";
                wr_data <= X"00000000";
                data_out <= X"00";
                data_out_vld  <= '0';
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
                wr_en <= '0';
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
                
                if (rising_edge(clk) and data_in/=E7) then 
                    addrCounter <= addrCounter + 1;
                end if;
                       
                if (data_in = E7) then
                    next_state <= AddrIn_stateE7;
                elsif (addrCounter = 3) then
                    if (writeFlag = '0') then
                        next_state <= MEM_read;
                    else 
                        next_state <= DataIn_state;
                    end if;
                else
                    next_state <= AddrIn_state;
                end if;
                
            when AddrIn_stateE7 =>
                
                if (rising_edge(clk) and data_in=E7) then 
                    addrCounter <= addrCounter + 1;
                end if;
                            
                if (data_in = E7) then
                    if (addrCounter = 3) then
                        if (addrCounter < 4 ) then
                            addrReaded_buff ((31-addrCounter*8) downto (24-addrCounter*8)) <= data_in;
                        end if;                        
                        if (writeFlag = '0') then
                            next_state <= MEM_read;
                        else 
                            next_state <= DataIn_state;
                        end if;
                    else 
                        next_state <= AddrIn_state;
                    end if;
                else
                    if (data_in = BREAK) then
                        next_state <= IDLE;
                     else 
                        next_state <= IDLE;
                    end if;
                end if;   
            
            when MEM_read =>
                addr <= addrReaded_buff (15 downto 0);
                rd_en <='1';
                next_state <= MEM_sample;
                SampleCounter <= 0;
            when MEM_sample =>
                rd_en <='0';
                if (rising_edge(clk)) then 
                    SampleCounter <= SampleCounter + 1;
                end if;
                
                if (rd_ack = '1') then
                    memRespondData <= rd_data;
                    next_state <= Read_out;
                elsif (SampleCounter = 3) then
                    next_state <= Break_state;
                else
                    next_state <= MEM_sample;                
                end if;
                
            when Read_out =>
                data_out_vld <= '1';
                data_out <= X"e7";
                next_state <= Read_out_CMD;
            
            when Read_out_CMD =>    
                data_out <= READ_DATA;
                next_state <= Read_out_DATA;
                ReadOutCounter <= 0;
            
            when Read_out_DATA =>
                if (rising_edge(clk)) then 
                    ReadOutCounter <= ReadOutCounter + 1;  
                end if ;
                
                if (ReadOutCounter <4) then
                    if (memRespondData ((31-ReadOutCounter*8) downto (24-ReadOutCounter*8)) = E7) then
                        next_state <= Read_out_DATA_E7;
                    elsif (ReadOutCounter >= 3) then
                        next_state <= IDLE;
                    else
                        next_state <= Read_out_DATA;
                    end if;
                    data_out<= memRespondData ((31-ReadOutCounter*8) downto (24-ReadOutCounter*8));
                end if; 

             when Read_out_DATA_E7 => 
                data_out <=E7;
                if (ReadOutCounter >= 3) then
                    next_state <= IDLE;
                else
                    next_state <= Read_out_DATA;
                end if;                    
                          
            when Break_state =>
                data_out_vld  <= '1';
                data_out <= BREAK;
                next_state <= IDLE;
                       
            when DataIn_state =>
                if (dataCounter < 4 )then
                    datareaded_buff ((31-dataCounter*8) downto (24-dataCounter*8)) <= data_in;
                end if;
                
                if (rising_edge(clk) and data_in/=E7) then 
                    dataCounter <= dataCounter + 1;
                end if;
                       
                if (data_in = E7) then
                    next_state <= DataIn_stateE7;
                elsif (dataCounter >= 3) then
                    next_state <= DataWrite_state;
                else
                    next_state <= DataIn_state;
                end if;
                
            when DataIn_stateE7 =>
                if (rising_edge(clk) and data_in=E7) then 
                    dataCounter <= dataCounter + 1;
                end if;            
                if (data_in = E7) then
                    if (dataCounter = 3) then
                        if (dataCounter < 4 )then
                            datareaded_buff ((31-dataCounter*8) downto (24-dataCounter*8)) <= data_in;
                        end if;                    
                        next_state <= DataWrite_state;
                    else next_state <= dataIn_state;
                    end if;
                else
                    if (data_in = BREAK) then
                        next_state <= IDLE;
                    else 
                        next_state <= IDLE;
                    end if;  
                end if;
                
            when DataWrite_state =>
                addr <= addrReaded_buff (15 downto 0);
                wr_en <= '1';
                wr_data <= datareaded_buff;
                if (data_in = E7) then
                    next_state <= CMDIn_state;
                else
                    next_state <= IDLE;
                end if; 
            when others =>
                next_state <= IDLE;
        end case;
    end process;
	    
	    
	    
end rtl;