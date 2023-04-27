//------------------------------------------------------------------------------
// SPDX-License-Identifier: GPL-3.0-or-later
// SPDX-FileType: SOURCE
// SPDX-FileCopyrightText: (c) 2023, OpenGateware authors and contributors
//------------------------------------------------------------------------------
//
// ADV7513 Config Program ROM
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

module adv7513_config
    (
        input  logic        clk,
        input  logic  [7:0] addr,
        output logic [15:0] data
    );

    always_ff @(posedge clk) begin
        data <= rom[addr];
    end

    logic [15:0] rom[2] = '{
              16'h0000,  // DUMMY DATA
              16'hFFFF   // END
          };

endmodule
