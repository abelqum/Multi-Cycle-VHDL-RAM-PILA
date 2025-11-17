library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity UC is
    port(
        Instruction : in  std_logic_vector(23 downto 0);
        clk         : in  std_logic;
        reset       : in  std_logic;
        pause_run   : in  std_logic;
        CF, ZF, SF, OvF : in  std_logic;
        EnPC, Mux_Addr, EnRAM, RW, EnIR, MUX_Dest, MUX_RData, EnRF, MUX_ALUA,EnFlags : out std_logic;
        MUX_ALUB,PC_sel : out std_logic_vector(1 downto 0);
        estados: out std_logic_vector(3 downto 0);
        ALU_Op   : out std_logic_vector(3 downto 0);
        Display_En : out std_logic  -- NUEVO: 0=inhabilitar, 1=habilitar display
    );
end UC;

architecture Behavioral of UC is


    signal opcode       : std_logic_vector(7 downto 0);
    signal opcode_int   : integer;
    signal palabra_temp : std_logic_vector(18 downto 0);  -- Aumentado a 19 bits

  type FSM is (
    FETCH, DECODE,
    
    -- Operaciones Tipo R (2 estados cada una)
    ADD, ADD_WB, SUB, SUB_WB, MULT, MULT_WB, DIV, DIV_WB, CMP,
    AND1, AND1_WB, OR1, OR1_WB, COMP1, COMP1_WB, COMP2, COMP2_WB,
    LSL, LSL_WB, ASR, ASR_WB,
    
    -- Operaciones Inmediatas (2 estados cada una)  
    ADDI, ADDI_WB, SUBI, SUBI_WB, MULI, MULI_WB, DIVI, DIVI_WB, CMPI,
    ANDI1, ANDI1_WB, ORI1, ORI1_WB, LSLI, LSLI_WB, ASRI, ASRI_WB,
    
    -- El resto de las instrucciones (mantienen misma estructura)
    LW1, LW2, LW3, SW1, SW2,
    MOVRR1, MOVRR2, MOVAR1, MOVAR2, MOVRA1, MOVRA2,
    JALR1, JALR2, JALR3, JMP,
    BNZ1, BNZ2, BZ1, BZ2, BS1, BS2, BNS1, BNS2,
    BC1, BC2, BNC1, BNC2, BOV1, BOV2, BNOV1, BNOV2,
    NOP, HALT,DISP
);

signal presente, siguiente : FSM := FETCH;

type Deco is array (0 to 255) of FSM;
constant ROM_DECO : Deco := (
    -- Opcodes 0-10 (Tipo R)
    0   => ADD,
    1   => SUB,
    2   => MULT,
    3   => DIV,
    4   => CMP,       -- (1 ciclo, no usa WB_ALU)
    5   => AND1,
    6   => OR1,
    7   => COMP1,
    8   => COMP2,
    9   => LSL,
    10  => ASR,
    
    -- Opcodes 11-26 (Memoria, Saltos, etc.)
    11  => LW1,
    12  => SW1,
    13  => MOVRR1,
    14  => MOVAR1,
    15  => MOVRA1,
    16  => JMP,
    17  => JALR1,
    18  => BNZ1,
    19  => BZ1,
    20  => BS1,
    21  => BNS1,
    22  => BC1,
    23  => BNC1,
    24  => BOV1,
    25  => BNOV1,
    26  => NOP,

    -- Nuevas Instrucciones Inmediatas (Opcodes 27-35)
    27  => ADDI,
    28  => SUBI,
    29  => MULI,
    30  => DIVI,
    31  => CMPI,     -- (1 ciclo, no usa WB_ALU)
    32  => ANDI1,
    33  => ORI1,
    34  => LSLI,
    35  => ASRI,
    36  => HALT,
    37  => DISP,
    -- Opcodes restantes (37-255)
    others => FETCH
);

