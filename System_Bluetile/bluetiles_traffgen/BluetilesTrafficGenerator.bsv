package BluetilesTrafficGenerator;

import Bluetiles::*;
import ClientServer::*;
import GetPut::*;

interface BluetilesTrafficGenerator;
	interface BlueClient bluetile;
endinterface

(* synthesize *)
module mkBluetilesTrafficGenerator(BluetilesTrafficGenerator);
	Reg#(int) num <- mkReg(0);

	interface BlueClient bluetile;
		interface Get request;
			method ActionValue#(BlueBits) get() if(num < 2);
				BlueBits rv = 0;

				if(num == 0)
					rv = 'h00000001;
				else
					rv = 'h01006006;

				num <= num + 1;
				return rv;
			endmethod
		endinterface

		interface Put response;
			method Action put(BlueBits x);
			endmethod
		endinterface
	endinterface
endmodule

endpackage
