library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity RAM is
port(
    clk          : in  std_logic; 
    reset        : in  std_logic;
    Adress       : in  std_logic_vector(7 downto 0);
    Data_in      : in  std_logic_vector(23 downto 0);
    EnRAM        : in  std_logic; 
    RW           : in  std_logic; 
    
    -- Ahora estas entradas esperan un PULSO de 1 ciclo (Active High)
    push         : in  std_logic; 
    pop          : in  std_logic;
    
    data_teclado : in  std_logic_vector(23 downto 0);
    pause_run    : in  std_logic;
    lleno, vacio : out std_logic;
    count_out    : out std_logic_vector(7 downto 0);
    Data_out     : out std_logic_vector(23 downto 0)
);
end RAM;

architecture Behavioral of RAM is

    constant STACK_TOP : integer := 10; 
    signal count : integer range 0 to 255 := STACK_TOP; 

    type RAM_MEMORY is array (0 to 255) of std_logic_vector(23 downto 0);
    signal MEMORY: RAM_MEMORY := (others => (others => '0'));

    signal addr_int : integer range 0 to 255;
    
begin
    
    addr_int <= to_integer(unsigned(Adress));
    Data_out <= MEMORY(addr_int);
    count_out <= std_logic_vector(to_unsigned(count, 8));

    process(clk)
    begin
        if rising_edge(clk) then
            -- Reset síncrono
            if reset = '0' then
                count <= STACK_TOP;
            else
                -- LÓGICA DE CONTROL
                if pause_run = '1' then
                    
                    -- Como ya recibimos un pulso limpio de 1 ciclo, 
                    -- simplemente chequeamos si está en '1'.
                    -- PUSH: Escribir y bajar puntero
                    if push = '1' then
                        MEMORY(count) <= data_teclado;
                        if count > 0 then
                            count <= count - 1;
                        end if;
                    end if;

                    -- POP: Subir puntero
                    if pop = '1' then
                        if count < STACK_TOP then
                            count <= count + 1;
                        end if;
                    end if;

                else 
                    -- Modo CPU
                    if EnRAM = '1' and RW = '0' then 
                        MEMORY(addr_int) <= Data_in;
                    end if;
                end if;
            end if;
        end if;
    end process;

    lleno <= '0' when count = 0 else '1';
    vacio <= '0' when count = STACK_TOP else '1';

end Behavioral;
