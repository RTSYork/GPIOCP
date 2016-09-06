// Block RAM generator for Virtex-6 or 7-series
// Produces RAMB36E1 block RAMs, each 32Kbits in size,
// with data width in [1, 2, 4, 8, 16, 32] bits.
//
// V6/V7 specific code is found here. More general Xilinx code is
// in platforms/Xilinx.bsv - this applies to block RAMs on any 
// Xilinx device. And platform-independent block RAM interfaces are
// found in BlueBRAMIf.bsv.

package BlueBRAM;

export mkByteRAM;
export IfcByteRAMPort(..);
export IfcByteRAM(..);

import BlueBRAMIf::*;
import XilinxBRAM::*;

typedef Bit#(15) UpperBoundAddr;

typedef IfcXBlockRAM#(UpperBoundAddr) IfcXBlockRAMV6;

import "BVI" bram_v6 =
module mkRAMV6#(Integer data_width) (IfcXBlockRAMV6);

    default_clock my_clk;
    input_clock my_clk (CLK) <- exposeCurrentClock;
    default_reset my_rst;
    input_reset my_rst (RST_N) <- exposeCurrentReset;

    parameter DATA_WIDTH = data_width;

    interface IfcXBlockRAMPort xa;
        method DOA xread();
        method xput(WEA, ADDRA, DIA) enable(ENA);
    endinterface
    interface IfcXBlockRAMPort xb;
        method DOB xread();
        method xput(WEB, ADDRB, DIB) enable(ENB);
    endinterface

    // read methods do not conflict
    schedule (xa.xread, xb.xread) CF (xa.xread, xb.xread);

    // put methods conflict with themselves
    schedule xa.xput C xa.xput;
    schedule xb.xput C xb.xput;
    schedule xa.xput CF (xb.xput, xa.xread, xb.xread);
    schedule xb.xput CF (xa.xput, xa.xread, xb.xread);
endmodule


module mkByteRAM#(String name) (IfcByteRAM#(addr_type, data_type, we_type))
            provisos(Bits#(data_type, data_size),
                    Bits#(addr_type, addr_size),
                    Bits#(we_type, we_size),
                    
                    // data_size = we_size * 8
                    Div#(data_size, 8, we_size),
                    Mul#(we_size, 8, data_size));

    function module#(IfcXBlockRAMV6) factory(Integer xds);
        return mkRAMV6(xds);
    endfunction

    IfcXRAM#(addr_type, data_type, we_type, UpperBoundAddr) xr <- 
                    mkXRAM(name, 0, factory);

    interface a = xr.a;
    interface b = xr.b;
endmodule



endpackage

