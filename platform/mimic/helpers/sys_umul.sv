//------------------------------------------------------------------------------
// SPDX-License-Identifier: GPL-3.0-or-later
// SPDX-FileType: SOURCE
// SPDX-FileCopyrightText: (c) 2023, OpenGateware authors and contributors
//------------------------------------------------------------------------------
//
// Copyright (c) 2020 Alexey Melnikov <pour.garbage@gmail.com>
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
// result = mul1*mul2
//------------------------------------------------------------------------------

`default_nettype none

module sys_umul
    #(
         parameter NB_MUL1 = 0,
         parameter NB_MUL2 = 0
     ) (
         input                            clk,
         input                            start,
         output                           busy,

         input              [NB_MUL1-1:0] mul1,
         input              [NB_MUL2-1:0] mul2,
         output reg [NB_MUL1+NB_MUL2-1:0] result
     );

    reg run;
    assign busy = run;

    always @(posedge clk) begin
        reg [NB_MUL1+NB_MUL2-1:0] add;
        reg [NB_MUL2-1:0] map;

        if (start) begin
            run    <= 1;
            result <= 0;
            add    <= mul1;
            map    <= mul2;
        end
        else if (run) begin
            if(!map)
                run <= 0;
            if(map[0])
                result <= result + add;
            add <= add << 1;
            map <= map >> 1;
        end
    end

endmodule
