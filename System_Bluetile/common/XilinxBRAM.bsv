// Block RAM generator for Xilinx devices
// 
// This code is supposed to be used from platforms/*/BlueBRAM.bsv, where
// the device-specific interface is defined. It is good for any platform
// offering block RAMs with 32-bit data interfaces and byte-wide enables.
// For other platforms (64 bit/16 bit?) we would have to extend this module
// with a higher level of polymorphism.
//
// First use of higher-order modules ("factory")!

package XilinxBRAM;

import BlueBRAMIf::*;
import List::*;
import DimensionRAM::*;

export DataPort;
export WEPort;
export IfcXBlockRAMPort(..);
export IfcXBlockRAM(..);
export IfcXRAM(..);
export mkXRAM;

typedef Bit#(32) DataPort;
typedef Bit#(4) WEPort;

interface IfcXBlockRAMPort#(type x_addr_type);
    method DataPort xread();
    method Action xput(WEPort we, x_addr_type addr, DataPort data);
endinterface

interface IfcXBlockRAM#(type x_addr_type);
    interface IfcXBlockRAMPort#(x_addr_type) xa;
    interface IfcXBlockRAMPort#(x_addr_type) xb;
endinterface

interface IfcXRAM#(type addr_type, type data_type, 
                        type we_type, type x_addr_type);
    interface IfcByteRAMPort#(addr_type, data_type, we_type) a;
    interface IfcByteRAMPort#(addr_type, data_type, we_type) b;
endinterface

