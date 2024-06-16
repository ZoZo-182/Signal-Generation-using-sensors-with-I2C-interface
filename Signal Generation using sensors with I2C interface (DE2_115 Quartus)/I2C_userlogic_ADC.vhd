library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.std_logic_unsigned.all;

entity I2C_userlogic_ADC is							-- Modified from SPI usr logic from last year
    Port ( iclk         : in STD_LOGIC;
           oSDA         : inout STD_LOGIC; -- THE I2C DATA 
           oSCL         : inout STD_LOGIC; 
           controlbyte  : in STD_LOGIC_VECTOR(1 downto 0); -- 00 FOR LDR, 01 FOR TEMP, 10 FOR ANALOG, AND 11 FOR POT (FROM MY STATE MACHINE)
           adc_data_out   : OUT    STD_LOGIC_VECTOR(7 DOWNTO 0)); -- from data_rd
end I2C_userlogic_ADC;

architecture Behavioral of I2C_userlogic_ADC is

------------------------------------------------------------------------------------------------------------------
component i2c_master IS
  GENERIC(
    input_clk : INTEGER := 50_000_000; --input clock speed from user logic in Hz
    bus_clk   : INTEGER := 400_000);  --speed the i2c bus (scl) will run at in Hz (7-Segment can run from 100khz(slow mode) to 400khz(high speed mode))
  PORT(
    clk       : IN     STD_LOGIC;                    --system clock
    reset_n   : IN     STD_LOGIC;                    --active low reset
    ena       : IN     STD_LOGIC;                    --latch in command
    addr      : IN     STD_LOGIC_VECTOR(6 DOWNTO 0); --address of target slave
    rw        : IN     STD_LOGIC;                    --'0' is write, '1' is read
    data_wr   : IN     STD_LOGIC_VECTOR(7 DOWNTO 0); --data to write to slave
    busy      : OUT    STD_LOGIC;                    --indicates transaction in progress
    data_rd   : OUT    STD_LOGIC_VECTOR(7 DOWNTO 0); --data read from slave
    ack_error : BUFFER STD_LOGIC;                    --flag if improper acknowledge from slave
    sda       : INOUT  STD_LOGIC;                    --serial data output of i2c bus
    scl       : INOUT  STD_LOGIC);                   --serial clock output of i2c bus
END component i2c_master;
------------------------------------------------------------------------------------------------------------------
signal regBusy,sigBusy,reset,enable,rw_sig : std_logic;

signal  dataIn   : STD_LOGIC_VECTOR (7 downto 0);  -- should be 8-bit control data

signal wData : std_logic_vector(7 downto 0);
signal cntrlbyte_prev : std_logic_vector(1 downto 0);

signal dataOut : std_logic_vector(7 downto 0);

signal byteSel : std_logic_vector(1 downto 0);

signal rddata  : std_logic_vector(7 downto 0);
signal wrdata  : std_logic_vector(7 downto 0);

type state_type is (start,write,read, stop);

signal State : state_type := start;

signal address : std_logic_vector(6 downto 0);

signal Counter : integer := 16383;		--187497 orig 

begin
------------------------------------------------------------------------------------------------------------------
INST_I2C_master: I2C_master
	Generic map(input_clk => 50_000_000,bus_clk=> 100000) --9600 orig
	port map (
		clk=>iclk,
		reset_n=>reset,
		ena=>enable,
		addr=>address,						-- For implementation of 2 or more components, link address to a mux to select which component.
		rw=>rw_sig,
		data_wr=>dataOut, -- was dataout? (instructions)
		busy=>sigBusy,
		data_rd=>adc_data_out,-- analog_in (output data)
		ack_error=>open,				
		sda=>oSDA,
		scl=>oSCL
		);
	
------------------------------------------------------------------------------------------------------------------


StateChange: process (iClk)
begin
	if rising_edge(iClk) then
		case State is
		
			when start =>
				if Counter /= 0 then
					Counter<=Counter-1;
					reset<='0';
			--		rddata <= "00000000";
					State<=start;
					enable<='0';
				else
					reset<='1';					-- Sent to I2C master to start ready transaction
				--	enable<='1';				-- Sent to I2C master to transition to start state.
					
					address <="1001000";		-- Hardcoded to X"48", Default address
					rw_sig<='0';				-- Only writing in this project
					State <= write;
				end if;
			
			when write=>
			enable<='1';
			regBusy <= sigBusy; --wait until the busy = 0

			
			if regBusy /= sigBusy and sigBusy = '0' then
			rw_sig<='1';				-- send to read
			State<=read;
			end if;
			
			when read=>
			enable<='1';
			regBusy <= sigBusy;			
               
 
                if regBusy /= sigBusy and sigBusy = '0' then
						cntrlbyte_prev <= controlbyte;
					
					 
					 if cntrlbyte_prev /= controlbyte then
						 counter <= 16383;
						 enable<='0';
                   state <= start;
						 end if;
					 
					 else
						state <= read;
						rw_sig <= '1';
                end if;
	
				when stop=>
					enable<='0';
				if cntrlbyte_prev /= controlbyte then -- CURRENTLY TESTING NO STOP MODE TO SEE IF WORKS
					State<=start;
				else
					State<=stop;
end if;
end case;
end if;
end process;
------------------------------------------------------------------------------------------------------------------

process(controlbyte)
begin
    case controlbyte is
		  when "00" => dataOut <= "00000000";  -- LDR
        when "01" => dataOut <= "00000001"; 	-- TEMP
		  when "10" => dataOut <= "00000010";  -- ANALOG
        when "11" => dataOut <= "00000011"; -- POT
	 end case;
end process;
		  
------------------------------------------------------------------------------------------------------------------
end Behavioral;
