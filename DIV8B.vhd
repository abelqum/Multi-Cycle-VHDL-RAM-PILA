library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity Divisor8b is
port(
    Dividendo : in  std_logic_vector(7 downto 0);
    Divisor   : in  std_logic_vector(7 downto 0);
    
    Cociente : out std_logic_vector(7 downto 0);
    Residuo  : out std_logic_vector(7 downto 0);
    
    Error_DivCero : out std_logic;
    
    OvF : out std_logic;
    ZF  : out std_logic;
    SF  : out std_logic;
    Cout: out std_logic
);
end Divisor8b;

architecture Behavioral of Divisor8b is

    component FAS16b is
    port(
        a, b : in  std_logic_vector(15 downto 0);
        s_r  : in  std_logic;
        s    : out std_logic_vector(15 downto 0);
        OvF, ZF, SF, Cout: out std_logic
    );
    end component;

    signal reg_D : std_logic_vector(15 downto 0);

    type tipo_A_Q_etapas is array (0 to 8) of std_logic_vector(15 downto 0);
    signal A_Q_etapas : tipo_A_Q_etapas;

    type tipo_resta_a is array (0 to 7) of std_logic_vector(15 downto 0);
    signal resta_entrada_a : tipo_resta_a;
    
    type tipo_resta_s is array (0 to 7) of std_logic_vector(15 downto 0);
    signal resta_salida_s : tipo_resta_s;

    -- *** CAMBIO 1: Usar Cout (Carry) en lugar de SF (Sign) ***
    signal resta_bandera_cout : std_logic_vector(7 downto 0);

    signal dummy_of, dummy_zf, dummy_sf : std_logic_vector(7 downto 0);
    
    signal resultado_final_A_Q : std_logic_vector(15 downto 0);
    signal error_interno : std_logic;

begin

    reg_D <= Divisor & "00000000";
    A_Q_etapas(0) <= "00000000" & Dividendo;
    error_interno <= '1' when Divisor = x"00" else '0';

    gen_etapas: for i in 0 to 7 generate
    
        resta_entrada_a(i) <= A_Q_etapas(i)(14 downto 0) & '0';
        
        Restador_Etapa_I: FAS16b port map (
            a    => resta_entrada_a(i),
            b    => reg_D,
            s_r  => '1', -- '1' para RESTAR
            s    => resta_salida_s(i),
            
            -- *** CAMBIO 2: Conectar Cout, no SF ***
            Cout => resta_bandera_cout(i),
            SF   => dummy_sf(i), 
            
            OvF  => dummy_of(i), 
            ZF   => dummy_zf(i)
        );
        
        -- *** CAMBIO 3: Comprobar la bandera Cout, no SF ***
        A_Q_etapas(i+1) <= (resta_salida_s(i)(15 downto 8) & A_Q_etapas(i)(6 downto 0) & '1') when resta_bandera_cout(i) = '1' else
                           resta_entrada_a(i);
        
    end generate;

    resultado_final_A_Q <= (others => '0') when error_interno = '1' else
                             A_Q_etapas(8);
    
    Cociente <= resultado_final_A_Q(7 downto 0);
    Residuo  <= resultado_final_A_Q(15 downto 8);

    -- Lógica de Banderas (basadas en el Cociente)
    ZF <= '1' when resultado_final_A_Q(7 downto 0) = x"00" else '0';
    SF <= resultado_final_A_Q(7);
    OvF <= '0';
    Cout <= '0';
    
    -- *** CAMBIO 4: Asignar la señal de error al puerto de salida ***
    Error_DivCero <= error_interno;

end Behavioral;