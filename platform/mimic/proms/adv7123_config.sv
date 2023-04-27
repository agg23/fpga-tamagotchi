//------------------------------------------------------------------------------
// SPDX-License-Identifier: GPL-3.0-or-later
// SPDX-FileType: SOURCE
// SPDX-FileCopyrightText: (c) 2023, OpenGateware authors and contributors
//------------------------------------------------------------------------------
//
// ADV7123 Config Program ROM
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

`default_nettype none
`timescale 1ns / 1ps

module adv7123_config
    (
        input  logic        clk,
        input  logic  [7:0] addr,
        output logic [15:0] data
    );

    always_ff @(posedge clk) begin
        data <= rom[addr];
    end

    logic [15:0] rom[12] = '{
              16'h0000,  // 0x00 | DUMMY DATA
              16'h009A,  // 0x01 | R0 LINVOL = 1Ah (+4.5bB)
              16'h029A,  // 0x02 | R1 RINVOL = 1Ah (+4.5bB)
              16'h0479,  // 0x03 | R2 LHPVOL = 7Bh (+2dB)
              16'h0679,  // 0x04 | R3 RHPVOL = 7Bh (+2dB)
              16'h08D2,  // 0x05 | R4 DACSEL = 1
              16'h0A06,  // 0x06 | R5 DEEMP  = 11 (48 KHz)
              16'h0C20,  // 0x07 | R6 internal oscilator MCLK powered down
              16'h1009,  // 0x08 | R8 48KHz,USB-mode
              16'h1008,  // 0x09 | R8 48KHz,Normal mode, clkdiv2=0
              16'h1201,  // 0x0A | R9 ACTIVE
              16'hFFFF   // 0x0B | END
          };

endmodule
