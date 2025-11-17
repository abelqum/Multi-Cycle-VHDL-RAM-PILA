Library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

Entity ALU16bits is
    port(
        A : in std_logic_vector(15 downto 0);
        B : in std_logic_vector(15 downto 0);
        sel : in std_logic_vector(3 downto 0);
        resultado : out std_logic_vector(15 downto 0);
        residuo : out std_logic_vector(7 downto 0);
        CF : out std_logic;
        ZF: out std_logic;
        SF: out std_logic;
        OvF: out std_logic;
        error_div : out std_logic
    );
end ALU16bits;

Architecture Behavioral of ALU16bits is

    component FAS16b is
    port(
        a    : in  std_logic_vector(15 downto 0);
        b    : in  std_logic_vector(15 downto 0);
        s_r  : in  std_logic;
        s    : out std_logic_vector(15 downto 0);
        OvF  : out std_logic;
        ZF   : out std_logic;
        SF   : out std_logic;
        Cout : out std_logic
    );
    end component;

    component Multiplicador8b is
    port(
        Multiplicando  : in  std_logic_vector(7 downto 0);
        Multiplicador  : in  std_logic_vector(7 downto 0);
        Producto_Final : out std_logic_vector(15 downto 0);
        OvF : out std_logic;
        ZF  : out std_logic;
        SF  : out std_logic;
        Cout: out std_logic
    );
    end component;

    component Divisor8b is
    port(
        Dividendo : in  std_logic_vector(7 downto 0);
        Divisor   : in  std_logic_vector(7 downto 0);
        Cociente  : out std_logic_vector(7 downto 0);
        Residuo   : out std_logic_vector(7 downto 0);
        Error_DivCero : out std_logic;
        OvF : out std_logic;
        ZF  : out std_logic;
        SF  : out std_logic;
        Cout: out std_logic
    );
    end component;

    -- Señales para operaciones
    signal s_suma, s_resta, s_c2a : std_logic_vector(15 downto 0);
    signal ovf_suma, zf_suma, sf_suma, cout_suma : std_logic;
    signal ovf_resta, zf_resta, sf_resta, cout_resta : std_logic;
    signal ovf_c2a, zf_c2a, sf_c2a, cout_c2a : std_logic;
    signal s_mult : std_logic_vector(15 downto 0);
    signal ovf_mult, zf_mult, sf_mult, cout_mult : std_logic;
    signal s_div_cociente, s_div_residuo : std_logic_vector(7 downto 0);
    signal ovf_div, zf_div, sf_div, cout_div : std_logic;
    signal err_div_interno : std_logic;
    
    -- Operaciones lógicas y shifts
    signal s_not, s_and, s_or : std_logic_vector(15 downto 0);
    signal s_lsl, s_asr : std_logic_vector(15 downto 0);
    signal cout_lsl : std_logic;
    
    -- Constantes
    signal uno_16b : std_logic_vector(15 downto 0) := (0 => '1', others => '0');
    signal s_not_a : std_logic_vector(15 downto 0);
    
    -- Señales de resultado
    signal res_temp : std_logic_vector(15 downto 0);
    signal cf_temp, zf_temp, sf_temp, ovf_temp : std_logic;
    signal residuo_temp : std_logic_vector(7 downto 0);
    signal error_div_temp : std_logic;

