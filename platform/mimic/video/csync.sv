//------------------------------------------------------------------------------
// SPDX-License-Identifier: GPL-3.0-or-later
// SPDX-FileType: SOURCE
// SPDX-FileCopyrightText: (c) 2023, OpenGateware authors and contributors
//------------------------------------------------------------------------------
//
// Copyright (c) 2020, Alexey Melnikov <pour.garbage@gmail.com>
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
// CSync generation
// Shifts HSync left by 1 HSync period during VSync
//------------------------------------------------------------------------------

`default_nettype none

module csync
    (
        input  clk,
        input  hsync,
        input  vsync,

        output csync
    );

    assign csync = (csync_vs ^ csync_hs);

    reg csync_hs, csync_vs;
    always @(posedge clk) begin
        reg prev_hs;
        reg [15:0] h_cnt, line_len, hs_len;

        // Count line/Hsync length
        h_cnt <= h_cnt + 1'd1;

        prev_hs <= hsync;
        if (prev_hs ^ hsync) begin
            h_cnt <= 0;
            if (hsync) begin
                line_len <= h_cnt - hs_len;
                csync_hs <= 0;
            end
            else begin
                hs_len <= h_cnt;
            end
        end

        if (~vsync) begin
            csync_hs <= hsync;
        end
        else if(h_cnt == line_len) begin
            csync_hs <= 1;
        end

        csync_vs <= vsync;
    end

endmodule
