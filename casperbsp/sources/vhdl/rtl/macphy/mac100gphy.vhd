--------------------------------------------------------------------------------
-- Company          : Kutleng Dynamic Electronics Systems (Pty) Ltd            -
-- Engineer         : Benjamin Hector Hlophe                                   -
--                                                                             -
-- Design Name      : CASPER BSP                                               -
-- Module Name      : mac100gphy - rtl                                         -
-- Project Name     : SKARAB2                                                  -
-- Target Devices   : N/A                                                      -
-- Tool Versions    : N/A                                                      -
-- Description      : This module instantiates one QSFP28+ ports with CMACs.   -
-- Dependencies     : gmacqsfp1top,gmacqsfp2top                                -
-- Revision History : V1.0 - Initial design                                    -
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

entity mac100gphy is
    generic(
        C_MAC_INSTANCE             : natural range 0 to 3 := 0;
        C_COURSE_PACKET_THROTTLING : boolean              := false;
        C_USE_RS_FEC : boolean := false;
        -- Number GTYE4_COMMON primitives to be instanced, for hardware layouts (like zcu216) using 2GTY per quad across 2 quads
        C_N_COMMON : natural range 1 to 2 := 1
    );
    port(
        -- Ethernet reference clock for 156.25MHz
        -- QSFP+ 
        mgt_qsfp_clock_p             : in  STD_LOGIC;
        mgt_qsfp_clock_n             : in  STD_LOGIC;
        --RX     
        qsfp_mgt_rx_p                : in  STD_LOGIC_VECTOR(3 downto 0);
        qsfp_mgt_rx_n                : in  STD_LOGIC_VECTOR(3 downto 0);
        -- TX
        qsfp_mgt_tx_p                : out STD_LOGIC_VECTOR(3 downto 0);
        qsfp_mgt_tx_n                : out STD_LOGIC_VECTOR(3 downto 0);
        -- Reference clock to generate 100MHz from
        Clk100MHz                    : in  STD_LOGIC;
        ------------------------------------------------------------------------
        -- These signals/buses run at 322.265625MHz clock domain               -
        ------------------------------------------------------------------------
        -- Global System Enable
        Enable                       : in  STD_LOGIC;
        Reset                        : in  STD_LOGIC;
        DataRateBackOff              : out STD_LOGIC;
        -- incoming packet filters
        fabric_mac                   : in STD_LOGIC_VECTOR(47 downto 0);
        fabric_ip                    : in STD_LOGIC_VECTOR(31 downto 0);
        fabric_port                  : in STD_LOGIC_VECTOR(15 downto 0);
        -- Statistics interface
        gmac_reg_core_type           : out STD_LOGIC_VECTOR(31 downto 0);
        gmac_reg_phy_status_h        : out STD_LOGIC_VECTOR(31 downto 0);
        gmac_reg_phy_status_l        : out STD_LOGIC_VECTOR(31 downto 0);
        gmac_reg_phy_control_h       : in  STD_LOGIC_VECTOR(31 downto 0);
        gmac_reg_phy_control_l       : in  STD_LOGIC_VECTOR(31 downto 0);
        gmac_reg_tx_packet_rate      : out STD_LOGIC_VECTOR(31 downto 0);
        gmac_reg_tx_packet_count     : out STD_LOGIC_VECTOR(31 downto 0);
        gmac_reg_tx_valid_rate       : out STD_LOGIC_VECTOR(31 downto 0);
        gmac_reg_tx_valid_count      : out STD_LOGIC_VECTOR(31 downto 0);
        gmac_reg_rx_packet_rate      : out STD_LOGIC_VECTOR(31 downto 0);
        gmac_reg_rx_packet_count     : out STD_LOGIC_VECTOR(31 downto 0);
        gmac_reg_rx_valid_rate       : out STD_LOGIC_VECTOR(31 downto 0);
        gmac_reg_rx_valid_count      : out STD_LOGIC_VECTOR(31 downto 0);
        gmac_reg_rx_bad_packet_count : out STD_LOGIC_VECTOR(31 downto 0);
        gmac_reg_counters_reset      : in  STD_LOGIC;
        -- Lbus and AXIS
        lbus_reset                   : in  STD_LOGIC;
        -- Overflow signal
        lbus_tx_ovfout               : out STD_LOGIC;
        -- Underflow signal
        lbus_tx_unfout               : out STD_LOGIC;
        -- AXIS Bus
        -- RX Bus
        axis_rx_clkin                : in  STD_LOGIC;
        axis_rx_tdata                : in  STD_LOGIC_VECTOR(511 downto 0);
        axis_rx_tvalid               : in  STD_LOGIC;
        axis_rx_tready               : out STD_LOGIC;
        axis_rx_tkeep                : in  STD_LOGIC_VECTOR(63 downto 0);
        axis_rx_tlast                : in  STD_LOGIC;
        axis_rx_tuser                : in  STD_LOGIC;
        -- TX Bus
        axis_tx_clkout               : out STD_LOGIC;
        axis_tx_tdata                : out STD_LOGIC_VECTOR(511 downto 0);
        axis_tx_tvalid               : out STD_LOGIC;
        axis_tx_tkeep                : out STD_LOGIC_VECTOR(63 downto 0);
        axis_tx_tlast                : out STD_LOGIC;
        -- User signal for errors and dropping of packets
        axis_tx_tuser                : out STD_LOGIC;

        yellow_block_user_clk    : in STD_LOGIC;
        yellow_block_rx_data     : out  STD_LOGIC_VECTOR(511 downto 0);
        yellow_block_rx_valid    : out  STD_LOGIC;
        yellow_block_rx_eof      : out  STD_LOGIC;
        yellow_block_rx_overrun  : out STD_LOGIC
    );
