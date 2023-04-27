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

module audio_out
    #(
         parameter CLK_RATE = 24576000
     ) (
         input        reset,
         input        clk,

         //0 - 48KHz, 1 - 96KHz
         input        sample_rate,

         input  [31:0] flt_rate,
         input  [39:0] cx,
         input   [7:0] cx0,
         input   [7:0] cx1,
         input   [7:0] cx2,
         input  [23:0] cy0,
         input  [23:0] cy1,
         input  [23:0] cy2,

         input  [4:0] att,
         input  [1:0] mix,

         input        is_signed,
         input [15:0] core_l,
         input [15:0] core_r,

         input [15:0] alsa_l,
         input [15:0] alsa_r,

         // I2S
         output       i2s_bclk,
         output       i2s_lrclk,
         output       i2s_data,

         // SPDIF
         output       spdif,

         // Sigma-Delta DAC
         output       dac_l,
         output       dac_r
     );

    localparam AUDIO_RATE = 48000;
    localparam AUDIO_DW = 16;

    localparam CE_RATE = AUDIO_RATE*AUDIO_DW*8;
    localparam FILTER_DIV = (CE_RATE/(AUDIO_RATE*32))-1;

    wire [31:0] real_ce = sample_rate ? {CE_RATE[30:0],1'b0} : CE_RATE[31:0];

    reg mclk_ce;
    always @(posedge clk) begin
        reg [31:0] cnt;

        mclk_ce = 0;
        cnt = cnt + real_ce;
        if(cnt >= CLK_RATE) begin
            cnt = cnt - CLK_RATE;
            mclk_ce = 1;
        end
    end

    reg i2s_ce;
    always @(posedge clk) begin
        reg div;
        i2s_ce <= 0;
        if(mclk_ce) begin
            div <= ~div;
            i2s_ce <= div;
        end
    end

    i2s i2s
        (
            .reset      ( reset     ),

            .clk        ( clk       ),
            .ce         ( i2s_ce    ),

            .sclk       ( i2s_bclk  ),
            .lrclk      ( i2s_lrclk ),
            .sdata      ( i2s_data  ),

            .left_chan  ( al        ),
            .right_chan ( ar        )
        );

    spdif toslink
          (
              .rst_i        ( reset   ),

              .clk_i        ( clk     ),
              .bit_out_en_i ( mclk_ce ),

              .sample_i     ( {ar,al} ),
              .spdif_o      ( spdif   )
          );

    sigma_delta_dac #(15) sd_l
                    ( 
                        .iCLK ( clk   ),
                        .iRST ( reset ),
                        .iDAC ( {~al[15], al[14:0]} ),
                        .oDAC ( dac_l )
                    );

    sigma_delta_dac #(15) sd_r
                    (
                        .iCLK ( clk   ),
                        .iRST ( reset ),
                        .iDAC ( {~ar[15], ar[14:0]} ),
                        .oDAC ( dac_r )
                    );

    reg sample_ce;
    always @(posedge clk) begin
        reg [8:0] div = 0;
        reg [1:0] add = 0;

        div <= div + add;
        if(!div) begin
            div <= 2'd1 << sample_rate;
            add <= 2'd1 << sample_rate;
        end

        sample_ce <= !div;
    end

    reg flt_ce;
    always @(posedge clk) begin
        reg [31:0] cnt = 0;

        flt_ce = 0;
        cnt = cnt + {flt_rate[30:0],1'b0};
        if(cnt >= CLK_RATE) begin
            cnt = cnt - CLK_RATE;
            flt_ce = 1;
        end
    end

    reg [15:0] cl,cr;
    always @(posedge clk) begin
        reg [15:0] cl1, cl2;
        reg [15:0] cr1, cr2;

        cl1 <= core_l;
        cl2 <= cl1;
        if(cl2 == cl1)
            cl <= cl2;

        cr1 <= core_r;
        cr2 <= cr1;
        if(cr2 == cr1)
            cr <= cr2;
    end

    reg a_en1 = 0, a_en2 = 0;
    always @(posedge clk, posedge reset) begin
        reg  [1:0] dly1 = 0;
        reg [14:0] dly2 = 0;

        if(reset) begin
            dly1  <= 0;
            dly2  <= 0;
            a_en1 <= 0;
            a_en2 <= 0;
        end
        else begin
            if(flt_ce) begin
                if(~&dly1)
                    dly1 <= dly1 + 1'd1;
                else
                    a_en1 <= 1;
            end

            if(sample_ce) begin
                if(!dly2[13+sample_rate])
                    dly2 <= dly2 + 1'd1;
                else
                    a_en2 <= 1;
            end
        end
    end

    wire [15:0] acl, acr;
    IIR_filter #(.use_params(0)) IIR_filter
               (
                   .clk(clk),
                   .reset(reset),

                   .ce(flt_ce & a_en1),
                   .sample_ce(sample_ce),

                   .cx(cx),
                   .cx0(cx0),
                   .cx1(cx1),
                   .cx2(cx2),
                   .cy0(cy0),
                   .cy1(cy1),
                   .cy2(cy2),

                   .input_l({~is_signed ^ cl[15], cl[14:0]}),
                   .input_r({~is_signed ^ cr[15], cr[14:0]}),
                   .output_l(acl),
                   .output_r(acr)
               );

    wire [15:0] adl;
    DC_blocker dcb_l
               (
                   .clk(clk),
                   .ce(sample_ce),
                   .sample_rate(sample_rate),
                   .mute(~a_en2),
                   .din(acl),
                   .dout(adl)
               );

    wire [15:0] adr;
    DC_blocker dcb_r
               (
                   .clk(clk),
                   .ce(sample_ce),
                   .sample_rate(sample_rate),
                   .mute(~a_en2),
                   .din(acr),
                   .dout(adr)
               );

    wire [15:0] al, audio_l_pre;
    audio_mixer audmix_l
                (
                    .clk(clk),
                    .ce(sample_ce),
                    .att(att),
                    .mix(mix),

                    .core_audio(adl),
                    .pre_in(audio_r_pre),
                    .linux_audio(alsa_l),

                    .pre_out(audio_l_pre),
                    .out(al)
                );

    wire [15:0] ar, audio_r_pre;
    audio_mixer audmix_r
                (
                    .clk(clk),
                    .ce(sample_ce),
                    .att(att),
                    .mix(mix),

                    .core_audio(adr),
                    .pre_in(audio_l_pre),
                    .linux_audio(alsa_r),

                    .pre_out(audio_r_pre),
                    .out(ar)
                );

endmodule
