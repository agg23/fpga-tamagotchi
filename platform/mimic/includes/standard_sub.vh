    //! Dummy Wires for usage with DE10-Standard, DE1-SoC and Arrow SoCkit
    //! HDMI
    wire        HDMI_TX_CLK;
    wire        HDMI_TX_DE;
    wire [23:0] HDMI_TX_D;
    wire        HDMI_TX_HS;
    wire        HDMI_TX_VS;
    wire        HDMI_TX_INT;
    wire        HDMI_I2C_SCL;
    wire        HDMI_I2C_SDA;
    wire        HDMI_MCLK;
    wire        HDMI_SCLK;
    wire        HDMI_LRCLK;
    wire        HDMI_I2S;

    //! VGA
    wire        VGA_EN;

    //! ADC
    wire        ADC_SCK;
    wire        ADC_SDO;
    wire        ADC_SDI;
    wire        ADC_CONVST;

    //! I/O ALT
    wire        SD_SPI_CS;
    wire        SD_SPI_MISO;
    wire        SD_SPI_CLK;
    wire        SD_SPI_MOSI;

    //! MB LED
    wire  [7:0] LED;

    //! LED Assignements
    assign LED_0_USER   = LED[0];
    assign LED_1_HDD    = LED[2];
    assign LED_2_POWER  = LED[4];
    assign LED_3_LOCKED = LED[6];

    //! VGA DAC
    assign VGA_EN = 1'b0; // enable VGA mode when VGA_EN is low
    assign SW[3]  = 1'b0; // necessary for VGA mode

    //! Audio Codec
    assign AUD_MUTE    = 1'b1;
    assign AUD_XCK     = HDMI_MCLK;
    assign AUD_DACLRCK = HDMI_LRCLK;
    assign AUD_BCLK    = HDMI_SCLK;
    assign AUD_DACDAT  = HDMI_I2S;

    // I2C audio config
    i2c_av_config #(.IC(VID_IC)) audio_config
                  (
                      .clk      ( clk_audio    ),
                      .reset_n  ( !reset       ),
                      .i2c_addr ( 8'h34        ),
                      .I2C_SCL  ( AUD_I2C_SCLK ),
                      .I2C_SDA  ( AUD_I2C_SDAT )
                  );