begin

    -- ACTUALIZA AL SIGUIENTE ESTADO
  process(clk, reset)
    begin
        if reset = '0' then
            presente <= FETCH;
        -- Añade "and pause_run = '1'"
        elsif rising_edge(clk) and pause_run = '1' then
            presente <= siguiente;
        end if;
    end process;

   
    -- MÁQUINA DE ESTADOS
    process(presente)
    begin
 case presente is
    when FETCH =>
        -- PCsel(00),EnFlags(0),EnPC(1),Mux_Addr(0),EnRAM(1),RW(1),EnIR(1),MUX_Dest(X),MUX_RData(X),EnRF(0),MUX_ALUA(0),MUX_ALUB(01),ALU_Op(0000)
        -- Lee instrucción de RAM y calcula PC+1
        estados <= "0001";
        palabra_temp <= '0' & "00"&'0'&'1'&'0'&'1'&'1'&'1'&'X'&'X'&'0'&'0'&"01"&"0000";
        siguiente <= DECODE;

    when DECODE =>
        -- PCsel(00),EnFlags(0),EnPC(0),Mux_Addr(X),EnRAM(0),RW(X),EnIR(0),MUX_Dest(X),MUX_RData(X),EnRF(0),MUX_ALUA(X),MUX_ALUB(XX),ALU_Op(XXXX)
        -- Carga PC+1 al registro PC y decodifica instrucción
        estados <= "0010";
        palabra_temp <= '0' & "00"&'0'&'0'&'X'&'0'&'X'&'0'&'X'&'X'&'0'&'X'&"XX"&"XXXX";
        siguiente <= ROM_DECO(opcode_int);

    -- === OPERACIONES TIPO R CON 2 ESTADOS ===
    when ADD =>
        -- PCsel(00),EnFlags(0),EnPC(0),Mux_Addr(X),EnRAM(0),RW(X),EnIR(0),MUX_Dest(X),MUX_RData(X),EnRF(0),MUX_ALUA(1),MUX_ALUB(00),ALU_Op(0000)
        -- Ejecuta ADD: A + B
        estados <= "0011";
        palabra_temp <= '0' & "00"&'1'&'0'&'X'&'0'&'X'&'0'&'X'&'X'&'0'&'1'&"00"&"0000";
        siguiente <= ADD_WB;
        
    when ADD_WB =>
        -- PCsel(00),EnFlags(1),EnPC(0),Mux_Addr(X),EnRAM(0),RW(X),EnIR(0),MUX_Dest(0),MUX_RData(1),EnRF(1),MUX_ALUA(1),MUX_ALUB(00),ALU_Op(0000)
        -- Write Back de ADD manteniendo ALU_Op
        estados <= "0100";
        palabra_temp <= '0' & "00"&'1'&'0'&'X'&'0'&'X'&'0'&'0'&'1'&'1'&'1'&"00"&"0000";
        siguiente <= FETCH;

    when SUB =>
        -- PCsel(00),EnFlags(0),EnPC(0),Mux_Addr(X),EnRAM(0),RW(X),EnIR(0),MUX_Dest(X),MUX_RData(X),EnRF(0),MUX_ALUA(1),MUX_ALUB(00),ALU_Op(0001)
        -- Ejecuta SUB: A - B
        estados <= "0011";
        palabra_temp <= '0' & "00"&'1'&'0'&'X'&'0'&'X'&'0'&'X'&'X'&'0'&'1'&"00"&"0001";
        siguiente <= SUB_WB;
        
    when SUB_WB =>
        -- PCsel(00),EnFlags(1),EnPC(0),Mux_Addr(X),EnRAM(0),RW(X),EnIR(0),MUX_Dest(0),MUX_RData(1),EnRF(1),MUX_ALUA(1),MUX_ALUB(00),ALU_Op(0001)
        -- Write Back de SUB manteniendo ALU_Op
        estados <= "0100";
        palabra_temp <= '0' & "00"&'1'&'0'&'X'&'0'&'X'&'0'&'0'&'1'&'1'&'1'&"00"&"0001";
        siguiente <= FETCH;

    when MULT =>
        -- PCsel(00),EnFlags(0),EnPC(0),Mux_Addr(X),EnRAM(0),RW(X),EnIR(0),MUX_Dest(X),MUX_RData(X),EnRF(0),MUX_ALUA(1),MUX_ALUB(00),ALU_Op(0010)
        -- Ejecuta MULT: A * B
        estados <= "0011";
        palabra_temp <= '0' & "00"&'1'&'0'&'X'&'0'&'X'&'0'&'X'&'X'&'0'&'1'&"00"&"0010";
        siguiente <= MULT_WB;
        
    when MULT_WB =>
        -- PCsel(00),EnFlags(1),EnPC(0),Mux_Addr(X),EnRAM(0),RW(X),EnIR(0),MUX_Dest(0),MUX_RData(1),EnRF(1),MUX_ALUA(1),MUX_ALUB(00),ALU_Op(0010)
        -- Write Back de MULT manteniendo ALU_Op
        estados <= "0100";
        palabra_temp <= '0' & "00"&'1'&'0'&'X'&'0'&'X'&'0'&'0'&'1'&'1'&'1'&"00"&"0010";
        siguiente <= FETCH;

    when DIV =>
        -- PCsel(00),EnFlags(0),EnPC(0),Mux_Addr(X),EnRAM(0),RW(X),EnIR(0),MUX_Dest(X),MUX_RData(X),EnRF(0),MUX_ALUA(1),MUX_ALUB(00),ALU_Op(0011)
        -- Ejecuta DIV: A / B
        estados <= "0011";
        palabra_temp <= '0' & "00"&'1'&'0'&'X'&'0'&'X'&'0'&'X'&'X'&'0'&'1'&"00"&"0011";
        siguiente <= DIV_WB;
        
    when DIV_WB =>
        -- PCsel(00),EnFlags(1),EnPC(0),Mux_Addr(X),EnRAM(0),RW(X),EnIR(0),MUX_Dest(0),MUX_RData(1),EnRF(1),MUX_ALUA(1),MUX_ALUB(00),ALU_Op(0011)
        -- Write Back de DIV manteniendo ALU_Op
        estados <= "0100";
        palabra_temp <= '0' & "00"&'1'&'0'&'X'&'0'&'X'&'0'&'0'&'1'&'1'&'1'&"00"&"0011";
        siguiente <= FETCH;

    when AND1 =>
        -- PCsel(00),EnFlags(0),EnPC(0),Mux_Addr(X),EnRAM(0),RW(X),EnIR(0),MUX_Dest(X),MUX_RData(X),EnRF(0),MUX_ALUA(1),MUX_ALUB(00),ALU_Op(0101)
        -- Ejecuta AND: A AND B
        estados <= "0011";
        palabra_temp <= '0' & "00"&'1'&'0'&'X'&'0'&'X'&'0'&'X'&'X'&'0'&'1'&"00"&"0101";
        siguiente <= AND1_WB;
        
    when AND1_WB =>
        -- PCsel(00),EnFlags(1),EnPC(0),Mux_Addr(X),EnRAM(0),RW(X),EnIR(0),MUX_Dest(0),MUX_RData(1),EnRF(1),MUX_ALUA(1),MUX_ALUB(00),ALU_Op(0101)
        -- Write Back de AND manteniendo ALU_Op
        estados <= "0100";
        palabra_temp <= '0' & "00"&'1'&'0'&'X'&'0'&'X'&'0'&'0'&'1'&'1'&'1'&"00"&"0101";
        siguiente <= FETCH;

    when OR1 =>
        -- PCsel(00),EnFlags(0),EnPC(0),Mux_Addr(X),EnRAM(0),RW(X),EnIR(0),MUX_Dest(X),MUX_RData(X),EnRF(0),MUX_ALUA(1),MUX_ALUB(00),ALU_Op(0110)
        -- Ejecuta OR: A OR B
        estados <= "0011";
        palabra_temp <= '0' & "00"&'1'&'0'&'X'&'0'&'X'&'0'&'X'&'X'&'0'&'1'&"00"&"0110";
        siguiente <= OR1_WB;
        
    when OR1_WB =>
        -- PCsel(00),EnFlags(1),EnPC(0),Mux_Addr(X),EnRAM(0),RW(X),EnIR(0),MUX_Dest(0),MUX_RData(1),EnRF(1),MUX_ALUA(1),MUX_ALUB(00),ALU_Op(0110)
        -- Write Back de OR manteniendo ALU_Op
        estados <= "0100";
        palabra_temp <= '0' & "00"&'1'&'0'&'X'&'0'&'X'&'0'&'0'&'1'&'1'&'1'&"00"&"0110";
        siguiente <= FETCH;

    when COMP1 =>
        -- PCsel(00),EnFlags(0),EnPC(0),Mux_Addr(X),EnRAM(0),RW(X),EnIR(0),MUX_Dest(X),MUX_RData(X),EnRF(0),MUX_ALUA(1),MUX_ALUB(00),ALU_Op(0111)
        -- Ejecuta COMP1: Complemento a 1 de A
        estados <= "0011";
        palabra_temp <= '0' & "00"&'1'&'0'&'X'&'0'&'X'&'0'&'X'&'X'&'0'&'1'&"00"&"0111";
        siguiente <= COMP1_WB;
        
    when COMP1_WB =>
        -- PCsel(00),EnFlags(1),EnPC(0),Mux_Addr(X),EnRAM(0),RW(X),EnIR(0),MUX_Dest(0),MUX_RData(1),EnRF(1),MUX_ALUA(1),MUX_ALUB(00),ALU_Op(0111)
        -- Write Back de COMP1 manteniendo ALU_Op
        estados <= "0100";
        palabra_temp <= '0' & "00"&'1'&'0'&'X'&'0'&'X'&'0'&'0'&'1'&'1'&'1'&"00"&"0111";
        siguiente <= FETCH;

    when COMP2 =>
        -- PCsel(00),EnFlags(0),EnPC(0),Mux_Addr(X),EnRAM(0),RW(X),EnIR(0),MUX_Dest(X),MUX_RData(X),EnRF(0),MUX_ALUA(1),MUX_ALUB(00),ALU_Op(1000)
        -- Ejecuta COMP2: Complemento a 2 de A
        estados <= "0011";
        palabra_temp <= '0' & "00"&'1'&'0'&'X'&'0'&'X'&'0'&'X'&'X'&'0'&'1'&"00"&"1000";
        siguiente <= COMP2_WB;
        
    when COMP2_WB =>
        -- PCsel(00),EnFlags(1),EnPC(0),Mux_Addr(X),EnRAM(0),RW(X),EnIR(0),MUX_Dest(0),MUX_RData(1),EnRF(1),MUX_ALUA(1),MUX_ALUB(00),ALU_Op(1000)
        -- Write Back de COMP2 manteniendo ALU_Op
        estados <= "0100";
        palabra_temp <= '0' & "00"&'1'&'0'&'X'&'0'&'X'&'0'&'0'&'1'&'1'&'1'&"00"&"1000";
        siguiente <= FETCH;

    when LSL =>
        -- PCsel(00),EnFlags(0),EnPC(0),Mux_Addr(X),EnRAM(0),RW(X),EnIR(0),MUX_Dest(X),MUX_RData(X),EnRF(0),MUX_ALUA(1),MUX_ALUB(00),ALU_Op(1001)
        -- Ejecuta LSL: Logical Shift Left de A
        estados <= "0011";
        palabra_temp <= '0' & "00"&'1'&'0'&'X'&'0'&'X'&'0'&'X'&'X'&'0'&'1'&"00"&"1001";
        siguiente <= LSL_WB;
        
    when LSL_WB =>
        -- PCsel(00),EnFlags(1),EnPC(0),Mux_Addr(X),EnRAM(0),RW(X),EnIR(0),MUX_Dest(0),MUX_RData(1),EnRF(1),MUX_ALUA(1),MUX_ALUB(00),ALU_Op(1001)
        -- Write Back de LSL manteniendo ALU_Op
        estados <= "0100";
        palabra_temp <= '0' & "00"&'1'&'0'&'X'&'0'&'X'&'0'&'0'&'1'&'1'&'1'&"00"&"1001";
        siguiente <= FETCH;

    when ASR =>
        -- PCsel(00),EnFlags(0),EnPC(0),Mux_Addr(X),EnRAM(0),RW(X),EnIR(0),MUX_Dest(X),MUX_RData(X),EnRF(0),MUX_ALUA(1),MUX_ALUB(00),ALU_Op(1010)
        -- Ejecuta ASR: Arithmetic Shift Right de A
        estados <= "0011";
        palabra_temp <= '0' & "00"&'1'&'0'&'X'&'0'&'X'&'0'&'X'&'X'&'0'&'1'&"00"&"1010";
        siguiente <= ASR_WB;
        
    when ASR_WB =>
        -- PCsel(00),EnFlags(1),EnPC(0),Mux_Addr(X),EnRAM(0),RW(X),EnIR(0),MUX_Dest(0),MUX_RData(1),EnRF(1),MUX_ALUA(1),MUX_ALUB(00),ALU_Op(1010)
        -- Write Back de ASR manteniendo ALU_Op
        estados <= "0100";
        palabra_temp <= '0' & "00"&'1'&'0'&'X'&'0'&'X'&'0'&'0'&'1'&'1'&'1'&"00"&"1010";
        siguiente <= FETCH;

    -- === OPERACIONES INMEDIATAS CON 2 ESTADOS ===
    when ADDI =>
        -- PCsel(00),EnFlags(0),EnPC(0),Mux_Addr(X),EnRAM(0),RW(X),EnIR(0),MUX_Dest(X),MUX_RData(X),EnRF(0),MUX_ALUA(1),MUX_ALUB(11),ALU_Op(0000)
        -- Ejecuta ADDI: A + Inmediato
        estados <= "0011";
        palabra_temp <= '0' & "00"&'1'&'0'&'X'&'0'&'X'&'0'&'X'&'X'&'0'&'1'&"11"&"0000";
        siguiente <= ADDI_WB;
        
    when ADDI_WB =>
        -- PCsel(00),EnFlags(1),EnPC(0),Mux_Addr(X),EnRAM(0),RW(X),EnIR(0),MUX_Dest(0),MUX_RData(1),EnRF(1),MUX_ALUA(1),MUX_ALUB(11),ALU_Op(0000)
        -- Write Back de ADDI manteniendo ALU_Op
        estados <= "0100";
        palabra_temp <= '0' & "00"&'1'&'0'&'X'&'0'&'X'&'0'&'0'&'1'&'1'&'1'&"11"&"0000";
        siguiente <= FETCH;

    when SUBI =>
        -- PCsel(00),EnFlags(0),EnPC(0),Mux_Addr(X),EnRAM(0),RW(X),EnIR(0),MUX_Dest(X),MUX_RData(X),EnRF(0),MUX_ALUA(1),MUX_ALUB(11),ALU_Op(0001)
        -- Ejecuta SUBI: A - Inmediato
        estados <= "0011";
        palabra_temp <= '0' & "00"&'1'&'0'&'X'&'0'&'X'&'0'&'X'&'X'&'0'&'1'&"11"&"0001";
        siguiente <= SUBI_WB;
        
    when SUBI_WB =>
        -- PCsel(00),EnFlags(1),EnPC(0),Mux_Addr(X),EnRAM(0),RW(X),EnIR(0),MUX_Dest(0),MUX_RData(1),EnRF(1),MUX_ALUA(1),MUX_ALUB(11),ALU_Op(0001)
        -- Write Back de SUBI manteniendo ALU_Op
        estados <= "0100";
        palabra_temp <= '0' & "00"&'1'&'0'&'X'&'0'&'X'&'0'&'0'&'1'&'1'&'1'&"11"&"0001";
        siguiente <= FETCH;

    when MULI =>
        -- PCsel(00),EnFlags(0),EnPC(0),Mux_Addr(X),EnRAM(0),RW(X),EnIR(0),MUX_Dest(X),MUX_RData(X),EnRF(0),MUX_ALUA(1),MUX_ALUB(11),ALU_Op(0010)
        -- Ejecuta MULI: A * Inmediato
        estados <= "0011";
        palabra_temp <= '0' & "00"&'1'&'0'&'X'&'0'&'X'&'0'&'X'&'X'&'0'&'1'&"11"&"0010";
        siguiente <= MULI_WB;
        
    when MULI_WB =>
        -- PCsel(00),EnFlags(1),EnPC(0),Mux_Addr(X),EnRAM(0),RW(X),EnIR(0),MUX_Dest(0),MUX_RData(1),EnRF(1),MUX_ALUA(1),MUX_ALUB(11),ALU_Op(0010)
        -- Write Back de MULI manteniendo ALU_Op
        estados <= "0100";
        palabra_temp <= '0' & "00"&'1'&'0'&'X'&'0'&'X'&'0'&'0'&'1'&'1'&'1'&"11"&"0010";
        siguiente <= FETCH;

    when DIVI =>
        -- PCsel(00),EnFlags(0),EnPC(0),Mux_Addr(X),EnRAM(0),RW(X),EnIR(0),MUX_Dest(X),MUX_RData(X),EnRF(0),MUX_ALUA(1),MUX_ALUB(11),ALU_Op(0011)
        -- Ejecuta DIVI: A / Inmediato
        estados <= "0011";
        palabra_temp <= '0' & "00"&'1'&'0'&'X'&'0'&'X'&'0'&'X'&'X'&'0'&'1'&"11"&"0011";
        siguiente <= DIVI_WB;
        
    when DIVI_WB =>
        -- PCsel(00),EnFlags(1),EnPC(0),Mux_Addr(X),EnRAM(0),RW(X),EnIR(0),MUX_Dest(0),MUX_RData(1),EnRF(1),MUX_ALUA(1),MUX_ALUB(11),ALU_Op(0011)
        -- Write Back de DIVI manteniendo ALU_Op
        estados <= "0100";
        palabra_temp <= '0' & "00"&'1'&'0'&'X'&'0'&'X'&'0'&'0'&'1'&'1'&'1'&"11"&"0011";
        siguiente <= FETCH;

    when ANDI1 =>
        -- PCsel(00),EnFlags(0),EnPC(0),Mux_Addr(X),EnRAM(0),RW(X),EnIR(0),MUX_Dest(X),MUX_RData(X),EnRF(0),MUX_ALUA(1),MUX_ALUB(11),ALU_Op(0101)
        -- Ejecuta ANDI: A AND Inmediato
        estados <= "0011";
        palabra_temp <= '0' & "00"&'1'&'0'&'X'&'0'&'X'&'0'&'X'&'X'&'0'&'1'&"11"&"0101";
        siguiente <= ANDI1_WB;
        
    when ANDI1_WB =>
        -- PCsel(00),EnFlags(1),EnPC(0),Mux_Addr(X),EnRAM(0),RW(X),EnIR(0),MUX_Dest(0),MUX_RData(1),EnRF(1),MUX_ALUA(1),MUX_ALUB(11),ALU_Op(0101)
        -- Write Back de ANDI manteniendo ALU_Op
        estados <= "0100";
        palabra_temp <= '0' & "00"&'1'&'0'&'X'&'0'&'X'&'0'&'0'&'1'&'1'&'1'&"11"&"0101";
        siguiente <= FETCH;

    when ORI1 =>
        -- PCsel(00),EnFlags(0),EnPC(0),Mux_Addr(X),EnRAM(0),RW(X),EnIR(0),MUX_Dest(X),MUX_RData(X),EnRF(0),MUX_ALUA(1),MUX_ALUB(11),ALU_Op(0110)
        -- Ejecuta ORI: A OR Inmediato
        estados <= "0011";
        palabra_temp <= '0' & "00"&'1'&'0'&'X'&'0'&'X'&'0'&'X'&'X'&'0'&'1'&"11"&"0110";
        siguiente <= ORI1_WB;
        
    when ORI1_WB =>
        -- PCsel(00),EnFlags(1),EnPC(0),Mux_Addr(X),EnRAM(0),RW(X),EnIR(0),MUX_Dest(0),MUX_RData(1),EnRF(1),MUX_ALUA(1),MUX_ALUB(11),ALU_Op(0110)
        -- Write Back de ORI manteniendo ALU_Op
        estados <= "0100";
        palabra_temp <= '0' & "00"&'1'&'0'&'X'&'0'&'X'&'0'&'0'&'1'&'1'&'1'&"11"&"0110";
        siguiente <= FETCH;

    when LSLI =>
        -- PCsel(00),EnFlags(0),EnPC(0),Mux_Addr(X),EnRAM(0),RW(X),EnIR(0),MUX_Dest(X),MUX_RData(X),EnRF(0),MUX_ALUA(1),MUX_ALUB(11),ALU_Op(1001)
        -- Ejecuta LSLI: Logical Shift Left de A con inmediato
        estados <= "0011";
        palabra_temp <= '0' & "00"&'1'&'0'&'X'&'0'&'X'&'0'&'X'&'X'&'0'&'1'&"11"&"1001";
        siguiente <= LSLI_WB;
        
    when LSLI_WB =>
        -- PCsel(00),EnFlags(1),EnPC(0),Mux_Addr(X),EnRAM(0),RW(X),EnIR(0),MUX_Dest(0),MUX_RData(1),EnRF(1),MUX_ALUA(1),MUX_ALUB(11),ALU_Op(1001)
        -- Write Back de LSLI manteniendo ALU_Op
        estados <= "0100";
        palabra_temp <= '0' & "00"&'1'&'0'&'X'&'0'&'X'&'0'&'0'&'1'&'1'&'1'&"11"&"1001";
        siguiente <= FETCH;

    when ASRI =>
        -- PCsel(00),EnFlags(0),EnPC(0),Mux_Addr(X),EnRAM(0),RW(X),EnIR(0),MUX_Dest(X),MUX_RData(X),EnRF(0),MUX_ALUA(1),MUX_ALUB(11),ALU_Op(1010)
        -- Ejecuta ASRI: Arithmetic Shift Right de A con inmediato
        estados <= "0011";
        palabra_temp <= '0' & "00"&'1'&'0'&'X'&'0'&'X'&'0'&'X'&'X'&'0'&'1'&"11"&"1010";
        siguiente <= ASRI_WB;
        
    when ASRI_WB =>
        -- PCsel(00),EnFlags(1),EnPC(0),Mux_Addr(X),EnRAM(0),RW(X),EnIR(0),MUX_Dest(0),MUX_RData(1),EnRF(1),MUX_ALUA(1),MUX_ALUB(11),ALU_Op(1010)
        -- Write Back de ASRI manteniendo ALU_Op
        estados <= "0100";
        palabra_temp <= '0' & "00"&'1'&'0'&'X'&'0'&'X'&'0'&'0'&'1'&'1'&'1'&"11"&"1010";
        siguiente <= FETCH;

    -- === OPERACIONES DE 1 CICLO ===
    when CMP =>
        -- PCsel(00),EnFlags(1),EnPC(0),Mux_Addr(X),EnRAM(0),RW(X),EnIR(0),MUX_Dest(X),MUX_RData(X),EnRF(0),MUX_ALUA(1),MUX_ALUB(00),ALU_Op(0100)
        -- Ejecuta CMP: Compara A con B y actualiza flags
        estados <= "0011";
        palabra_temp <= '0' & "00"&'1'&'0'&'X'&'0'&'X'&'0'&'X'&'X'&'0'&'1'&"00"&"0100";
        siguiente <= FETCH;
        
    when CMPI =>
        -- PCsel(00),EnFlags(1),EnPC(0),Mux_Addr(X),EnRAM(0),RW(X),EnIR(0),MUX_Dest(X),MUX_RData(X),EnRF(0),MUX_ALUA(1),MUX_ALUB(11),ALU_Op(0100)
        -- Ejecuta CMPI: Compara A con Inmediato y actualiza flags
        estados <= "0011";
        palabra_temp <= '0' & "00"&'1'&'0'&'X'&'0'&'X'&'0'&'X'&'X'&'0'&'1'&"11"&"0100";
        siguiente <= FETCH;


        -- == INSTRUCCIONES DE MEMORIA ==
