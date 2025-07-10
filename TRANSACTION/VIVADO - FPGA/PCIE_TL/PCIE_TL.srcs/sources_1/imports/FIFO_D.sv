//DEPTH
module FIFO_D
#(parameter DEPTH = 32, parameter DATA_WIDTH = 32)
(
input  logic                    clk, 
input  logic                    rst,
input  logic                    WrEn, 
input  logic                    RdEn,
input  logic [DATA_WIDTH-1:0]   DataIn,
output logic [DATA_WIDTH-1:0]   DataOut,
output logic [DATA_WIDTH-1:0]   comb_DataOut,
output logic                    Full, 
output logic                    Empty,
output logic                    AlmostEmpty,
output logic                    AlmostFull
);

localparam ADDR_WIDTH = $clog2(DEPTH) + 1;

reg [ADDR_WIDTH-1:0]    WrCounter, RdCounter;

reg [ADDR_WIDTH-1:0]    NextWrCounter, NextRdCounter;
reg                     NextFull, NextEmpty;

wire [ADDR_WIDTH-2:0] WrAddr = WrCounter[ADDR_WIDTH-2:0];
wire [ADDR_WIDTH-2:0] RdAddr = RdCounter[ADDR_WIDTH-2:0];

reg [DATA_WIDTH-1:0] mem [2**(ADDR_WIDTH-1)];


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

        AlmostFull<=0;
        AlmostEmpty<=0;
    end
    else
    begin
        Full  <= NextFull;
        Empty <= NextEmpty;

        AlmostFull  <= ((NextWrCounter[ADDR_WIDTH-1] != NextRdCounter[ADDR_WIDTH-1]) && ((NextRdCounter[ADDR_WIDTH-2:0] - NextWrCounter[ADDR_WIDTH-2:0]) == 1'b1));
        AlmostEmpty <= ((NextWrCounter[ADDR_WIDTH-1] == NextRdCounter[ADDR_WIDTH-1]) && ((NextWrCounter[ADDR_WIDTH-2:0] - NextRdCounter[ADDR_WIDTH-2:0]) == 1'b1));
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
    else
        NextRdCounter = RdCounter;
end

always@(*)
begin
    comb_DataOut = mem[RdAddr];
end

always@(*)
begin
    NextFull  = (NextWrCounter[ADDR_WIDTH-1] == ~NextRdCounter[ADDR_WIDTH-1]) && (NextWrCounter[ADDR_WIDTH-2:0] == NextRdCounter[ADDR_WIDTH-2:0]);
    NextEmpty = (NextWrCounter[ADDR_WIDTH-1:0] == NextRdCounter[ADDR_WIDTH-1:0]);
end


endmodule
