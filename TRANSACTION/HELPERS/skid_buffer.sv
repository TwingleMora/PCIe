module skid_buffer #(parameter OPT_OUTREG = 0, parameter DATA_WIDTH = 32)
(
    input  logic                    clk,
    input  logic                    rst,
    input  logic                    i_valid,
    input  logic                    i_ready,
    input  logic [DATA_WIDTH-1:0]   i_data,

    output logic                    o_valid,
    output logic                    o_ready,
    output logic [DATA_WIDTH-1:0]   o_data
);


logic [DATA_WIDTH-1:0] r_data;
logic                  r_valid;

always@(*) begin
    o_ready = !r_valid;
    // i_ready = 0 ::: 
    // o_ready = 1 ::: 
    // ...............
end

always@(posedge clk or negedge rst) begin
    if(!rst) begin
        r_data  <= 0;
        r_valid <= 0;
    end
    else begin
        if(o_ready) begin //if(!r_valid)
            r_data <= i_data;
        end

        if((i_valid && o_ready) && (o_valid && !i_ready)) begin //every thing was fine untill !i_ready
            r_valid <= 1;
        end
        else if(i_ready) begin
            r_valid <= 0;
        end

    end

end

generate if(!OPT_OUTREG)
begin

    always@(*) begin
        o_valid = i_valid || r_valid; 
        o_data = r_valid? r_data : i_data;
    end
end
else begin
always@(posedge clk or negedge rst) begin
    if(!rst) begin
        o_valid <= 0;
        o_data  <= 0;
    end 
    else begin
        if(!o_valid || i_ready) begin //if not stalled
            o_valid <= (i_valid || r_valid);
            o_data  <= (r_valid? r_data:i_data);
        end
    end

end

end

endgenerate




endmodule