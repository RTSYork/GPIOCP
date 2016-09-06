
package DimensionRAM;


export GridConfiguration(..);
export getGridConfiguration;

typedef struct {
    Bool        valid;
    Integer     width;
    Integer     height;
    Integer     data_size;
    Integer     addr_size;
    Integer     d_size;
    Integer     a_size;
    Integer     words;
    Integer     num_rams;
    Integer     log_height;
    Integer     unused_a_bits;
} GridConfiguration;


function Bool is_log2(Integer x);
    while ((x > 1) && ((x % 2) == 0)) begin
        x = x / 2;
    end
    return ((x == 0) || (x == 1));
endfunction

function Integer div_ceil(Integer x, Integer y);
    return (x + y - 1) / y;
endfunction

function Integer log2_exact(Integer x);
    Integer y = 0;
    while ((2 ** y) != x) begin
        y = y + 1;
    end
    return y;
endfunction

function GridConfiguration 
            getGridConfiguration(Integer addr_size, Integer data_size,
                    Integer data_max, Integer ram_size);
    // Number of RAMs (determine range)
    Integer max_width = data_size; // 1 bit each
    Integer min_width = div_ceil(data_size, data_max);

    Bool input_ok = is_log2(data_size) && (data_size >= 1)
                && (addr_size >= 1);

    // For each possible grid width, find RAM dimensions & grid height
    Integer width = min_width;
    GridConfiguration best;
    best.valid = False;

    while (width <= max_width) begin
        GridConfiguration now;

        now.valid = input_ok;
        now.addr_size = addr_size;
        now.data_size = data_size;
        now.width = width;

        now.valid = now.valid && ((data_size % now.width) == 0);
        now.d_size = data_size / now.width;

        now.valid = now.valid && ((ram_size % now.d_size) == 0);
        now.words = ram_size / now.d_size;
        now.a_size = log2_exact(now.words);

        now.log_height = max(0, addr_size - now.a_size);
        now.height = 2 ** now.log_height;
        now.num_rams = now.width * now.height;
        now.unused_a_bits = 0;
        if (now.addr_size < now.a_size) begin
            now.unused_a_bits = now.a_size - now.addr_size;
        end

        if ((!best.valid)
        || (now.num_rams < best.num_rams)
        || ((now.num_rams == best.num_rams)
        && (now.height < best.height))) begin
            best = now;
        end

        width = width * 2;
    end
    return best;
endfunction

(* synthesize *)
module mkTestDimensionRAM (Empty);
    rule test;
        Integer a, d;
        
        for (a = 1; a < 12; a = a + 1) begin
            for (d = 1; d <= 256; d = d * 2) begin
                GridConfiguration gc = getGridConfiguration(a, d, 32, 16384);
                $display(a, " ", d, " ", gc.width, " ",
                        gc.height, " ", gc.d_size, " ",
                        gc.a_size, " ", gc.unused_a_bits, " ",
                        gc.valid);
            end
        end
        $finish(0);
    endrule
endmodule

endpackage

