library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity CMP1b is
port(
    A         : in  std_logic;
    B         : in  std_logic;
    Mayor_in  : in  std_logic; 
    Igual_in  : in  std_logic; 
    Mayor_out : out std_logic;
    Igual_out : out std_logic
);
end CMP1b;

architecture Behavioral of CMP1b is
    signal mayor_loc : std_logic;
    signal igual_loc : std_logic;
begin
    mayor_loc <= A and (not B); 
    igual_loc <= A xnor B;     
    Mayor_out <= Mayor_in or (Igual_in and mayor_loc);
    Igual_out <= Igual_in and igual_loc;

end Behavioral;