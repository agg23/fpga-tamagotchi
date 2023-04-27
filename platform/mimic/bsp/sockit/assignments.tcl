# ==============================================================================
# SPDX-License-Identifier: CC0-1.0
# SPDX-FileType: SOURCE
# SPDX-FileCopyrightText: (c) 2022, OpenGateware authors and contributors
# ==============================================================================
#
# Platform Global/Location/Instance Assignments
#
# ==============================================================================
# Hardware Information
# ==============================================================================
set_global_assignment -name FAMILY "Cyclone V"
set_global_assignment -name DEVICE 5CSXFC6D6F31C6
set_global_assignment -name DEVICE_FILTER_PACKAGE FBGA
set_global_assignment -name DEVICE_FILTER_PIN_COUNT 896
set_global_assignment -name DEVICE_FILTER_SPEED_GRADE 6_H6

# ==============================================================================
# Hardware Parameters
# ==============================================================================
set_parameter -name MIMIC_DEVICE_ID "sockit"
set_parameter -name MIMIC_DEVICE_NAME "Arrow SoCKit"
set_parameter -name MIMIC_DEVICE_HAS_SOC ON

# ==============================================================================
# Classic Timing Assignments
# ==============================================================================
set_global_assignment -name MIN_CORE_JUNCTION_TEMP 0
set_global_assignment -name MAX_CORE_JUNCTION_TEMP 85
set_global_assignment -name TIMEQUEST_MULTICORNER_ANALYSIS ON

# ==============================================================================
# Assembler Assignments
# ==============================================================================
set_global_assignment -name GENERATE_RBF_FILE ON

# ==============================================================================
# Power Estimation Assignments
# ==============================================================================
set_global_assignment -name POWER_PRESET_COOLING_SOLUTION "23 MM HEAT SINK WITH 200 LFPM AIRFLOW"
set_global_assignment -name POWER_BOARD_THERMAL_MODEL "NONE (CONSERVATIVE)"

# ==============================================================================
# Scripts
# ==============================================================================
set_global_assignment -name PRE_FLOW_SCRIPT_FILE "quartus_sh:../platform/mimic/scripts/pre-flow.tcl"
set_global_assignment -name POST_FLOW_SCRIPT_FILE "quartus_sh:../platform/mimic/scripts/post-flow.tcl"

# ==============================================================================
# System Top Level and Constrains
# ==============================================================================
set_global_assignment -name SYSTEMVERILOG_FILE "../platform/mimic/bsp/sockit/sys_top.sv"
set_global_assignment -name SDC_FILE           "../platform/mimic/constraints/sockit.sdc"

# ==============================================================================
# Framework Files
# ==============================================================================
set_global_assignment -name QIP_FILE "../platform/mimic/index.qip"
set_global_assignment -name QIP_FILE "../target/mimic/core.qip"

# ==============================================================================
# Clock Circuitry
# ==============================================================================
set_location_assignment PIN_Y26  -to FPGA_CLK1_50
set_location_assignment PIN_AA16 -to FPGA_CLK2_50
set_location_assignment PIN_AF14 -to FPGA_CLK3_50
set_location_assignment PIN_K14  -to FPGA_CLK4_50

set_instance_assignment -name IO_STANDARD "2.5 V" -to FPGA_CLK1_50
set_instance_assignment -name IO_STANDARD "1.5 V" -to FPGA_CLK2_50
set_instance_assignment -name IO_STANDARD "1.5 V" -to FPGA_CLK3_50
set_instance_assignment -name IO_STANDARD "2.5 V" -to FPGA_CLK4_50

#============================================================
# ADC                              (DE10-nano ADC IC signals)
#============================================================
# set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to ADC_CONVST
# set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to ADC_SCK
# set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to ADC_SDI
# set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to ADC_SDO
# set_location_assignment PIN_U9 -to ADC_CONVST
# set_location_assignment PIN_V10 -to ADC_SCK
# set_location_assignment PIN_AC4 -to ADC_SDI
# set_location_assignment PIN_AD4 -to ADC_SDO

