library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity PC is
port(
      Clk: in std_logic;
      Reset: in std_logic;
      D_in: in std_logic_vector(7 downto 0);
      EnPC: in std_logic;
      D_out: out std_logic_vector(7 downto 0)
);
end PC;

architecture Behavioral of PC is
signal pc_temp: std_logic_vector(7 downto 0):="01000110";
begin
pc_temp<=D_in;
process(clk,reset)
begin

    if reset= '0' then
        D_out<= (others=>'0');
    elsif rising_edge(clk) then 
        if enPC='1' then    
            D_out<= D_in;
        end if;
       end if;
end process;


end Behavioral;


