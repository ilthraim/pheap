`include "pheapTypes.sv"

module pheap
    import pheapTypes::*;

    (input logic clk, rst, valid, [31:0] priorityIn, pheapTypes::opcode_t toperation,
    output logic rdy, [31:0] priorityOut, valid_out
    );

    pheapTypes::opArray_t opArray [LEVELS:1];
    
    initial begin
        for (int i = 1; i <= LEVELS; i++) begin
            opArray[i].levelOp = FREE;
            opArray[i].priorityValue = 0;
        end
    end
    
    logic wenTop [LEVELS:1];
    logic start [LEVELS:1];
    logic actives [LEVELS:1];
    logic shift_pos [LEVELS:1];
    pheapTypes::done_t [LEVELS:1] done ;
    pheapTypes::entry_t [LEVELS:1] a;
    pheapTypes::entry_t [LEVELS:1] yTop ;
    pheapTypes::entry_t [LEVELS + 1:1] yBotL ;
    pheapTypes::entry_t [LEVELS + 1:1] yBotR ;
    logic [31:0] outs [LEVELS:1];
    assign priorityOut = outs[1];
    assign yBotL[LEVELS + 1] = 'b0;
    assign yBotR[LEVELS + 1] = 'b0;

    genvar i;
    generate
        for (i = 1; i <= LEVELS; i = i + 1) begin: genHeap
            logic [i - 2:0] raddrTop ;
            logic [i - 1:0] raddrBot ; //this ones borked
            logic [i - 2:0] wraddrTop;
            logic [i - 2:0] startPos;
            logic [i - 1:0] endPos;

            if ((i != 1) && (i != LEVELS)) begin
                levelv2 #(i) I_LEVEL(.clk, .topActive(actives[i]), .wenTop(wenTop[i]), .raddrTop(genHeap[i].raddrTop), .raddrBot(genHeap[i - 1].raddrBot),
                .wraddrTop(genHeap[i].wraddrTop), .aTop(a[i]), .yTop(yTop[i]), .yBotR(yBotR[i]), .yBotL(yBotL[i]));

                leq #(i) I_LEQ(.clk, .rst, .start(start[i]), .startPos(genHeap[i].startPos), .in(opArray[i].priorityValue), .rTop(yTop[i]),
                .rBotL(yBotL[i + 1]), .rBotR(yBotR[i + 1]), .op(opArray[i].levelOp), .wenTop(wenTop[i]), .active(actives[i]), .done(done[i]), .raddrTop(genHeap[i].raddrTop), .raddrBot(genHeap[i].raddrBot),
                .wraddrTop(genHeap[i].wraddrTop), .endPos(genHeap[i].endPos), .out(outs[i]), .wData(a[i]));
                
                level_shifter #(i) I_SHIFTER(.clk, .rst, .shift(shift_pos[i - 1]), .pos_in(genHeap[i - 1].endPos), .pos_out(genHeap[i].startPos));
            end else if (i == 1) begin

                leq1 I_LEQ(.clk, .rst, .start(start[i]), .in(opArray[i].priorityValue),
                .rBotL(yBotL[i + 1]), .rBotR(yBotR[i + 1]), .op(opArray[i].levelOp), .done(done[i]), .raddrBot(genHeap[i].raddrBot),
                .endPos(genHeap[i].endPos), .out(outs[i]));
            end else begin
                levelv2 #(i) I_LEVEL(.clk, .topActive(actives[i]), .wenTop(wenTop[i]), .raddrTop(genHeap[i].raddrTop), .raddrBot(genHeap[i - 1].raddrBot),
                .wraddrTop(genHeap[i].wraddrTop), .aTop(a[i]), .yTop(yTop[i]), .yBotR(yBotR[i]), .yBotL(yBotL[i]));

                leq #(i) I_LEQ(.clk, .rst, .start(start[i]), .startPos(genHeap[i].startPos), .in(opArray[i].priorityValue), .rTop(yTop[i]),
                .rBotL(yBotL[i + 1]), .rBotR(yBotR[i + 1]), .op(opArray[i].levelOp), .wenTop(wenTop[i]), .active(actives[i]), .done(done[i]), .raddrTop(genHeap[i].raddrTop), .raddrBot(genHeap[i].raddrBot),
                .wraddrTop(genHeap[i].wraddrTop), .endPos(genHeap[i].endPos), .out(outs[i]), .wData(a[i]));
                
                level_shifter #(i) I_SHIFTER(.clk, .rst, .shift(shift_pos[i - 1]), .pos_in(genHeap[i - 1].endPos), .pos_out(genHeap[i].startPos));
            end
        end
    endgenerate

    assign rdy = (done[1] == DONE && (done[2] == DONE || done[2] == NEXT_LEVEL));
    assign valid_out = ((done[1] == DONE || done[1] == NEXT_LEVEL) && (opArray[1].levelOp == DEQ));
    

    always_ff @(posedge clk) begin
        if (rdy & valid) begin
            start[1] <= 1;
            opArray[1].priorityValue <= priorityIn;
            opArray[1].levelOp <= toperation; 
        end else start[1] <= 0; 
        //else begin
            //start[1] <= 0;
            //opArray[1].priorityValue <= 0;
            //opArray[1].levelOp <= FREE; 
        //end
    
        //shift ops down
        for (int i = 1; i < LEVELS; i++) begin
            if (done[i] == NEXT_LEVEL) begin
                opArray[i + 1].priorityValue <= outs[i];
                opArray[i + 1].levelOp <= opArray[i].levelOp;
                //outs[i + 1] <= outs[i];
                start[i + 1] <= 1;
            end else begin
                //opArray[i + 1].levelOp <= FREE;
                opArray[i + 1].priorityValue <= 0;
                start[i + 1] <= 0;
            end
        end
    end
    
    always_comb begin
        for (int i = 1; i < LEVELS; i++) begin
            if (done[i] == NEXT_LEVEL) begin
                shift_pos[i] = 1;
            end else begin
                shift_pos[i] = 0;
            end
        end
        
    end


endmodule



/* ok so like the address has to be as many bits as there are Levels, ignoring 0
if it is =1, level 1, <=3, level 2 and so on and so forth
also dimension of the address at this level is 2^(level - 1)



to enque:
incoming value -> opArray[1][1 + priorityValue + 1]
then localenqueue

localenqueue:
takes level to be operated on along with position and priorityValue
if the current position is inactive, chuck the priorityValue into the node and make it active
drop capacity of current node by 1

if current position is active
compare value to be queued with value at current position
if priorityValue > value at current position, swap the two
move value to be written to the next level of opArray
Check capacity at left of current position
if greater than 0, write the index of the left child to the next level of opArray
otherwise write the index of the right child to the next level of opArray
run localenqueue on the next level
*/

//index i has to access the ith element in the heap, which is on a specific level, which has its own sram.
//decoder?
//structs for nodes, restructure to always_ff
