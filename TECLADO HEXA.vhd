library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity teclado is
    Port (
        clk_27mhz : in  STD_LOGIC;
        reset     : in  STD_LOGIC;
        fila      : in  std_logic_vector(3 downto 0);
        columnas  : out std_logic_vector(3 downto 0);
        numero    : out std_logic_vector(31 downto 0)  -- 8 dígitos hexadecimales (32 bits)
    );
end teclado;

architecture Behavioral of teclado is

    signal dig7, dig6, dig5, dig4, dig3, dig2, dig1, dig0 : STD_LOGIC_VECTOR(3 downto 0) := "0000"; -- Inicializar en "0000"
    signal clk_tec: std_logic := '0';
    signal contador_1khz: integer := 0;
    signal tec: std_logic_vector(3 downto 0) := "1000";
    signal fila_leida: std_logic_vector(3 downto 0);
    signal digito: std_logic_vector(3 downto 0) := "0000";
    signal tecla_presionada, tecla_presionada_prev : std_logic := '0';
    signal digito_valido : std_logic := '0';
    signal anti_rebote_counter : integer := 0;
    constant DEBOUNCE_TIME : integer := 13500000;

    signal res_db : STD_LOGIC := '0';
    signal debounce_counter : integer := 0;
    signal tecla_valida_pulsada : std_logic := '0';
    
begin

    -- Número de salida (8 dígitos hexadecimales)
    numero <= dig7 & dig6 & dig5 & dig4 & dig3 & dig2 & dig1 & dig0;

    fila_leida <= fila;

    process(clk_tec)
    begin
        if rising_edge(clk_tec) then
            tecla_presionada <= '0';
            
           case tec & fila_leida is
    -- Primera columna (tec = "1000")
    when "10000001" => digito <= "0001"; tecla_presionada <= '1'; -- 1
    when "10000010" => digito <= "0100"; tecla_presionada <= '1'; -- 4
    when "10000100" => digito <= "0111"; tecla_presionada <= '1'; -- 7
    when "10001000" => digito <= "1111"; tecla_presionada <= '1'; -- F
    
    -- Segunda columna (tec = "0100")
    when "01000001" => digito <= "0010"; tecla_presionada <= '1'; -- 2
    when "01000010" => digito <= "0101"; tecla_presionada <= '1'; -- 5
    when "01000100" => digito <= "1000"; tecla_presionada <= '1'; -- 8
    when "01001000" => digito <= "0000"; tecla_presionada <= '1'; -- 0
    
    -- Tercera columna (tec = "0010")
    when "00100001" => digito <= "0011"; tecla_presionada <= '1'; -- 3
    when "00100010" => digito <= "0110"; tecla_presionada <= '1'; -- 6
    when "00100100" => digito <= "1001"; tecla_presionada <= '1'; -- 9
    when "00101000" => digito <= "1110"; tecla_presionada <= '1'; -- E
    
    -- Cuarta columna (tec = "0001")
    when "00010001" => digito <= "1010"; tecla_presionada <= '1'; -- A
    when "00010010" => digito <= "1011"; tecla_presionada <= '1'; -- B
    when "00010100" => digito <= "1100"; tecla_presionada <= '1'; -- C
    when "00011000" => digito <= "1101"; tecla_presionada <= '1'; -- D
    
    when others => null;
end case;
            
        end if;
    end process;
    
    -- Proceso principal para el desplazamiento de dígitos
    process(clk_27mhz, res_db)
    begin
        if res_db = '0' then
            -- Reset: poner todos los dígitos en "0000" (apagado)
            dig7 <= "0000";
            dig6 <= "0000";
            dig5 <= "0000";
            dig4 <= "0000";
            dig3 <= "0000";
            dig2 <= "0000";
            dig1 <= "0000";
            dig0 <= "0000";
            
        elsif rising_edge(clk_27mhz) then
            tecla_presionada_prev <= tecla_presionada;
            digito_valido <= '0';
            
            -- Detección de flanco positivo en tecla presionada
            if tecla_presionada = '1' and tecla_presionada_prev = '0' then
                if anti_rebote_counter = 0 then
                    tecla_valida_pulsada <= '1';
                    anti_rebote_counter <= DEBOUNCE_TIME;
                end if;
            end if;
            
            -- Cuando termina el anti-rebote, realizar el desplazamiento
            if tecla_valida_pulsada = '1' and anti_rebote_counter = DEBOUNCE_TIME - 1 then
                digito_valido <= '1';
                tecla_valida_pulsada <= '0';
                
                -- Realizar desplazamiento a la izquierda de 4 bits
                dig7 <= dig6;
                dig6 <= dig5;
                dig5 <= dig4;
                dig4 <= dig3;
                dig3 <= dig2;
                dig2 <= dig1;
                dig1 <= dig0;
                dig0 <= digito;  -- Nuevo dígito en la posición menos significativa
            end if;
            
            -- Contador anti-rebote
            if anti_rebote_counter > 0 then
                anti_rebote_counter <= anti_rebote_counter - 1;
            end if;
        end if;
    end process;

    -- Proceso para el debounce del reset
    process(clk_27mhz)
    begin
        if rising_edge(clk_27mhz) then
            if debounce_counter = 4050000 then
                debounce_counter <= 0;
                res_db <= reset;
            else
                debounce_counter <= debounce_counter + 1;
            end if;
        end if;
    end process;

    -- Generación de reloj para el teclado (1kHz)
    process(clk_27mhz)
    begin
        if rising_edge(clk_27mhz) then
            if contador_1khz = 13500 then
                contador_1khz <= 0;
                clk_tec <= not clk_tec;
            else
                contador_1khz <= contador_1khz + 1;
            end if;
        end if;
    end process;

    -- Rotación de columnas para el escaneo del teclado
    process(clk_tec)
    begin
        if rising_edge(clk_tec) then
            tec <= tec(2 downto 0) & tec(3);
        end if;
    end process;

    columnas <= tec;

end Behavioral;