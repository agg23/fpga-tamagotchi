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
// result = (mul1*mul2)/div
//------------------------------------------------------------------------------

`default_nettype none

module sys_umuldiv
    #(
         parameter NB_MUL1 = 0,
         parameter NB_MUL2 = 0,
         parameter NB_DIV  = 0
     ) (
         input                        clk,
         input                        start,
         output                       busy,

         input          [NB_MUL1-1:0] mul1,
         input          [NB_MUL2-1:0] mul2,
         input           [NB_DIV-1:0] div,
         output [NB_MUL1+NB_MUL2-1:0] result,
         output          [NB_DIV-1:0] remainder
     );

    wire mul_run;
    wire [NB_MUL1+NB_MUL2-1:0] mul_res;
    sys_umul #(NB_MUL1,NB_MUL2) umul(clk,start,mul_run,mul1,mul2,mul_res);

    sys_udiv #(NB_MUL1+NB_MUL2,NB_DIV) udiv(clk,start|mul_run,busy,mul_res,div,result,remainder);

endmodule
