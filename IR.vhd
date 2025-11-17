library IEEE;
use IEEE.STD_LOGIC_1164.ALL;


entity InstReg is
port( 
    EnIR: std_logic;
    clk: std_logic;
    Reset: std_logic;
    Data_in: in std_logic_vector(23 downto 0);
    Data_out: out std_logic_vector(23 downto 0)
);
end InstReg;

architecture Behavioral of InstReg is


begin

    process(Reset,clk)
    begin
    if reset='0' then   
    Data_out<=(others=>'0');
    elsif rising_edge(clk) then
        if EnIR='1' then 
        Data_out<= Data_in;
        
    end if;
end if;
end process;
        
   
end Behavioral;
    
       