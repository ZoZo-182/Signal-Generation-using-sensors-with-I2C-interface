library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity statemachine is
    Port ( clk : in STD_LOGIC;
           reset : in STD_LOGIC;
           btn_pulse : in STD_LOGIC; -- BTN1
           state_out : out STD_LOGIC_VECTOR(1 downto 0));
--			  led0         : out std_logic;
--			  led1         : out std_logic;
--			  led2         : out std_logic;
--		     led3         : out std_logic);
end statemachine;

architecture Behavioral of statemachine is
    type StateType is (CHANNEL0, CHANNEL1, CHANNEL2, CHANNEL3); -- 00 FOR LDR, 01 FOR TEMP, 10 FOR ANALOG, AND 11 FOR POT
    signal current_state, next_state : StateType;
	 signal state_value : STD_LOGIC_VECTOR(1 downto 0); 
    
begin
    process(clk, reset, btn_pulse)
    begin
        if reset = '1' then
            current_state <= CHANNEL0;
        elsif rising_edge(clk) then
            case current_state is
            --    when INIT =>
             --       next_state <= CHANNEL0; -- Transition to ANALOG after one clock cycle
                --    state_out <= "00";
                    
                when CHANNEL0 =>
                    if btn_pulse = '1' then
                        current_state <= CHANNEL1;
					--			led0 <= '0'; led1 <= '0'; led2 <= '1'; led3 <= '0';
                     --   state_out <= "01";
                    else
                        current_state <= CHANNEL0;
						--		led0 <= '0'; led1 <= '1'; led2 <= '0'; led3 <= '0';
                    end if;
                    
                when CHANNEL1 =>
                    if btn_pulse = '1' then
                        current_state <= CHANNEL2;
						--		led0 <= '1'; led1 <= '0'; led2 <= '0'; led3 <= '0';
                 --       state_out <= "10";
                    else
                        current_state <= CHANNEL1;
					--			led0 <= '0'; led1 <= '0'; led2 <= '1'; led3 <= '0';
                    end if;
                    
                when CHANNEL2 =>
                    if btn_pulse = '1' then
                        current_state <= CHANNEL3;
						--		led0 <= '0'; led1 <= '0'; led2 <= '0'; led3 <= '1';
                    --    state_out <= "11";
                    else
                        current_state <= CHANNEL2;
						--		led0 <= '1'; led1 <= '0'; led2 <= '0'; led3 <= '0';
                    end if;
                    
               when CHANNEL3 =>
                    if btn_pulse = '1' then
                        current_state <= CHANNEL0;
						--		led0 <= '0'; led1 <= '1'; led2 <= '0'; led3 <= '0';
                     --   state_out <= "00";
                    else
                        current_state <= CHANNEL3;
						--		led0 <= '0'; led1 <= '0'; led2 <= '0'; led3 <= '1';
                    end if;  
            end case;
        end if;
    end process;

	 
	 with current_state select
	 
	     state_value <= "00" when CHANNEL0, 

                   "01" when CHANNEL1, 

                   "10" when CHANNEL2, 

                   "11" when CHANNEL3,  

                   "00" when others;  -- Default value for unknown states 
 

    state_out <= state_value;
	 
	 
 end Behavioral;
 
