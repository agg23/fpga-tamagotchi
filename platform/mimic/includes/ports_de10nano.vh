        //! CLOCK
        input  wire        FPGA_CLK1_50,
        input  wire        FPGA_CLK2_50,
        input  wire        FPGA_CLK3_50,

        //! HDMI
        output wire        HDMI_I2C_SCL,
        inout  wire        HDMI_I2C_SDA,

        output wire        HDMI_MCLK,
        output wire        HDMI_SCLK,
        output wire        HDMI_LRCLK,
        output wire        HDMI_I2S,

        output wire        HDMI_TX_CLK,
        output wire        HDMI_TX_DE,
        output wire [23:0] HDMI_TX_D,
        output wire        HDMI_TX_HS,
        output wire        HDMI_TX_VS,

        input  wire        HDMI_TX_INT,

        //! SDRAM
        output wire [12:0] SDRAM_A,
        inout  wire [15:0] SDRAM_DQ,
        output wire        SDRAM_DQML,
        output wire        SDRAM_DQMH,
        output wire        SDRAM_nWE,
        output wire        SDRAM_nCAS,
        output wire        SDRAM_nRAS,
        output wire        SDRAM_nCS,
        output wire  [1:0] SDRAM_BA,
        output wire        SDRAM_CLK,
        output wire        SDRAM_CKE,

    `ifdef MISTER_DUAL_SDRAM
        //! SDRAM #2
        output wire [12:0] SDRAM2_A,
        inout  wire [15:0] SDRAM2_DQ,
        output wire        SDRAM2_nWE,
        output wire        SDRAM2_nCAS,
        output wire        SDRAM2_nRAS,
        output wire        SDRAM2_nCS,
        output wire  [1:0] SDRAM2_BA,
        output wire        SDRAM2_CLK,
    `else
        //! VGA
        output wire  [5:0] VGA_R,
        output wire  [5:0] VGA_G,
        output wire  [5:0] VGA_B,
        inout  wire        VGA_HS,  // VGA_HS is secondary SD card detect when VGA_EN = 1 (inactive)
        output wire        VGA_VS,
        input  wire        VGA_EN,  // active low

        //! AUDIO
        output wire        AUDIO_L,
        output wire        AUDIO_R,
        output wire        AUDIO_SPDIF,

        //! SDIO
        inout  wire  [3:0] SDIO_DAT,
        inout  wire        SDIO_CMD,
        output wire        SDIO_CLK,

        //! I/O
        output wire        LED_USER,
        output wire        LED_HDD,
        output wire        LED_POWER,
        input  wire        BTN_USER,
        input  wire        BTN_OSD,
        input  wire        BTN_RESET,
    `endif

        //! I/O ALT
        output wire        SD_SPI_CS,
        input  wire        SD_SPI_MISO,
        output wire        SD_SPI_CLK,
        output wire        SD_SPI_MOSI,

        inout  wire        SDCD_SPDIF,
        output wire        IO_SCL,
        inout  wire        IO_SDA,

        //! ADC
        output wire        ADC_SCK,
        input  wire        ADC_SDO,
        output wire        ADC_SDI,
        output wire        ADC_CONVST,

        //! MB KEY
        input  wire  [1:0] KEY,

        //! MB SWITCH
        input  wire  [3:0] SW,

        //! MB LED
        output wire  [7:0] LED,

        //! USER IO
        inout  wire  [6:0] USER_IO