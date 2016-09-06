// Membership: Bluetiles
// Purpose: Network router

//
// NoC wormhole router
// Nathan Lasseter (njel500)
// Jack Whitham 
// University of York Computer Science Department
// Summer 2012
//
//
// The router comprises five "forwarders", which sit around the edge
// on the INPUT ports, and forward packets when they are allowed.
//
package BluetilesRouter;

/*
 * Things other people need access to
 */
export IfcBluetilesRouter(..);
export mkBluetilesRouter;

/*
 * Things we need access to
 */
import FIFO::*;
import GetPut::*;
import Bluetiles::*;
import ClientServer::*;
import Connectable::*;

/*
 * Some handy type synonyms
 */
typedef enum { HEADER, HEADER_2, PAYLOAD } FSMState deriving (Bits, Eq);
typedef enum { BLACKHOLE, NORTH, EAST, SOUTH, WEST, HOME } Port deriving (Bits, Eq, Bounded);


/*
 * This interface sits on each incoming port.
 */
interface Inner; endinterface

/*
 * This is the forwarding logic for each input port
 */
module mkInner#(String me, LocationX xAddr, LocationY yAddr, BlueFIFO in,
				BlueFIFO n_out, BlueFIFO s_out, BlueFIFO e_out, BlueFIFO w_out, BlueFIFO h_out,
				Reg#(Bit#(6)) lockreg) (Inner);

	Reg#(FSMState) state <- mkReg(HEADER);	// Current FSM state
	Reg#(PacketSize) size <- mkReg(0);			// Bluetiles payload size
	Reg#(Port) dstport <- mkReg(BLACKHOLE);	// Port to forward flits to

    BT_Header_0 h0 = unpack(in.first());
    LocationX packX = h0.dest_x;
    LocationY packY = h0.dest_y;
    Port dst = BLACKHOLE;

    if (packX < xAddr) begin
        dst = WEST;
    end else if (packX == xAddr) begin
        if (packY < yAddr) begin
            dst = NORTH;
        end else if (packY == yAddr) begin
            dst = HOME;
        end else begin
            dst = SOUTH;
        end
    end else begin 
        dst = EAST;
    end

	// Set up forwarding if the outgoing port is available
	rule r_header if ((state == HEADER) && (lockreg[pack(dst)] == 0));
        dstport <= dst;				    // Set that as the destination
        lockreg[pack(dst)] <= 1;	    // Lock it
        state <= PAYLOAD;				// Move on to next state
        size <= h0.size;
        $display(xAddr, yAddr, " routing header from ", me, " to ", dst,
                " data ", in.first());
    endrule

	rule r_blocked if ((state == HEADER) && (lockreg[pack(dst)] != 0));
        $display(xAddr, yAddr, " blocked header from ", me, " as ", dst,
                " is locked, data ", in.first());
	endrule

	// Forward on payload flits
    PacketSize minus_one = ~0;
    Bool done = (size == minus_one);

	rule r_payload_north ((state == PAYLOAD) && (!done) && (dstport == NORTH));
		size <= size - 1;
		in.deq();
        n_out.enq(in.first());
		$display(xAddr, yAddr, " routing payload from ", me, 
                " north, data ", in.first());
	endrule

	rule r_payload_east ((state == PAYLOAD) && (!done) && (dstport == EAST));
		size <= size - 1;
		in.deq();
        e_out.enq(in.first());
		$display(xAddr, yAddr, " routing payload from ", me, 
                " east , data ", in.first());
	endrule

	rule r_payload_south ((state == PAYLOAD) && (!done) && (dstport == SOUTH));
		size <= size - 1;
		in.deq();
        s_out.enq(in.first());
		$display(xAddr, yAddr, " routing payload from ", me, 
                " south, data ", in.first());
	endrule

	rule r_payload_west ((state == PAYLOAD) && (!done) && (dstport == WEST));
		size <= size - 1;
		in.deq();
        w_out.enq(in.first());
		$display(xAddr, yAddr, " routing payload from ", me, 
                " west, data ", in.first());
	endrule

	rule r_payload_home ((state == PAYLOAD) && (!done) && (dstport == HOME));
		size <= size - 1;
		in.deq();
        h_out.enq(in.first());
		$display(xAddr, yAddr, " routing payload from ", me, 
                " home, data ", in.first());
	endrule

	rule r_payload_bh ((state == PAYLOAD) && (!done) && (dstport == BLACKHOLE));
		size <= size - 1;
		in.deq();
		$display(xAddr, yAddr, " routing payload from ", me, 
                " blackhole, data ", in.first());
	endrule

	// Forward the last flit and tear down state
	rule r_finish (state == PAYLOAD && done);
		state <= HEADER;
		dstport <= BLACKHOLE;
		lockreg[pack(dstport)] <= 0;	// Unlock the outgoing port
		$display(xAddr, yAddr, " packet done for ", me, " to ", dstport);
	endrule

