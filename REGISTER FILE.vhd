library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL; 

entity RF is
port(
    clk     : in  std_logic; 
    A       : in  std_logic_vector(7 downto 0);
    B       : in  std_logic_vector(7 downto 0);
    Reset   : in  std_logic;
    Dest    : in  std_logic_vector(7 downto 0);
    Data_in : in  std_logic_vector(15 downto 0);
    EnRF    : in  std_logic; 
    A_out   : out std_logic_vector(15 downto 0);
    asr: out std_logic_vector( 4 downto 0 );
    B_out   : out std_logic_vector(15 downto 0)
);
end RF;

architecture Behavioral of RF is
signal asr16: std_logic_vector(15 downto 0);
type RegFile is array (0 to 15) of std_logic_vector(15 downto 0);
   signal TablaReg : RegFile := (
        0 => (others => '0'),  -- R0
        1 => (others => '0'),  -- R1
        2 => (others => '0'),  -- R2
        3 => (others => '0'),  -- R3
        4 => (others => '0'),  -- R4
        5 => (others => '0'),  -- R5
        6 => (others => '0'),  -- R6
        7 => (others => '0'),  -- R7
        8 => (others => '0'),  -- R8
        9 => (others => '0'),  -- R9
        10 => (others => '0'), -- R10
        11 => (others => '0'), -- R11
        12 => (others => '0'), -- R12
        13 => (others => '0'), -- R13
        14 => (others => '0'), -- R14
        15 => "0000000000010000"  -- R15
   );

 signal addr_a, addr_b, addr_dest : integer range 0 to 15; 

begin
    addr_a    <= to_integer(unsigned(A(3 downto 0)));
    addr_b    <= to_integer(unsigned(B(3 downto 0)));
    addr_dest <= to_integer(unsigned(Dest(3 downto 0)));

 
process(clk, Reset)
    begin
        if Reset = '0' then
            TablaReg(0) <= (others => '0');
            TablaReg(1) <= (others => '0');
            TablaReg(2) <= (others => '0');
            TablaReg(3) <= (others => '0');
            TablaReg(4) <= (others => '0');
            TablaReg(5) <= (others => '0');
            TablaReg(6) <= (others => '0');
            TablaReg(7) <= (others => '0');
            TablaReg(8) <= (others => '0');
            TablaReg(9) <= (others => '0');
            TablaReg(10) <= (others => '0');
            TablaReg(11) <= (others => '0');
            TablaReg(12) <= (others => '0');
            TablaReg(13) <= (others => '0');
            TablaReg(14) <= (others => '0');
            TablaReg(15) <= "0000000000010000"; -- Valor inicial en reset
            
        elsif rising_edge(clk) then -- Lógica de Escritura
            if EnRF = '1' then
                
                -- Lógica de escritura normal para R0-R14
                if addr_dest /= 15 then
                    TablaReg(addr_dest) <= Data_in;
                
                -- Lógica de escritura especial para R15 (LEDs)
                else
                    -- Revisa si el valor ACTUAL es 1 (el último LED)
                    if TablaReg(15) = "0000000000000001" then
                        -- Si es 1, reinicia la secuencia a 16 (primer LED)
                        TablaReg(15) <= "0000000000010000";
                    else
                        -- Si no es 1, escribe el valor de Data_in (resultado del ASRI)
                        TablaReg(15) <= Data_in;
                    end if;
                end if;
                
            end if;
        end if;
    end process;
    
    asr16<=TablaReg(15);
asr<=asr16(4 downto 0);
    A_out <= TablaReg(addr_a);
    B_out <= TablaReg(addr_b);

end Behavioral;