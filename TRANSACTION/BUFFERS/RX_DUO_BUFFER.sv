module RX_DUO_BUFFER
#(parameter DATA_WIDTH = 32, parameter DEPTH = 128)
(
input  logic                    clk,
input  logic                    rst,
input  logic                    WrEn,
input  logic                    RdEn,

input  logic                    commit,
input  logic                    flush,

input  logic                    HEADER_DATA,  //H = 0, D = 1;   


input  logic                    HEADER_DATA_OUT,
input  logic [DATA_WIDTH-1:0]   IN_TLP_DW,

output wire                     FULL_HEADER,
output wire                     FULL_DATA,

output logic                    OUT_EMPTY,
output logic [DATA_WIDTH-1:0]   OUT_TLP_DW,
output logic [DATA_WIDTH-1:0]   OUT_TLP_DW_COMB,

output logic  [9:0]             HeaderCredit,
output logic  [9:0]             DataCredit
);

//output logic        Done

//Inputs
reg HWrEn, HRdEn;
reg DWrEn, DRdEn;

reg [DATA_WIDTH-1:0] HDataIn;
reg [DATA_WIDTH-1:0] DDataIn;

//Outputs
reg HFull, HEmpty;
reg DFull, DEmpty;

assign FULL_HEADER = HFull;
assign FULL_DATA  =  DFull;

reg [DATA_WIDTH-1:0]    HEADER_OUT_TLP_DW;
reg [DATA_WIDTH-1:0]    DATA_OUT_TLP_DW;

reg [DATA_WIDTH-1:0]    HEADER_OUT_TLP_DW_COMB;
reg [DATA_WIDTH-1:0]    DATA_OUT_TLP_DW_COMB;

logic                   HEADER_DATA_OUT_REG;

RX_FIFO #(.DATA_WIDTH(DATA_WIDTH), .DEPTH(DEPTH)) Header (.clk(clk), .rst(rst), .WrEn(HWrEn), .RdEn(HRdEn), .DataIn(IN_TLP_DW), .DataOut(HEADER_OUT_TLP_DW), .comb_DataOut(HEADER_OUT_TLP_DW_COMB), .FullPending(HFull), .Empty(HEmpty),
.flush(flush), .commit(commit), .Credit(HeaderCredit));

RX_FIFO #(.DATA_WIDTH(DATA_WIDTH), .DEPTH(DEPTH)) Data   (.clk(clk), .rst(rst), .WrEn(DWrEn), .RdEn(DRdEn), .DataIn(IN_TLP_DW), .DataOut(DATA_OUT_TLP_DW), .comb_DataOut(DATA_OUT_TLP_DW_COMB), .FullPending(DFull), .Empty(DEmpty),
.flush(flush), .commit(commit), .Credit(DataCredit));

always@(posedge clk or negedge rst)
begin
    if(!rst)
    begin
        HEADER_DATA_OUT_REG <= 0;
    end
    else
    begin
        HEADER_DATA_OUT_REG <= HEADER_DATA_OUT;
    end

end


always@(*)
begin
    HWrEn = 0; HRdEn = 0;
    DWrEn = 0; DRdEn = 0;

    HDataIn = 0;
    DDataIn = 0;

    OUT_EMPTY = 0;
    OUT_TLP_DW = 0;
    
    case(HEADER_DATA)
    0:
    begin
        HWrEn = WrEn;
        //HRdEn = RdEn;

        //OUT_TLP_DW = HEADER_OUT_TLP_DW;

    end

    1:
    begin
        DWrEn = WrEn;
        //DRdEn = RdEn;

        //OUT_TLP_DW = DATA_OUT_TLP_DW;
    end
    endcase


    case(HEADER_DATA_OUT)
    0:
    begin
        //HWrEn = WrEn;
        HRdEn = RdEn;


    end

    1:
    begin
        //DWrEn = WrEn;
        DRdEn = RdEn;

    end
    endcase
    
    case(HEADER_DATA_OUT)
    0:
    begin
        //HWrEn = WrEn;
        OUT_TLP_DW_COMB = HEADER_OUT_TLP_DW_COMB;


    end

    1:
    begin
        //DWrEn = WrEn;
        OUT_TLP_DW_COMB = DATA_OUT_TLP_DW_COMB;

    end
    endcase

    case(HEADER_DATA_OUT_REG)
    0:
    begin

        OUT_TLP_DW = HEADER_OUT_TLP_DW;
        
        OUT_EMPTY = HEmpty;
    end

    1:
    begin

        OUT_TLP_DW = DATA_OUT_TLP_DW;
        
        OUT_EMPTY = DEmpty;
    end
    endcase

end
endmodule