endmodule

/*
 * This is the actual router
 */

(* descending_urgency = "home_route.r_payload_north, east_route.r_payload_north, south_route.r_payload_north, west_route.r_payload_north, north_route.r_payload_north" *)
(* descending_urgency = "home_route.r_payload_east, east_route.r_payload_east, south_route.r_payload_east, west_route.r_payload_east, north_route.r_payload_east" *)
(* descending_urgency = "home_route.r_payload_south, east_route.r_payload_south, south_route.r_payload_south, west_route.r_payload_south, north_route.r_payload_south" *)
(* descending_urgency = "home_route.r_payload_west, east_route.r_payload_west, south_route.r_payload_west, west_route.r_payload_west, north_route.r_payload_west" *)
(* descending_urgency = "home_route.r_payload_home, east_route.r_payload_home, south_route.r_payload_home, west_route.r_payload_home, north_route.r_payload_home" *)
(* descending_urgency = "home_route.r_header, east_route.r_header, south_route.r_header, west_route.r_header, north_route.r_header, home_route.r_finish, east_route.r_finish, south_route.r_finish, west_route.r_finish, north_route.r_finish" *)
(* synthesize *)
module mkBluetilesRouter#(parameter LocationX xAddr, parameter LocationY yAddr) (IfcBluetilesRouter);
	Reg#(Bit#(6)) locks <- mkReg(0);	// Outgoing port locks

	// Input and output fifos
	BlueFIFO n_in <- mkSizedFIFO(16);
	BlueFIFO n_out <- mkSizedFIFO(16);
	BlueFIFO s_in <- mkSizedFIFO(16);
	BlueFIFO s_out <- mkSizedFIFO(16);
	BlueFIFO e_in <- mkSizedFIFO(16);
	BlueFIFO e_out <- mkSizedFIFO(16);
	BlueFIFO w_in <- mkSizedFIFO(16);
	BlueFIFO w_out <- mkSizedFIFO(16);
	BlueFIFO h_in <- mkSizedFIFO(16);
	BlueFIFO h_out <- mkSizedFIFO(16);

	// Forwarders
	Inner ifc_home_route ();
	mkInner#("home", xAddr, yAddr, h_in, n_out, s_out, e_out, w_out, h_out, locks) home_route (ifc_home_route);

	Inner ifc_north_route ();
	mkInner#("north", xAddr, yAddr, n_in, n_out, s_out, e_out, w_out, h_out, locks) north_route (ifc_north_route);

	Inner ifc_west_route ();
	mkInner#("west", xAddr, yAddr, w_in, n_out, s_out, e_out, w_out, h_out, locks) west_route (ifc_west_route);

	Inner ifc_south_route ();
	mkInner#("south", xAddr, yAddr, s_in, n_out, s_out, e_out, w_out, h_out, locks) south_route (ifc_south_route);

	Inner ifc_east_route ();
	mkInner#("east", xAddr, yAddr, e_in, n_out, s_out, e_out, w_out, h_out, locks) east_route (ifc_east_route);

	// External interfaces
    interface BlueServer north;
        interface request  = fifoToPut(n_in);
        interface response = fifoToGet(n_out);
    endinterface
    interface BlueClient south;
        interface response = fifoToPut(s_in);
        interface request  = fifoToGet(s_out);
    endinterface
    interface BlueServer east;
        interface request  = fifoToPut(e_in);
        interface response = fifoToGet(e_out);
    endinterface
    interface BlueClient west;
        interface response = fifoToPut(w_in);
        interface request  = fifoToGet(w_out);
    endinterface
    interface BlueServer home;
        interface request  = fifoToPut(h_in);
        interface response = fifoToGet(h_out);
    endinterface
endmodule

endpackage
