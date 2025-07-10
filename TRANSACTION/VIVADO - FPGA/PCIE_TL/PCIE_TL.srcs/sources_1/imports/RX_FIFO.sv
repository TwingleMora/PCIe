module RX_FIFO
#(parameter /* ADDR_WIDTH = 5 */DEPTH = 128, parameter DATA_WIDTH = 32)
(
input  logic                    clk, 
input  logic                    rst,

input  logic                    commit,
input  logic                    flush,

input  logic                    WrEn, 
input  logic                    RdEn,

input  logic [DATA_WIDTH-1:0]   DataIn,

output logic [DATA_WIDTH-1:0]   DataOut,
output logic [DATA_WIDTH-1:0]   comb_DataOut,

output logic                    Full, 
output  logic                    FullPending,
output logic                    Empty,

output logic                    AlmostEmpty,
output logic                    AlmostFull,
output logic [9:0]              Credit
);
localparam ADDR_WIDTH = $clog2(128)+1;
reg [ADDR_WIDTH-1:0]    WrPendCounter, RdCounter;
reg [ADDR_WIDTH-1:0]    WrCommitCounter;

reg [ADDR_WIDTH-1:0]    NextWrPendCounter, NextRdCounter;
reg [ADDR_WIDTH-1:0]    NextWrCommitCounter;

reg                     NextFull, NextEmpty;
reg                     NextFullPending;

reg [9:0]               NextCredit;

wire [ADDR_WIDTH-2:0] WrPendAddr = WrPendCounter[ADDR_WIDTH-2:0];
wire [ADDR_WIDTH-2:0] RdAddr = RdCounter[ADDR_WIDTH-2:0];

reg [DATA_WIDTH-1:0] mem [2**(ADDR_WIDTH-1)];


always@(posedge clk or negedge rst)
begin
    if(!rst) begin
        WrCommitCounter<=0;
    end
    else begin
        WrCommitCounter<=NextWrCommitCounter;
    end
end



always@(posedge clk or negedge rst)
begin
    if(!rst)
    begin
        WrPendCounter<=0;
    end
    else
    begin
        WrPendCounter <= NextWrPendCounter;
        if(WrEn && !FullPending)
        begin
            mem[WrPendAddr] <= DataIn;
        end
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

        FullPending <= 0;

        AlmostFull<=0;
        AlmostEmpty<=0;
        Credit <= 2**(ADDR_WIDTH-1);
    end
    else
    begin
        Full  <= NextFull;

        FullPending <= NextFullPending;

        Empty <= NextEmpty;

        AlmostFull <=  ((NextWrCommitCounter[ADDR_WIDTH-1] != NextRdCounter[ADDR_WIDTH-1]) && ((NextRdCounter[ADDR_WIDTH-2:0] - NextWrCommitCounter[ADDR_WIDTH-2:0]) == 1'b1));
        AlmostEmpty <= ((NextWrCommitCounter[ADDR_WIDTH-1] == NextRdCounter[ADDR_WIDTH-1]) && ((NextWrCommitCounter[ADDR_WIDTH-2:0] - NextRdCounter[ADDR_WIDTH-2:0]) == 1'b1));
    
        Credit <= NextCredit;
    end
end

always@(*) begin
    NextWrCommitCounter = WrCommitCounter;
    if(commit&&!flush) begin
        NextWrCommitCounter = WrPendCounter;
    end
    
end

always@(*)
begin
    if(flush&&!commit) begin
       if(WrEn && !Full)
            NextWrPendCounter = WrCommitCounter + 1;
        else
            NextWrPendCounter = WrCommitCounter;

    end
    else if(WrEn && !Full)
        NextWrPendCounter = WrPendCounter + 1;
    else
        NextWrPendCounter = WrPendCounter;
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
    NextFull  = (NextWrCommitCounter[ADDR_WIDTH-1] == ~NextRdCounter[ADDR_WIDTH-1]) && (NextWrCommitCounter[ADDR_WIDTH-2:0] == NextRdCounter[ADDR_WIDTH-2:0]);

    NextFullPending  = (NextWrPendCounter[ADDR_WIDTH-1] == ~NextRdCounter[ADDR_WIDTH-1]) && (NextWrPendCounter[ADDR_WIDTH-2:0] == NextRdCounter[ADDR_WIDTH-2:0]);

    NextEmpty = (NextWrCommitCounter[ADDR_WIDTH-1:0] == NextRdCounter[ADDR_WIDTH-1:0]);

    NextCredit = NextWrCommitCounter>NextRdCounter? ((2**(ADDR_WIDTH-1))-(NextWrCommitCounter - NextRdCounter)):((2**(ADDR_WIDTH-1))-(NextRdCounter - NextWrCommitCounter));
end


endmodule
