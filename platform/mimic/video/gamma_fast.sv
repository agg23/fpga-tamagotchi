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

module gamma_fast
(
	input             clk_vid,
	input             ce_pix,

	inout      [21:0] gamma_bus,

	input             HSync,
	input             VSync,
	input             HBlank,
	input             VBlank,
	input             DE,
	input      [23:0] RGB_in,

	output reg        HSync_out,
	output reg        VSync_out,
	output reg        HBlank_out,
	output reg        VBlank_out,
	output reg        DE_out,
	output reg [23:0] RGB_out
);

(* ramstyle="no_rw_check" *) reg [7:0] gamma_curve_r[256];
(* ramstyle="no_rw_check" *) reg [7:0] gamma_curve_g[256];
(* ramstyle="no_rw_check" *) reg [7:0] gamma_curve_b[256];

assign     gamma_bus[21] = 1;
wire       clk_sys = gamma_bus[20];
wire       gamma_en = gamma_bus[19];
wire       gamma_wr = gamma_bus[18];
wire [9:0] gamma_wr_addr = gamma_bus[17:8];
wire [7:0] gamma_value = gamma_bus[7:0];

always @(posedge clk_sys) if (gamma_wr) begin
	case(gamma_wr_addr[9:8])
		0: gamma_curve_r[gamma_wr_addr[7:0]] <= gamma_value;
		1: gamma_curve_g[gamma_wr_addr[7:0]] <= gamma_value;
		2: gamma_curve_b[gamma_wr_addr[7:0]] <= gamma_value;
	endcase
end

reg [7:0] gamma_index_r,gamma_index_g,gamma_index_b;

always @(posedge clk_vid) begin
	reg [7:0] R_in, G_in, B_in;
	reg [7:0] R_gamma, G_gamma;
	reg       hs,vs,hb,vb,de;

	if(ce_pix) begin
		{gamma_index_r,gamma_index_g,gamma_index_b} <= RGB_in;
		hs <= HSync; vs <= VSync;
		hb <= HBlank; vb <= VBlank;
		de <= DE;

		RGB_out  <= gamma_en ? {gamma_curve_r[gamma_index_r],gamma_curve_g[gamma_index_g],gamma_curve_b[gamma_index_b]}
	                        : {gamma_index_r,gamma_index_g,gamma_index_b};
		HSync_out <= hs; VSync_out <= vs;
		HBlank_out <= hb; VBlank_out <= vb;
		DE_out <= de;
	end
end

endmodule
