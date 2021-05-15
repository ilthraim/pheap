`include "pheapTypes.sv"

module leq
    import pheapTypes::*;

    #(parameter LEVEL=2)
    (input logic start, [LEVEL - 1:0] startPos,  [31:0] in, pheapTypes::entry_t rTop, rBot, pheapTypes::opcode_t op,
    output logic wenTop, pheapTypes::done_t done, [LEVEL - 1:0] raddrTop, wraddrTop, [LEVEL:0] raddrBot, [LEVEL:0] endPos, [31:0] out, pheapTypes::entry_t wData
);


    assign wraddrTop = startPos;
    assign raddrTop = startPos;

    always_comb begin
        done = WAIT;
        endPos = 'b0;
        out = 'b0;
        wenTop = 1'b0;
        if (start) begin
            if (op == LEQ) begin
                raddrBot = {startPos, 1'b0};
                if (~rTop.active) begin
                    wData.active = 1'b1;
                    wData.capacity = rTop.capacity - 1;
                    wData.priorityValue = in; //gotta fix this - write the prioritity, decremented capacity and active
                    wenTop = 1'b1;
                    done = DONE;
                end else begin
                    if (rTop.priorityValue < in) begin //also fix this - if currentpriority less than priority to be written
                        out = rTop.priorityValue; //take a look at this logic: idk if legal
                        wData.active = 1'b1;
                        wData.capacity = rTop.capacity - 1;
                        wData.priorityValue = in;
                        wenTop = 1'b1;
                    end else out = in;
                    if (rBot.capacity != 0)
                        endPos = {startPos, 1'b0};
                    else
                        endPos = {startPos, 1'b0} + 1;

                    done = NEXT_LEVEL;
                end
            end else begin //have to do capacities
                done = WAIT;
                out = rTop.priorityValue;
                raddrBot = {startPos, 1'b0};
                if (rBot.active == 1'b0) begin //double check blocking logic here, also the if logic doesn't work if one is
                    raddrBot = {startPos, 1'b1};
                    if (rBot.active == 1'b0)
                        done = DONE;
                end
                if (done != DONE) begin
                    
                end

            end
        end
    end

    always_comb begin

    end

endmodule
