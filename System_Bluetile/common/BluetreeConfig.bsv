// The width of all fields in Bluetree. Make sure to change all XPS projects
// if anything in this file is changed!
package BluetreeConfig;

export BluetreeClient(..);
export BluetreeServer(..);
export FattreeClient(..);
export FattreeServer(..);
export BluetreeTaskId;
export BluetreeCPUId;
export BluetreeData;
export BluetreeBEN;
export FattreeData;
export FattreeBEN;
export BluetreeAddress;
export BluetreeBlockAddress;
export FattreeBlockAddress;
export BluetreeByteAddress;
export BluetreeWordAddress;
export BluetreeBurstCounter;
export BluetreePriority;

export BluetreeServerPacket(..);
export BluetreeClientPacket(..);
export FattreeServerPacket(..);
export FattreeClientPacket(..);
export BluetreeMessageType(..);
export BluetreeClientMessageType(..);

export bluetreeBlockSize;
export bluetreeDataSize;
export fattreeDataSize;
export bluetreeBlockAddressSize;
export fattreeBlockAddressSize;
export bluetreeByteAddressSize;
export bluetreeWordAddressSize;
export bluetreeAddressSize;
export bluetreeBENSize;
export fattreeBENSize;
export bluetreeBurstCounterSize;
export bluetreePrioritySize;

import ClientServer::*;
import GetPut::*;

typedef Bit#(8) BluetreeTaskId;
typedef Bit#(8) BluetreeCPUId;
typedef Bit#(128) BluetreeData;
typedef Bit#(512) FattreeData;
typedef Bit#(28) BluetreeBlockAddress;
typedef Bit#(26) FattreeBlockAddress;
typedef Bit#(16) BluetreeBEN;
typedef Bit#(64) FattreeBEN;
typedef Bit#(4) BluetreeByteAddress;
typedef Bit#(2) BluetreeWordAddress;
typedef Bit#(32) BluetreeAddress;
typedef Bit#(4) BluetreeBurstCounter;
typedef Bit#(4) BluetreePriority;

typedef SizeOf#(BluetreeData) DataSize;
Integer bluetreeDataSize = valueOf(DataSize);

typedef SizeOf#(FattreeData) FatDataSize;
Integer fattreeDataSize = valueOf(FatDataSize);

typedef SizeOf#(BluetreeBEN) BENSize;
Integer bluetreeBENSize = valueOf(BENSize);

typedef SizeOf#(FattreeBEN) FatBENSize;
Integer fattreeBENSize = valueOf(FatBENSize);

typedef SizeOf#(BluetreeBlockAddress) BlockAddressSize;
Integer bluetreeBlockAddressSize = valueOf(BlockAddressSize);

typedef SizeOf#(FattreeBlockAddress) FatBlockAddressSize;
Integer fattreeBlockAddressSize = valueOf(FatBlockAddressSize);

typedef SizeOf#(BluetreeByteAddress) ByteAddressSize;
Integer bluetreeByteAddressSize = valueOf(ByteAddressSize);

typedef SizeOf#(BluetreeWordAddress) WordAddressSize;
Integer bluetreeWordAddressSize = valueOf(WordAddressSize);

typedef SizeOf#(BluetreeAddress) AddressSize;
Integer bluetreeAddressSize = valueOf(AddressSize);

Integer bluetreeBlockSize = bluetreeBENSize;

typedef SizeOf#(BluetreeBurstCounter) BurstCounterSize;
Integer bluetreeBurstCounterSize = valueOf(BurstCounterSize);

typedef SizeOf#(BluetreePriority) PrioritySize;
Integer bluetreePrioritySize = valueOf(PrioritySize);

// BT_MEM_SCHEDULED is to notify multiplexors of which CPU has been scheduled.
typedef enum {BT_READ = 0, BT_BROADCAST, BT_PREFETCH, BT_WRITE_ACK, BT_AXI_PROBE, BT_SQUASH, BT_MEM_SCHEDULED}
            BluetreeMessageType deriving (Bits, Eq);

// Standard = normal mem request. Prefetch is to signify a prefetch packet and is currently largely
// unused. Prefetch hit denotes that a prefetched packet was hit and so another prefetch should be generated.
// BT_AXI_PROBE is used for sending a command to the AXI bus.
typedef enum {BT_STANDARD = 0, BT_PREFETCH, BT_PREFETCH_HIT, BT_AXI_PROBE}
            BluetreeClientMessageType deriving (Bits, Eq);

typedef struct {
    BluetreeClientMessageType   message_type;
    BluetreeData                data;
    BluetreeBEN                 ben;
    BluetreeBlockAddress        address;
    BluetreeTaskId              task_id;
    BluetreeCPUId               cpu_id;
    BluetreePriority            prio;
    BluetreeBurstCounter        size;
} BluetreeClientPacket deriving (Bits, Eq);

typedef struct {
    BluetreeMessageType     message_type;
    BluetreeData            data;
    BluetreeBlockAddress    address;
    BluetreeTaskId          task_id;
    BluetreeCPUId           cpu_id;
} BluetreeServerPacket deriving (Bits, Eq);

typedef Client#(BluetreeClientPacket, BluetreeServerPacket) BluetreeClient;
typedef Server#(BluetreeClientPacket, BluetreeServerPacket) BluetreeServer;

typedef struct {
    BluetreeClientMessageType   message_type;
    FattreeData                 data;
    FattreeBEN                  ben;
    FattreeBlockAddress         address;

    // For compatibility with Bluetree without having to store intermediate packets
    Bit#(2)                     steering;

    BluetreeTaskId              task_id;
    BluetreeCPUId               cpu_id;
    BluetreePriority            prio;
    BluetreeBurstCounter        size;
} FattreeClientPacket deriving (Bits, Eq);

typedef struct {
    BluetreeMessageType     message_type;
    FattreeData             data;
    FattreeBlockAddress     address;

    // For compatibility with Bluetree without having to store intermediate packets
    Bit#(2)                 steering;

    BluetreeTaskId          task_id;
    BluetreeCPUId           cpu_id;
} FattreeServerPacket deriving (Bits, Eq);

typedef Client#(FattreeClientPacket, FattreeServerPacket) FattreeClient;
typedef Server#(FattreeClientPacket, FattreeServerPacket) FattreeServer;

endpackage