#============================================================
# ARDUINO
#============================================================
# set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to ARDUINO_IO[*]
# set_instance_assignment -name WEAK_PULL_UP_RESISTOR ON -to ARDUINO_IO[*]
# set_instance_assignment -name CURRENT_STRENGTH_NEW "MAXIMUM CURRENT" -to ARDUINO_IO[*]

#============================================================
# I2C LEDS/BUTTONS                     (DE10-nano Arduino_IO)
#============================================================
set_location_assignment PIN_C5 -to IO_SCL
set_location_assignment PIN_J12 -to IO_SDA
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to IO_S*
set_instance_assignment -name WEAK_PULL_UP_RESISTOR ON -to IO_S*
set_instance_assignment -name CURRENT_STRENGTH_NEW "MAXIMUM CURRENT" -to IO_S*

# HSMC J3 connector pin 27 HSMC_TX _n[3] PIN_C5   IO_SCL
# HSMC J3 connector pin 28 HSMC_RX _n[1] PIN_J12  IO_SDA

#============================================================
# USER PORT                            (DE10-nano Arduino_IO)
#============================================================
set_location_assignment PIN_C3 -to USER_IO[6]
set_location_assignment PIN_E4 -to USER_IO[5]
set_location_assignment PIN_E2 -to USER_IO[4]
set_location_assignment PIN_J7 -to USER_IO[3]
set_location_assignment PIN_H8 -to USER_IO[2]
set_location_assignment PIN_D4 -to USER_IO[1]
set_location_assignment PIN_H7 -to USER_IO[0]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to USER_IO[*]
set_instance_assignment -name WEAK_PULL_UP_RESISTOR ON -to USER_IO[*]
set_instance_assignment -name CURRENT_STRENGTH_NEW "MAXIMUM CURRENT" -to USER_IO[*]

# HSMC J3 connector pin 7   JOY1_B2_P9;  HSMC_TX _p[7] PIN_C3  USER_IO[6] C
# HSMC J3 connector pin 8   JOY1_B1_P6;  HSMC_RX _p[6] PIN_H8  USER_IO[2] B
# HSMC J3 connector pin 9   JOY1_UP;     HSMC_TX _n[6] PIN_D4  USER_IO[1]
# HSMC J3 connector pin 10  JOY1_DOWN;   HSMC_RX _n[5] PIN_H7  USER_IO[0]
# HSMC J3 connector pin 13  JOY1_LEFT;   HSMC_TX _p[6] PIN_E4  USER_IO[5]
# HSMC J3 connector pin 14  JOY1_RIGHT;  HSMC_RX _p[5] PIN_J7  USER_IO[3]
# HSMC J3 connector pin 15  JOYX_SEL_O;  HSMC_TX _n[5] PIN_E2  USER_IO[4]

#============================================================
# SDIO_CD or SPDIF_OUT                 (DE10-nano Arduino_IO) 
#============================================================
set_location_assignment PIN_J10 -to SDCD_SPDIF
set_instance_assignment -name CURRENT_STRENGTH_NEW "MAXIMUM CURRENT" -to SDCD_SPDIF
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to SDCD_SPDIF
set_instance_assignment -name WEAK_PULL_UP_RESISTOR ON -to SDCD_SPDIF

# HSMC J3 connector pin 22 / PMOD3[6];  HSMC_RX _p[3] PIN_J10   SDCD_SPDIF

