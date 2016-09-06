package UpDownCounter;

export IfcUpDownCounter(..);
export mkUpDownCounter;
export mkUpDownCounterInit;

interface IfcUpDownCounter#(numeric type c_size);
    method Action inc();
    method Action dec();
    method Bool is_zero();
    method Bool is_pending_zero();
    method Bit#(c_size) _read();
endinterface

module mkUpDownCounterInit#(Bit#(c_size) inc_step, Bit#(c_size) init) (IfcUpDownCounter#(c_size));
    PulseWire i <- mkPulseWire();
    PulseWire d <- mkPulseWire();
    Reg#(Bit#(c_size)) count <- mkReg(init);

    Integer maxVal = 2**valueOf(c_size) - 1;

    rule update if (i != d);
        if (i) begin
            count <= count + 1 + inc_step;
        end else if (count != 0) begin
            count <= count - 1;
        end
    endrule

    method Action inc();
        i.send();
    endmethod

    method Action dec();
        d.send();
    endmethod

    method Bool is_zero();
        return (count == 0);
    endmethod
    
    method Bit#(c_size) _read();
    return count;
    endmethod

    method Bool is_pending_zero();
        return (count == 0) || ((count == 1) && d);
    endmethod
endmodule

module mkUpDownCounter#(Bit#(c_size) inc_step) (IfcUpDownCounter#(c_size));
    IfcUpDownCounter#(c_size) inner <- mkUpDownCounterInit(inc_step, 0);
    return inner;
endmodule

endpackage