end entity mac100gphy;

architecture rtl of mac100gphy is
    component gmacqsfptop is
    generic(
        C_USE_RS_FEC : boolean := false;
        C_INST_ID : integer;
        C_N_COMMON : natural range 1 to 2 := 1
    );
        port(
            -- Reference clock to generate 100MHz from
            Clk100MHz                    : in  STD_LOGIC;
            -- Ethernet reference clock for 156.25MHz
            -- QSFP+ 
            mgt_qsfp_clock_p             : in  STD_LOGIC;
            mgt_qsfp_clock_n             : in  STD_LOGIC;
            -- incoming packet filters
            fabric_mac                   : in STD_LOGIC_VECTOR(47 downto 0);
            fabric_ip                    : in STD_LOGIC_VECTOR(31 downto 0);
            fabric_port                  : in STD_LOGIC_VECTOR(15 downto 0);
            --RX     
            qsfp_mgt_rx_p                : in  STD_LOGIC_VECTOR(3 downto 0);
            qsfp_mgt_rx_n                : in  STD_LOGIC_VECTOR(3 downto 0);
            -- TX
            qsfp_mgt_tx_p                : out STD_LOGIC_VECTOR(3 downto 0);
            qsfp_mgt_tx_n                : out STD_LOGIC_VECTOR(3 downto 0);
            ------------------------------------------------------------------------
            -- These signals/buses run at 322.265625MHz clock domain.              -
            ------------------------------------------------------------------------
            -- Global System Enable
            Enable                       : in  STD_LOGIC;
            Reset                        : in  STD_LOGIC;
            -- Statistics interface            
            gmac_reg_core_type           : out STD_LOGIC_VECTOR(31 downto 0);
            gmac_reg_phy_status_h        : out STD_LOGIC_VECTOR(31 downto 0);
            gmac_reg_phy_status_l        : out STD_LOGIC_VECTOR(31 downto 0);
            gmac_reg_phy_control_h       : in  STD_LOGIC_VECTOR(31 downto 0);
            gmac_reg_phy_control_l       : in  STD_LOGIC_VECTOR(31 downto 0);
            gmac_reg_tx_packet_rate      : out STD_LOGIC_VECTOR(31 downto 0);
            gmac_reg_tx_packet_count     : out STD_LOGIC_VECTOR(31 downto 0);
            gmac_reg_tx_valid_rate       : out STD_LOGIC_VECTOR(31 downto 0);
            gmac_reg_tx_valid_count      : out STD_LOGIC_VECTOR(31 downto 0);
            gmac_reg_rx_packet_rate      : out STD_LOGIC_VECTOR(31 downto 0);
            gmac_reg_rx_packet_count     : out STD_LOGIC_VECTOR(31 downto 0);
            gmac_reg_rx_valid_rate       : out STD_LOGIC_VECTOR(31 downto 0);
            gmac_reg_rx_valid_count      : out STD_LOGIC_VECTOR(31 downto 0);
            gmac_reg_rx_bad_packet_count : out STD_LOGIC_VECTOR(31 downto 0);
            gmac_reg_counters_reset      : in  STD_LOGIC;
            -- Lbus and AXIS
            -- This bus runs at 322.265625MHz
            lbus_reset                   : in  STD_LOGIC;
            -- Overflow signal
            lbus_tx_ovfout               : out STD_LOGIC;
            -- Underflow signal
            lbus_tx_unfout               : out STD_LOGIC;
            -- AXIS Bus
            -- RX Bus
            axis_rx_clkin                : in  STD_LOGIC;
            axis_rx_tdata                : in  STD_LOGIC_VECTOR(511 downto 0);
            axis_rx_tvalid               : in  STD_LOGIC;
            axis_rx_tready               : out STD_LOGIC;
            axis_rx_tkeep                : in  STD_LOGIC_VECTOR(63 downto 0);
            axis_rx_tlast                : in  STD_LOGIC;
            axis_rx_tuser                : in  STD_LOGIC;
            -- TX Bus
            axis_tx_clkout               : out STD_LOGIC;
            axis_tx_tdata                : out STD_LOGIC_VECTOR(511 downto 0);
            axis_tx_tvalid               : out STD_LOGIC;
            axis_tx_tkeep                : out STD_LOGIC_VECTOR(63 downto 0);
            axis_tx_tlast                : out STD_LOGIC;
            -- User signal for errors and dropping of packets
            axis_tx_tuser                : out STD_LOGIC;
            yellow_block_user_clk    : in STD_LOGIC;
            yellow_block_rx_data     : out  STD_LOGIC_VECTOR(511 downto 0);
            yellow_block_rx_valid    : out  STD_LOGIC;
            yellow_block_rx_eof      : out  STD_LOGIC;
            yellow_block_rx_overrun  : out STD_LOGIC
        );
    end component gmacqsfptop;
    component macaxisdecoupler is
        port(
            axis_tx_clk       : in  STD_LOGIC;
            axis_rx_clk       : in  STD_LOGIC;
            axis_reset        : in  STD_LOGIC;
            DataRateBackOff   : in  STD_LOGIC;
            TXOverFlowCount   : out STD_LOGIC_VECTOR(31 downto 0);
            TXAlmostFullCount : out STD_LOGIC_VECTOR(31 downto 0);
            --Outputs to AXIS bus MAC side 
            axis_tx_tdata     : out STD_LOGIC_VECTOR(511 downto 0);
            axis_tx_tvalid    : out STD_LOGIC;
            axis_tx_tready    : in  STD_LOGIC;
            axis_tx_tuser     : out STD_LOGIC;
            axis_tx_tkeep     : out STD_LOGIC_VECTOR(63 downto 0);
            axis_tx_tlast     : out STD_LOGIC;
            --Inputs from AXIS bus of the MAC side
            axis_rx_tready    : out STD_LOGIC;
            axis_rx_tdata     : in  STD_LOGIC_VECTOR(511 downto 0);
            axis_rx_tvalid    : in  STD_LOGIC;
            axis_rx_tuser     : in  STD_LOGIC;
            axis_rx_tkeep     : in  STD_LOGIC_VECTOR(63 downto 0);
            axis_rx_tlast     : in  STD_LOGIC
        );
    end component macaxisdecoupler;
    component axispacketbufferfifo
        port(
            s_aclk         : IN  STD_LOGIC;
            s_aresetn      : IN  STD_LOGIC;
            s_axis_tvalid  : IN  STD_LOGIC;
            s_axis_tready  : OUT STD_LOGIC;
            s_axis_tdata   : IN  STD_LOGIC_VECTOR(511 DOWNTO 0);
            s_axis_tkeep   : IN  STD_LOGIC_VECTOR(63 DOWNTO 0);
            s_axis_tlast   : IN  STD_LOGIC;
            s_axis_tuser   : IN  STD_LOGIC_VECTOR(0 DOWNTO 0);
            m_axis_tvalid  : OUT STD_LOGIC;
            m_axis_tready  : IN  STD_LOGIC;
            m_axis_tdata   : OUT STD_LOGIC_VECTOR(511 DOWNTO 0);
            m_axis_tkeep   : OUT STD_LOGIC_VECTOR(63 DOWNTO 0);
            m_axis_tlast   : OUT STD_LOGIC;
            m_axis_tuser   : OUT STD_LOGIC_VECTOR(0 DOWNTO 0);
            axis_prog_full : OUT STD_LOGIC
        );
    end component axispacketbufferfifo;

    component axis_stream_data_tx_ila is
        port(
            clk    : in STD_LOGIC;
            probe0 : in STD_LOGIC_VECTOR(511 downto 0);
            probe1 : in STD_LOGIC_VECTOR(63 downto 0);
            probe2 : in STD_LOGIC_VECTOR(0 to 0);
            probe3 : in STD_LOGIC_VECTOR(0 to 0);
            probe4 : in STD_LOGIC_VECTOR(0 to 0);
            probe5 : in STD_LOGIC_VECTOR(0 to 0);
            probe6 : in STD_LOGIC_VECTOR(0 to 0)
        );
    end component axis_stream_data_tx_ila;
    signal axis_tdata       : STD_LOGIC_VECTOR(511 downto 0);
    signal axis_tvalid      : STD_LOGIC;
    signal axis_tready      : STD_LOGIC;
    signal axis_tkeep       : STD_LOGIC_VECTOR(63 downto 0);
    signal axis_tlast       : STD_LOGIC;
    signal axis_tuser       : STD_LOGIC;
    signal axis_cp_tdata    : STD_LOGIC_VECTOR(511 downto 0);
    signal axis_cp_tvalid   : STD_LOGIC;
    signal axis_cp_tready   : STD_LOGIC;
    signal axis_cp_tkeep    : STD_LOGIC_VECTOR(63 downto 0);
    signal axis_cp_tlast    : STD_LOGIC;
    signal axis_cp_tuser    : STD_LOGIC;
    signal laxis_tx_clk     : STD_LOGIC;
    signal lDataRateBackOff : STD_LOGIC;
    signal ResetN           : STD_LOGIC;

