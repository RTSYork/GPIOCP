// Main package containing the relevant data structures and macros for the Bluetiles system.
// Should feed into both the plain Bluetiles routers and Bharath's routers.
package Bluetiles;

import FIFO::*;
import GetPut::*;
import ClientServer::*;
import Connectable::*;

typedef Bit#(32) DWord;
typedef DWord BlueBits;
typedef Bit#(16) HalfBus;
typedef Bit#(8) LocationX;
typedef Bit#(8) LocationY;
typedef Bit#(8) Priority;
typedef Bit#(8) PacketSize;
typedef Bit#(8) PortNumber;

typedef Server#(DWord, DWord) BlueServer;
typedef Client#(DWord, DWord) BlueClient;

typedef FIFO#(DWord) BlueFIFO;
typedef Put#(DWord) BluePut;
typedef Get#(DWord) BlueGet;

typedef struct {
        LocationX       dest_x;
        LocationY       dest_y;
        Priority        prio;
        PacketSize      size;
    } BT_Header_0 deriving (Bits, Eq);

typedef struct {
        LocationX       src_x;
        LocationY       src_y;
        PortNumber      src_port;
        PortNumber      dest_port;
    } BT_Header_1 deriving (Bits, Eq);

typedef struct {
        BT_Header_0     h0;
        BT_Header_1     h1;
    } BT_Header deriving (Bits, Eq);

function BT_Header bt_header_combine(BT_Header_0 h0, BT_Header_1 h1);
    BT_Header o = unpack(0);
    o.h0 = h0;
    o.h1 = h1;
    return o;
endfunction

function BT_Header bt_make_reply(BT_Header i, PacketSize payload_size);
    BT_Header o = unpack(0);
    o.h0.dest_x = i.h1.src_x;
    o.h0.dest_y = i.h1.src_y;
    o.h1.dest_port = i.h1.src_port;
    o.h1.src_x = i.h0.dest_x;
    o.h1.src_y = i.h0.dest_y;
    o.h1.src_port = i.h1.dest_port;
    o.h0.prio = i.h0.prio;
    o.h0.size = payload_size + 1;
    return o;
endfunction

typedef struct {
        Bit#(1)         address_hi;
        Bit#(23)        address;
        PacketSize      out_of_band;
    } BT_RW_Header deriving (Bits, Eq);

function BT_RW_Header bt_make_read_write_header(DWord address, Bit#(8) oob);
    BT_RW_Header h = unpack(0);
    h.out_of_band = oob;
    h.address = address[24:2];
    h.address_hi = address[31];
    return h;
endfunction

function DWord bt_get_read_write_address(BT_RW_Header h);
    DWord address = 0;
    address[24:2] = h.address;
    address[31] = h.address_hi;
    return address;
endfunction

function PacketSize bt_get_read_write_oob(BT_RW_Header h);
    return h.out_of_band;
endfunction

interface IfcBluetilesRouter;
    interface BlueServer north;
    interface BlueServer east;
    interface BlueClient south;
    interface BlueClient west;
    interface BlueServer home;
endinterface

endpackage

