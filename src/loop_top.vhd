----------------------------------------------------------------------------------
-- CMS Muon Endcap
-- GEM Collaboration
-- ME0 -- ASIGO Loopback
-- A. Peck
----------------------------------------------------------------------------------
-- Description:
--
----------------------------------------------------------------------------------
-- 2019/11/29 -- Initial
----------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_misc.all;
use ieee.numeric_std.all;

library unisim;
use unisim.vcomponents.all;

entity loop_top is
generic (
    g_NUM_VFATS : integer := 2
);
port(
    clock_in_p  : in  std_logic_vector (  g_NUM_VFATS-1 downto 0);
    clock_in_n  : in  std_logic_vector (  g_NUM_VFATS-1 downto 0);
    rx_in_p     : in  std_logic_vector (  g_NUM_VFATS-1 downto 0);
    rx_in_n     : in  std_logic_vector (  g_NUM_VFATS-1 downto 0);
    tx_out_p    : out std_logic_vector (  g_NUM_VFATS-1 downto 0);
    tx_out_n    : out std_logic_vector (  g_NUM_VFATS-1 downto 0);
    trig_out_p  : out std_logic_vector (8*g_NUM_VFATS-1 downto 0);
    trig_out_n  : out std_logic_vector (8*g_NUM_VFATS-1 downto 0);
    sot_out_p   : out std_logic_vector (  g_NUM_VFATS-1 downto 0);
    sot_out_n   : out std_logic_vector (  g_NUM_VFATS-1 downto 0);
    reset_in    : in  std_logic_vector (  g_NUM_VFATS-1 downto 0); -- use external (resistive) voltage divider to shift to SSTL range
    fpga_id     : in std_logic_vector  (1 downto 0);               -- use external (resistive) voltage divider to shift to SSTL range
    mux_control : out std_logic                                    -- configure as open-drain, drive with OBUFT, pull-up to 1.2V
);
end loop_top;

architecture Behavioral of loop_top is
    signal clock40 : std_logic_vector (g_NUM_VFATS-1 downto 0);
    signal clock160 : std_logic_vector (g_NUM_VFATS-1 downto 0);
    signal mmcm_locked : std_logic_vector (g_NUM_VFATS-1 downto 0);
begin

    VFAT_LOOP : for I in 0 to g_NUM_VFATS-1 generate
    begin

        -- clock mmcm

        -- require all clocks to lock but only use the first one for actual
        -- clocking, since the others might not be able to use dedicated routing
        -- due to placement constraints
        u_loopback_clock_wizard : entity work.loopback_clock_wizard
        port map (
            -- Clock in ports
            clk_in1_p => clock_in_p(I),
            clk_in1_n => clock_in_n(I),
            -- Clock out ports
            clk40_o  => clock40(I),
            clk160_o => clock160(I),
            -- Status and control signals
            reset  => or_reduce(reset_in),
            locked => mmcm_locked(I)
        );

        u_vfat_loopback : entity work.vfat_loopback
        generic map (
            g_VFAT_ID   => I,
            g_NUM_VFATS => g_NUM_VFATS
        )
        port map (
            clock40     => clock40 (0),
            clock160    => clock160 (0),
            mmcm_locked => and_reduce (mmcm_locked),
            rx_in_p     => rx_in_p    (I),
            rx_in_n     => rx_in_n    (I),
            tx_out_p    => tx_out_p   (I),
            tx_out_n    => tx_out_n   (I),
            trig_out_p  => trig_out_p ((I+1)*8-1 downto I*8),
            trig_out_n  => trig_out_n ((I+1)*8-1 downto I*8),
            sot_out_p   => sot_out_p  (I),
            sot_out_n   => sot_out_n  (I),
            fpga_id     => fpga_id,
            reset_in    => reset_in   (I)
        );
    end generate;

    mux_control <= or_reduce(reset_in);

end Behavioral;
