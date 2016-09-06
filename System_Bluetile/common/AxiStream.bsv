package AxiStream;

export AXISMaster(..);
export AXISMasterLast(..);
export AXISSlave(..);

interface AXISMaster#(type dataType);
    (* ready="M_AXIS_TVALID", result="M_AXIS_TDATA" *)
    method dataType get_data();

    (* always_ready *)
    (* enable="M_AXIS_TREADY" *)
    method Action slave_is_ready();
endinterface

interface AXISMasterLast#(type dataType);
    (* ready="M_AXIS_TVALID", result="M_AXIS_TDATA" *)
    method dataType get_data();

    (* always_ready *)
    (* enable="M_AXIS_TREADY" *)
    method Action slave_is_ready();

    (* always_ready *)
    (* result="M_AXIS_TLAST" *)
    method Bit#(1) slave_is_last();
endinterface

interface AXISSlave#(type dataType);
    (* ready = "S_AXIS_TREADY", enable="S_AXIS_TVALID", prefix = "" *)
    method Action put_data((* port = "S_AXIS_TDATA" *)dataType data);
endinterface

endpackage