when LW1 =>
    -- Calcula dirección: PC + Offset (igual que BZ1)
    -- MUX_ALUA(0)=PC, MUX_ALUB(11)=Inmediato, ALU_Op(0000)=ADD
    estados <= "0101";
        palabra_temp <= '0' & "00"&'0'&'0'&'X'&'0'&'0'&'0'&'X'&'X'&'0'&'0'&"11"&"0000";
    siguiente <= LW2;
    
  when LW2 =>
    -- Lee RAM en dirección calculada (ALU Result)
    -- Mux_Addr(1)=usa dirección ALU, EnRAM(1), RW(1)=lectura
    estados <= "0110";
 --         PCsel(00),EnFlags(0),EnPC(0),Mux_Addr(X),EnRAM(0),RW(X),EnIR(0),MUX_Dest(X),MUX_RData(X),EnRF(0),MUX_ALUA(0),MUX_ALUB(11),ALU_Op(0000)
    palabra_temp <= '0' & "00"&'0'&'0'&'1'&'1'&'1'&'0'&'X'&'X'&'0'&'0'&"11"&"0000";
    siguiente <= LW3;
 when LW3 =>
    -- Guarda RAM_out en registro destino (IR[15:8])
    -- MUX_Dest(0), MUX_RData(0)=RAM_out, EnRF(1)
    estados <= "0111";
