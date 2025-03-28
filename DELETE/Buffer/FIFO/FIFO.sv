module FIFO
#(parameter WIDTH = 5)
(
input  logic        clk, rst,
input  logic        WrEn, 
input  logic        RdEn,
input  logic [31:0] DataIn,
output logic [31:0] DataOut,
output logic        Full, 
output logic        Empty 
);

reg [WIDTH-1:0] WrCounter, RdCounter;

reg [WIDTH-1:0] NextWrCounter, NextRdCounter;
reg             NextFull, NextEmpty;

wire [WIDTH-2:0] WrAddr = WrCounter[WIDTH-2:0];
wire [WIDTH-2:0] RdAddr = RdCounter[WIDTH-2:0];

reg [31:0] mem [2**(WIDTH-1)];
always@(posedge clk or negedge rst)
begin
    if(!rst)
    begin
        WrCounter<=0;
    end
    else
    begin
        if(WrEn && !Full)
        begin
            mem[WrAddr] <= DataIn;
        end
        WrCounter <= NextWrCounter;
    end

end

always@(posedge clk or negedge rst)
begin
    if(!rst)
    begin
        RdCounter<=0;
        //DataOut<=0;
    end
    else
    begin
        if(RdEn && !Empty)
        begin
            DataOut <= mem[RdAddr]; 
        end
        RdCounter <= NextRdCounter;
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
        NextWrCounter = WrCounter + 1;
    else
        NextWrCounter = WrCounter;
end

always@(*)
begin
    if(RdEn && !Empty)
        NextRdCounter = RdCounter + 1;
        //DataOut = mem[RdAddr];
    else
        NextRdCounter = RdCounter;
end

always@(*)
begin
    NextFull  = (NextWrCounter[WIDTH-1] == ~NextRdCounter[WIDTH-1]) && (NextWrCounter[WIDTH-2:0] == NextRdCounter[WIDTH-2:0]);
    NextEmpty = (NextWrCounter[WIDTH-1:0] == NextRdCounter[WIDTH-1:0]);
end


endmodule
