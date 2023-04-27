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

module gamma_corr
(
	input             clk_sys,
	input             clk_vid,
	input             ce_pix,
	input             gamma_en,
	input             gamma_wr,
	input       [9:0] gamma_wr_addr,
	input       [7:0] gamma_value,
	input             HSync,
	input             VSync,
	input             HBlank,
	input             VBlank,
	input      [23:0] RGB_in,
	output reg        HSync_out,
	output reg        VSync_out,
	output reg        HBlank_out,
	output reg        VBlank_out,
	output reg [23:0] RGB_out
);

(* ramstyle="no_rw_check" *) reg [7:0] gamma_curve[768];

always @(posedge clk_sys) if (gamma_wr) gamma_curve[gamma_wr_addr] <= gamma_value;
always @(posedge clk_vid) gamma <= gamma_curve[gamma_index];

reg [9:0] gamma_index;
reg [7:0] gamma;

always @(posedge clk_vid) begin
	reg [7:0] R_in, G_in, B_in;
	reg [7:0] R_gamma, G_gamma;
	reg       hs,vs,hb,vb;
	reg [1:0] ctr = 0;
	reg       old_ce;

	old_ce <= ce_pix;
	if(~old_ce & ce_pix) begin
		{R_in,G_in,B_in} <= RGB_in;
		hs <= HSync; vs <= VSync;
		hb <= HBlank; vb <= VBlank;

		RGB_out  <= gamma_en ? {R_gamma,G_gamma,gamma} : {R_in,G_in,B_in};
		HSync_out <= hs; VSync_out <= vs;
		HBlank_out <= hb; VBlank_out <= vb;

		ctr <= 1;
		gamma_index <= {2'b00,RGB_in[23:16]};
	end

	if (|ctr) ctr <= ctr + 1'd1;

	case(ctr)
		1: begin                   gamma_index <= {2'b01,G_in}; end
		2: begin R_gamma <= gamma; gamma_index <= {2'b10,B_in}; end
		3: begin G_gamma <= gamma; end
	endcase
end

endmodule