--         PCsel(00),EnFlags(0),EnPC(0),Mux_Addr(X),EnRAM(0),RW(X),EnIR(0),MUX_Dest(X),MUX_RData(X),EnRF(0),MUX_ALUA(0),MUX_ALUB(11),ALU_Op(0000)
    palabra_temp <= '0' & "00"&'0'&'0'&'1'&'1'&'1'&'0'&'0'&'0'&'1'&'0'&"11"&"0000";
    siguiente <= FETCH;



  when SW1 =>
   -- PCsel(00),EnFlags(0),EnPC(0),Mux_Addr(X),EnRAM(0),RW(X),EnIR(0),MUX_Dest(X),MUX_RData(X),EnRF(0),MUX_ALUA(0),MUX_ALUB(11),ALU_Op(0000)
        -- Calcula PC + offset si ZF=0 - NO MOSTRAR
    estados <= "1000";
    palabra_temp <= '0' & "00"&'0'&'0'&'X'&'0'&'0'&'0'&'X'&'X'&'0'&'0'&"11"&"0000";
    siguiente <= SW2;

    when SW2 =>
       -- PCsel(00),EnFlags(1),EnPC(0),Mux_Addr(X),EnRAM(0),RW(X),EnIR(0),MUX_Dest(0),MUX_RData(1),EnRF(1),MUX_ALUA(1),MUX_ALUB(11),ALU_Op(0000)
        -- Write Back de ADDI manteniendo ALU_Op
        estados <= "0100";

    palabra_temp <= '0' & "00"&'0'&'0'&'1'&'1'&'0'&'0'&'X'&'X'&'0'&'0'&"11"&"0000";
        siguiente <= FETCH;



