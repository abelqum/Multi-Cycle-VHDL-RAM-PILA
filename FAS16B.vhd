Library IEEE;
Use IEEE.std_logic_1164.all;

Entity FAS16b is
    port(
        a, b : in std_logic_vector(15 downto 0);
        s_r : in std_logic;
        s   : out std_logic_vector(15 downto 0);
        OvF: out std_logic;
        ZF: out std_logic;
        SF: out std_logic;
        Cout: out std_logic
    );
end FAS16b;

architecture behavioral of FAS16b is

    component FAS is
        port(
            a, b, c_in, x : in std_logic;
            s, c_out : out std_logic
        );
    end component;

    signal c : std_logic_vector(16 downto 0);
    signal s_interno : std_logic_vector(15 downto 0);

begin

    gen: for i in 0 to 15 generate
        fas_inst: FAS port map(
            a => a(i),
            b => b(i),
            c_in => c(i),
            x => s_r,
            s => s_interno(i), 
            c_out => c(i + 1)
        );
    end generate;

    c(0) <= s_r;
    cout <= c(16); --bandera carry
    OvF <= c(16) xor c(15); -- bandera overflow
    SF <= s_interno(15); --bandera signo
    ZF <= '1' when s_interno = x"0000" else '0'; --bandera cero
    s <= s_interno;

end behavioral;