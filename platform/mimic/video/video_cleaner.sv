//------------------------------------------------------------------------------
// SPDX-License-Identifier: GPL-3.0-or-later
// SPDX-FileType: SOURCE
// SPDX-FileCopyrightText: (c) 2023, OpenGateware authors and contributors
//------------------------------------------------------------------------------
//
// Copyright (c) 2018, Alexey Melnikov <pour.garbage@gmail.com>
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, version 3.
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

module video_cleaner
    (
        input            clk_vid,
        input            ce_pix,

        input      [7:0] R,
        input      [7:0] G,
        input      [7:0] B,

        input            HSync,
        input            VSync,
        input            HBlank,
        input            VBlank,

        //optional de
        input            DE_in,

        // video output signals
        output reg [7:0] VGA_R,
        output reg [7:0] VGA_G,
        output reg [7:0] VGA_B,
        output reg       VGA_VS,
        output reg       VGA_HS,
        output           VGA_DE,

        // optional aligned blank
        output reg       HBlank_out,
        output reg       VBlank_out,

        // optional aligned de
        output reg       DE_out
    );

    wire hs, vs;
    sync_fix sync_v(clk_vid, HSync, hs);
    sync_fix sync_h(clk_vid, VSync, vs);

    wire hbl = hs | HBlank;
    wire vbl = vs | VBlank;

    assign VGA_DE = ~(HBlank_out | VBlank_out);

    always @(posedge clk_vid) begin
        if(ce_pix) begin
            HBlank_out <= hbl;

            VGA_HS <= hs;
            if(~VGA_HS & hs) begin
                VGA_VS <= vs;
            end

            VGA_R  <= R;
            VGA_G  <= G;
            VGA_B  <= B;
            DE_out <= DE_in;

            if(HBlank_out & ~hbl) begin
                VBlank_out <= vbl;
            end
        end
    end

endmodule
