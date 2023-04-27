//------------------------------------------------------------------------------
// SPDX-License-Identifier: GPL-3.0-or-later
// SPDX-FileType: SOURCE
// SPDX-FileCopyrightText: (c) 2023, OpenGateware authors and contributors
//------------------------------------------------------------------------------
//
// AV Config via I2C
// Copyright (c) 2023 Marcus Andrade <marcus@opengateware.org>
//
// This source file is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published
// by the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful, but
// WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
// General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program. If not, see <http://www.gnu.org/licenses/>.
//
//------------------------------------------------------------------------------
// IC: 7513 | Slave address 0x39 | Chip: ADV7513 (HDMI-TX)
// IC: 7123 | Slave address 0x34 | Chip: ADV7123 (Audio Codec)
//------------------------------------------------------------------------------

`default_nettype none

module i2c_av_config
    #(
         parameter IC = 0
     ) (
         // Host Side
         input  logic       clk,
         input  logic       reset_n,
         input  logic [7:0] i2c_addr,
         output logic       done,
         // I2C Side
         output logic       I2C_SCL,
         inout  wire        I2C_SDA
     );

    //! Internal Registers/Wires -----------------------------------------------
    reg         i2c_start = 0;
    wire        i2c_end;
    wire        i2c_ack;
    reg   [7:0] rom_addr = 0;
    wire [15:0] rom_data;

    //! I2C Controller ---------------------------------------------------------
    i2c #(.CLK_Freq(24_576_000), .I2C_Freq(20_000)) i2c_av
        (
            .iCLK       ( clk            ),
            .I2C_ADDR   ( i2c_addr       ),
            .I2C_WLEN   ( 1              ),
            .I2C_WDATA1 ( rom_data[15:8] ), // SUB_ADDR
            .I2C_WDATA2 ( rom_data[7:0]  ), // DATA
            .iSTART     ( i2c_start      ), // START transfer
            .oEND       ( i2c_end        ), // END transfer
            .oACK       ( i2c_ack        ), // ACK
            .I2C_SCL    ( I2C_SCL        ), // I2C CLOCK
            .I2C_SDA    ( I2C_SDA        )  // I2C DATA
        );

    //! Config Data LUT --------------------------------------------------------
    initial begin
        if (IC <= 0) begin
            $error("Invalid AV Config PROM");
        end
    end
    generate
        if(IC == 7123) begin
            adv7123_config adv7123_config(.clk(clk), .addr(rom_addr), .data (rom_data));
        end
        else if(IC == 7513) begin
            adv7513_config adv7513_config(.clk(clk), .addr(rom_addr), .data (rom_data));
        end
    endgenerate

    //! Config Control ---------------------------------------------------------
    always@(posedge clk or negedge reset_n) begin
        reg [1:0] state;

        if(!reset_n) begin
            rom_addr  <= 0;
            state     <= 0;
            i2c_start <= 0;
            done      <= 0;
        end
        else begin
            if(rom_data != 16'hFFFF) begin
                case(state)
                    0: begin
                        i2c_start <= 1;
                        state     <= 1;
                    end
                    1: begin
                        if(~i2c_end) begin
                            state <= 2;
                        end
                    end
                    2: begin
                        i2c_start <= 0;
                        if(i2c_end) begin
                            state <= 0;
                            if(!i2c_ack) begin
                                rom_addr <= rom_addr + 8'd1;
                            end
                        end
                    end
                endcase
            end
            else begin
                done <= 1;
            end
        end
    end

endmodule
