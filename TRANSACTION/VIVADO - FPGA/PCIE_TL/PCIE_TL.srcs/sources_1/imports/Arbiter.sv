module Arbiter #(parameter WIDTH = 16, parameter DESC = 1) 
(
    input   logic [WIDTH-1:0] IN,
    output  logic [WIDTH-1:0] OUT
);   
    logic [WIDTH-1:0] OUT1;
    logic [WIDTH-1:0] OUT2;
    logic [WIDTH-1:0] OR1;
    logic [WIDTH-1:0] OR2;
    logic option;
generate
    if(DESC==1) begin:descending_priority
        always@(*)
        begin
            OUT[WIDTH-1] = IN[WIDTH-1];
            
            OR1[WIDTH -1] = IN[WIDTH-1];
            OUT[WIDTH-2] = !OR1[WIDTH-1] & IN[WIDTH-2];

            for(int x = WIDTH-3; x>=0 ; x--)
            begin
                OR1[x+1] = OR1[x+2] | IN[x+1]; 
                OUT[x] = !(OR1[x+1]) & IN[x];
            end

        end
    end
    else
    begin: ascending_priority

        always@(*)
        begin
            OUT[0] = IN[0];
            OR2[0] = IN[0];
            OUT[1] = !OR2[0] & IN[1];
            for(int x = 2; x<WIDTH ; x++)
            begin
                OR2[x-1] = OR2[x-2] | IN[x-1];
                OUT[x] = !OR2[x-1] & IN[x];
            end
        end
    end
endgenerate
endmodule