-- == INSTRUCCIONES DE MOVIMIENTO ==
    when MOVRR1 =>
        -- PCsel(00),EnFlags(0),EnPC(0),Mux_Addr(X),EnRAM(0),RW(X),EnIR(0),MUX_Dest(X),MUX_RData(X),EnRF(0),MUX_ALUA(1),MUX_ALUB(00),ALU_Op(0000)
        -- Mueve RegB a RegA (ADD con cero) - NO MOSTRAR
        palabra_temp <= '0' & "00"&'0'&'0'&'X'&'0'&'X'&'0'&'X'&'X'&'0'&'1'&"00"&"0000";
        siguiente <= MOVRR2;
        
    when MOVRR2 =>
        -- PCsel(00),EnFlags(0),EnPC(0),Mux_Addr(X),EnRAM(0),RW(X),EnIR(0),MUX_Dest(0),MUX_RData(0),EnRF(1),MUX_ALUA(X),MUX_ALUB(XX),ALU_Op(XXXX)
        -- Escribe resultado en RegA - MOSTRAR
        palabra_temp <= '0' & "00"&'0'&'0'&'X'&'0'&'X'&'0'&'0'&'0'&'1'&'X'&"XX"&"XXXX";
        siguiente <= FETCH;

    when MOVAR1 =>
        -- PCsel(00),EnFlags(0),EnPC(0),Mux_Addr(X),EnRAM(0),RW(X),EnIR(0),MUX_Dest(X),MUX_RData(X),EnRF(0),MUX_ALUA(1),MUX_ALUB(10),ALU_Op(0000)
        -- Mueve dirección a acumulador (ADD con cero) - NO MOSTRAR
        palabra_temp <= '0' & "00"&'0'&'0'&'X'&'0'&'X'&'0'&'X'&'X'&'0'&'1'&"10"&"0000";
        siguiente <= MOVAR2;
        
    when MOVAR2 =>
        -- PCsel(00),EnFlags(0),EnPC(0),Mux_Addr(X),EnRAM(0),RW(X),EnIR(0),MUX_Dest(0),MUX_RData(0),EnRF(1),MUX_ALUA(X),MUX_ALUB(XX),ALU_Op(XXXX)
        -- Escribe resultado en RegA - MOSTRAR
        palabra_temp <= '0' & "00"&'0'&'0'&'X'&'0'&'X'&'0'&'0'&'0'&'1'&'X'&"XX"&"XXXX";
        siguiente <= FETCH;

    when MOVRA1 =>
        -- PCsel(00),EnFlags(0),EnPC(0),Mux_Addr(X),EnRAM(0),RW(X),EnIR(0),MUX_Dest(X),MUX_RData(X),EnRF(0),MUX_ALUA(1),MUX_ALUB(10),ALU_Op(0000)
        -- Mueve acumulador a registro - NO MOSTRAR
        palabra_temp <= '0' & "00"&'0'&'0'&'X'&'0'&'X'&'0'&'X'&'X'&'0'&'1'&"10"&"0000";
        siguiente <= MOVRA2;
        
    when MOVRA2 =>
        -- PCsel(00),EnFlags(0),EnPC(0),Mux_Addr(X),EnRAM(0),RW(X),EnIR(0),MUX_Dest(1),MUX_RData(0),EnRF(1),MUX_ALUA(X),MUX_ALUB(XX),ALU_Op(XXXX)
        -- Escribe resultado en RegB - MOSTRAR
        palabra_temp <= '0' & "00"&'0'&'0'&'X'&'0'&'X'&'0'&'1'&'0'&'1'&'X'&"XX"&"XXXX";
        siguiente <= FETCH;

    -- == SALTOS Y BRANCHES ==
    when JMP =>
        -- PCsel(01),EnFlags(0),EnPC(1),Mux_Addr(X),EnRAM(0),RW(X),EnIR(0),MUX_Dest(X),MUX_RData(X),EnRF(0),MUX_ALUA(X),MUX_ALUB(XX),ALU_Op(XXXX)
        -- Salto incondicional a dirección inmediata - NO MOSTRAR
        palabra_temp <= '0' & "01"&'0'&'1'&'X'&'0'&'X'&'0'&'X'&'X'&'0'&'X'&"XX"&"XXXX";
        siguiente <= FETCH;