begin
    ResetN          <= not Reset;
    DataRateBackOff <= lDataRateBackOff;

    axis_tx_clkout <= laxis_tx_clk;
    Throttle_false_i : if (C_COURSE_PACKET_THROTTLING = false) generate
    begin
        ------------------------------------------------------------------------
        -- Here we generate a simple packet decoupling FIFO buffer.           -- 
        -- This buffer will have very fine packet throttling through tready.  -- 
        ------------------------------------------------------------------------
        AXISPAcketBufferFIFO_i : axispacketbufferfifo
            PORT MAP(
                s_aclk          => laxis_tx_clk,
                s_aresetn       => ResetN,
                s_axis_tvalid   => axis_rx_tvalid,
                s_axis_tready   => axis_rx_tready,
                s_axis_tdata    => axis_rx_tdata,
                s_axis_tkeep    => axis_rx_tkeep,
                s_axis_tlast    => axis_rx_tlast,
                s_axis_tuser(0) => axis_rx_tuser,
                m_axis_tvalid   => axis_tvalid,
                m_axis_tready   => axis_tready,
                m_axis_tdata    => axis_tdata,
                m_axis_tkeep    => axis_tkeep,
                m_axis_tlast    => axis_tlast,
                m_axis_tuser(0) => axis_tuser,
                axis_prog_full  => lDataRateBackOff
            );
    end generate;

    Throttle_true_i : if (C_COURSE_PACKET_THROTTLING = true) generate
        ------------------------------------------------------------------------
        -- Here we generate a course packet decoupling FIFO buffer.           -- 
        -- This buffer will have course packet throttling through the use of  --         
        -- lDataRateBackOff. The incoming data will only be injested as whole --
        -- packets delimited by TLAST. TREADY will never toggle to control    --
        -- packet rate.                                                       --
        ------------------------------------------------------------------------        
        AXISPAcketBufferFIFO_i : axispacketbufferfifo
            PORT MAP(
                s_aclk          => laxis_tx_clk,
                s_aresetn       => ResetN,
                s_axis_tvalid   => axis_cp_tvalid,
                s_axis_tready   => axis_cp_tready,
                s_axis_tdata    => axis_cp_tdata,
                s_axis_tkeep    => axis_cp_tkeep,
                s_axis_tlast    => axis_cp_tlast,
                s_axis_tuser(0) => axis_cp_tuser,
                m_axis_tvalid   => axis_tvalid,
                m_axis_tready   => axis_tready,
                m_axis_tdata    => axis_tdata,
                m_axis_tkeep    => axis_tkeep,
                m_axis_tlast    => axis_tlast,
                m_axis_tuser(0) => axis_tuser,
                axis_prog_full  => lDataRateBackOff
            );

        DecouplerIlAi : axis_stream_data_tx_ila
            port map(
                clk       => laxis_tx_clk,
                probe0    => axis_tdata,
                probe1    => axis_tkeep,
                probe2(0) => axis_tready,
                probe3(0) => axis_tlast,
                probe4(0) => axis_tuser,
                probe5(0) => axis_tvalid,
                probe6(0) => lDataRateBackOff
            );

        AXISDecoupleri : macaxisdecoupler
            port map(
                axis_tx_clk       => laxis_tx_clk,
                axis_rx_clk       => axis_rx_clkin,
                axis_reset        => Reset,
                DataRateBackOff   => lDataRateBackOff,
                TXOverFlowCount   => open,
                TXAlmostFullCount => open,
                axis_tx_tdata     => axis_cp_tdata,
                axis_tx_tvalid    => axis_cp_tvalid,
                axis_tx_tready    => axis_cp_tready,
                axis_tx_tuser     => axis_cp_tuser,
                axis_tx_tkeep     => axis_cp_tkeep,
                axis_tx_tlast     => axis_cp_tlast,
                axis_rx_tready    => axis_rx_tready,
                axis_rx_tdata     => axis_rx_tdata,
                axis_rx_tvalid    => axis_rx_tvalid,
                axis_rx_tuser     => axis_rx_tuser,
                axis_rx_tkeep     => axis_rx_tkeep,
                axis_rx_tlast     => axis_rx_tlast
            );

    end generate;

    assert C_MAC_INSTANCE > 3 report "Error bad C_MAC_INSTANCE = " & integer'image(C_MAC_INSTANCE) severity failure;

    CMAC0_i : gmacqsfptop
        generic map(
            C_USE_RS_FEC => C_USE_RS_FEC,
            C_INST_ID => C_MAC_INSTANCE,
            C_N_COMMON  => C_N_COMMON
        )
        port map(
            Clk100MHz                    => Clk100MHz,
            Enable                       => Enable,
            Reset                        => Reset,
            fabric_mac                   => fabric_mac,
            fabric_ip                    => fabric_ip,
            fabric_port                  => fabric_port,
            mgt_qsfp_clock_p             => mgt_qsfp_clock_p,
            mgt_qsfp_clock_n             => mgt_qsfp_clock_n,
            qsfp_mgt_rx_p                => qsfp_mgt_rx_p,
            qsfp_mgt_rx_n                => qsfp_mgt_rx_n,
            qsfp_mgt_tx_p                => qsfp_mgt_tx_p,
            qsfp_mgt_tx_n                => qsfp_mgt_tx_n,
            gmac_reg_core_type           => gmac_reg_core_type,
            gmac_reg_phy_status_h        => gmac_reg_phy_status_h,
            gmac_reg_phy_status_l        => gmac_reg_phy_status_l,
            gmac_reg_phy_control_h       => gmac_reg_phy_control_h,
            gmac_reg_phy_control_l       => gmac_reg_phy_control_l,
            gmac_reg_tx_packet_rate      => gmac_reg_tx_packet_rate,
            gmac_reg_tx_packet_count     => gmac_reg_tx_packet_count,
            gmac_reg_tx_valid_rate       => gmac_reg_tx_valid_rate,
            gmac_reg_tx_valid_count      => gmac_reg_tx_valid_count,
            gmac_reg_rx_packet_rate      => gmac_reg_rx_packet_rate,
            gmac_reg_rx_packet_count     => gmac_reg_rx_packet_count,
            gmac_reg_rx_valid_rate       => gmac_reg_rx_valid_rate,
            gmac_reg_rx_valid_count      => gmac_reg_rx_valid_count,
            gmac_reg_rx_bad_packet_count => gmac_reg_rx_bad_packet_count,
            gmac_reg_counters_reset      => gmac_reg_counters_reset,
            lbus_reset                   => lbus_reset,
            lbus_tx_ovfout               => lbus_tx_ovfout,
            lbus_tx_unfout               => lbus_tx_unfout,
            axis_rx_clkin                => axis_rx_clkin,
            axis_rx_tdata                => axis_tdata,
            axis_rx_tvalid               => axis_tvalid,
            axis_rx_tready               => axis_tready,
            axis_rx_tkeep                => axis_tkeep,
            axis_rx_tlast                => axis_tlast,
            axis_rx_tuser                => axis_tuser,
            axis_tx_clkout               => laxis_tx_clk,
            axis_tx_tdata                => axis_tx_tdata,
            axis_tx_tvalid               => axis_tx_tvalid,
            axis_tx_tkeep                => axis_tx_tkeep,
            axis_tx_tlast                => axis_tx_tlast,
            axis_tx_tuser                => axis_tx_tuser,
            yellow_block_user_clk        => yellow_block_user_clk,
            yellow_block_rx_data         => yellow_block_rx_data,
            yellow_block_rx_valid        => yellow_block_rx_valid,
            yellow_block_rx_eof          => yellow_block_rx_eof,
            yellow_block_rx_overrun      => yellow_block_rx_overrun
        );

end architecture rtl;