#============================================================
# SDRAM
#============================================================
set_location_assignment PIN_B1  -to SDRAM_A[0]
set_location_assignment PIN_C2  -to SDRAM_A[1]
set_location_assignment PIN_B2  -to SDRAM_A[2]
set_location_assignment PIN_D2  -to SDRAM_A[3]
set_location_assignment PIN_D9  -to SDRAM_A[4]
set_location_assignment PIN_C7  -to SDRAM_A[5]
set_location_assignment PIN_E12 -to SDRAM_A[6]
set_location_assignment PIN_B7  -to SDRAM_A[7]
set_location_assignment PIN_D12 -to SDRAM_A[8]
set_location_assignment PIN_A11 -to SDRAM_A[9]
set_location_assignment PIN_B6  -to SDRAM_A[10]
set_location_assignment PIN_D11 -to SDRAM_A[11]
set_location_assignment PIN_A10 -to SDRAM_A[12]
set_location_assignment PIN_B5  -to SDRAM_BA[0]
set_location_assignment PIN_A4  -to SDRAM_BA[1]
set_location_assignment PIN_F14 -to SDRAM_DQ[0]
set_location_assignment PIN_G15 -to SDRAM_DQ[1]
set_location_assignment PIN_F15 -to SDRAM_DQ[2]
set_location_assignment PIN_H15 -to SDRAM_DQ[3]
set_location_assignment PIN_G13 -to SDRAM_DQ[4]
set_location_assignment PIN_A13 -to SDRAM_DQ[5]
set_location_assignment PIN_H14 -to SDRAM_DQ[6]
set_location_assignment PIN_B13 -to SDRAM_DQ[7]
set_location_assignment PIN_C13 -to SDRAM_DQ[8]
set_location_assignment PIN_C8  -to SDRAM_DQ[9]
set_location_assignment PIN_B12 -to SDRAM_DQ[10]
set_location_assignment PIN_B8  -to SDRAM_DQ[11]
set_location_assignment PIN_F13 -to SDRAM_DQ[12]
set_location_assignment PIN_C12 -to SDRAM_DQ[13]
set_location_assignment PIN_B11 -to SDRAM_DQ[14]
set_location_assignment PIN_E13 -to SDRAM_DQ[15]
set_location_assignment PIN_D10 -to SDRAM_CLK
set_location_assignment PIN_A5  -to SDRAM_nWE
set_location_assignment PIN_A6  -to SDRAM_nCAS
set_location_assignment PIN_A3  -to SDRAM_nCS
set_location_assignment PIN_E9  -to SDRAM_nRAS

set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to SDRAM_*
set_instance_assignment -name CURRENT_STRENGTH_NEW "MAXIMUM CURRENT" -to SDRAM_*
set_instance_assignment -name FAST_OUTPUT_REGISTER ON -to SDRAM_*
set_instance_assignment -name FAST_OUTPUT_ENABLE_REGISTER ON -to SDRAM_DQ[*]
set_instance_assignment -name FAST_INPUT_REGISTER ON -to SDRAM_DQ[*]
set_instance_assignment -name ALLOW_SYNCH_CTRL_USAGE OFF -to *|SDRAM_*

#DQMH/L & CKE not connected in new MiSTer SDRAM modules
set_location_assignment PIN_D1  -to SDRAM_CKE
set_location_assignment PIN_E1  -to SDRAM_DQMH
set_location_assignment PIN_E11 -to SDRAM_DQML
# HSMC J2 connector prototype area
# HSMC_TX_n[8] PIN_D1   SDRAM_CKE
# HSMC_TX_p[8] PIN_E1   SDRAM_DQMH
# HSMC_RX_n[8] PIN_E11  SDRAM_DQML
# set_location_assignment -remove -to SDRAM_DQML
# set_location_assignment -remove -to SDRAM_DQMH
# set_location_assignment -remove -to SDRAM_CKE

#============================================================
# SPI SD     (Secondary SD)            (DE10-nano Arduino_IO)    [Sockit uses SDIO for 2nd SD card]
#============================================================
# set_location_assignment PIN_AE15 -to SD_SPI_CS
# set_location_assignment PIN_AH8  -to SD_SPI_MISO
# set_location_assignment PIN_AG8  -to SD_SPI_CLK
# set_location_assignment PIN_U13  -to SD_SPI_MOSI
# set_instance_assignment -name CURRENT_STRENGTH_NEW "MAXIMUM CURRENT" -to SD_SPI*
# set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to SD_SPI*
# set_instance_assignment -name WEAK_PULL_UP_RESISTOR ON -to SD_SPI*

#============================================================
# KEY
# KEY[0] = OSD  button
# KEY[1] = USER button
#============================================================
set_location_assignment PIN_AE9  -to KEY[0]
set_location_assignment PIN_AE12 -to KEY[1]
set_location_assignment PIN_AD27 -to RESET_n

set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to KEY[0]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to KEY[1]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to RESET_n

#============================================================
# LED
#============================================================
set_location_assignment PIN_AF10 -to LED_0_USER
set_location_assignment PIN_AD10 -to LED_1_HDD
set_location_assignment PIN_AE11 -to LED_2_POWER
set_location_assignment PIN_AD7  -to LED_3_LOCKED

