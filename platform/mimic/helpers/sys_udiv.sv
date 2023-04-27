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
// result = num/div
//------------------------------------------------------------------------------

`default_nettype none

module sys_udiv #
    (
        parameter NB_NUM = 1,
        parameter NB_DIV = 1
    ) (
        input                   clk,
        input                   start,
        output                  busy,

        input      [NB_NUM-1:0] num,
        input      [NB_DIV-1:0] div,
        output reg [NB_NUM-1:0] result,
        output reg [NB_DIV-1:0] remainder
    );

    reg run;
    assign busy = run;

    always @(posedge clk) begin
        reg [5:0] cpt;
        reg [NB_NUM+NB_DIV+1:0] rem;

        if (start) begin
            cpt <= 0;
            run <= 1;
            rem <= num;
        end
        else if (run) begin
            cpt <= cpt + 1'd1;
            run <= (cpt != NB_NUM + 1'd1);
            remainder <= rem[NB_NUM+NB_DIV:NB_NUM+1];
            if (!rem[NB_DIV + NB_NUM + 1'd1])
                rem <= {rem[NB_DIV+NB_NUM:0] - (div << NB_NUM),1'b0};
            else
                rem <= {rem[NB_DIV+NB_NUM:0] + (div << NB_NUM),1'b0};
            result <= {result[NB_NUM-2:0], !rem[NB_DIV + NB_NUM + 1'd1]};
        end
    end

endmodule