module mkXRAM#(String name, Integer x_addr_offset,
        function module#(IfcXBlockRAM#(x_addr_type)) factory(Integer xds)) 
    (IfcXRAM#(addr_type, data_type, we_type, x_addr_type))
            provisos(Bits#(data_type, data_size),
                    Bits#(addr_type, addr_size),
                    Bits#(we_type, we_size),
                    Bits#(x_addr_type, x_addr_size),
                    Literal#(x_addr_type),
                    PrimUpdateable#(x_addr_type, Bit#(1)),
                    
                    // data_size = we_size * 8
                    Div#(data_size, 8, we_size),
                    Mul#(we_size, 8, data_size));

    GridConfiguration gc = getGridConfiguration(valueOf(addr_size),
                        valueOf(data_size), 
                        valueOf(SizeOf#(DataPort)),
                        2 ** valueOf(x_addr_size));

    if (!gc.valid) begin
        error("mkXRAM cannot generate a RAM with the requested dimensions");
    end

    Integer xilinx_size = gc.d_size;

    if (gc.d_size == 32) begin
        xilinx_size = 36;
    end else if (gc.d_size == 16) begin
        xilinx_size = 18;
    end else if (gc.d_size == 8) begin
        xilinx_size = 9;
    end else if ((gc.d_size != 4) && (gc.d_size != 2) && (gc.d_size != 1)) begin
        error("mkXRAM: Unsupported d_size");
    end

    List#(List#(IfcXBlockRAMPort#(x_addr_type))) rows_a;
    List#(List#(IfcXBlockRAMPort#(x_addr_type))) rows_b;
    List#(Reg#(Bool)) row_enable_a;
    List#(Reg#(Bool)) row_enable_b;
    Reg#(Bool) start <- mkReg(True);
    Integer x, y;

    // Per row: generate RAMs
    for (y = 0; y < gc.height; y = y + 1) begin
        List#(IfcXBlockRAMPort#(x_addr_type)) cols_a;
        List#(IfcXBlockRAMPort#(x_addr_type)) cols_b;


        // Per column: generate one RAM
        for (x = 0; x < gc.width; x = x + 1) begin
            IfcXBlockRAM#(x_addr_type) r <- factory(xilinx_size);

            cols_a = cons(r.xa, cols_a);
            cols_b = cons(r.xb, cols_b);
        end
        rows_a = cons(cols_a, rows_a);
        rows_b = cons(cols_b, rows_b);

        Reg#(Bool) enable_a <- mkReg(False);
        Reg#(Bool) enable_b <- mkReg(False);

        row_enable_a = cons(enable_a, row_enable_a);
        row_enable_b = cons(enable_b, row_enable_b);
    end

    // announce RAM settings
    rule run if (start);
        start <= False;
        $display(name, " XRAM settings:",
                " gc.addr_size=", gc.addr_size, 
                " gc.data_size=", gc.data_size, 
                " gc.width=", gc.width, 
                " gc.height=", gc.height, 
                " gc.d_size=", gc.d_size, 
                " gc.a_size=", gc.a_size, 
                " gc.unused_a_bits=", gc.unused_a_bits, 
                " gc.valid=", gc.valid,
                " size=", (gc.data_size * (2 ** gc.addr_size)),
                " bits");
    endrule

    // interface factory
    function IfcByteRAMPort#(addr_type, data_type, we_type)
            mkIf(List#(List#(IfcXBlockRAMPort#(x_addr_type))) rows, 
                List#(Reg#(Bool)) row_enable);

        return (interface IfcByteRAMPort#(addr_type, data_type, we_type);

            method data_type read();
                Integer x, y;
                Bit#(data_size) data1 = 0;

                // data extracted from grid
                for (y = 0; y < gc.height; y = y + 1) begin
                    List#(IfcXBlockRAMPort#(x_addr_type)) row = rows[y];
                    Bool ce = row_enable[y];
                    Bit#(data_size) data2 = 0;

                    for (x = 0; x < gc.width; x = x + 1) begin
                        DataPort part1 = row[x].xread();
                        Integer offset = x * gc.d_size;

                        data2 = data2 | (part1[gc.d_size - 1 : 0]
                                                    << offset);
                    end
                    if (ce) data1 = data2;
                end
                return unpack(data1);
            endmethod

            method Action put(we_type we, addr_type addr, data_type data);
                Integer i, x, y;

                // type conversion (Bit)
                Bit#(data_size) data1 = pack(data);
                Bit#(addr_size) addr1 = pack(addr);
                Bit#(we_size) we1 = pack(we);

               
                // Decode address into grid row and low bits
                Bit#(addr_size) addr_low_bits = 0;
                Bit#(addr_size) addr_grid_y = 0;
                for (i = 0; i < gc.addr_size; i = i + 1) begin
                    if (i < gc.a_size) begin
                        addr_low_bits[i] = addr1[i];
                    end else begin
                        addr_grid_y[i] = addr1[i];
                    end
                end

                // Low bits right-justified for use by RAMB16BWER
                x_addr_type addr2 = -1;
                for (i = 0; i < gc.a_size; i = i + 1) begin
                    Integer j = gc.a_size - (1 + i);
                    if (j < valueOf(addr_size)) begin
                        addr2[valueOf(SizeOf#(x_addr_type)) - (1 + 
                                x_addr_offset + i)] =
                                    addr_low_bits[j];
                    end
                end

                // Setup output lines
                for (y = 0; y < gc.height; y = y + 1) begin
                    Bool ce = (fromInteger(y * (2 ** gc.a_size)) == 
                                        (addr_grid_y));

                    row_enable[y] <= ce;

                    List#(IfcXBlockRAMPort#(x_addr_type)) row = rows[y];

                    for (x = 0; x < gc.width; x = x + 1) begin
                        Integer x1 = x * gc.d_size;
                        WEPort we2 = 0;
                        
                        if (ce) begin 
                            if (gc.d_size <= 9) begin
                                we2[0] = we1[x1 / 8];
                                we2 = {we2[0], we2[0], we2[0], we2[0]};
                            end else if (gc.d_size <= 18) begin
                                we2[1:0] = we1[(x1 / 8) + 1 : x1 / 8];
                                we2 = {we2[1:0], we2[1:0]};
                            end else begin
                                we2 = we1[(x1 / 8) + 3 : x1 / 8];
                            end
                        end

                        row[x].xput(we2, addr2, data1[x1 + gc.d_size - 1 : x1]);
                    end
                end
            endmethod
        endinterface);
    endfunction

    interface a = mkIf(rows_a, row_enable_a);
    interface b = mkIf(rows_b, row_enable_b);
endmodule

endpackage

