// Block RAM generator interfaces
// Block RAM modules are actually found in platforms/<fpga family>/BlueBRAM.bsv

package BlueBRAMIf;

export IfcByteRAMPort(..);
export IfcByteRAM(..);

interface IfcByteRAMPort#(type addr_type, type data_type, type we_type);
    method data_type read();
    method Action put(we_type we, addr_type addr, data_type data);
endinterface

interface IfcByteRAM#(type addr_type, type data_type, type we_type);
    interface IfcByteRAMPort#(addr_type, data_type, we_type) a;
    interface IfcByteRAMPort#(addr_type, data_type, we_type) b;
endinterface


endpackage