when JALR1 =>
    -- Paso 1: Guardar PC+1 en registro destino (RegA)
    -- PCsel(00),EnFlags(0),EnPC(0),Mux_Addr(X),EnRAM(0),RW(X),EnIR(0),MUX_Dest(0),MUX_RData(1),EnRF(1),MUX_ALUA(0),MUX_ALUB(01),ALU_Op(0000)
    -- Calcula PC + 1 y guarda en RegA
    estados <= "0101";
    palabra_temp <= '0' & "00"&'0'&'0'&'X'&'0'&'X'&'0'&'0'&'1'&'1'&'0'&"10"&"0000";
    siguiente <= JALR2;

when JALR2 =>
    -- Paso 2: Preparar salto - leer dirección desde RegB
    -- PCsel(00),EnFlags(0),EnPC(0),Mux_Addr(X),EnRAM(0),RW(X),EnIR(0),MUX_Dest(X),MUX_RData(X),EnRF(0),MUX_ALUA(X),MUX_ALUB(XX),ALU_Op(XXXX)
    -- Solo asegura que RF_B_out tenga el valor correcto para el siguiente ciclo
    estados <= "0110";
    palabra_temp <= '0' & "10"&'0'&'0'&'X'&'0'&'X'&'0'&'X'&'1'&'0'&'0'&"10"&"0000";
    siguiente <= JALR3;

