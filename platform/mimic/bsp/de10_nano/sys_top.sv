//------------------------------------------------------------------------------
// SPDX-License-Identifier: GPL-3.0-or-later
// SPDX-FileType: SOURCE
// SPDX-FileCopyrightText: (c) 2023, OpenGateware authors and contributors
//------------------------------------------------------------------------------
//
// Hardware Abstraction Module for DE10-Nano
// Copyright (c) 2023, Marcus Andrade <marcus@opengateware.org>
// Copyright (c) 2017-2020, Alexey Melnikov <pour.garbage@gmail.com>
// Copyright (c) 2014, Till Harbaum <till@harbaum.org>
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

module sys_top
    (
`include "../../includes/ports_de10nano.vh"
    );

    //! Set Video IC and VGA Color Depth
    localparam VID_IC  = 0;
    localparam VGA_BPP = 6;

    //! Dummy Wires for VGA DAC
    wire VGA_BLANK_N, VGA_SYNC_N, VGA_CLK;

`include "../../includes/sys_common.vh"

endmodule
