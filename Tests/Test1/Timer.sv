module Timer #(parameter WIDTH = 44)
(
    input  logic clk,
    input  logic rst,

    input  logic             sync_rst,
    output logic [WIDTH-1:0] timer
    
);


    always@(posedge clk or negedge rst)
    begin
        if(!rst)
        begin
            timer[WIDTH-1] <= 1;
            timer[WIDTH-2:0] <= 0;
        end
        else
        begin
            if(!sync_rst)
            begin
                timer <= 0;
            end
            else
            begin
                timer <= timer + 1;
            end
        end

    end

endmodule