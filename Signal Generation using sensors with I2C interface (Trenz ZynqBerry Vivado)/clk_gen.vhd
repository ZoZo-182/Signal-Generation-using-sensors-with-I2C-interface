LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE IEEE.NUMERIC_STD.ALL;
USE ieee.std_logic_unsigned.all;

entity clk_gen is
  port (
    clk 	: in std_logic;
    reset   	: in std_logic;
    On_off      	: in std_logic;
    Data_in     	: in std_logic_vector(7 downto 0);
    Clock_out   	: buffer std_logic;
    freq            : out integer range 0 to 1500;
    state           : in std_logic_vector(1 downto 0)
  );
end clk_gen;

Architecture behv of clk_gen is
signal cnt_max   : integer range 0 to 50001;
signal off_onprev: std_logic;
signal clk_cnt   : integer range 0 to 50001;
signal clock_outsig 	: std_logic := '0';
--signal datain_freq : integer;
	 
begin
off_onprev <= On_off;
--datain_freq <= ((4 * to_integer(unsigned(Data_in))+ 500));

	process(clk, reset)
	begin
	if reset = '1' then 
      clock_outsig <= '0';
		cnt_max <= 0;
	elsif rising_edge(clk) then
	if off_onprev = On_off and state /= "10" then --On_off = '1'
		cnt_max <= 50_000 - 131 * to_integer(unsigned(Data_in));-- ((4 * to_integer(unsigned(Data_in))+ 500));
		clk_cnt <= clk_cnt + 1;
        if clk_cnt = cnt_max then
		    clock_outsig <= not clock_outsig;  -- Toggle the clock
          clk_cnt <= 0;
        end if;
      else
        clk_cnt <= 0;
		  cnt_max <= 0;
		  clock_outsig <= '0';  -- Ensure clock is low when On_off is '0'
      end if;
    end if;
  end process;
  
  Clock_out <= clock_outsig;
--  freq <= datain_freq;
   
end behv;