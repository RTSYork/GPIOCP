// Membership: Bluetiles
// Purpose: A serial port interface for the Bluetiles network

package TileVlab;

export IfcTileVlab(..);
export mkTileVlab;

import FIFO::*;
import GetPut::*;
import StmtFSM::*;
import ScUART::*;
import Bluetiles::*;
import ClientServer::*;

interface IfcTileVlab;
    interface SerialWires serial;
    interface BlueClient bluetile;
endinterface

(* synthesize *)
module mkTileVlab#(parameter Bit#(32) clk_freq, 
            parameter Bit#(32) baud_rate) (IfcTileVlab);
	FIFO#(BlueBits) i <- mkSizedFIFO(16);
	FIFO#(BlueBits) o <- mkFIFO();
    IfcScUART u <- mkScUART(clk_freq, baud_rate);
    Reg#(BlueBits) receive_bytes <- mkReg(0);
    Reg#(BlueBits) send_bytes <- mkReg(0);
    Reg#(Bit#(3)) send_counter <- mkReg(0);
    Reg#(Bit#(3)) receive_counter <- mkReg(0);

    Stmt lab = seq
        // Synchronise with the virtual lab software on the user's PC
        while (True) seq
            while (u.first() != 8'h42) seq // Await B
                u.enq(8'h3f); // Incorrect byte, reply with "?"
                u.deq();
            endseq
            u.deq();
            if (u.first() != 8'h74) seq // Await t
                u.enq(8'h3f); // Incorrect byte, reply with "?"
                u.deq();
                continue;
            endseq
            u.deq();
            u.enq(8'h4f); // Reply "Ok2"
            u.enq(8'h6b); 
            u.enq(8'h32); 

            // Enter relay stage 
            par while (True) seq // Relay to the PC
                    send_bytes <= i.first();
                    i.deq();
                
                    send_counter <= 0;
                    while (send_counter != 4) action
                        u.enq(send_bytes[31:24]);
                        send_bytes <= {send_bytes[23:0], ?};
                        send_counter <= send_counter + 1;
                    endaction
                endseq
                while (True) seq // Relay from the PC
                    receive_counter <= 0;
                    while (receive_counter != 4) action
                        receive_bytes <= {receive_bytes[23:0], u.first()};
                        u.deq();
                        receive_counter <= receive_counter + 1;
                    endaction
                    o.enq(receive_bytes);
                endseq
            endpar           
        endseq
    endseq;

    FSM lab_FSM <- mkFSM(lab);

    rule when_reset;
        lab_FSM.start();
    endrule

    interface serial = u.serial;
    interface BlueClient bluetile;
        interface Put response;
            method Action put(BlueBits b);
                $display("VLAB: %c%c%c%c", b[7:0], b[15:8], b[23:16], b[31:24]);
                i.enq(b);
            endmethod
        endinterface
        interface request = toGet(o);
    endinterface
endmodule


endpackage
