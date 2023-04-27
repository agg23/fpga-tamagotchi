//------------------------------------------------------------------------------
// SPDX-License-Identifier: GPL-3.0-or-later
// SPDX-FileType: SOURCE
// SPDX-FileCopyrightText: (c) 2023, OpenGateware authors and contributors
//------------------------------------------------------------------------------
//
// Copyright (c) 2021, Alexey Melnikov <pour.garbage@gmail.com>
// Copyright (c) 2020, Grabulosaure
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
// Video Crop
//------------------------------------------------------------------------------

`default_nettype none
`timescale 1ns / 1ps

module video_freak
    (
        input             CLK_VIDEO,
        input             CE_PIXEL,
        input             VGA_VS,
        input      [11:0] HDMI_WIDTH,
        input      [11:0] HDMI_HEIGHT,
        output            VGA_DE,
        output reg [12:0] VIDEO_ARX,
        output reg [12:0] VIDEO_ARY,

        input             VGA_DE_IN,
        input      [11:0] ARX,
        input      [11:0] ARY,
        input      [11:0] CROP_SIZE,
        input       [4:0] CROP_OFF, // -16...+15
        input       [2:0] SCALE     //0 - normal, 1 - V-integer, 2 - HV-Integer-, 3 - HV-Integer+, 4 - HV-Integer
    );

    reg         mul_start;
    wire        mul_run;
    reg  [11:0] mul_arg1, mul_arg2;
    wire [23:0] mul_res;
    sys_umul #(12,12) mul(CLK_VIDEO,mul_start,mul_run, mul_arg1,mul_arg2,mul_res);

    reg        vde;
    reg [11:0] arxo,aryo;
    reg [11:0] vsize;
    reg [11:0] hsize;

    always @(posedge CLK_VIDEO) begin
        reg        old_de, old_vs,ovde;
        reg [11:0] vtot,vcpt,vcrop,voff;
        reg [11:0] hcpt;
        reg [11:0] vadj;
        reg [23:0] ARXG,ARYG;
        reg [11:0] arx,ary;
        reg  [1:0] vcalc;

        if (CE_PIXEL) begin
            old_de <= VGA_DE_IN;
            old_vs <= VGA_VS;
            if (VGA_VS & ~old_vs) begin
                vcpt  <= 0;
                vtot  <= vcpt;
                vcalc <= 1;
                vcrop <= (CROP_SIZE >= vcpt) ? 12'd0 : CROP_SIZE;
            end

            if (VGA_DE_IN)
                hcpt <= hcpt + 1'd1;
            if (~VGA_DE_IN & old_de) begin
                vcpt <= vcpt + 1'd1;
                if(!vcpt)
                    hsize <= hcpt;
                hcpt <= 0;
            end
        end

        arx <= ARX;
        ary <= ARY;

        vsize <= vcrop ? vcrop : vtot;

        mul_start <= 0;

        if(!vcrop || !ary || !arx) begin
            arxo  <= arx;
            aryo  <= ary;
        end
        else if (vcalc) begin
            if(~mul_start & ~mul_run) begin
                vcalc <= vcalc + 1'd1;
                case(vcalc)
                    1: begin
                        mul_arg1  <= arx;
                        mul_arg2  <= vtot;
                        mul_start <= 1;
                    end

                    2: begin
                        ARXG      <= mul_res;
                        mul_arg1  <= ary;
                        mul_arg2  <= vcrop;
                        mul_start <= 1;
                    end

                    3: begin
                        ARYG      <= mul_res;
                    end
                endcase
            end
        end
        else if (ARXG[23] | ARYG[23]) begin
            arxo <= ARXG[23:12];
            aryo <= ARYG[23:12];
        end
        else begin
            ARXG <= ARXG << 1;
            ARYG <= ARYG << 1;
        end

        vadj <= (vtot-vcrop) + {{6{CROP_OFF[4]}},CROP_OFF,1'b0};
        voff <= vadj[11] ? 12'd0 : ((vadj[11:1] + vcrop) > vtot) ? vtot-vcrop : vadj[11:1];
        ovde <= ((vcpt >= voff) && (vcpt < (vcrop + voff))) || !vcrop;
        vde  <= ovde;
    end

    assign VGA_DE = vde & VGA_DE_IN;

    video_scale_int scale
                    (
                        .CLK_VIDEO(CLK_VIDEO),
                        .HDMI_WIDTH(HDMI_WIDTH),
                        .HDMI_HEIGHT(HDMI_HEIGHT),
                        .SCALE(SCALE),
                        .hsize(hsize),
                        .vsize(vsize),
                        .arx_i(arxo),
                        .ary_i(aryo),
                        .arx_o(VIDEO_ARX),
                        .ary_o(VIDEO_ARY)
                    );

endmodule
