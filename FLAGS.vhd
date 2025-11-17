library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity FlagReg is
port(
    OvF_in  : in  std_logic;
    ZF_in   : in  std_logic;
    SF_in   : in  std_logic;
    CF_in   : in  std_logic;
    clk     : in  std_logic;
    reset   : in  std_logic;
    EnFlags : in  std_logic;
    OvF_out : out std_logic;
    ZF_out  : out std_logic;
    SF_out  : out std_logic;
    CF_out  : out std_logic
);
end FlagReg;

architecture Behavioral of FlagReg is
    signal ovf_reg : std_logic := '0';
    signal zf_reg  : std_logic := '0';
    signal sf_reg  : std_logic := '0';
    signal cf_reg  : std_logic := '0';
begin

    process(clk, reset)
    begin
        if reset = '0' then
            ovf_reg <= '0';
            zf_reg  <= '0';
            sf_reg  <= '0';
            cf_reg  <= '0';
        elsif rising_edge(clk) then
            if EnFlags = '1' then
                ovf_reg <= OvF_in;
                zf_reg  <= ZF_in;
                sf_reg  <= SF_in;
                cf_reg  <= CF_in;
            end if;
        end if;
    end process;

    OvF_out <= ovf_reg;
    ZF_out  <= zf_reg;
    SF_out  <= sf_reg;
    CF_out  <= cf_reg;

end Behavioral;