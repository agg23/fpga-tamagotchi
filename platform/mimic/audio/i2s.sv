//------------------------------------------------------------------------------
// SPDX-License-Identifier: GPL-3.0-or-later
// SPDX-FileType: SOURCE
// SPDX-FileCopyrightText: (c) 2023, OpenGateware authors and contributors
//------------------------------------------------------------------------------
//
// Copyright (c) 2017-2022, Alexey Melnikov <pour.garbage@gmail.com>
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

module i2s
    #(
         parameter AUDIO_DW = 16
     ) (
         input                reset,
         input                clk,
         input                ce,

         output reg           sclk,
         output reg           lrclk,
         output reg           sdata,

         input [AUDIO_DW-1:0] left_chan,
         input [AUDIO_DW-1:0] right_chan
     );

    always @(posedge clk) begin
        reg [7:0] bit_cnt;
        reg       msclk;

        reg [AUDIO_DW-1:0] left;
        reg [AUDIO_DW-1:0] right;

        if (reset) begin
            bit_cnt <= 1;
            lrclk   <= 1;
            sclk    <= 1;
            msclk   <= 1;
        end
        else begin
            sclk <= msclk;
            if(ce) begin
                msclk <= ~msclk;
                if(msclk) begin
                    if(bit_cnt >= AUDIO_DW) begin
                        bit_cnt <= 1;
                        lrclk <= ~lrclk;
                        if(lrclk) begin
                            left  <= left_chan;
                            right <= right_chan;
                        end
                    end
                    else begin
                        bit_cnt <= bit_cnt + 1'd1;
                    end
                    sdata <= lrclk ? right[AUDIO_DW - bit_cnt] : left[AUDIO_DW - bit_cnt];
                end
            end
        end
    end

endmodule