set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to LED_0_USER
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to LED_1_HDD
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to LED_2_POWER
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to LED_3_LOCKED

#============================================================
# SW
#============================================================
set_location_assignment PIN_W25  -to SW[0]
set_location_assignment PIN_V25  -to SW[1]
set_location_assignment PIN_AC28 -to SW[2]
set_location_assignment PIN_AC29 -to SW[3]

set_instance_assignment -name IO_STANDARD "2.5 V" -to SW[0]
set_instance_assignment -name IO_STANDARD "2.5 V" -to SW[1]
set_instance_assignment -name IO_STANDARD "2.5 V" -to SW[2]
set_instance_assignment -name IO_STANDARD "2.5 V" -to SW[3]

#============================================================
# SDIO      (Secondary SD)                 (DE10-nano GPIO 1)
#============================================================
set_location_assignment PIN_K7 -to SDIO_DAT[0]
set_location_assignment PIN_J9 -to SDIO_DAT[1]
set_location_assignment PIN_E7 -to SDIO_DAT[2]
set_location_assignment PIN_K8 -to SDIO_DAT[3]
set_location_assignment PIN_E3 -to SDIO_CMD
set_location_assignment PIN_E6 -to SDIO_CLK
set_instance_assignment -name CURRENT_STRENGTH_NEW "MAXIMUM CURRENT" -to SDIO_*

set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to SDIO_*
set_instance_assignment -name WEAK_PULL_UP_RESISTOR ON -to SDIO_DAT[*]
set_instance_assignment -name WEAK_PULL_UP_RESISTOR ON -to SDIO_CMD

# HSMC J3 connector pin 18 / PMOD3[2];  HSMC_RX_p[4]    PIN_K7  SDIO_DAT[0]
# HSMC J3 connector pin 20 / PMOD3[4];  HSMC_RX_n[3]    PIN_J9  SDIO_DAT[1]
# HSMC J3 connector pin 21 / PMOD3[5];  HSMC_CLKOUT_p1  PIN_E7  SDIO_DAT[2]
# HSMC J3 connector pin 16 / PMOD3[0];  HSMC_RX_n[4]    PIN_K8  SDIO_DAT[3]
# HSMC J3 connector pin 17 / PMOD3[1];  HSMC_TX_p[5]    PIN_E3  SDIO_CMD
# HSMC J3 connector pin 19 / PMOD3[3];  HSMC_CLKOUT_n1  PIN_E6  SDIO_CLK
# HSMC J3 connector pin 22 / PMOD3[6];  HSMC_RX_p[3]    PIN_J10 -->  SDCD_SPDIF  (sys.tcl)
# HSMC J3 connector pin 23 / PMOD3[7];  HSMC_TX_n[4]    PIN_C4  -->  not used

#============================================================
# VGA (SOCKIT BOARD)
#============================================================
set_location_assignment PIN_AG5  -to VGA_R[0]
set_location_assignment PIN_AA12 -to VGA_R[1]
set_location_assignment PIN_AB12 -to VGA_R[2]
set_location_assignment PIN_AF6  -to VGA_R[3]
set_location_assignment PIN_AG6  -to VGA_R[4]
set_location_assignment PIN_AJ2  -to VGA_R[5]
set_location_assignment PIN_AH5  -to VGA_R[6]
set_location_assignment PIN_AJ1  -to VGA_R[7]

set_location_assignment PIN_Y21  -to VGA_G[0]
set_location_assignment PIN_AA25 -to VGA_G[1]
set_location_assignment PIN_AB26 -to VGA_G[2]
set_location_assignment PIN_AB22 -to VGA_G[3]
set_location_assignment PIN_AB23 -to VGA_G[4]
set_location_assignment PIN_AA24 -to VGA_G[5]
set_location_assignment PIN_AB25 -to VGA_G[6]
set_location_assignment PIN_AE27 -to VGA_G[7]

