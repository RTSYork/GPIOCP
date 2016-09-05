
// Copyright (c) 2000-2009 Bluespec, Inc.

// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:

// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.

// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.
//
// $Revision: 17872 $
// $Date: 2009-09-18 14:32:56 +0000 (Fri, 18 Sep 2009) $

// This module is not synthesizable.

`ifdef BSV_ASSIGNMENT_DELAY
`else
`define BSV_ASSIGNMENT_DELAY
`endif


// A generator for resets from an absolute clock, starting at 
// time 0. The output reset is held for RSTHOLD cycles, RSTHOLD > 0.

module InitialReset (
                     CLK,
                     OUT_RST_N
                     );

   parameter          RSTHOLD = 2  ; // Width of reset shift reg

   input              CLK ;
   output             OUT_RST_N ;

   // synopsys translate_off

   reg [RSTHOLD-1:0]  reset_hold ;

   assign  OUT_RST_N = reset_hold[RSTHOLD-1] ;

   always @( posedge CLK )
     begin
       reset_hold <= `BSV_ASSIGNMENT_DELAY ( reset_hold << 1 ) | 'b1 ;
     end // always @ ( posedge CLK )

   initial
     begin
       #0 // Required so that negedge is seen by any derived async resets
       reset_hold = 0;  // set to all 0s: RSTHOLD{1'b0}
     end


   // synopsys translate_on
   
endmodule // InitialReset