when JALR3 =>
    -- Paso 3: Ejecutar salto a dirección en RegB
    -- PCsel(10),EnFlags(0),EnPC(1),Mux_Addr(X),EnRAM(0),RW(X),EnIR(0),MUX_Dest(X),MUX_RData(X),EnRF(0),MUX_ALUA(X),MUX_ALUB(XX),ALU_Op(XXXX)
    -- Salta a la dirección almacenada en RF_B_out
    estados <= "0111";
    palabra_temp <= '0' & "10"&'0'&'1'&'X'&'0'&'X'&'0'&'X'&'X'&'0'&'X'&"XX"&"XXXX";
    siguiente <= FETCH;
    -- == BRANCHES CONDICIONALES ==
    when BNZ1 =>
        -- PCsel(00),EnFlags(0),EnPC(0),Mux_Addr(X),EnRAM(0),RW(X),EnIR(0),MUX_Dest(X),MUX_RData(X),EnRF(0),MUX_ALUA(0),MUX_ALUB(11),ALU_Op(0000)
        -- Calcula PC + offset si ZF=0 - NO MOSTRAR
        if ZF = '0' then
            palabra_temp <= '0' & "00"&'0'&'0'&'X'&'0'&'X'&'0'&'X'&'X'&'0'&'0'&"11"&"0000";
            siguiente <= BNZ2;
        else
            palabra_temp <= '0' & "00"&'0'&'0'&'X'&'0'&'X'&'0'&'X'&'X'&'0'&'X'&"XX"&"XXXX";
            siguiente <= FETCH;
        end if;

    when BNZ2 =>
        -- PCsel(00),EnFlags(0),EnPC(1),Mux_Addr(X),EnRAM(0),RW(X),EnIR(0),MUX_Dest(X),MUX_RData(X),EnRF(0),MUX_ALUA(X),MUX_ALUB(XX),ALU_Op(XXXX)
        -- Actualiza PC con dirección de branch - NO MOSTRAR
        palabra_temp <= '0' & "00"&'0'&'1'&'X'&'0'&'X'&'0'&'X'&'X'&'0'&'0'&"11"&"0000";
        siguiente <= FETCH;

    when BZ1 =>
        if ZF = '1' then
            palabra_temp <= '0' & "00"&'0'&'0'&'X'&'0'&'X'&'0'&'X'&'X'&'0'&'0'&"11"&"0000";
            siguiente <= BZ2;
        else
            palabra_temp <= '0' & "00"&'0'&'0'&'X'&'0'&'X'&'0'&'X'&'X'&'0'&'X'&"XX"&"XXXX";
            siguiente <= FETCH;
        end if;

    when BZ2 =>
        palabra_temp <= '0' & "00"&'0'&'1'&'X'&'0'&'X'&'0'&'X'&'X'&'0'&'0'&"11"&"0000";
        siguiente <= FETCH;

    when BS1 =>
        if SF = '1' then
            palabra_temp <= '0' & "00"&'0'&'0'&'X'&'0'&'X'&'0'&'X'&'X'&'0'&'0'&"11"&"0000";
            siguiente <= BS2;
        else
            palabra_temp <= '0' & "00"&'0'&'0'&'X'&'0'&'X'&'0'&'X'&'X'&'0'&'X'&"XX"&"XXXX";
            siguiente <= FETCH;
        end if;

    when BS2 =>
        palabra_temp <= '0' & "00"&'0'&'1'&'X'&'0'&'X'&'0'&'X'&'X'&'0'&'0'&"11"&"0000";
        siguiente <= FETCH;

    when BNS1 =>
        if SF = '0' then
            palabra_temp <= '0' & "00"&'0'&'0'&'X'&'0'&'X'&'0'&'X'&'X'&'0'&'0'&"11"&"0000";
            siguiente <= BNS2;
        else
            palabra_temp <= '0' & "00"&'0'&'0'&'X'&'0'&'X'&'0'&'X'&'X'&'0'&'X'&"XX"&"XXXX";
            siguiente <= FETCH;
        end if;

    when BNS2 =>
        palabra_temp <= '0' & "00"&'0'&'1'&'X'&'0'&'X'&'0'&'X'&'X'&'0'&'0'&"11"&"0000";
        siguiente <= FETCH;

    when BC1 =>
        if CF = '1' then
            palabra_temp <= '0' & "00"&'0'&'0'&'X'&'0'&'X'&'0'&'X'&'X'&'0'&'0'&"11"&"0000";
            siguiente <= BC2;
        else
            palabra_temp <= '0' & "00"&'0'&'0'&'X'&'0'&'X'&'0'&'X'&'X'&'0'&'X'&"XX"&"XXXX";
            siguiente <= FETCH;
        end if;

    when BC2 =>
        palabra_temp <= '0' & "00"&'0'&'1'&'X'&'0'&'X'&'0'&'X'&'X'&'0'&'0'&"11"&"0000";
        siguiente <= FETCH;

    when BNC1 =>
        if CF = '0' then
            palabra_temp <= '0' & "00"&'0'&'0'&'X'&'0'&'X'&'0'&'X'&'X'&'0'&'0'&"11"&"0000";
            siguiente <= BNC2;
        else
            palabra_temp <= '0' & "00"&'0'&'0'&'X'&'0'&'X'&'0'&'X'&'X'&'0'&'X'&"XX"&"XXXX";
            siguiente <= FETCH;
        end if;

    when BNC2 =>
        palabra_temp <= '0' & "00"&'0'&'1'&'X'&'0'&'X'&'0'&'X'&'X'&'0'&'0'&"11"&"0000";
        siguiente <= FETCH;

    when BOV1 =>
        if OvF = '1' then
            palabra_temp <= '0' & "00"&'0'&'0'&'X'&'0'&'X'&'0'&'X'&'X'&'0'&'0'&"11"&"0000";
            siguiente <= BOV2;
        else
            palabra_temp <= '0' & "00"&'0'&'0'&'X'&'0'&'X'&'0'&'X'&'X'&'0'&'X'&"XX"&"XXXX";
            siguiente <= FETCH;
        end if;

    when BOV2 =>
        palabra_temp <= '0' & "00"&'0'&'1'&'X'&'0'&'X'&'0'&'X'&'X'&'0'&'0'&"11"&"0000";
        siguiente <= FETCH;

    when BNOV1 =>
        if OvF = '0' then
            palabra_temp <= '0' & "00"&'0'&'0'&'X'&'0'&'X'&'0'&'X'&'X'&'0'&'0'&"11"&"0000";
            siguiente <= BNOV2;
        else
            palabra_temp <= '0' & "00"&'0'&'0'&'X'&'0'&'X'&'0'&'X'&'X'&'0'&'X'&"XX"&"XXXX";
            siguiente <= FETCH;
        end if;

    when BNOV2 =>
        palabra_temp <= '0' & "00"&'0'&'1'&'X'&'0'&'X'&'0'&'X'&'X'&'0'&'0'&"11"&"0000";
        siguiente <= FETCH;

    when NOP =>
        -- PCsel(00),EnFlags(0),EnPC(0),Mux_Addr(X),EnRAM(0),RW(X),EnIR(0),MUX_Dest(X),MUX_RData(X),EnRF(0),MUX_ALUA(X),MUX_ALUB(XX),ALU_Op(XXXX)
        -- No operation - NO MOSTRAR
        palabra_temp <= '0' & "00"&'0'&'0'&'X'&'0'&'X'&'0'&'X'&'X'&'0'&'X'&"XX"&"XXXX";
        siguiente <= FETCH;

    when HALT =>
        -- PCsel(00),EnFlags(0),EnPC(0),Mux_Addr(X),EnRAM(0),RW(X),EnIR(0),MUX_Dest(X),MUX_RData(X),EnRF(0),MUX_ALUA(X),MUX_ALUB(XX),ALU_Op(XXXX)
        -- Detiene la ejecución manteniéndose en este estado - NO MOSTRAR
        estados<="0000";
        palabra_temp <= '0' & "00"&'0'&'0'&'X'&'0'&'X'&'0'&'X'&'X'&'0'&'X'&"XX"&"XXXX";
        siguiente <= HALT;
    when DISP =>
        -- Muestra el valor de RF(A) en el display y continúa.
        -- Habilita el latch del display (Display_En = '1').
        estados <= "1111"; -- (LEDs indican estado DISP)
        --                Display_En|PC_sel|EnFlags|EnPC |Mux_Addr|EnRAM|RW   |EnIR |MUX_Dest|MUX_RData|EnRF |MUX_ALUA|MUX_ALUB|ALU_Op
        palabra_temp <= '1' &       "00" & '0' &   '0' & 'X' &    '0' & 'X' & '0' & 'X' &    'X' &     '0' & 'X' &    "XX" &  "XXXX";
        siguiente <= FETCH;

    when others =>
        -- PCsel(00),EnFlags(0),EnPC(0),Mux_Addr(X),EnRAM(0),RW(X),EnIR(0),MUX_Dest(X),MUX_RData(X),EnRF(0),MUX_ALUA(X),MUX_ALUB(XX),ALU_Op(XXXX)
        -- Estado por defecto: vuelve a FETCH - NO MOSTRAR
        palabra_temp <= '0' & "00"&'0'&'0'&'X'&'0'&'X'&'0'&'X'&'X'&'0'&'X'&"XX"&"XXXX";
        siguiente <= FETCH;

end case;
    end process;

process(Instruction)
begin
 opcode <= Instruction(23 downto 16);
      opcode_int <= to_integer(unsigned(opcode));
end process;

-- Asignación concurrente de la palabra de control a las salidas
    Display_En <= palabra_temp(18);  -- NUEVO BIT
    PC_sel<= palabra_temp(17 downto 16);
    EnFlags<= palabra_temp(15);
    EnPC     <= palabra_temp(14);
    Mux_Addr <= palabra_temp(13);
    EnRAM    <= palabra_temp(12);
    RW       <= palabra_temp(11);
    EnIR     <= palabra_temp(10);
    MUX_Dest <= palabra_temp(9);
    MUX_RData<= palabra_temp(8);
    EnRF     <= palabra_temp(7);
    MUX_ALUA <= palabra_temp(6);
    MUX_ALUB <= palabra_temp(5 downto 4);
    ALU_Op   <= palabra_temp(3 downto 0);
    

end Behavioral;