library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL; 

entity TopModule is
port( 
    fila             : in std_logic_vector(3 downto 0);
    columnas         : out std_logic_vector(3 downto 0);
    clk, reset       : in std_logic;
    pause_run        : in std_logic; -- Switch: 1=Cargar(Pausa), 0=Correr CPU
    Sel_program      : in std_logic_vector(2 downto 0);
    
    -- Botones Físicos
    Pop, Push, Clear : in std_logic; 
    
    -- Salidas Visuales
    Pop_out, Push_out: out std_logic; 
    seg              : out std_logic_vector(0 to 7);
    an               : out std_logic_vector(7 downto 0);
    lleno, vacio     : out std_logic; 
    ledsd            : out std_logic_vector(3 downto 0);
    ZF, CF, SF, OvF  : out std_logic
);
end TopModule;

architecture Behavioral of TopModule is

    -- ==========================================================
    -- DECLARACIÓN DE COMPONENTES
    -- ==========================================================

    COMPONENT teclado
    PORT (
        clk_27mhz : IN  STD_LOGIC;
        reset     : IN  STD_LOGIC;
        clear     : IN  STD_LOGIC;
        fila      : IN  std_logic_vector(3 downto 0);
        columnas  : OUT std_logic_vector(3 downto 0);
        numero    : OUT std_logic_vector(31 downto 0)
    );
    END COMPONENT;

    COMPONENT display
    PORT (
        Datos     : IN  std_logic_vector(31 downto 0);
        clk_27mhz : IN  STD_LOGIC;
        seg       : OUT STD_LOGIC_VECTOR(0 to 7);
        an        : OUT STD_LOGIC_VECTOR(7 downto 0)
    );
    END COMPONENT;

    component RAM is
        port(
            clk          : in std_logic;
            reset        : in std_logic;
            Adress       : in std_logic_vector(7 downto 0);
            Data_in      : in std_logic_vector(23 downto 0);
            EnRAM, RW    : in std_logic;
            push, pop    : in std_logic; 
            data_teclado : in std_logic_vector(23 downto 0);
            pause_run    : in std_logic;
            lleno, vacio : out std_logic;
            count_out    : out std_logic_vector(7 downto 0); 
            Data_out     : out std_logic_vector(23 downto 0)
        );
    end component;

    -- Componentes del CPU
    COMPONENT bcdbin PORT (clk, reset : IN STD_LOGIC; bcd : IN STD_LOGIC_VECTOR(31 downto 0); binario : OUT STD_LOGIC_VECTOR(15 downto 0)); END COMPONENT;
    COMPONENT binbcd PORT (clk, reset, signo : IN STD_LOGIC; binario : IN STD_LOGIC_VECTOR(15 downto 0); bcd : OUT STD_LOGIC_VECTOR(31 downto 0)); END COMPONENT;
    component ALU16bits is port(A, B : in std_logic_vector(15 downto 0); sel : in std_logic_vector(3 downto 0); resultado : out std_logic_vector(15 downto 0); residuo : out std_logic_vector(7 downto 0); CF, ZF, SF, OvF, error_div : out std_logic); end component;
    component FlagReg is port(OvF_in, ZF_in, SF_in, CF_in, clk, reset, EnFlags : in std_logic; OvF_out, ZF_out, SF_out, CF_out : out std_logic); end component;
    component InstReg is port(EnIR, clk, Reset : in std_logic; Data_in : in std_logic_vector(23 downto 0); Data_out : out std_logic_vector(23 downto 0)); end component;
    component PC is port(Clk, Reset, EnPC : in std_logic; D_in : in std_logic_vector(7 downto 0); D_out : out std_logic_vector(7 downto 0)); end component;
    component RF is port(clk, Reset, EnRF : in std_logic; A, B, Dest : in std_logic_vector(7 downto 0); Data_in : in std_logic_vector(15 downto 0); asr: out std_logic_vector( 4 downto 0 ); A_out, B_out : out std_logic_vector(15 downto 0)); end component;
    component SignExtend is port(Data_in : in std_logic_vector(7 downto 0); Data_out : out std_logic_vector(15 downto 0)); end component;
    component UC is port(Instruction : in std_logic_vector(23 downto 0); clk, reset, pause_run, CF, ZF, SF, OvF : in std_logic; EnPC, Mux_Addr, EnRAM, RW, EnIR, MUX_Dest, MUX_RData, EnRF, MUX_ALUA, EnFlags : out std_logic; MUX_ALUB, PC_sel : out std_logic_vector(1 downto 0); estados, ALU_Op : out std_logic_vector(3 downto 0); Display_En : out std_logic); end component;

    -- ==========================================================
    -- SEÑALES INTERNAS
    -- ==========================================================
    
    -- Señales de Control General
    signal pause_en     : std_logic;
    signal s_EnPC, s_EnIR, s_EnRegFile, s_EnFlags, s_Display_En : std_logic;
    signal UC_reset, PC_Load_Pulse : std_logic;

    -- Señales de Datos
    signal IR, RAM_out, dat_in : std_logic_vector(23 downto 0);
    signal Resultado_alu, Mux_ALUA_out, Mux_ALUB_out, SignExt_out, Mux_Data_out, RF_A_out, RF_B_out, mar16, Ram_16, instruct1, entrada_display1 : std_logic_vector(15 downto 0);
    signal Sel_op : std_logic_vector(3 downto 0);
    signal Residuo, Mux_Dest_out, Mux_Addr_out, Mux_PC_out, MAR, Program_dir, PC_actual : std_logic_vector(7 downto 0) := (others => '0');
    
    -- Señales de Control (Bits individuales)
    signal EnRegFile, EnRam, RW, EnIR, EnPC, EnFlags : std_logic; 
    signal OvF_out, SF_out, ZF_out, CF_out, Display_En, Mux_addr, Mux_rdata, Mux_dest, Mux_alua : std_logic;
    signal EnPC_Final, Err_div, OvF_TEMP, SF_TEMP, ZF_TEMP, CF_TEMP : std_logic;
    
    -- *** SEÑALES FALTANTES CORREGIDAS ***
    signal Mux_PC, Mux_alub : std_logic_vector(1 downto 0);

    -- Señales de Display y Teclado
    signal salida_teclado, entrada_display, datos_para_display : std_logic_vector(31 downto 0);
    signal ram_counter_debug : std_logic_vector(7 downto 0);

    -- ANTI-REBOTE
    constant DEBOUNCE_LIMIT : integer := 200000; 
    signal cnt_push, cnt_pop, cnt_clear : integer range 0 to DEBOUNCE_LIMIT := 0;
    signal push_stable, pop_stable, clear_stable : std_logic := '1';
    signal push_prev, pop_prev, clear_prev : std_logic := '1';
    signal push_pulse, pop_pulse, clear_pulse : std_logic := '0';

