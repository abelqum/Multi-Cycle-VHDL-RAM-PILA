library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity binbcd is
    Port (
        clk     : in  std_logic;
        reset   : in  std_logic;
        binario : in  STD_LOGIC_VECTOR (15 downto 0);
        signo   : in  std_logic;
        bcd     : out STD_LOGIC_VECTOR (31 downto 0)
    );
end binbcd;



architecture Behavioral of binbcd is
begin
    process(clk, reset)
        variable temp_int : integer range -32768 to 32767;
        variable abs_value : integer range 0 to 32768;
        variable is_negative : boolean;
    begin
        if reset = '0' then
            bcd <= (others => '0');
        elsif rising_edge(clk) then
            -- Convertir a entero con signo
            temp_int := to_integer(signed(binario));
            
            -- Determinar si es negativo y tomar valor absoluto
            if temp_int < 0 then
                is_negative := true;
                abs_value := -temp_int;  -- Valor absoluto
            else
                is_negative := false;
                abs_value := temp_int;
            end if;
            
         
          -- 4. Extraer los 8 dígitos BCD
            -- (Dígito 7: Decenas de Millón)
            bcd(31 downto 28) <= std_logic_vector(to_unsigned((abs_value / 10000000) mod 10, 4));
            -- (Dígito 6: Unidades de Millón)
            bcd(27 downto 24) <= std_logic_vector(to_unsigned((abs_value / 1000000)  mod 10, 4));
            -- (Dígito 5: Centenas de Mil)
            bcd(23 downto 20) <= std_logic_vector(to_unsigned((abs_value / 100000)   mod 10, 4));
            -- (Dígito 4: Decenas de Mil)
            bcd(19 downto 16) <= std_logic_vector(to_unsigned((abs_value / 10000)    mod 10, 4));
            -- (Dígito 3: Unidades de Mil)
            bcd(15 downto 12) <= std_logic_vector(to_unsigned((abs_value / 1000)     mod 10, 4));
            -- (Dígito 2: Centenas)
            bcd(11 downto 8)  <= std_logic_vector(to_unsigned((abs_value / 100)      mod 10, 4));
            -- (Dígito 1: Decenas)
            bcd(7 downto 4)   <= std_logic_vector(to_unsigned((abs_value / 10)       mod 10, 4));
            -- (Dígito 0: Unidades)
            bcd(3 downto 0)   <= std_logic_vector(to_unsigned( abs_value             mod 10, 4));
            
        end if;
    end process;
end Behavioral;