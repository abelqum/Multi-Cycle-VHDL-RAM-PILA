library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity display is
    Port (
        Datos: in std_logic_vector(31 downto 0);     -- Entrada BCD de 32 bits (8 dígitos)
        clk_27mhz : in  STD_LOGIC;                   -- Reloj de 27 MHz        
        seg       : out STD_LOGIC_VECTOR(0 to 7);    -- Salida de segmentos (a-g)
        an        : out STD_LOGIC_VECTOR(7 downto 0) -- Ánodos 8 (selección de display)
    );
end display;

architecture Behavioral of display is
 
    -- Señales para el divisor de frecuencia
    signal contador : integer := 0;
    signal clk_10khz : STD_LOGIC := '0';

    -- Señales del multiplexor
    signal display_sel : INTEGER := 0;
    signal bcd_actual : STD_LOGIC_VECTOR(3 downto 0) := "0000";
    
    -- Señales para los dígitos BCD
    signal unidades, decenas, centenas, millares,unidades2, decenas2, centenas2, millares2: std_logic_vector(3 downto 0);  

begin

    -- Extraer los 4 dígitos BCD del vector de entrada de 16 bits
    unidades <= Datos(3 downto 0);    -- Dígito unidades (bits 3-0)
    decenas  <= Datos(7 downto 4);    -- Dígito decenas (bits 7-4)
    centenas <= Datos(11 downto 8);   -- Dígito centenas (bits 11-8)
    millares <= Datos(15 downto 12);  -- Dígito millares (bits 15-12)
    unidades2 <= Datos(19 downto 16);    -- Dígito unidades (bits 3-0)
    decenas2  <= Datos(23 downto 20);    -- Dígito decenas (bits 7-4)
    centenas2 <= Datos(27 downto 24);   -- Dígito centenas (bits 11-8)
    millares2 <= Datos(31 downto 28);  -- Dígito millares (bits 15-12)

    -- Divisor de frecuencia: de 27MHz a 10kHz
    process(clk_27mhz)
    begin
        if rising_edge(clk_27mhz) then
            if contador = 1349 then  -- 27MHz / 10kHz = 2700, medio ciclo = 1350-1
                contador <= 0;
                clk_10khz <= not clk_10khz;  -- Genera reloj de 10kHz
            else
                contador <= contador + 1;
            end if;
        end if;
    end process;

    -- Multiplexor de displays (funciona a 10kHz)
    process(clk_10khz)
    begin
        if rising_edge(clk_10khz) then
            display_sel <= (display_sel + 1) mod 8;  -- Cicla entre 0,1,2,3,4,5,6,7
        end if;
    end process;

    -- Selección del dígito actual para mostrar
    process(display_sel, unidades, decenas, centenas, millares)
    begin
        case display_sel is
            when 0 =>
                bcd_actual <= unidades;  -- Muestra unidades
                an <= "11111110";           -- Habilita primer display
            when 1 =>
                bcd_actual <= decenas;   -- Muestra decenas
                an <= "11111101";           -- Habilita segundo display
            when 2 =>
                bcd_actual <= centenas;  -- Muestra centenas
                an <= "11111011";           -- Habilita tercer display
            when 3 =>
                bcd_actual <= millares;  -- Muestra millares
                an <= "11110111";           -- Habilita cuarto display
            when 4 =>
                bcd_actual <= unidades2;  -- Muestra unidades
                an <= "11101111";           -- Habilita quinto display
            when 5 =>
                bcd_actual <= decenas2;   -- Muestra decenas
                an <= "11011111";           -- Habilita sexto display
            when 6 =>
                bcd_actual <= centenas2;  -- Muestra centenas
                an <= "10111111";           -- Habilita septimo display
            when 7 =>
                bcd_actual <= millares2;  -- Muestra millares
                an <= "01111111";           -- Habilita octavo display
            when others =>
                bcd_actual <= "0000";    -- Apagado
                an <= "11111111";           -- Todos los displays apagados
        end case;
    end process;

    -- Conversor BCD a 7 segmentos (cátodo común)
    process(bcd_actual)
    begin
       case bcd_actual is
    -- Dígitos Numéricos (0 - 9)
    when "0000" => seg <= "11111100"; -- 0
    when "0001" => seg <= "01100000"; -- 1
    when "0010" => seg <= "11011010"; -- 2
    when "0011" => seg <= "11110010"; -- 3
    when "0100" => seg <= "01100110"; -- 4
    when "0101" => seg <= "10110110"; -- 5
    when "0110" => seg <= "10111110"; -- 6
    when "0111" => seg <= "11100000"; -- 7
    when "1000" => seg <= "11111110"; -- 8
    when "1001" => seg <= "11110110"; -- 9
    
    -- Dígitos Hexadecimales (A - F)
    when "1010" => seg <= "11101110"; -- A (Mayúscula)
    when "1011" => seg <= "00111110"; -- b (Minúscula)
    when "1100" => seg <= "10011100"; -- C (Mayúscula)
    when "1101" => seg <= "01111010"; -- d (Minúscula)
    when "1110" => seg <= "10011110"; -- E (Mayúscula)
    when "1111" => seg <= "10001110"; -- F (Mayúscula)
    
    when others => seg <= "00000000"; -- Apagado
end case;
    end process;

end Behavioral;