begin

    Pop_out  <= not Pop; 
    Push_out <= not Push;
    mar16    <= "00000000" & MAR; 
    ledsd    <= CF_out & ZF_out & SF_out & OvF_out;

    -- ==========================================================
    -- 1. ANTI-REBOTE (DEBOUNCE + ONE-SHOT)
    -- ==========================================================
    process(clk)
    begin
        if rising_edge(clk) then
            -- PUSH
            if (Push = push_stable) then cnt_push <= 0;
            else cnt_push <= cnt_push + 1; if cnt_push = DEBOUNCE_LIMIT then push_stable <= Push; end if; end if;
            -- POP
            if (Pop = pop_stable) then cnt_pop <= 0;
            else cnt_pop <= cnt_pop + 1; if cnt_pop = DEBOUNCE_LIMIT then pop_stable <= Pop; end if; end if;
            -- CLEAR
            if (Clear = clear_stable) then cnt_clear <= 0;
            else cnt_clear <= cnt_clear + 1; if cnt_clear = DEBOUNCE_LIMIT then clear_stable <= Clear; end if; end if;

            -- Generación de Pulsos
            push_prev  <= push_stable;
            pop_prev   <= pop_stable;
            clear_prev <= clear_stable;

            if (push_prev = '1' and push_stable = '0') then push_pulse <= '1'; else push_pulse <= '0'; end if;
            if (pop_prev = '1' and pop_stable = '0') then pop_pulse <= '1'; else pop_pulse <= '0'; end if;
            if (clear_prev = '1' and clear_stable = '0') then clear_pulse <= '1'; else clear_pulse <= '0'; end if;
        end if;
    end process;

    -- ==========================================================
    -- 2. INSTANCIAS DE I/O
    -- ==========================================================

    U1_teclado: teclado PORT MAP (
        clk_27mhz => clk,
        reset     => reset,
        clear     => clear_pulse,
        fila      => fila,
        columnas  => columnas,
        numero    => salida_teclado
    );

    pause_en <= pause_run;
    datos_para_display <= (ram_counter_debug & salida_teclado(23 downto 0)) when pause_en = '1' else entrada_display;

    U4_display: display PORT MAP (
        Datos     => datos_para_display,
        clk_27mhz => clk,
        seg       => seg,
        an        => an
    );

    -- ==========================================================
    -- 3. GATING DEL CPU
    -- ==========================================================
    s_EnPC       <= EnPC      and (not pause_en);
    s_EnIR       <= EnIR      and (not pause_en);
    s_EnRegFile  <= EnRegFile and (not pause_en);
    s_EnFlags    <= EnFlags   and (not pause_en);
    s_Display_En <= Display_En and (not pause_en);

    process(clk, reset) 
    begin
        if UC_reset = '0' then
            entrada_display1 <= (others => '0');
        elsif rising_edge(clk) then
            if pause_en = '0' and s_Display_En = '1' then
                entrada_display1 <= RF_A_out;
            end if;
        end if;
    end process;

    U3_binbcd: binbcd PORT MAP (clk=>clk, reset=>reset, binario=>entrada_display1, signo=>SF_out, bcd=>entrada_display);
    U2_bcdbin: bcdbin PORT MAP (clk=>clk, reset=>reset, bcd=>salida_teclado, binario=>instruct1);

    -- ==========================================================
    -- 4. CONTROL DE RESET Y DATAPATH
    -- ==========================================================
    
    PC_Load_Pulse <= pop_pulse; 
    UC_reset <= reset and (not PC_Load_Pulse);

    with Sel_program select Program_dir <= 
        "00000000" when "000", "00100101" when "001", "01001010" when "010", "01110000" when "011", (others => '0') when others;

    PC_actual <= Program_dir when PC_Load_Pulse = '1' else Mux_PC_out;
    EnPC_Final <= s_EnPC or PC_Load_Pulse;

    -- Mux PC usa la señal Mux_PC declarada (Vector de 2 bits)
    with Mux_PC select Mux_PC_out <= 
        Resultado_alu(7 downto 0) when "00", 
        IR(7 downto 0) when "01", 
        RF_B_out(7 downto 0) when "10", 
        (others => '0') when others;
    
    Contador_Programa: PC port map (Clk=>clk, Reset=>reset, D_in=>PC_actual, EnPC=>EnPC_Final, D_out=>MAR);
    
    with Mux_addr select Mux_Addr_out <= MAR when '0', Resultado_alu(7 downto 0) when '1', (others => '0') when others;
    
    dat_in <= "00000000" & RF_A_out;

    Memoria_Principal: RAM port map (
        clk          => clk,
        reset        => reset,
        Adress       => Mux_Addr_out,
        Data_in      => dat_in,
        EnRAM        => EnRam,
        RW           => RW,
        push         => push_pulse,
        pop          => pop_pulse,
        data_teclado => salida_teclado(23 downto 0),
        pause_run    => pause_en,
        lleno        => lleno,
        vacio        => vacio,
        count_out    => ram_counter_debug,
        Data_out     => RAM_out
    );

    Registro_Instruccion: InstReg port map (EnIR=>s_EnIR, clk=>clk, Reset=>reset, Data_in=>RAM_out, Data_out=>IR);
    with Mux_dest select Mux_Dest_out <= IR(15 downto 8) when '0', IR(7 downto 0) when '1', (others => '0') when others;
    RAM_16 <= RAM_out(15 downto 0);
    with Mux_rdata select Mux_Data_out <= RAM_16 when '0', Resultado_alu when '1', (others => '0') when others;

    Banco_Registros: RF port map (clk=>clk, Reset=>reset, EnRF=>s_EnRegFile, A=>IR(15 downto 8), B=>IR(7 downto 0), Dest=>Mux_Dest_out, Data_in=>Mux_Data_out, A_out=>RF_A_out, B_out=>RF_B_out, asr=>open);
    
    with Mux_alua select Mux_ALUA_out <= "00000000" & MAR when '0', RF_A_out when '1', (others => '0') when others;
    Extensor_Signo: SignExtend port map (Data_in=>IR(7 downto 0), Data_out=>SignExt_out);
    
    -- Mux ALU B usa la señal Mux_alub declarada (Vector de 2 bits)
    with Mux_alub select Mux_ALUB_out <= 
        RF_B_out when "00", 
        std_logic_vector(to_unsigned(1, 16)) when "01", 
        (others => '0') when "10", 
        SignExt_out when "11", 
        (others => '0') when others;

    ALU_principal: ALU16bits port map (A=>Mux_ALUA_out, B=>Mux_ALUB_out, sel=>Sel_op, resultado=>Resultado_alu, residuo=>Residuo, CF=>CF_TEMP, ZF=>ZF_TEMP, SF=>SF_TEMP, OvF=>OvF_TEMP, error_div=>Err_div);
    Registro_Banderas: FlagReg port map (OvF_in=>OvF_TEMP, ZF_in=>ZF_TEMP, SF_in=>SF_TEMP, CF_in=>CF_TEMP, clk=>clk, reset=>reset, EnFlags=>s_EnFlags, OvF_out=>OvF_out, ZF_out=>ZF_out, SF_out=>SF_out, CF_out=>CF_out);
    
    Unidad_Control_inst: UC port map (
        Instruction => IR, 
        clk => clk, 
        reset => UC_reset, 
        pause_run => pause_en, 
        CF => CF_out, 
        ZF => ZF_out, 
        SF => SF_out, 
        OvF => OvF_out, 
        EnPC => EnPC, 
        Mux_Addr => Mux_addr, 
        EnRAM => EnRam, 
        RW => RW, 
        EnIR => EnIR, 
        MUX_Dest => Mux_dest, 
        MUX_RData => Mux_rdata, 
        EnRF => EnRegFile, 
        MUX_ALUA => Mux_alua, 
        EnFlags => EnFlags, 
        
        -- Conexión de vectores de 2 bits
        MUX_ALUB => Mux_alub, 
        PC_sel => Mux_PC, 
        
        estados => open, 
        ALU_Op => Sel_op, 
        Display_En => Display_En
    );

end Behavioral;
