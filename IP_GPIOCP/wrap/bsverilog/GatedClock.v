
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

`ifdef BSV_ASSIGNMENT_DELAY
`else
`define BSV_ASSIGNMENT_DELAY
`endif

// Bluespec primitive module which gates a clock
// To avoid glitches, CLK_GATE_OUT only changes  when CLK_IN is low.  
// CLK_GATE_OUT follows CLK_GATE_IN in the same cycle, but COND is first
// registered, thus delaying the gate condition by one cycle.
// In this model, the oscillator CLK_OUT stop when the CLK_GATE_IN or
// COND are deasserted.
module GatedClock(
		  // ports for the internal register
		  CLK,
		  RST_N,
                  COND,
		  COND_EN,
		  COND_OUT,

		  // ports for the input clock being gated
		  CLK_IN,
		  CLK_GATE_IN,

		  // ports for the output clock
                  CLK_OUT,
                  CLK_GATE_OUT );
   
   parameter init = 1 ;

   input  CLK ;
   input  RST_N ;
   input  COND ;
   input  COND_EN ;
   output COND_OUT ;

   input  CLK_IN ;
   input  CLK_GATE_IN ;

   output CLK_OUT ;
   output CLK_GATE_OUT ;

   reg    new_gate ;
   reg    COND_reg ;
   
   assign COND_OUT = COND_reg;

   assign CLK_OUT = CLK_IN & new_gate ;
   assign CLK_GATE_OUT = new_gate ;

   // Use latch to avoid glitches
   // Gate can only change when clock is low
   always @( CLK_IN or CLK_GATE_IN or COND_reg )
     begin
        if ( ! CLK_IN )
          new_gate <= `BSV_ASSIGNMENT_DELAY CLK_GATE_IN & COND_reg ;
     end

   // register the COND (asynchronous reset)
   always @( posedge CLK or negedge RST_N )
     begin
	if ( RST_N == 0 )
	  COND_reg <= `BSV_ASSIGNMENT_DELAY init ;
        else
          begin
             if ( COND_EN )
               COND_reg <= `BSV_ASSIGNMENT_DELAY COND ;
          end
     end

`ifdef BSV_NO_INITIAL_BLOCKS
`else // not BSV_NO_INITIAL_BLOCKS
   // synopsys translate_off
   initial
      begin
	 #0 ;
         new_gate = 1'b0 ;
	 COND_reg = 1'b0 ;
      end // initial begin
   // synopsys translate_on
`endif // BSV_NO_INITIAL_BLOCKS
   
endmodule // GatedClock