begin

    -- Instancias de componentes
    s_not_a <= not A;
    
    fas_c2a_inst: FAS16b port map ( 
        a => s_not_a, 
        b => uno_16b, 
        s_r => '0', 
        s => s_c2a, 
        OvF => ovf_c2a, 
        ZF => zf_c2a, 
        SF => sf_c2a, 
        Cout => cout_c2a 
    );
    
    fas_suma_inst: FAS16b port map ( 
        a => A, 
        b => B, 
        s_r => '0', 
        s => s_suma, 
        OvF => ovf_suma, 
        ZF => zf_suma, 
        SF => sf_suma, 
        Cout => cout_suma 
    );
    
    fas_resta_inst: FAS16b port map ( 
        a => A, 
        b => B, 
        s_r => '1', 
        s => s_resta, 
        OvF => ovf_resta, 
        ZF => zf_resta, 
        SF => sf_resta, 
        Cout => cout_resta 
    );
    
    mult_inst: Multiplicador8b port map ( 
        Multiplicando => A(7 downto 0), 
        Multiplicador => B(7 downto 0), 
        Producto_Final => s_mult, 
        OvF => ovf_mult, 
        ZF => zf_mult, 
        SF => sf_mult, 
        Cout => cout_mult 
    );
    
    div_inst: Divisor8b port map ( 
        Dividendo => A(7 downto 0), 
        Divisor => B(7 downto 0), 
        Cociente => s_div_cociente, 
        Residuo => s_div_residuo, 
        Error_DivCero => err_div_interno, 
        OvF => ovf_div, 
        ZF => zf_div, 
        SF => sf_div, 
        Cout => cout_div 
    );

    -- Operaciones lógicas
    s_not <= not A;
    s_and <= A and B;
    s_or  <= A or B;

    -- Shifts
    s_lsl <= std_logic_vector(shift_left(unsigned(A), to_integer(unsigned(B(3 downto 0)))));
    s_asr <= std_logic_vector(shift_right(signed(A), to_integer(unsigned(B(3 downto 0)))));
    cout_lsl <= A(16 - to_integer(unsigned(B(3 downto 0)))) when to_integer(unsigned(B(3 downto 0))) > 0 else '0';

    -- Multiplexor para resultado
    with sel select res_temp <=
        s_suma                    when "0000",  -- ADD
        s_resta                   when "0001",  -- SUB
        s_mult                    when "0010",  -- MULT
        "00000000" & s_div_cociente when "0011",  -- DIV
        s_resta                   when "0100",  -- CMP (usa resta para comparar)
        s_and                     when "0101",  -- AND
        s_or                      when "0110",  -- OR
        s_not                     when "0111",  -- COMP1
        s_c2a                     when "1000",  -- COMP2
        s_lsl                     when "1001",  -- LSL
        s_asr                     when "1010",  -- ASR
        (others => '0')           when others;

    -- Multiplexor para flags
    with sel select cf_temp <=
        cout_suma  when "0000",
        cout_resta when "0001",
        cout_mult  when "0010",
        cout_div   when "0011",
        cout_resta when "0100",  -- CMP
        '0'        when "0101",  -- AND
        '0'        when "0110",  -- OR
        '0'        when "0111",  -- COMP1
        cout_c2a   when "1000",  -- COMP2
        cout_lsl   when "1001",  -- LSL
        '0'        when "1010",  -- ASR
        '0'        when others;

    with sel select ovf_temp <=
        ovf_suma  when "0000",
        ovf_resta when "0001",
        ovf_mult  when "0010",
        ovf_div   when "0011",
        ovf_resta when "0100",  -- CMP
        '0'       when "0101",  -- AND
        '0'       when "0110",  -- OR
        '0'       when "0111",  -- COMP1
        ovf_c2a   when "1000",  -- COMP2
        '0'       when "1001",  -- LSL
        '0'       when "1010",  -- ASR
        '0'       when others;

    -- Zero Flag
    zf_temp <= '1' when res_temp = x"0000" else '0';

    -- Sign Flag
    sf_temp <= res_temp(15);

    -- Residuo y error de división
    residuo_temp <= s_div_residuo when sel = "0011" else (others => '0');
    error_div_temp <= err_div_interno when sel = "0011" else '0';

    -- Asignación de salidas
    resultado <= res_temp;
    residuo <= residuo_temp;
    CF <= cf_temp;
    ZF <= zf_temp;
    SF <= sf_temp;
    OvF <= ovf_temp;
    error_div <= error_div_temp;

end Behavioral;