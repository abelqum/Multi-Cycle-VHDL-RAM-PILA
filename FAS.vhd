Library IEEE;
Use IEEE.std_logic_1164.all;


entity FAS is
port(
     a, b, c_in, x : in std_logic;
            s, c_out : out std_logic

);
end FAS;

architecture Behavioral of FAS is
signal bx: std_logic;
begin

    bx<=b xor x;
    s<=a xor bx xor c_in;
    c_out<= ((a xor bx) and c_in) or (a and bx);
end Behavioral;
    






