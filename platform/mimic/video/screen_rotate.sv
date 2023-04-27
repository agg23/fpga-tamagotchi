//------------------------------------------------------------------------------
// SPDX-License-Identifier: GPL-3.0-or-later
// SPDX-FileType: SOURCE
// SPDX-FileCopyrightText: (c) 2023, OpenGateware authors and contributors
//------------------------------------------------------------------------------
//
// Copyright (c) 2020 Alexey Melnikov <pour.garbage@gmail.com>
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
// Screen +90/-90 deg. rotation
//------------------------------------------------------------------------------

`default_nettype none

module screen_rotate
    (
        input         CLK_VIDEO,
        input         CE_PIXEL,

        input   [7:0] VGA_R,
        input   [7:0] VGA_G,
        input   [7:0] VGA_B,
        input         VGA_HS,
        input         VGA_VS,
        input         VGA_DE,

        input         rotate_ccw,
        input         no_rotate,
        input         flip,
        output        video_rotated,

        output            FB_EN,
        output      [4:0] FB_FORMAT,
        output reg [11:0] FB_WIDTH,
        output reg [11:0] FB_HEIGHT,
        output     [31:0] FB_BASE,
        output     [13:0] FB_STRIDE,
        input             FB_VBL,
        input             FB_LL,

        output        DDRAM_CLK,
        input         DDRAM_BUSY,
        output  [7:0] DDRAM_BURSTCNT,
        output [28:0] DDRAM_ADDR,
        output [63:0] DDRAM_DIN,
        output  [7:0] DDRAM_BE,
        output        DDRAM_WE,
        output        DDRAM_RD
    );

    parameter MEM_BASE    = 7'b0010010; // buffer at 0x24000000, 3x8MB

    reg  do_flip;

    assign DDRAM_CLK      = CLK_VIDEO;
    assign DDRAM_BURSTCNT = 1;
    assign DDRAM_ADDR     = {MEM_BASE, i_fb, ram_addr[22:3]};
    assign DDRAM_BE       = ram_addr[2] ? 8'hF0 : 8'h0F;
    assign DDRAM_DIN      = {ram_data,ram_data};
    assign DDRAM_WE       = ram_wr;
    assign DDRAM_RD       = 0;

    assign FB_EN     = fb_en[2];
    assign FB_FORMAT = 5'b00110;
    assign FB_BASE   = {MEM_BASE,o_fb,23'd0};
    assign FB_STRIDE = stride;

    function [1:0] buf_next;
        input [1:0] a,b;
        begin
            buf_next = 1;
            if ((a==0 && b==1) || (a==1 && b==0))
                buf_next = 2;
            if ((a==1 && b==2) || (a==2 && b==1))
                buf_next = 0;
        end
    endfunction

    assign video_rotated = ~no_rotate;

    always @(posedge CLK_VIDEO) begin
        do_flip <= no_rotate && flip;
        if( do_flip ) begin
            FB_WIDTH  <= hsz;
            FB_HEIGHT <= vsz;
        end
        else begin
            FB_WIDTH  <= vsz;
            FB_HEIGHT <= hsz;
        end
    end

    reg [1:0] i_fb,o_fb;
    always @(posedge CLK_VIDEO) begin
        reg old_vbl,old_vs;
        old_vbl <= FB_VBL;
        old_vs <= VGA_VS;

        if(FB_LL) begin
            if(~old_vbl & FB_VBL)
                o_fb<={1'b0,~i_fb[0]};
            if(~old_vs & VGA_VS)
                i_fb<={1'b0,~i_fb[0]};
        end
        else begin
            if(~old_vbl & FB_VBL)
                o_fb<=buf_next(o_fb,i_fb);
            if(~old_vs & VGA_VS)
                i_fb<=buf_next(i_fb,o_fb);
        end
    end

    initial begin
        fb_en = 0;
    end

    reg  [2:0] fb_en = 0;
    reg [11:0] hsz = 320, vsz = 240;
    reg [11:0] bwidth;
    reg [22:0] bufsize;
    always @(posedge CLK_VIDEO) begin
        reg [11:0] hcnt = 0, vcnt = 0;
        reg old_vs, old_de;

        if(CE_PIXEL) begin
            old_vs <= VGA_VS;
            old_de <= VGA_DE;

            hcnt <= hcnt + 1'd1;
            if(~old_de & VGA_DE) begin
                hcnt <= 1;
                vcnt <= vcnt + 1'd1;
            end
            if(old_de & ~VGA_DE) begin
                hsz <= hcnt;
                if( do_flip )
                    bwidth <= hcnt + 2'd3;
            end
            if(~old_vs & VGA_VS) begin
                vsz <= vcnt;
                if( !do_flip )
                    bwidth <= vcnt + 2'd3;
                vcnt <= 0;
                fb_en <= {fb_en[1:0], ~no_rotate | flip};
            end
            if(old_vs & ~VGA_VS)
                bufsize <= (do_flip ? vsz : hsz ) * stride;
        end
    end

    wire [13:0] stride = {bwidth[11:2], 4'd0};

    reg [22:0] ram_addr, next_addr;
    reg [31:0] ram_data;
    reg        ram_wr;
    always @(posedge CLK_VIDEO) begin
        reg [13:0] hcnt = 0;
        reg old_vs, old_de;

        ram_wr <= 0;
        if(CE_PIXEL && FB_EN) begin
            old_vs <= VGA_VS;
            old_de <= VGA_DE;

            if(~old_vs & VGA_VS) begin
                next_addr <= do_flip    ? bufsize-3'd4 : 
                             rotate_ccw ? (bufsize - stride) : {vsz-1'd1, 2'b00};
                hcnt <= rotate_ccw ? 3'd4 : {vsz-2'd2, 2'b00};
            end
            if(VGA_DE) begin
                ram_wr <= 1;
                ram_data <= {8'd0,VGA_B,VGA_G,VGA_R};
                ram_addr <= next_addr;
                next_addr <= do_flip    ? next_addr-3'd4 :
                             rotate_ccw ? (next_addr - stride) : (next_addr + stride);
            end
            if(old_de & ~VGA_DE & ~do_flip) begin
                next_addr <= rotate_ccw ? (bufsize - stride + hcnt) : hcnt;
                hcnt <= rotate_ccw ? (hcnt + 3'd4) : (hcnt - 3'd4);
            end
        end
    end

endmodule
