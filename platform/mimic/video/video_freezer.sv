//------------------------------------------------------------------------------
// SPDX-License-Identifier: GPL-3.0-or-later
// SPDX-FileType: SOURCE
// SPDX-FileCopyrightText: (c) 2023, OpenGateware authors and contributors
//------------------------------------------------------------------------------
//
// Copyright (c) 2020, Alexey Melnikov <pour.garbage@gmail.com>
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
// Video freeze with sync
//------------------------------------------------------------------------------

`default_nettype none

module video_freezer
    (
        input  logic clk,

        output logic sync,
        input  logic freeze,

        input  logic hs_in,
        input  logic vs_in,
        input  logic hbl_in,
        input  logic vbl_in,

        output logic hs_out,
        output logic vs_out,
        output logic hbl_out,
        output logic vbl_out
    );

    sync_lock #(33) vs_lock
              (
                  .clk      ( clk     ),
                  .sync_in  ( vs_in   ),
                  .sync_out ( vs_out  ),
                  .de_in    ( vbl_in  ),
                  .de_out   ( vbl_out ),
                  .freeze   ( freeze  )
              );

    wire sync_pt;
    sync_lock #(21) hs_lock
              (
                  .clk      ( clk     ),
                  .sync_in  ( hs_in   ),
                  .sync_out ( hs_out  ),
                  .de_in    ( hbl_in  ),
                  .de_out   ( hbl_out ),
                  .freeze   ( freeze  ),
                  .sync_pt  ( sync_pt )
              );

    reg sync_o;
    always @(posedge clk) begin
        reg old_hs, old_vs;
        reg vs_sync;

        old_vs <= vs_out;

        if(~old_vs & vs_out) begin
            vs_sync <= 1;
        end
        if(sync_pt & vs_sync) begin
            vs_sync <= 0;
            sync_o <= ~sync_o;
        end
    end

    assign sync = sync_o;

endmodule
