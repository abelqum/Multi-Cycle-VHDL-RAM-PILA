library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL; 

entity TopModule is
port( 
    fila : in std_logic_vector(3 downto 0);
        columnas : out std_logic_vector(3 downto 0);
    clk, reset, pause_run : in std_logic;
    Pop,Push : in std_logic;
    Pop_out,Push_out: out std_logic;
    seg : out std_logic_vector(0 to 7);
    an : out std_logic_vector(7 downto 0);
    ledsd : out std_logic_vector(3 downto 0);
asr: out std_logic_vector( 4 downto 0 );
    ZF, CF, SF, OvF : out std_logic
);
end TopModule;

architecture Behavioral of TopModule is
COMPONENT teclado
PORT (
    clk_27mhz : IN  STD_LOGIC;
    reset     : IN  STD_LOGIC;
    fila      : IN  std_logic_vector(3 downto 0);
    columnas  : OUT std_logic_vector(3 downto 0);
    numero    : OUT std_logic_vector(31 downto 0)
);
END COMPONENT;

 COMPONENT bcdbin
PORT (
    clk     : IN  STD_LOGIC;
    reset   : IN  STD_LOGIC;
    bcd     : IN  STD_LOGIC_VECTOR(31 downto 0);
    binario : OUT STD_LOGIC_VECTOR(15 downto 0)
);
END COMPONENT;

