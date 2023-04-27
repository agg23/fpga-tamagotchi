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

`default_nettype none

module sync_lock 
    #(
         parameter WIDTH = 16
     ) (
         input   clk,

         input   sync_in,
         input   de_in,

         output  sync_out,
         output  de_out,

         input   freeze,
         output  sync_pt,
         output  valid
     );

    reg [WIDTH-1:0] f_len, s_len, de_start, de_end;
    reg sync_valid;

    reg old_sync;
    always @(posedge clk) old_sync <= sync_in;

    always @(posedge clk) begin
        reg [WIDTH-1:0] cnti;
        reg f_valid;
        reg old_de;

        cnti <= cnti + 1'd1;
        if(~old_sync & sync_in) begin
            if(sync_valid) begin
                f_len <= cnti;
            end
            f_valid <= 1;
            sync_valid <= f_valid;
            cnti <= 0;
        end

        if(old_sync & ~sync_in & sync_valid)
            s_len <= cnti;

        old_de <= de_in;
        if(~old_de & de_in & sync_valid) de_start <= cnti;
        if(old_de & ~de_in & sync_valid) de_end   <= cnti;

        if(freeze) begin
            {f_valid, sync_valid} <= 0;
        end
    end

    reg sync_o, de_o, sync_o_pre;
    always @(posedge clk) begin
        reg [WIDTH-1:0] cnto;

        cnto <= cnto + 1'd1;
        if(old_sync & ~sync_in & sync_valid) begin
            cnto <= s_len + 2'd2;
        end
        if(cnto == f_len) begin
            cnto <= 0;
        end

        sync_o_pre <= (cnto == (s_len>>1)); // middle in sync
        if(cnto == f_len)    sync_o <= 1;
        if(cnto == s_len)    sync_o <= 0;
        if(cnto == de_start) de_o   <= 1;
        if(cnto == de_end)   de_o   <= 0;
    end

    assign sync_out = freeze ? sync_o : sync_in;
    assign valid    = sync_valid;
    assign sync_pt  = sync_o_pre;
    assign de_out   = freeze ? de_o   : de_in;

endmodule
