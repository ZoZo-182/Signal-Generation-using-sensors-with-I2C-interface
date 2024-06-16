LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE IEEE.NUMERIC_STD.ALL;
USE ieee.std_logic_unsigned.all;

-- notes: weak pull-up resistor? How in Vivado

entity top_level is
  Port ( clock          : in std_logic:= '0';
		 BTN_0        : in std_logic; 
		 BTN_1        : in std_logic;
		 BTN_2        : in std_logic;
		 I2C_SDA      : inout std_LOGIC;
		 I2C_SCL      : inout std_LOGIC;
		 I2C_SDA_ADC  : inout std_logic;
		 I2C_SCL_ADC  : inout std_logic;
		 led0         : out std_logic;
		 led1         : out std_logic;
		 led2         : out std_logic;
		 led3         : out std_logic;
		 oPwm         : out std_LOGIC);
end top_level;

architecture Behavioral of top_level is

-- components
component I2C_user_logic is							
    Port ( iclk         : in STD_LOGIC;
 --          dataIn       : in STD_LOGIC_VECTOR (15 downto 0);
           oSDA         : inout STD_LOGIC;
           input1       : inout std_logic_vector(127 downto 0);
           input2       : inout std_logic_vector(127 downto 0);
           oSCL         : inout STD_LOGIC);
end component;
------------------------------------------------------------------------------------------------------------------
component I2C_userlogic_ADC is			

    Port ( iclk         : in STD_LOGIC;
           oSDA         : inout STD_LOGIC; -- THE I2C DATA 
           oSCL         : inout STD_LOGIC; 
           controlbyte  : in STD_LOGIC_VECTOR(1 downto 0); -- 00 FOR LDR, 01 FOR TEMP, 10 FOR ANALOG, AND 11 FOR POT (FROM MY STATE MACHINE)
           adc_data_out   : OUT    STD_LOGIC_VECTOR(7 DOWNTO 0)); -- from data_rd				
--    Port ( iclk         : in STD_LOGIC;
--           dataIn       : in STD_LOGIC_VECTOR (15 downto 0);
--           oSDA         : inout STD_LOGIC;
--           data_rd      : OUT    STD_LOGIC_VECTOR(7 DOWNTO 0);
--           oSCL         : inout STD_LOGIC);
end component;
------------------------------------------------------------------------------------------------------------------
component Reset_Delay IS
	PORT (
 		SIGNAL iCLK : IN std_logic;
 		SIGNAL oRESET : OUT std_logic
	);
end component;
------------------------------------------------------------------------------------------------------------------
component PWM is
   generic(N: integer := 8);
   port(
clk         : in std_logic;
datain      : in std_logic_vector(N-1 downto 0);
BigReset    : in std_logic;
PWMState    : in std_logic_vector(1 downto 0);
PWM         : out std_logic
   );
end component;
------------------------------------------------------------------------------------------------------------------
component clk_gen is
  port (
    clk 	        : in std_logic;
    reset   	    : in std_logic;
    On_off      	: in std_logic;
    Data_in     	: in std_logic_vector(7 downto 0) := X"4D";
    Clock_out   	: buffer std_logic;
    freq            : out integer range 0 to 1500;
    state           : in std_logic_vector(1 downto 0)
  );
end component;
------------------------------------------------------------------------------------------------------------------
component btn_debounce_toggle is
GENERIC (
	CONSTANT CNTR_MAX : std_logic_vector(15 downto 0) := X"FFFF");  
    Port ( BTN_I 	: in  STD_LOGIC;
           CLK 		: in  STD_LOGIC;
           BTN_O 	: out  STD_LOGIC;
           TOGGLE_O : out  STD_LOGIC;
		   PULSE_O  : out STD_LOGIC);
end component;
------------------------------------------------------------------------------------------------------------------
component statemachine
    Port ( clk : in STD_LOGIC;
           reset : in STD_LOGIC;
           btn_pulse : in STD_LOGIC;
           state_out : out STD_LOGIC_VECTOR(1 downto 0));
--			  led0         : out std_logic;
--		     led1         : out std_logic;
--		     led2         : out std_logic;
--		     led3         : out std_logic
end component;
------------------------------------------------------------------------------------------------------------------

--signals
signal univreset: std_logic;
signal reset_d: std_logic;
signal reset_btn : std_logic;

signal sm_btn_pulse : std_logic; 
signal clkgen_btn_tg: std_logic; 
signal clkgen_btn_tgprev: std_logic; 

signal state : std_logic_vector(1 downto 0);

signal data2pwmclkgen : std_logic_vector(7 downto 0);
--signal data2clkgen : std_logic_vector(7 downto 0);

signal clk_out: std_logic;
signal freqdis: integer range 0 to 1500;

signal line1disLCD: std_logic_vector(127 downto 0);
signal line2disLCD: std_logic_vector(127 downto 0);

--signal datainI2c: std_logic_vector(15 downto 0);

--signal controlbytesig   : std_logic_vector(1 downto 0);

begin
--processes & signal assignments
univreset <= reset_btn or reset_d;
--datainI2c <= "00000000" & data2pwmclkgen;
--state map:
--"00" LDR
--"01" TEMP
--"10" ANALOG
--"11" POT


-- Data in I2C Logic ADC: Based on states
--process(clock, univreset, state) 
--begin 
--
--    if univreset = '1' then 
--        datainI2c <= AIN2;
--        
--        elsif rising_edge(clock) then 
--    case state is 
--        when "00" => data2clkgen <= data2pwmclkgen; 
--        when "01" => data2clkgen <= data2pwmclkgen; 
--        when "10" => data2clkgen <=  ; 
--        when "11" => data2clkgen <= data2pwmclkgen; 
--    end case;
--end if;
--end process;

