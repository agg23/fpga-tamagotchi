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
//
// DW:
//  6 : 2R 2G 2B
//  8 : 3R 3G 2B
//  9 : 3R 3G 3B
// 12 : 4R 4G 4B
// 24 : 8R 8G 8B
//
//------------------------------------------------------------------------------

`default_nettype none

module arcade_video #(parameter WIDTH=320, DW=8, GAMMA=1)
    (
        input         clk_video,
        input         ce_pix,

        input[DW-1:0] RGB_in,
        input         HBlank,
        input         VBlank,
        input         HSync,
        input         VSync,

        output        CLK_VIDEO,
        output        CE_PIXEL,
        output  [7:0] VGA_R,
        output  [7:0] VGA_G,
        output  [7:0] VGA_B,
        output        VGA_HS,
        output        VGA_VS,
        output        VGA_DE,
        output  [1:0] VGA_SL,

        input   [2:0] fx,
        input         forced_scandoubler,
        inout  [21:0] gamma_bus
    );

    assign CLK_VIDEO = clk_video;

    wire hs_fix,vs_fix;
    sync_fix sync_v(CLK_VIDEO, HSync, hs_fix);
    sync_fix sync_h(CLK_VIDEO, VSync, vs_fix);

    reg [DW-1:0] RGB_fix;

    reg CE,HS,VS,HBL,VBL;
    always @(posedge CLK_VIDEO) begin
        reg old_ce;
        old_ce <= ce_pix;
        CE <= 0;
        if(~old_ce & ce_pix) begin
            CE <= 1;
            HS <= hs_fix;
            if(~HS & hs_fix)
                VS <= vs_fix;

            RGB_fix <= RGB_in;
            HBL <= HBlank;
            if(HBL & ~HBlank)
                VBL <= VBlank;
        end
    end

    wire [7:0] R,G,B;

    generate
        if(DW == 6) begin
            assign R = {RGB_fix[5:4],RGB_fix[5:4],RGB_fix[5:4],RGB_fix[5:4]};
            assign G = {RGB_fix[3:2],RGB_fix[3:2],RGB_fix[3:2],RGB_fix[3:2]};
            assign B = {RGB_fix[1:0],RGB_fix[1:0],RGB_fix[1:0],RGB_fix[1:0]};
        end
        else if(DW == 8) begin
            assign R = {RGB_fix[7:5],RGB_fix[7:5],RGB_fix[7:6]};
            assign G = {RGB_fix[4:2],RGB_fix[4:2],RGB_fix[4:3]};
            assign B = {RGB_fix[1:0],RGB_fix[1:0],RGB_fix[1:0],RGB_fix[1:0]};
        end
        else if(DW == 9) begin
            assign R = {RGB_fix[8:6],RGB_fix[8:6],RGB_fix[8:7]};
            assign G = {RGB_fix[5:3],RGB_fix[5:3],RGB_fix[5:4]};
            assign B = {RGB_fix[2:0],RGB_fix[2:0],RGB_fix[2:1]};
        end
        else if(DW == 12) begin
            assign R = {RGB_fix[11:8],RGB_fix[11:8]};
            assign G = {RGB_fix[7:4],RGB_fix[7:4]};
            assign B = {RGB_fix[3:0],RGB_fix[3:0]};
        end
        else begin // 24
            assign R = RGB_fix[23:16];
            assign G = RGB_fix[15:8];
            assign B = RGB_fix[7:0];
        end
    endgenerate

    assign VGA_SL  = sl[1:0];
    wire [2:0] sl = fx ? fx - 1'd1 : 3'd0;
    wire scandoubler = fx || forced_scandoubler;

    video_mixer #(.LINE_LENGTH(WIDTH+4), .HALF_DEPTH(DW!=24), .GAMMA(GAMMA)) video_mixer
                (
                    .CLK_VIDEO(CLK_VIDEO),
                    .ce_pix(CE),
                    .CE_PIXEL(CE_PIXEL),

                    .scandoubler(scandoubler),
                    .hq2x(fx==1),
                    .gamma_bus(gamma_bus),

                    .R((DW!=24) ? R[7:4] : R),
                    .G((DW!=24) ? G[7:4] : G),
                    .B((DW!=24) ? B[7:4] : B),

                    .HSync (HS),
                    .VSync (VS),
                    .HBlank(HBL),
                    .VBlank(VBL),

                    .VGA_R(VGA_R),
                    .VGA_G(VGA_G),
                    .VGA_B(VGA_B),
                    .VGA_VS(VGA_VS),
                    .VGA_HS(VGA_HS),
                    .VGA_DE(VGA_DE)
                );

endmodule