COMPONENT binbcd
PORT (
    clk     : IN  STD_LOGIC;
    reset   : IN  STD_LOGIC;
    binario : IN  STD_LOGIC_VECTOR(15 downto 0);
    signo   : IN  STD_LOGIC;
    bcd     : OUT STD_LOGIC_VECTOR(31 downto 0)
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

    component ALU16bits is
        port(
            A, B : in std_logic_vector(15 downto 0);
            sel : in std_logic_vector(3 downto 0);
            resultado : out std_logic_vector(15 downto 0);
            residuo : out std_logic_vector(7 downto 0);
            CF, ZF, SF, OvF, error_div : out std_logic
        );
    end component;

    component FlagReg is
        port(
            OvF_in, ZF_in, SF_in, CF_in : in std_logic;
            clk, reset, EnFlags : in std_logic;
            OvF_out, ZF_out, SF_out, CF_out : out std_logic
        );
    end component;

    component InstReg is
        port( 
            EnIR, clk, Reset : in std_logic;
            Data_in  : in std_logic_vector(23 downto 0);
            Data_out : out std_logic_vector(23 downto 0)
        );
    end component;

    component PC is
        port(
            Clk, Reset, EnPC : in std_logic;
            D_in  : in std_logic_vector(7 downto 0);
            D_out : out std_logic_vector(7 downto 0)
        );
    end component;

    component RAM is
        port(
            clk : in std_logic;
            Adress  : in std_logic_vector(7 downto 0);
            Data_in : in std_logic_vector(23 downto 0);
            EnRAM, RW : in std_logic;
            Data_out : out std_logic_vector(23 downto 0)
        );
    end component;

    component RF is
        port(
            clk, Reset, EnRF : in std_logic;
            A, B, Dest : in std_logic_vector(7 downto 0);
            Data_in : in std_logic_vector(15 downto 0);
          asr: out std_logic_vector( 4 downto 0 );
            A_out, B_out : out std_logic_vector(15 downto 0)
        );
    end component;

    component SignExtend is
        port(
            Data_in  : in std_logic_vector(7 downto 0);
            Data_out : out std_logic_vector(15 downto 0)
        );
    end component;

    -- <<-- MODIFICADO: Añadido 'pause_run' al port de la UC
    component UC is
        port(
            Instruction : in std_logic_vector(23 downto 0);
            clk, reset : in std_logic;
            pause_run   : in std_logic; -- <<-- AÑADIDO
            CF, ZF, SF, OvF : in std_logic;
            EnPC, Mux_Addr, EnRAM, RW, EnIR, MUX_Dest, MUX_RData, EnRF, MUX_ALUA, EnFlags : out std_logic;
            MUX_ALUB, PC_sel : out std_logic_vector(1 downto 0);
            estados : out std_logic_vector(3 downto 0);
            ALU_Op : out std_logic_vector(3 downto 0);
            Display_En : out std_logic
        );
    end component;

    -- SEÑALES PARA PAUSA
    signal pause_en    : std_logic;
    signal s_EnPC      : std_logic;
    signal s_EnIR      : std_logic;
    signal s_EnRegFile : std_logic;
    signal s_EnFlags   : std_logic;
    signal s_Display_En: std_logic;
    signal  asr_TEMP: std_logic_vector(4 downto 0):="10000";
    -- Señales del Datapath y Control
    signal UC_reset, Err_div, OvF_TEMP, SF_TEMP, ZF_TEMP, CF_TEMP, EnRegFile, EnRam, RW, EnIR, EnPC, EnFlags, OvF_out, SF_out, ZF_out, CF_out, Mux_addr, Mux_rdata, Mux_dest, Mux_alua, Display_En : std_logic := '0';
    signal EnPC_Final : std_logic;
    signal Mux_PC, Mux_alub : std_logic_vector(1 downto 0);
    signal IR, RAM_out, dat_in,intruct : std_logic_vector(23 downto 0);
    signal entrada_display1, Resultado_alu, Mux_ALUA_out, Mux_ALUB_out, SignExt_out, Mux_Data_out, RF_A_out, RF_B_out, mar16, Ram_16,intruct1 : std_logic_vector(15 downto 0);
    signal Sel_op : std_logic_vector(3 downto 0);
    signal Residuo, Mux_Dest_out, Mux_Addr_out, Mux_PC_out, MAR, Program_dir, PC_actual : std_logic_vector(7 downto 0) := (others => '0');
    signal salida_teclado, entrada_display: std_logic_vector(31 downto 0);
    -- Señales del Botón PC
    signal pc_btn_s1, pc_btn_s2, PC_Load_Pulse : std_logic := '1';
signal binario_16bits   : std_logic_vector(15 downto 0);
begin

-- INSTANCIA
U1_teclado: teclado PORT MAP (
    clk_27mhz => clk,
    reset     => reset,
    fila      => fila,
    columnas  => columnas,
    numero    => salida_teclado
);
    -- ==========================================================
    -- LÓGICA DE PAUSA Y GATING
    -- ==========================================================
    -- Asume '1' = RUN, '0' = PAUSE (Pull-up)
    pause_en <= pause_run;

    -- Filtra ("gate") todas las señales de habilitación
    s_EnPC       <= EnPC and pause_en;
    s_EnIR       <= EnIR and pause_en;
    s_EnRegFile  <= EnRegFile and pause_en;
    s_EnFlags    <= EnFlags and pause_en;
    s_Display_En <= Display_En and pause_en;
    -- ==========================================================


    -- ==========================================================
    -- LÓGICA DEL BOTÓN PC_Btn
    -- ==========================================================
    Debounce_PC_Btn : process(clk, reset)
    begin
        if reset = '0' then
            pc_btn_s1 <= '1';
            pc_btn_s2 <= '1';
        elsif rising_edge(clk) then
            pc_btn_s1 <= Pop;
            pc_btn_s2 <= pc_btn_s1;
        end if;
    end process;

    PC_Load_Pulse <= pc_btn_s2 and (not pc_btn_s1);
    
    -- Lógica de Reset de la UC (Activo-Bajo)
    UC_reset <= reset and (not PC_Load_Pulse);
    -- ==========================================================


    -- ==========================================================
    -- LÓGICA DEL DISPLAY
    -- ==========================================================
 
-- INSTANCIA
U4_display: display PORT MAP (
    Datos     =>entrada_display,-- salida_teclado
    clk_27mhz => clk,
    seg       => seg,
    an        => an
);
    -- Latch del display (se pausa con pause_en)
    process(clk, reset) 
    begin
        if UC_reset = '0' then
            entrada_display1 <= (others => '0');
        elsif rising_edge(clk) and pause_en = '1' then -- <<-- MODIFICADO
            if s_Display_En = '1' then                 -- <<-- MODIFICADO
                entrada_display1 <= RF_A_out;
            end if;
        end if;
    end process;

  


-- INSTANCIA
U3_binbcd: binbcd PORT MAP (
    clk     => clk,
    reset   => reset,
    binario => entrada_display1,
    signo   => SF_out,
    bcd     => entrada_display
);
--del teclado a instruccion hexadecimal
U2_bcdbin: bcdbin PORT MAP (
    clk     => clk,
    reset   => reset,
    bcd     => salida_teclado,
    binario => intruct1
);
    -- ==========================================================


    -- ==========================================================
    -- LÓGICA DEL DATAPATH
    -- ==========================================================
    Pop_out <= not Pop;
 Push_out <= not Push;
    mar16 <= "00000000" & MAR;

    with Mux_PC select Mux_PC_out <=
        Resultado_alu(7 downto 0) when "00",
        IR(7 downto 0) when "01",
        RF_B_out(7 downto 0) when "10",
        (others => '0') when others;

    EnPC_Final <= s_EnPC or PC_Load_Pulse; -- <<-- MODIFICADO (usa s_EnPC)

    Contador_Programa: PC port map (
        Clk => clk,
        Reset => reset,
        D_in => Mux_PC_out,
        EnPC => EnPC_Final, -- <<-- MODIFICADO (ya está filtrado)
        D_out => MAR
    );

    with Mux_addr select Mux_Addr_out <=
        MAR when '0',
        Resultado_alu(7 downto 0) when '1',
        (others => '0') when others;

    dat_in <= "00000000" & RF_A_out;

    Memoria_Principal: RAM port map (
        clk => clk,
        Adress => Mux_Addr_out,
        Data_in => dat_in,
        EnRAM => EnRam,
        RW => RW,
        Data_out => RAM_out
    );

    Registro_Instruccion: InstReg port map (
        EnIR => s_EnIR, -- <<-- MODIFICADO
        clk => clk,
        Reset => reset,
        Data_in => RAM_out,
        Data_out => IR
    );

    with Mux_dest select Mux_Dest_out <=
        IR(15 downto 8) when '0',
        IR(7 downto 0) when '1',
        (others => '0') when others;

    RAM_16 <= RAM_out(15 downto 0);

    with Mux_rdata select Mux_Data_out <=
        RAM_16 when '0',
        Resultado_alu when '1',
        (others => '0') when others;

    Banco_Registros: RF port map (
        clk => clk,
        A => IR(15 downto 8),
        B => IR(7 downto 0),
        Reset => reset,
        Dest => Mux_Dest_out,
        Data_in => Mux_Data_out,
        EnRF => s_EnRegFile, -- <<-- MODIFICADO
        A_out => RF_A_out,
        asr => asr_TEMP,
        B_out => RF_B_out
    );

asr<=not asr_TEMP;
    with Mux_alua select Mux_ALUA_out <=
        "00000000" & MAR when '0',
        RF_A_out when '1',
        (others => '0') when others;

    with Mux_alub select Mux_ALUB_out <=
        RF_B_out when "00",
        "0000000000000001" when "01",
        "0000000000000000" when "10",
        SignExt_out when "11",
        (others => '0') when others;

    Extensor_Signo: SignExtend port map (
        Data_in => IR(7 downto 0),
        Data_out => SignExt_out
    );

    ALU_principal: ALU16bits port map (
        A => Mux_ALUA_out,
        B => Mux_ALUB_out,
        sel => Sel_op,
        resultado => Resultado_alu,
        residuo => Residuo,
        CF => CF_TEMP,
        ZF => ZF_TEMP,
        SF => SF_TEMP,
        OvF => OvF_TEMP,
        error_div => Err_div
    );

    Registro_Banderas: FlagReg port map (
        OvF_in => OvF_TEMP,
        ZF_in => ZF_TEMP,
        SF_in => SF_TEMP,
        CF_in => CF_TEMP,
        clk => clk,
        reset => reset,
        EnFlags => s_EnFlags, -- <<-- MODIFICADO
        OvF_out => OvF_out,
        ZF_out => ZF_out,
        SF_out => SF_out,
        CF_out => CF_out
    );

    Unidad_Control_inst: UC port map (
        Instruction => IR,
        clk => clk,
        reset => UC_reset,
        pause_run   => pause_en, -- <<-- AÑADIDO
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
        MUX_ALUB => Mux_alub,
        PC_sel => Mux_PC,
        estados =>open,
        ALU_Op => Sel_op,
        Display_En => Display_En
    );

    ledsd <= CF_out & ZF_out & SF_out & OvF_out;

end Behavioral;