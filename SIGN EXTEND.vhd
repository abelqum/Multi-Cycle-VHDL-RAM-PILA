library IEEE;
use IEEE.STD_LOGIC_1164.ALL;


entity SignExtend is
port( 
    Data_in: in std_logic_vector(7 downto 0);
    Data_out: out std_logic_vector(15 downto 0)
);
end SignExtend;

architecture Behavioral of SignExtend is


begin

    Data_out(7 downto 0) <= Data_in;
    Data_out(15 downto 8) <= (others => Data_in(7));

end Behavioral;
    
       