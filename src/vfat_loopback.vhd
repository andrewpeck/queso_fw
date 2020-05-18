library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_misc.all;
use ieee.numeric_std.all;

library unisim;
use unisim.vcomponents.all;

entity vfat_loopback is
generic (
   g_NUM_VFATS : integer := 0;
   g_VFAT_ID   : integer := 0
);
port(

    clock40     : in std_logic;
    clock160    : in std_logic;
    mmcm_locked : in std_logic;
    fpga_id     : in  std_logic_vector (1 downto 0);

    rx_in_p    : in  std_logic;
    rx_in_n    : in  std_logic;
    tx_out_p   : out std_logic;
    tx_out_n   : out std_logic;
    trig_out_p : out std_logic_vector (8-1 downto 0);
    trig_out_n : out std_logic_vector (8-1 downto 0);
    sot_out_p  : out std_logic;
    sot_out_n  : out std_logic;
    reset_in   : in std_logic
);
end vfat_loopback;

architecture Behavioral of vfat_loopback is

    signal rx_in    : std_logic;
    signal tx_out   : std_logic;
    signal trig_out : std_logic_vector (7 downto 0);
    signal sot_out  : std_logic;
    signal reset    : std_logic;

    type t_std8_array is array(integer range <>) of std_logic_vector(7 downto 0);

    signal data_in : std_logic_vector (7 downto 0);

    signal data_out_p : std_logic_vector (9 downto 0);
    signal data_out_n : std_logic_vector (9 downto 0);

    signal data_xform_mask : t_std8_array (6*10-1 downto 0);

begin

    reset <= not mmcm_locked or reset_in;

    -- input serdes

    u_input_from_lpgbt : entity work.input_from_lpgbt
    port map (
        data_in_from_pins_p(0) => rx_in_p,
        data_in_from_pins_n(0) => rx_in_n,
        data_in_to_device     => data_in,
        bitslip(0)            => '0',
        clk_in                => clock160,
        clk_div_in            => clock40,
        io_reset              => reset
    );

    -- output serdes


    oserdes_loop : for I in 0 to 9 generate
    begin
        u_output_to_lpgbt : entity work.output_to_lpgbt
        port map (
            -- transform data on each line so that we can be sure there aren't shorts/opens
            -- also make sure it is different for each VFAT... we want EVERY line to be a different data stream
            data_out_from_device  => data_in xor std_logic_vector(to_unsigned(10*g_NUM_VFATS*to_integer(unsigned(fpga_id)) + 10*g_VFAT_ID + I,8)),
            data_out_to_pins_p(0) => data_out_p(I),
            data_out_to_pins_n(0) => data_out_n(I),
            clk_in                => clock160,
            clk_div_in            => clock40,
            io_reset              => reset
        );
    end generate;

    trig_out_p <= data_out_p(7 downto 0);
    trig_out_n <= data_out_n(7 downto 0);

    sot_out_p  <= data_out_p(8);
    sot_out_n  <= data_out_n(8);

    tx_out_p   <= data_out_p(9);
    tx_out_n   <= data_out_n(9);

end Behavioral;
