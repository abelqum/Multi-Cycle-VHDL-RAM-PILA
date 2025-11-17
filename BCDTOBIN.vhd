library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity bcdbin is
    Port ( 
        clk, reset: in std_logic;
        bcd     : in  STD_LOGIC_VECTOR (31 downto 0);  -- 8 dígitos BCD (32 bits)
        binario : out STD_LOGIC_VECTOR (15 downto 0)   -- 16 bits binario
    );
end bcdbin;

architecture Behavioral of bcdbin is
begin
    process(clk, reset)
        variable digito7, digito6, digito5, digito4 : integer range 0 to 9;
        variable digito3, digito2, digito1, digito0 : integer range 0 to 9;
        variable resultado : integer range 0 to 65535;
        variable temp_result : integer;
    begin
        if reset = '0' then
            binario <= (others => '0');
        elsif rising_edge(clk) then
            -- Extraer los 8 dígitos BCD
            digito7 := to_integer(unsigned(bcd(31 downto 28)));
            digito6 := to_integer(unsigned(bcd(27 downto 24)));
            digito5 := to_integer(unsigned(bcd(23 downto 20)));
            digito4 := to_integer(unsigned(bcd(19 downto 16)));
            digito3 := to_integer(unsigned(bcd(15 downto 12)));
            digito2 := to_integer(unsigned(bcd(11 downto 8)));
            digito1 := to_integer(unsigned(bcd(7 downto 4)));
            digito0 := to_integer(unsigned(bcd(3 downto 0)));
            
            -- Convertir BCD a binario
            temp_result := (digito7 * 10000000) + 
                          (digito6 * 1000000) + 
                          (digito5 * 100000) + 
                          (digito4 * 10000) + 
                          (digito3 * 1000) + 
                          (digito2 * 100) + 
                          (digito1 * 10) + 
                          digito0;
            
            -- Verificar rango (0 a 65535 para 16 bits)
            if temp_result > 65535 then 
                resultado := 0; 
            else
                resultado := temp_result;
            end if;
            
            binario <= std_logic_vector(to_unsigned(resultado, 16));
        end if;
    end process;
end Behavioral;