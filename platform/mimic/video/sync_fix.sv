//------------------------------------------------------------------------------
// SPDX-License-Identifier: GPL-3.0-or-later
// SPDX-FileType: SOURCE
// SPDX-FileCopyrightText: (c) 2023, Open Gateware authors and contributors
//------------------------------------------------------------------------------
//
// Copyright (c) 2022, Marcus Andrade <marcus@opengateware.org>
// Copyright (c) 2020, Alexey Melnikov <pour.garbage@gmail.com>
// Copyright (c) 2014, Till Harbaum <till@harbaum.org>
//
// This source file is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published
// by the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This source file is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.
//
//------------------------------------------------------------------------------
// Automatically calculate the polarity signal and synchronize the output signal
// to the input signal based on the clock signal.
//
// This module implements a synchronized output signal based on an input signal
// and a clock. The output signal is the XOR of the input signal and a polarity
// signal (polarity). The polarity signal is calculated based on the number of
// positive and negative edges detected in the input signal, and is updated on
// each positive edge of the clock.
//------------------------------------------------------------------------------

`default_nettype none

module sync_fix
    (
        input  logic clk,      //! Clock
        input  logic sync_in,  //! Input Sync  (Horizontal or Vertical)
        output logic sync_out  //! Output Sync (Horizontal or Vertical)
    );

    // Assign the synchronized output signal by XORing input with polarity
    assign sync_out = sync_in ^ polarity;

    // Register for polarity
    logic polarity;

    // Create an always block triggered on positive edge of clock
    always_ff @(posedge clk) begin
        // Declare local integer variables for positive edge, negative edge, and counter
        integer pos, neg, cnt;
        // Declare registers for two synchronized signals s1 and s2
        logic s1, s2;
        // Assign s1 and s2 to current and previous values of sync_in
        s1 <= sync_in;
        s2 <= s1;
        // Update the positive and negative edge counts
        if(~s2 &  s1) begin neg <= cnt; end
        if( s2 & ~s1) begin pos <= cnt; end
        // Increment the counter and reset if the synchronized signal changes state
        cnt <= cnt + 1;
        if(s2 != s1) begin cnt <= 0; end
        // Update the polarity based on the difference between positive and negative edge counts
        polarity <= pos > neg;
    end

endmodule