set_location_assignment PIN_AE28 -to VGA_B[0]
set_location_assignment PIN_Y23  -to VGA_B[1]
set_location_assignment PIN_Y24  -to VGA_B[2]
set_location_assignment PIN_AG28 -to VGA_B[3]
set_location_assignment PIN_AF28 -to VGA_B[4]
set_location_assignment PIN_V23  -to VGA_B[5]
set_location_assignment PIN_W24  -to VGA_B[6]
set_location_assignment PIN_AF29 -to VGA_B[7]

set_location_assignment PIN_AD12 -to VGA_HS
set_location_assignment PIN_AC12 -to VGA_VS

set_location_assignment PIN_AG2  -to VGA_SYNC_N
set_location_assignment PIN_AH3  -to VGA_BLANK_N
set_location_assignment PIN_W20  -to VGA_CLK

set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to VGA_*
set_instance_assignment -name CURRENT_STRENGTH_NEW 8MA -to VGA_*

#============================================================
# AUDIO DELTA-SIGMA / SPDIF                (DE10-nano GPIO 1)
#============================================================
set_location_assignment PIN_D5  -to AUDIO_L
set_location_assignment PIN_G10 -to AUDIO_R
set_location_assignment PIN_F10 -to AUDIO_SPDIF
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to AUDIO_*
set_instance_assignment -name CURRENT_STRENGTH_NEW 8MA -to AUDIO_*

# HSMC J3 connector pin 24 HSMC_RX_n[2] PIN_F10  AUDIO_SPDIF
# HSMC J3 connector pin 25 HSMC_TX_p[4] PIN_D5   AUDIO_L
# HSMC J3 connector pin 26 HSMC_RX_p[2] PIN_G10  AUDIO_R

#============================================================
# AUDIO CODEC SOCKIT BOARD (I2S)
#============================================================
set_location_assignment PIN_AC27 -to AUD_ADCDAT
set_location_assignment PIN_AG30 -to AUD_ADCLRCK
set_location_assignment PIN_AE7  -to AUD_BCLK
set_location_assignment PIN_AG3  -to AUD_DACDAT
set_location_assignment PIN_AH4  -to AUD_DACLRCK
set_location_assignment PIN_AD26 -to AUD_MUTE
set_location_assignment PIN_AC9  -to AUD_XCK
set_location_assignment PIN_AH30 -to AUD_I2C_SCLK
set_location_assignment PIN_AF30 -to AUD_I2C_SDAT
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to AUD_*

#============================================================
# I/O #1                                   (DE10-nano GPIO 1)
#============================================================
set_location_assignment PIN_D6  -to LED_USER
set_location_assignment PIN_K12 -to LED_HDD
set_location_assignment PIN_F6  -to LED_POWER
# HSMC J3 connector pin 31 HSMC_TX_p[3] PIN_D6   LED_USER
# HSMC J3 connector pin 32 HSMC_RX_p[1] PIN_K12  LED_HDD
# HSMC J3 connector pin 33 HSMC_TX_n[2] PIN_F6   LED_POWER

set_location_assignment PIN_G11  -to BTN_USER
set_location_assignment PIN_G7   -to BTN_OSD
set_location_assignment PIN_AD27 -to BTN_RESET
# HSMC J3 connector pin 34 HSMC_RX_n[0] PIN_G11  BTN_USER
# HSMC J3 connector pin 35 HSMC_TX_p[2] PIN_G7   BTN_OSD
# HSMC J3 connector pin 36 HSMC_RX_p[0] PIN_G12  provision for a future external reset button
# SOCKIT KEY4 button (KEY_RESET_n)        PIN_AD27  BTN_RESET

set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to LED_*
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to BTN_*
set_instance_assignment -name WEAK_PULL_UP_RESISTOR ON -to BTN_*

# ==============================================================================
# HPS Peripherals
# ==============================================================================
set_instance_assignment -name HPS_LOCATION HPSINTERFACEPERIPHERALSPIMASTER_X52_Y72_N111 -entity sys_top -to spi
set_instance_assignment -name HPS_LOCATION HPSINTERFACEPERIPHERALUART_X52_Y67_N111 -entity sys_top -to uart
# set_instance_assignment -name HPS_LOCATION HPSINTERFACEPERIPHERALI2C_X52_Y60_N111 -entity sys_top -to hdmi_i2c
