library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity CMP16b is
port(
    A : in  std_logic_vector(15 downto 0);
    B : in  std_logic_vector(15 downto 0);
    A_es_Mayor : out std_logic;
    A_es_Menor : out std_logic;
    A_es_Igual : out std_logic
);
end CMP16b;

architecture Behavioral of CMP16b is

    component CMP1b is
    port(
        A         : in  std_logic;
        B         : in  std_logic;
        Mayor_in  : in  std_logic;
        Igual_in  : in  std_logic;
        Mayor_out : out std_logic;
        Igual_out : out std_logic
    );
    end component;

    -- Necesitamos 17 bits (0 a 16) para conectar las 16 etapas
    signal cascada_igual : std_logic_vector(16 downto 0);
    signal cascada_mayor : std_logic_vector(16 downto 0);
    
    signal mayor_interno : std_logic;
    signal igual_interno : std_logic;
    signal menor_interno : std_logic;

begin

    -- Inicialización de la cascada (Etapa 16, la más significativa)
    cascada_igual(16) <= '1'; -- Asumimos igualdad al empezar
    cascada_mayor(16) <= '0'; -- Asumimos que A no es mayor que B al empezar

    -- Generador en cascada (Desde el MSB=15 hasta el LSB=0)
    gen_comparadores: for i in 15 downto 0 generate
        CMP_i: CMP1b port map (
            A         => A(i),
            B         => B(i),
            Mayor_in  => cascada_mayor(i+1), -- Se conecta a la salida de la etapa anterior (i+1)
            Igual_in  => cascada_igual(i+1), -- Se conecta a la salida de la etapa anterior (i+1)
            Mayor_out => cascada_mayor(i),   -- La salida va a la siguiente etapa (i)
            Igual_out => cascada_igual(i)    -- La salida va a la siguiente etapa (i)
        );
    end generate;

    -- La salida final se toma del LSB (bit 0) de la cascada
    igual_interno <= cascada_igual(0);
    mayor_interno <= cascada_mayor(0);
    
    -- La bandera "Menor que" se calcula lógicamente
    menor_interno <= not (cascada_igual(0) or cascada_mayor(0));
    
    A_es_Igual <= igual_interno;
    A_es_Mayor <= mayor_interno;
    A_es_Menor <= menor_interno;

end Behavioral;