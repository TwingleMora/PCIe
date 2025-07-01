module MEM #(parameter DEPTH = 32, parameter DATA_WIDTH = 32, localparam ADDR_WIDTH = $clog2(DEPTH))
( 
    input logic clk,
    input logic rst,
    input logic [ADDR_WIDTH-1:0]    address,
    input logic [DATA_WIDTH-1:0]    data_in,
    input logic                     wr_en,

    output logic [DATA_WIDTH-1:0]   data_out

);

    logic [DATA_WIDTH-1:0] mem [DEPTH];

    always@(posedge clk/*  or negedge rst */) 
    begin
        // if(!rst) begin
        //     for(int x = 0; x < DEPTH; x++) begin
        //         mem[x] <= 0;
        //     end
        // end
        // else 
        if(wr_en) begin
            mem[address] <= data_in;
        end
    end

    assign data_out = mem[address];

endmodule