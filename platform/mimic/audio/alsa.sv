//------------------------------------------------------------------------------
// SPDX-License-Identifier: GPL-3.0-or-later
// SPDX-FileType: SOURCE
// SPDX-FileCopyrightText: (c) 2023, OpenGateware authors and contributors
//------------------------------------------------------------------------------
//
// ALSA Sound Support
// Copyright (c) 2019-2020, Alexey Melnikov <pour.garbage@gmail.com>
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

module alsa
    #(
         parameter CLK_RATE = 24576000
     ) (
         input             reset,
         input             clk,

         output reg [31:3] ram_address,
         input      [63:0] ram_data,
         output reg        ram_req = 0,
         input             ram_ready,

         input             spi_ss,
         input             spi_sck,
         input             spi_mosi,
         output            spi_miso,

         output reg [15:0] pcm_l,
         output reg [15:0] pcm_r
     );

    reg [60:0] buf_info;
    reg  [6:0] spicnt = 0;
    always @(posedge spi_sck, posedge spi_ss) begin
        reg [95:0] spi_data;

        if(spi_ss) begin
            spicnt <= 0;
        end
        else begin
            spi_data[{spicnt[6:3],~spicnt[2:0]}] <= spi_mosi;
            if(&spicnt) begin
                buf_info <= {spi_data[82:67],spi_data[50:35],spi_data[31:3]};
            end
            spicnt <= spicnt + 1'd1;
        end
    end

    assign spi_miso = spi_out[{spicnt[4:3],~spicnt[2:0]}];

    reg [31:0] spi_out = 0;
    always @(posedge clk) begin
        if(spi_ss) begin
            spi_out <= {buf_rptr, hurryup, 8'h00};
        end
    end

    reg [31:3] buf_addr;
    reg [18:3] buf_len;
    reg [18:3] buf_wptr = 0;

    always @(posedge clk) begin
        reg [60:0] data1, data2;

        data1 <= buf_info;
        data2 <= data1;
        if(data2 == data1) begin
            {buf_wptr,buf_len,buf_addr} <= data2;
        end
    end

    reg  [2:0] hurryup  = 0;
    reg [18:3] buf_rptr = 0;

    always @(posedge clk) begin
        reg [63:0] readdata;
        reg [18:3] len       = 0;
        reg  [1:0] ready     = 0;
        reg        got_first = 0;
        reg  [7:0] ce_cnt    = 0;
        reg  [1:0] state     = 0;

        if(reset) begin
            ready     <= 0;
            ce_cnt    <= 0;
            state     <= 0;
            got_first <= 0;
            len       <= 0;
        end
        else begin

            //ramp up
            if(len[18:14] && (hurryup < 1)) begin hurryup <= 1; end
            if(len[18:16] && (hurryup < 2)) begin hurryup <= 2; end
            if(len[18:17] && (hurryup < 4)) begin hurryup <= 4; end

            //ramp down
            if(!len[18:15] && (hurryup > 2)) begin hurryup <= 2; end
            if(!len[18:13] && (hurryup > 1)) begin hurryup <= 1; end
            if(!len[18:10])                  begin hurryup <= 0; end

            if(ce_sample && ~&ce_cnt)begin
                ce_cnt <= ce_cnt + 1'd1;
            end

            case(state)
                0: begin
                    if(!ce_sample) begin
                        if(ready) begin
                            if(ce_cnt) begin
                                {readdata[31:0],pcm_r,pcm_l} <= readdata;
                                ready <= ready - 1'd1;
                                ce_cnt <= ce_cnt - 1'd1;
                            end
                        end
                        else if(buf_rptr != buf_wptr) begin
                            if(~got_first) begin
                                buf_rptr <= buf_wptr;
                                got_first <= 1;
                            end
                            else begin
                                ram_address <= buf_addr + buf_rptr;
                                ram_req <= ~ram_req;
                                buf_rptr <= buf_rptr + 1'd1;
                                len <= (buf_wptr < buf_rptr) ? (buf_len + buf_wptr - buf_rptr) : (buf_wptr - buf_rptr);
                                state <= 1;
                            end
                        end
                        else begin
                            len     <= 0;
                            ce_cnt  <= 0;
                            hurryup <= 0;
                        end
                    end
                end
                1: begin
                    if(ram_ready) begin
                        ready <= 2;
                        readdata <= ram_data;
                        if(buf_rptr >= buf_len) begin
                            buf_rptr <= buf_rptr - buf_len;
                        end
                        state <= 0;
                    end
                end
            endcase
        end
    end

    reg ce_sample;
    always @(posedge clk) begin
        reg [31:0] acc = 0;

        ce_sample <= 0;
        acc <= acc + 48000 + {hurryup,6'd0};
        if(acc >= CLK_RATE) begin
            acc <= acc - CLK_RATE;
            ce_sample <= 1;
        end
    end

endmodule
