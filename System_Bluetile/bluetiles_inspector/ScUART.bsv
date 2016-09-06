// Membership: Library
// Purpose: Serial port
package ScUART;

export mkScUART;
export SerialWires(..);
export IfcScUART(..);

import StmtFSM::*;
import FIFOF::*;

interface SerialWires;
    (* always_ready *)
    (* always_enabled *)
    method Action rxd(Bit#(1) rx);

    (* always_ready *)
    method Bit#(1) txd();
endinterface
    
interface IfcScUART;
    method Action enq(Bit#(8) data);
    method Bit#(8) first();
    method Action deq();
    interface SerialWires serial;
endinterface

module mkScUART#(parameter Bit#(32) clk_freq, 
            parameter Bit#(32) baud_rate) (IfcScUART);

    FIFOF#(Bit#(8)) tx_fifo <- mkFIFOF();
    FIFOF#(Bit#(8)) rx_fifo <- mkFIFOF();
    Reg#(Bit#(1)) rx_raw <- mkReg(1);
	Bit#(16) clk16_max = truncate((clk_freq/baud_rate+8)/16-1);
    Reg#(Bit#(16)) baud_div_count <- mkReg(0);
    Bool pulse = (baud_div_count == 0);
    Reg#(Bit#(4)) rx_beat <- mkReg(8);
    Reg#(Bit#(4)) rx_count <- mkReg(0);
    Reg#(Bit#(1)) rx_data <- mkReg(1);
    Reg#(Bit#(3)) rx_debounce <- mkReg(~0);
    Reg#(Bit#(10)) rx_capture <- mkReg(0);
    Reg#(Bit#(4)) tx_beat <- mkReg(8);
    Reg#(Bit#(4)) tx_count <- mkReg(8);
    Reg#(Bit#(9)) tx_send <- mkReg(8);
    Reg#(Bit#(1)) tx_raw <- mkReg(1);

    rule baudcounter;
        if (pulse) begin
            baud_div_count <= clk16_max;
        end else begin
            baud_div_count <= baud_div_count - 1;
        end
    endrule

    rule rx_data_get if (pulse);
        // Pulse at 16x baud rate
        rx_debounce <= { rx_debounce[1:0], rx_raw };
        case (rx_debounce)
        3, 5, 6, 7:     rx_data <= 1;
        default:        rx_data <= 0;
        endcase
    endrule

    Stmt tx_shift_out = seq
        action
            tx_send <= { tx_fifo.first(), 1'b0 };
            tx_fifo.deq();
            tx_beat <= 1;
            tx_count <= 0;
        endaction
        while (tx_count != 11) action
            if (pulse) begin
                tx_beat <= tx_beat + 1;
                if (tx_beat == 0) begin
                    tx_raw <= tx_send[0];
                    tx_send <= { 1'b1, tx_send[8:1] };
                    tx_count <= tx_count + 1;
                end
            end
        endaction
    endseq;

    Stmt rx_shift_in = seq
        while (rx_data == 1) noAction;  // Await data
        while (rx_count != 10) action       // Start shifting
            if (pulse) begin
                rx_beat <= rx_beat + 1;
                if (rx_beat == 0) begin    // Wait for middle of data signal
                    rx_capture <= { rx_data , rx_capture[9:1] };
                    rx_count <= rx_count + 1;
                end
            end
        endaction
        action
            rx_beat <= 8;
            rx_count <= 0;
        endaction
        if (rx_fifo.notFull() && (rx_capture[0] == 0)
        && (rx_capture[9] == 1)) action
            rx_fifo.enq(rx_capture[8:1]);
        endaction
    endseq;

    FSM rx_shift_in_FSM <- mkFSM(rx_shift_in);
    FSM tx_shift_out_FSM <- mkFSM(tx_shift_out);

    rule rx_shift;
        rx_shift_in_FSM.start();
    endrule
            
    rule tx_shift;
        tx_shift_out_FSM.start();
    endrule
            
    method Action enq(Bit#(8) data);
        tx_fifo.enq(data);
    endmethod

    method Bit#(8) first();
        return rx_fifo.first();
    endmethod

    method Action deq();
        rx_fifo.deq();
    endmethod

    interface SerialWires serial;
        method Action rxd(Bit#(1) rx);
            rx_raw <= rx;
        endmethod

        method Bit#(1) txd();
            return tx_raw;
        endmethod
    endinterface
endmodule


endpackage

