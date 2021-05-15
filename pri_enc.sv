module pri_enc #(parameter LEVELS=4)(input logic [LEVELS:0] a,
     output logic [$clog2(LEVELS):0] y,
     output logic idle);

always_comb begin
    idle = 1;
    y = 'd0; // default output value
    for (int i = LEVELS; i >=0; i--)
      begin
          if (a[i])
            begin
                y = i;
                idle = 0;
                break;
            end
      end
end

endmodule
