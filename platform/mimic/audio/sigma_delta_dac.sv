//------------------------------------------------------------------------------
// SPDX-License-Identifier: MIT
// SPDX-FileType: SOURCE
// SPDX-FileCopyrightText: (c) 2023, Open Gateware authors and contributors
//------------------------------------------------------------------------------
//
// Delta-Sigma DAC v1.1
// Copyright (c) 1999, Xilinx, Inc. All rights reserved.
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.
//
// Except as contained in this notice, the name of the Xilinx shall not be used
// in advertising or otherwise to promote the sale, use or other dealings in
// this Software without prior written authorization from Xilinx.
//
//------------------------------------------------------------------------------
//
// Digital to analog converters (DACs) convert a binary number into a voltage
// directly proportional to the value of the binary number.
// The only external circuitry required is a low pass filter comprised of
// just one resistor and one capacitor.
//
//     oDAC 0---XXXXX---+---0 analog audio
//               3k3    |
//                     === 4n7
//                      |
//                     GND
//
// Refer to Xilinx Application Note XAPP154.
//
//------------------------------------------------------------------------------

`default_nettype none

module sigma_delta_dac
    #(
         parameter MSBI = 7,         //! Most Significant Bit of DAC Input, NOT number of BITS
         parameter INV  = 1'b1
     ) (
         input  logic          iCLK, //! Positive edge clock for the SigmaLatch and the output D flip-flop.
         input  logic          iRST, //! Reset initializes the SigmaLatch and the output D flip-flop.
         input  logic [MSBI:0] iDAC, //! DAC input (excess 2**MSBI)
         output logic          oDAC  //! This is the average output that feeds low pass filter for optimum performance, ensure that this ff is in IOB
     );

    logic [MSBI+2:0] DeltaB;         //! B input of Delta Adder
    logic [MSBI+2:0] DeltaAdder;     //! Output of Delta Adder
    logic [MSBI+2:0] SigmaAdder;     //! Output of Sigma Adder
    logic [MSBI+2:0] SigmaLatch;     //! Latches output of Sigma Adder

    always @(*) DeltaB     = {SigmaLatch[MSBI+2], SigmaLatch[MSBI+2]} << (MSBI+1);
    always @(*) DeltaAdder = iDAC + DeltaB;
    always @(*) SigmaAdder = DeltaAdder + SigmaLatch;

    always @(posedge iCLK or posedge iRST) begin
        if(iRST) begin
            SigmaLatch <= 1'b1 << (MSBI+1);
            oDAC <= INV;
        end
        else begin
            SigmaLatch <= SigmaAdder;
            oDAC <= SigmaLatch[MSBI+2] ^ INV;
        end
    end

endmodule