-- Data in I2C Logic LCD: Based on states
process(clock, univreset, state) 
begin 

    if univreset = '1' then 
        line1disLCD <= X"20202020202020202020202020202020"; 
        
        elsif rising_edge(clock) then 
    case state is 
        when "10" => line1disLCD <= X"416E616C6F6720202020202020202020"; 
        when "00" => line1disLCD <= X"4C445220202020202020202020202020"; 
        when "01" => line1disLCD <= X"54454D50202020202020202020202020"; 
        when "11" => line1disLCD <= X"504F5420202020202020202020202020";
		  when others => line1disLCD <= X"20202020202020202020202020202020"; 
    end case;
end if;
end process;


-- Data in I2C Logic LCD: Based on states
process(clock, univreset, state) 
begin 
  
    if univreset = '1' then 
        line2disLCD <= X"20202020202020202020202020202020";
        clkgen_btn_tgprev <= clkgen_btn_tg;
		  
        elsif rising_edge(clock) then 
		  if clkgen_btn_tgprev = clkgen_btn_tg then
    case state is 
        when "10" => line2disLCD <= X"20202020202020202020202020202020"; -- analog; 
        when "00" => line2disLCD <= X"436C6F636B204F757470757420202020"; -- LDR; 
        when "01" => line2disLCD <= X"436C6F636B204F757470757420202020"; -- TEMP; 
        when "11" => line2disLCD <= X"436C6F636B204F757470757420202020"; -- POT stays 
		  when others => line2disLCD <= X"20202020202020202020202020202020";
    end case;
		else line2disLCD <= X"20202020202020202020202020202020";
	 end if;
end if;


end process;

-- Led on: Based on states
process(clock, univreset, state) 
begin 

    if univreset = '1' then 
        led0 <= '0';
        led1 <= '0';
        led2 <= '0';
        led3 <= '0';
        
        elsif rising_edge(clock) then 
    case state is 
        when "10" => led0 <= '1'; led1 <= '0'; led2 <= '0'; led3 <= '0';
        when "00" => led0 <= '0'; led1 <= '1'; led2 <= '0'; led3 <= '0'; -- 
        when "01" => led0 <= '0'; led1 <= '0'; led2 <= '1'; led3 <= '0'; 
        when "11" => led0 <= '0'; led1 <= '0'; led2 <= '0'; led3 <= '1';
		  when others => led0 <= '1'; led1 <= '1'; led2 <= '1'; led3 <= '1';
    end case;
end if;
end process;

--instantiations
inst_I2C_user_logic: I2C_user_logic 
    Port Map( iclk      => clock,
   --        dataIn       => datainI2c,
           oSDA         => I2C_SDA,
           input1       => line1disLCD,
           input2       => line2disLCD,
           oSCL         => I2C_SCL
);
------------------------------------------------------------------------------------------------------------------
inst_I2C_userlogic_ADC: I2C_userlogic_ADC 					
    Port Map( iclk      => clock,
           controlbyte  => state,
           oSDA         => I2C_SDA_ADC,
           adc_data_out      => data2pwmclkgen, -- 
           oSCL         => I2C_SCL_ADC
     );
------------------------------------------------------------------------------------------------------------------
inst_Reset_Delay: Reset_Delay
	PORT Map(
 		iCLK   => clock,
 		oRESET => reset_d
	);
------------------------------------------------------------------------------------------------------------------
inst_PWM: PWM 
   port map(
        clk         => clock,
        datain      => data2pwmclkgen,
        BigReset    => univreset,
        PWMState    => state,
        PWM         => oPwm
   );
------------------------------------------------------------------------------------------------------------------
inst_clk_gen: clk_gen 
  port map(
    clk 	        => clock,
    reset   	    => univreset,
    On_off      	=> clkgen_btn_tg,
    Data_in     	=> data2pwmclkgen,
    Clock_out   	=> clk_out,
    freq            => freqdis, -- get rid of 
    state           => state
  );
------------------------------------------------------------------------------------------------------------------
inst_BTN_0: btn_debounce_toggle
 Port Map( BTN_I 	=> BTN_0,
           CLK 		=> clock,
           BTN_O 	=> reset_btn,
           TOGGLE_O => open, 
		   PULSE_O  => open   
    );
------------------------------------------------------------------------------------------------------------------
inst_BTN_1: btn_debounce_toggle
 Port Map( BTN_I 	=> BTN_1,
           CLK 		=> clock,
           BTN_O 	=> open,
           TOGGLE_O => open,
		   PULSE_O  => sm_btn_pulse
    );
------------------------------------------------------------------------------------------------------------------
inst_BTN_2: btn_debounce_toggle 
 Port Map( BTN_I 	=> BTN_2,
           CLK 		=> clock,
           BTN_O 	=> open,
           TOGGLE_O => clkgen_btn_tg,
		   PULSE_O  => open
    );
------------------------------------------------------------------------------------------------------------------
inst_statemachine: statemachine
Port Map ( clk 	        => clock,
           reset 	    => univreset,
           btn_pulse 	=> sm_btn_pulse,
           state_out 	=> state
--			  led0     => led0,
--			  led1     => led1,
--		     led2     => led2,
--		     led3     => led3
    );
------------------------------------------------------------------------------------------------------------------

end Behavioral;
