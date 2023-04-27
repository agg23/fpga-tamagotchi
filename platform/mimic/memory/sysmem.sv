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

`default_nettype none
`timescale 1 ps / 1 ps

module sysmem_lite
    (
        output         clock,
        output         reset_out,

        input          reset_hps_cold_req,
        input          reset_hps_warm_req,
        input          reset_core_req,

        input          ram1_clk,
        input   [28:0] ram1_address,
        input    [7:0] ram1_burstcount,
        output         ram1_waitrequest,
        output  [63:0] ram1_readdata,
        output         ram1_readdatavalid,
        input          ram1_read,
        input   [63:0] ram1_writedata,
        input    [7:0] ram1_byteenable,
        input          ram1_write,

        input          ram2_clk,
        input   [28:0] ram2_address,
        input    [7:0] ram2_burstcount,
        output         ram2_waitrequest,
        output  [63:0] ram2_readdata,
        output         ram2_readdatavalid,
        input          ram2_read,
        input   [63:0] ram2_writedata,
        input    [7:0] ram2_byteenable,
        input          ram2_write,

        input          vbuf_clk,
        input   [27:0] vbuf_address,
        input    [7:0] vbuf_burstcount,
        output         vbuf_waitrequest,
        output [127:0] vbuf_readdata,
        output         vbuf_readdatavalid,
        input          vbuf_read,
        input  [127:0] vbuf_writedata,
        input   [15:0] vbuf_byteenable,
        input          vbuf_write
    );

    assign reset_out = ~init_reset_n | ~hps_h2f_reset_n | reset_core_req;

    ////////////////////////////////////////////////////////
    ////          f2sdram_safe_terminator_ram1          ////
    ////////////////////////////////////////////////////////
    wire  [28:0] f2h_ram1_address;
    wire   [7:0] f2h_ram1_burstcount;
    wire         f2h_ram1_waitrequest;
    wire  [63:0] f2h_ram1_readdata;
    wire         f2h_ram1_readdatavalid;
    wire         f2h_ram1_read;
    wire  [63:0] f2h_ram1_writedata;
    wire   [7:0] f2h_ram1_byteenable;
    wire         f2h_ram1_write;

    (* altera_attribute = {"-name SYNCHRONIZER_IDENTIFICATION FORCED_IF_ASYNCHRONOUS"} *) reg ram1_reset_0 = 1'b1;
    (* altera_attribute = {"-name SYNCHRONIZER_IDENTIFICATION FORCED_IF_ASYNCHRONOUS"} *) reg ram1_reset_1 = 1'b1;
    always @(posedge ram1_clk) begin
        ram1_reset_0 <= reset_out;
        ram1_reset_1 <= ram1_reset_0;
    end

    f2sdram_safe_terminator #(64, 8) f2sdram_safe_terminator_ram1
                            (
                                .clk                  ( ram1_clk               ),
                                .rst_req_sync         ( ram1_reset_1           ),

                                .waitrequest_slave    ( ram1_waitrequest       ),
                                .burstcount_slave     ( ram1_burstcount        ),
                                .address_slave        ( ram1_address           ),
                                .readdata_slave       ( ram1_readdata          ),
                                .readdatavalid_slave  ( ram1_readdatavalid     ),
                                .read_slave           ( ram1_read              ),
                                .writedata_slave      ( ram1_writedata         ),
                                .byteenable_slave     ( ram1_byteenable        ),
                                .write_slave          ( ram1_write             ),

                                .waitrequest_master   ( f2h_ram1_waitrequest   ),
                                .burstcount_master    ( f2h_ram1_burstcount    ),
                                .address_master       ( f2h_ram1_address       ),
                                .readdata_master      ( f2h_ram1_readdata      ),
                                .readdatavalid_master ( f2h_ram1_readdatavalid ),
                                .read_master          ( f2h_ram1_read          ),
                                .writedata_master     ( f2h_ram1_writedata     ),
                                .byteenable_master    ( f2h_ram1_byteenable    ),
                                .write_master         ( f2h_ram1_write         )
                            );

    ////////////////////////////////////////////////////////
    ////          f2sdram_safe_terminator_ram2          ////
    ////////////////////////////////////////////////////////
    wire [28:0] f2h_ram2_address;
    wire  [7:0] f2h_ram2_burstcount;
    wire        f2h_ram2_waitrequest;
    wire [63:0] f2h_ram2_readdata;
    wire        f2h_ram2_readdatavalid;
    wire        f2h_ram2_read;
    wire [63:0] f2h_ram2_writedata;
    wire  [7:0] f2h_ram2_byteenable;
    wire        f2h_ram2_write;

    (* altera_attribute = {"-name SYNCHRONIZER_IDENTIFICATION FORCED_IF_ASYNCHRONOUS"} *) reg ram2_reset_0 = 1'b1;
    (* altera_attribute = {"-name SYNCHRONIZER_IDENTIFICATION FORCED_IF_ASYNCHRONOUS"} *) reg ram2_reset_1 = 1'b1;
    always @(posedge ram2_clk) begin
        ram2_reset_0 <= reset_out;
        ram2_reset_1 <= ram2_reset_0;
    end

    f2sdram_safe_terminator #(64, 8) f2sdram_safe_terminator_ram2
                            (
                                .clk                  ( ram2_clk               ),
                                .rst_req_sync         ( ram2_reset_1           ),

                                .waitrequest_slave    ( ram2_waitrequest       ),
                                .burstcount_slave     ( ram2_burstcount        ),
                                .address_slave        ( ram2_address           ),
                                .readdata_slave       ( ram2_readdata          ),
                                .readdatavalid_slave  ( ram2_readdatavalid     ),
                                .read_slave           ( ram2_read              ),
                                .writedata_slave      ( ram2_writedata         ),
                                .byteenable_slave     ( ram2_byteenable        ),
                                .write_slave          ( ram2_write             ),

                                .waitrequest_master   ( f2h_ram2_waitrequest   ),
                                .burstcount_master    ( f2h_ram2_burstcount    ),
                                .address_master       ( f2h_ram2_address       ),
                                .readdata_master      ( f2h_ram2_readdata      ),
                                .readdatavalid_master ( f2h_ram2_readdatavalid ),
                                .read_master          ( f2h_ram2_read          ),
                                .writedata_master     ( f2h_ram2_writedata     ),
                                .byteenable_master    ( f2h_ram2_byteenable    ),
                                .write_master         ( f2h_ram2_write         )
                            );

    ////////////////////////////////////////////////////////
    ////          f2sdram_safe_terminator_vbuf          ////
    ////////////////////////////////////////////////////////
    wire  [27:0] f2h_vbuf_address;
    wire   [7:0] f2h_vbuf_burstcount;
    wire         f2h_vbuf_waitrequest;
    wire [127:0] f2h_vbuf_readdata;
    wire         f2h_vbuf_readdatavalid;
    wire         f2h_vbuf_read;
    wire [127:0] f2h_vbuf_writedata;
    wire  [15:0] f2h_vbuf_byteenable;
    wire         f2h_vbuf_write;

    (* altera_attribute = {"-name SYNCHRONIZER_IDENTIFICATION FORCED_IF_ASYNCHRONOUS"} *) reg vbuf_reset_0 = 1'b1;
    (* altera_attribute = {"-name SYNCHRONIZER_IDENTIFICATION FORCED_IF_ASYNCHRONOUS"} *) reg vbuf_reset_1 = 1'b1;
    always @(posedge vbuf_clk) begin
        vbuf_reset_0 <= reset_out;
        vbuf_reset_1 <= vbuf_reset_0;
    end

    f2sdram_safe_terminator #(128, 8) f2sdram_safe_terminator_vbuf
                            (
                                .clk                  ( vbuf_clk               ),
                                .rst_req_sync         ( vbuf_reset_1           ),

                                .waitrequest_slave    ( vbuf_waitrequest       ),
                                .burstcount_slave     ( vbuf_burstcount        ),
                                .address_slave        ( vbuf_address           ),
                                .readdata_slave       ( vbuf_readdata          ),
                                .readdatavalid_slave  ( vbuf_readdatavalid     ),
                                .read_slave           ( vbuf_read              ),
                                .writedata_slave      ( vbuf_writedata         ),
                                .byteenable_slave     ( vbuf_byteenable        ),
                                .write_slave          ( vbuf_write             ),

                                .waitrequest_master   ( f2h_vbuf_waitrequest   ),
                                .burstcount_master    ( f2h_vbuf_burstcount    ),
                                .address_master       ( f2h_vbuf_address       ),
                                .readdata_master      ( f2h_vbuf_readdata      ),
                                .readdatavalid_master ( f2h_vbuf_readdatavalid ),
                                .read_master          ( f2h_vbuf_read          ),
                                .writedata_master     ( f2h_vbuf_writedata     ),
                                .byteenable_master    ( f2h_vbuf_byteenable    ),
                                .write_master         ( f2h_vbuf_write         )
                            );

    ////////////////////////////////////////////////////////
    ////             HPS <> FPGA interfaces             ////
    ////////////////////////////////////////////////////////
    hps_fpga_interface fpga_interfaces
                       (
                           .f2h_cold_rst_req_n       ( ~reset_hps_cold_req    ),
                           .f2h_warm_rst_req_n       ( ~reset_hps_warm_req    ),
                           .h2f_user0_clk            ( clock                  ),
                           .h2f_rst_n                ( hps_h2f_reset_n        ),
                           .f2h_sdram0_clk           ( vbuf_clk               ),
                           .f2h_sdram0_ADDRESS       ( f2h_vbuf_address       ),
                           .f2h_sdram0_BURSTCOUNT    ( f2h_vbuf_burstcount    ),
                           .f2h_sdram0_WAITREQUEST   ( f2h_vbuf_waitrequest   ),
                           .f2h_sdram0_READDATA      ( f2h_vbuf_readdata      ),
                           .f2h_sdram0_READDATAVALID ( f2h_vbuf_readdatavalid ),
                           .f2h_sdram0_READ          ( f2h_vbuf_read          ),
                           .f2h_sdram0_WRITEDATA     ( f2h_vbuf_writedata     ),
                           .f2h_sdram0_BYTEENABLE    ( f2h_vbuf_byteenable    ),
                           .f2h_sdram0_WRITE         ( f2h_vbuf_write         ),
                           .f2h_sdram1_clk           ( ram1_clk               ),
                           .f2h_sdram1_ADDRESS       ( f2h_ram1_address       ),
                           .f2h_sdram1_BURSTCOUNT    ( f2h_ram1_burstcount    ),
                           .f2h_sdram1_WAITREQUEST   ( f2h_ram1_waitrequest   ),
                           .f2h_sdram1_READDATA      ( f2h_ram1_readdata      ),
                           .f2h_sdram1_READDATAVALID ( f2h_ram1_readdatavalid ),
                           .f2h_sdram1_READ          ( f2h_ram1_read          ),
                           .f2h_sdram1_WRITEDATA     ( f2h_ram1_writedata     ),
                           .f2h_sdram1_BYTEENABLE    ( f2h_ram1_byteenable    ),
                           .f2h_sdram1_WRITE         ( f2h_ram1_write         ),
                           .f2h_sdram2_clk           ( ram2_clk               ),
                           .f2h_sdram2_ADDRESS       ( f2h_ram2_address       ),
                           .f2h_sdram2_BURSTCOUNT    ( f2h_ram2_burstcount    ),
                           .f2h_sdram2_WAITREQUEST   ( f2h_ram2_waitrequest   ),
                           .f2h_sdram2_READDATA      ( f2h_ram2_readdata      ),
                           .f2h_sdram2_READDATAVALID ( f2h_ram2_readdatavalid ),
                           .f2h_sdram2_READ          ( f2h_ram2_read          ),
                           .f2h_sdram2_WRITEDATA     ( f2h_ram2_writedata     ),
                           .f2h_sdram2_BYTEENABLE    ( f2h_ram2_byteenable    ),
                           .f2h_sdram2_WRITE         ( f2h_ram2_write         )
                       );

    wire hps_h2f_reset_n;

    reg init_reset_n = 0;
    always @(posedge clock) begin
        integer timeout = 0;

        if(timeout < 2000000) begin
            init_reset_n <= 0;
            timeout <= timeout + 1;
        end
        else begin
            init_reset_n <= 1;
        end
    end

endmodule
