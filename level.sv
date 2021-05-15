`include "pheapTypes.sv"

module level
    import pheapTypes::*;

    (input logic clk, wenTop, raddrTop, raddrBot, wraddrTop, pheapTypes::entry_t aTop,
    output pheapTypes::entry_t yTop
);

    pheapTypes::entry_t level_mem = {32'h00000000, {LEVELS{1'b1}}, 1'b0};
    
    //initial level_mem = {32'h00000000, {LEVELS{1'b1}}, 1'b0};

    always_ff @(posedge clk) begin
        if (wenTop) begin
            level_mem <= aTop;
            if (wraddrTop == raddrTop) yTop <= aTop;
            else yTop <= level_mem;
        end else yTop <= level_mem;
        
    end

endmodule
