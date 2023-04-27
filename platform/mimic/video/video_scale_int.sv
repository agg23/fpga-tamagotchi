//------------------------------------------------------------------------------
// SPDX-License-Identifier: GPL-3.0-or-later
// SPDX-FileType: SOURCE
// SPDX-FileCopyrightText: (c) 2023, OpenGateware authors and contributors
//------------------------------------------------------------------------------
//
// Copyright (c) 2021, Alexey Melnikov <pour.garbage@gmail.com>
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
// Video Integer scaling
//------------------------------------------------------------------------------

`default_nettype none

module video_scale_int
    (
        input             CLK_VIDEO,

        input      [11:0] HDMI_WIDTH,
        input      [11:0] HDMI_HEIGHT,

        input       [2:0] SCALE,

        input      [11:0] hsize,
        input      [11:0] vsize,

        input      [11:0] arx_i,
        input      [11:0] ary_i,

        output reg [12:0] arx_o,
        output reg [12:0] ary_o
    );

    reg         div_start;
    wire        div_run;
    reg  [23:0] div_num;
    reg  [11:0] div_den;
    wire [23:0] div_res;
    sys_udiv #(24,12) div(CLK_VIDEO,div_start,div_run, div_num,div_den,div_res);

    reg         mul_start;
    wire        mul_run;
    reg  [11:0] mul_arg1, mul_arg2;
    wire [23:0] mul_res;
    sys_umul #(12,12) mul(CLK_VIDEO,mul_start,mul_run, mul_arg1,mul_arg2,mul_res);

    wire [11:0] wideres = mul_res[11:0] + hsize;

    always @(posedge CLK_VIDEO) begin
        reg [11:0] oheight,wres;
        reg [12:0] arxf,aryf;
        reg  [3:0] cnt;
        reg        narrow;

        div_start <= 0;
        mul_start <= 0;

        if (!SCALE || (!ary_i && arx_i)) begin
            arxf <= arx_i;
            aryf <= ary_i;
        end
        else if(~div_start & ~div_run & ~mul_start & ~mul_run) begin
            cnt <= cnt + 1'd1;
            case(cnt)
                0: begin
                    div_num   <= HDMI_HEIGHT;
                    div_den   <= vsize;
                    div_start <= 1;
                end

                1: begin
                    if(!div_res[11:0]) begin
                        // screen resolution is lower than video resolution.
                        // Integer scaling is impossible.
                        arxf      <= arx_i;
                        aryf      <= ary_i;
                        cnt       <= 0;
                    end
                    else begin
                        mul_arg1  <= vsize;
                        mul_arg2  <= div_res[11:0];
                        mul_start <= 1;
                    end
                end

                2: begin
                    oheight   <= mul_res[11:0];
                    if(!ary_i) begin
                        cnt    <= 8;
                    end
                end

                3: begin
                    mul_arg1  <= mul_res[11:0];
                    mul_arg2  <= arx_i;
                    mul_start <= 1;
                end

                4: begin
                    div_num   <= mul_res;
                    div_den   <= ary_i;
                    div_start <= 1;
                end

                5: begin
                    div_num   <= div_res;
                    div_den   <= hsize;
                    div_start <= 1;
                end

                6: begin
                    mul_arg1  <= hsize;
                    mul_arg2  <= div_res[11:0] ? div_res[11:0] : 12'd1;
                    mul_start <= 1;
                end

                7: begin
                    if(mul_res <= HDMI_WIDTH) begin
                        cnt   <= 10;
                    end
                end

                8: begin
                    div_num   <= HDMI_WIDTH;
                    div_den   <= hsize;
                    div_start <= 1;
                end

                9: begin
                    mul_arg1  <= hsize;
                    mul_arg2  <= div_res[11:0] ? div_res[11:0] : 12'd1;
                    mul_start <= 1;
                end

                10: begin
                    narrow    <= ((div_num[11:0] - mul_res[11:0]) <= (wideres - div_num[11:0])) || (wideres > HDMI_WIDTH);
                    wres      <= wideres;
                end

                11: begin
                    case(SCALE)
                        2:       arxf <= {1'b1, mul_res[11:0]};
                        3:       arxf <= {1'b1, (wres > HDMI_WIDTH) ? mul_res[11:0] : wres};
                        4:       arxf <= {1'b1,              narrow ? mul_res[11:0] : wres};
                        default: arxf <= {1'b1, div_num[11:0]};
                    endcase
                    aryf <= {1'b1, oheight};
                end
            endcase
        end

        arx_o <= arxf;
        ary_o <= aryf;
    end

endmodule
