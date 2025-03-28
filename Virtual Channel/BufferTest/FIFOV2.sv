module FIFOV3
#(parameter DEPTH = 5, parameter DATA_WIDTH = 32)
(
input  logic        clk, 
input  logic        rst,
input  logic        WrEn, 
input  logic        RdEn,
input  logic [DATA_WIDTH-1:0] DataIn,
output logic [DATA_WIDTH-1:0] DataOut,
output logic [DATA_WIDTH-1:0] comb_DataOut,
output logic        Full, 
output logic        Empty 
);


reg [$clog2(DEPTH):0]    counter;
reg [$clog2(DEPTH):0]    next_counter;


reg [$clog2(DEPTH)-1:0] WrAddr, RdAddr;
reg [$clog2(DEPTH)-1:0] NextWrAddr, NextRdAddr;
reg                     NextFull, NextEmpty;

// wire [ADDR_WIDTH-2:0] WrAddr = WrCounter[ADDR_WIDTH-2:0];
// wire [ADDR_WIDTH-2:0] RdAddr = RdCounter[ADDR_WIDTH-2:0];

reg [DATA_WIDTH-1 : 0] mem [DEPTH]; // from 0 to DEPTH -1 

always@(posedge clk or negedge rst)
begin
    if(!rst)
    begin
        counter <= 0;
    end
    else
    begin
        counter <= next_counter;
    end


end

always@(posedge clk or negedge rst)
begin
    if(!rst)
    begin
        WrAddr<=0;
    end
    else
    begin
        if(WrEn && !Full)
        begin
            mem[WrAddr] <= DataIn;
        end
        WrAddr <= NextWrAddr;
    end

end

always@(posedge clk or negedge rst)
begin
    if(!rst)
    begin
        RdAddr<=0;
        //DataOut<=0;
    end
    else
    begin
        if(RdEn && !Empty)
        begin
            DataOut <= mem[RdAddr]; 
        end
        RdAddr <= NextRdAddr;
    end

end

always@(posedge clk or negedge rst)
begin
    if(!rst)
    begin
        Full<=0;
        Empty<=1;
    end
    else
    begin
        Full  <= NextFull;
        Empty <= NextEmpty;
    end
end


always@(*)
begin

    if(WrEn && !Full)
    begin
        if(WrAddr == DEPTH-1)
            NextWrAddr = 0;
        else
            NextWrAddr = WrAddr + 1;
    end
    else
        NextWrAddr = WrAddr;
end

always@(*)
begin
    if(RdEn && !Empty)
    begin
        if(RdAddr == DEPTH-1)
            NextRdAddr = 0;
        else
            NextRdAddr = RdAddr + 1;
    end
    else
        NextRdAddr = RdAddr;
end

always@(*)
begin
    comb_DataOut = mem[RdAddr];
end

always@(*)
begin
case({WrEn&&!Full, RdEn&&!Empty})
2'b10:
begin
    next_counter = counter + 1;
end
2'b01:
begin
    next_counter = counter - 1;
end
default:
begin
    next_counter = counter;
end
endcase

end

always@(*)
begin
    // NextFull  = (NextWrCounter[ADDR_WIDTH-1] == ~NextRdCounter[ADDR_WIDTH-1]) && (NextWrCounter[ADDR_WIDTH-2:0] == NextRdCounter[ADDR_WIDTH-2:0]);
    // NextEmpty = (NextWrCounter[ADDR_WIDTH-1:0] == NextRdCounter[ADDR_WIDTH-1:0]);
       NextFull  = (next_counter == DEPTH);
       NextEmpty = (next_counter == 0);
end


endmodule
