library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_unsigned.all;

entity PWM is
   generic(N: integer := 8);
   port(
clk         : in std_logic;
datain : in std_logic_vector(N-1 downto 0);
BigReset : in std_logic;
PWMState : in std_logic_vector(1 downto 0);
PWM                     : out std_logic
   );
end PWM;

architecture Behavioral of PWM is

signal counter : std_logic_vector(N-1 downto 0);
signal PWMState_Sig: std_logic_vector(1 downto 0);

begin

process(clk)
begin
if rising_edge(Clk) then
PWMState_Sig <= PWMState;
end if;
end process;

process(clk, PWMState)
begin
if PWMState_Sig /= PWMState then
counter <= (others =>'0');
elsif rising_edge(clk) then  
counter <= counter + '1';
end if;
end process;

PWM <= '0' when ((datain)) < (counter) else '1';
end Behavioral;