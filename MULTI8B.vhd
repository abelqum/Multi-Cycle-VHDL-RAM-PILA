library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity Multiplicador8b is
port(
    Multiplicando  : in  std_logic_vector(7 downto 0); 
    Multiplicador  : in  std_logic_vector(7 downto 0); 
    Producto_Final : out std_logic_vector(15 downto 0);
    OvF : out std_logic;
    ZF  : out std_logic;
    SF  : out std_logic;
    Cout: out std_logic
);
end Multiplicador8b;

architecture Behavioral of Multiplicador8b is

    component FAS16b is
    port(
        a, b : in  std_logic_vector(15 downto 0);
        s_r  : in  std_logic;
        s    : out std_logic_vector(15 downto 0);
        OvF, ZF, SF, Cout: out std_logic
    );
    end component;

    type tipo_pp_8b is array (0 to 7) of std_logic_vector(7 downto 0);
    signal productos_parciales_8b : tipo_pp_8b;
    
    type tipo_pp_16b is array (0 to 7) of std_logic_vector(15 downto 0);
    signal productos_desplazados_16b : tipo_pp_16b;

   
    type tipo_suma is array (0 to 6) of std_logic_vector(15 downto 0);
    signal sumas_intermedias : tipo_suma;
    signal producto_interno : std_logic_vector(15 downto 0);

begin

    generar_pp_i: for i in 0 to 7 generate
        generar_pp_j: for j in 0 to 7 generate
            productos_parciales_8b(i)(j) <= Multiplicando(j) AND Multiplicador(i);
        end generate;
    end generate;

    productos_desplazados_16b(0) <= "00000000" & productos_parciales_8b(0);
    productos_desplazados_16b(1) <= "0000000"  & productos_parciales_8b(1) & '0';
    productos_desplazados_16b(2) <= "000000"   & productos_parciales_8b(2) & "00";
    productos_desplazados_16b(3) <= "00000"    & productos_parciales_8b(3) & "000";
    productos_desplazados_16b(4) <= "0000"     & productos_parciales_8b(4) & "0000";
    productos_desplazados_16b(5) <= "000"      & productos_parciales_8b(5) & "00000";
    productos_desplazados_16b(6) <= "00"       & productos_parciales_8b(6) & "000000";
    productos_desplazados_16b(7) <= '0'        & productos_parciales_8b(7) & "0000000";

  
    SUMADOR_0: FAS16b port map (
        a    => productos_desplazados_16b(0),
        b    => productos_desplazados_16b(1),
        s_r  => '0', 
        s    => sumas_intermedias(0),
        OvF  => open, ZF => open, 
        SF   => open, Cout => open
    );

 
    generar_sumadores_medios: for i in 1 to 5 generate
        SUMADOR_I: FAS16b port map (
            a    => sumas_intermedias(i-1),
            b    => productos_desplazados_16b(i+1),
            s_r  => '0',
            s    => sumas_intermedias(i),
            OvF  => open, ZF => open, 
            SF   => open, Cout => open
        );
    end generate;
    
 
    SUMADOR_FINAL: FAS16b port map (
        a    => sumas_intermedias(5),
        b    => productos_desplazados_16b(7), 
        s_r  => '0',
        s    => producto_interno, 
        
   
        OvF  => OvF, 
        ZF   => ZF, 
        SF   => SF, 
        Cout => Cout
    );
 

    Producto_Final <= producto_interno;

end Behavioral;