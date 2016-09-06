// Implements a mutex. This is intended to be included from elsewhere.
// This is parameterised on a index type for mutexes (i.e. how many mutexes there are)
// and a type for CPU indices (e.g. how many CPUs there are). The methods
// should be self explanatory. They either return True/False on success/failure
// or get_mutex_owner returns a Maybe type with the mutex owner.
package MutexManager;

export IfcMutexManager(..);
export mkMutexManager;

interface IfcMutexManager#(type mutex_index, type cpu_store);
    method Bool is_mutex_taken(mutex_index mux);
    method Maybe#(cpu_store) get_mutex_owner(mutex_index mux);
    method ActionValue#(Bool) take_mutex(mutex_index mux, cpu_store cpu);
    method ActionValue#(Bool) release_mutex(mutex_index mux, cpu_store cpu);
endinterface

module mkMutexManager(IfcMutexManager#(mutex_index, cpu_store))
    provisos(
	     Bits#(mutex_index, mutex_index_bits),
	     Bits#(cpu_store, cpu_store_bits),
	     Eq#(cpu_store),
	     PrimIndex#(mutex_index, __a)
       );
    
    Integer num_mutexes = 2**valueOf(mutex_index_bits);
    
    Reg#(Bool) mutex_taken[num_mutexes];
    Reg#(cpu_store) mutex_owner[num_mutexes];
    
    for(Integer i = 0; i < num_mutexes; i = i + 1) begin
	mutex_taken[i] <- mkReg(False);
	mutex_owner[i] <- mkReg(unpack(0));
    end
    
    method Bool is_mutex_taken(mutex_index mux);
	return mutex_taken[mux];
    endmethod
    
    method Maybe#(cpu_store) get_mutex_owner(mutex_index mux);
	if(mutex_taken[mux])
	    return tagged Valid mutex_owner[mux];
	else
	    return tagged Invalid;
    endmethod
    
    method ActionValue#(Bool) take_mutex(mutex_index mux, cpu_store cpu);
	if(mutex_taken[mux])
	    return False;
	else begin
	    mutex_owner[mux] <= cpu;
	    mutex_taken[mux] <= True;
	    return True;
	end
    endmethod
    
    method ActionValue#(Bool) release_mutex(mutex_index mux, cpu_store cpu);
	if(!mutex_taken[mux])
	    return False;
	else if(mutex_owner[mux] != cpu)
	    return False;
	else begin
	    mutex_taken[mux] <= False;
	    return True;
	end
    endmethod
endmodule
    
endpackage