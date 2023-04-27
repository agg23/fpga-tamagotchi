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

`default_nettype none

module audio_mixer
    (
        input             clk,
        input             ce,

        input       [4:0] att,
        input       [1:0] mix,

        input      [15:0] core_audio,
        input      [15:0] linux_audio,
        input      [15:0] pre_in,

        output reg [15:0] pre_out = 0,
        output reg [15:0] out = 0
    );

    reg signed [16:0] a1, a2, a3, a4;

    always @(posedge clk) begin
        if (ce) begin
            a1 <= {core_audio[15],core_audio};
            a2 <= a1 + {linux_audio[15],linux_audio};

            pre_out <= a2[16:1];

            case(mix)
                0: a3 <= a2;
                1: a3 <= $signed(a2) - $signed(a2[16:3]) + $signed(pre_in[15:2]);
                2: a3 <= $signed(a2) - $signed(a2[16:2]) + $signed(pre_in[15:1]);
                3: a3 <= {a2[16],a2[16:1]} + {pre_in[15],pre_in};
            endcase

            if(att[4]) begin
                a4 <= 0;
            end
            else begin
                a4 <= a3 >>> att[3:0];
            end

            //clamping
            out <= ^a4[16:15] ? {a4[16],{15{a4[15]}}} : a4[15:0];
        end
    end

endmodule
