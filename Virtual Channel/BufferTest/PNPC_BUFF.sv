module PNPC_BUFF //TL_TX_MAL / TL_RX_TB 1 & 2 / TL_TX(_TB) / AXI_TX_RX_TB / 
#(parameter DATA_WIDTH = 32)
(
input   logic                       clk,
input   logic                       rst,
input   logic                       HEADER_DATA, // 0: Header, 1: Data
input   logic [1:0]                 P_NP_CPL, // Posted: 00, Non-Posted: 01, Completion: 11
input   logic [DATA_WIDTH-1:0]      IN_TLP_DW,
input   logic                       WR_EN,
input   logic                       RD_EN,

input   logic                       TLP_START_BIT_IN,
input   logic                       TLP_END_BIT_IN, 




output  wire                        EMPTY,
output  logic                       OUT_EMPTY,
output  logic [DATA_WIDTH-1:0]      OUT_TLP_DW,      
output  logic [DATA_WIDTH-1:0]      OUT_TLP_DW_COMB,


output  logic                       TLP_START_BIT_OUT_COMB,
output  logic                       TLP_END_BIT_OUT_COMB



);

logic           HEADER_DATA_OUT;
logic [1:0]     P_NP_CPL_OUT;
logic           TLP_START, TLP_END;


logic           HEADER_DATA_OUT_REG;
logic [1:0]     P_NP_CPL_OUT_REG;
logic           TLP_START_REG, TLP_END_REG;


localparam [1:0] POSTED = 2'b00,
                 NONPOSTED = 2'b01,
                 CPL = 2'b11;

/* localparam [2:0] POSTED_HEADER = 3'b000,
                 POSTED_DATA = 3'b000,

                 NON_POSTED_HEADER = 3'b010,
                 NON_POSTED_DATA = 3'b011,

                 CPL_HEADER = 3'b100,
                 CPL_DATA = 3'b101; */


reg PWrEn, NPWrEn, CPLWrEn;
reg PRdEn, NPRdEn, CPLRdEn;


reg  [DATA_WIDTH-1:0] POSTED_OUT_TLP_DW;
reg  [DATA_WIDTH-1:0] NONPOSTED_OUT_TLP_DW;
reg  [DATA_WIDTH-1:0] CPL_OUT_TLP_DW;

reg  [DATA_WIDTH-1:0] POSTED_OUT_TLP_DW_COMB;
reg  [DATA_WIDTH-1:0] NONPOSTED_OUT_TLP_DW_COMB;
reg  [DATA_WIDTH-1:0] CPL_OUT_TLP_DW_COMB;

// wire [2:0]            BUFF_LOG_DATA; WT*?!
wire                  SEQUENCE_LOGGER_EMPTY;

reg                   POSTED_OUT_EMPTY;
reg                   NONPOSTED_OUT_EMPTY;
reg                   CPL_OUT_EMPTY;

assign EMPTY = SEQUENCE_LOGGER_EMPTY;

FIFO #(.ADDR_WIDTH(7), .DATA_WIDTH(5)) SEQUENCE_LOGGER
(
.clk(clk),//input  logic        clk, 
.rst(rst),//input  logic        rst,
.WrEn(WR_EN),//input  logic        WrEn, 
.RdEn(RD_EN),//input  logic        RdEn,
.DataIn({P_NP_CPL, HEADER_DATA, TLP_START_BIT_IN, TLP_END_BIT_IN}),//input  logic [DATA_WIDTH-1:0] DataIn,
.DataOut({P_NP_CPL_OUT_REG, HEADER_DATA_OUT_REG, TLP_START_REG, TLP_END_REG}),//output logic [DATA_WIDTH-1:0] DataOut,
.comb_DataOut({P_NP_CPL_OUT, HEADER_DATA_OUT, TLP_START_BIT_OUT_COMB, TLP_END_BIT_OUT_COMB}),//output logic [DATA_WIDTH-1:0] comb_DataOut,
//output logic        Full, 
.Empty(SEQUENCE_LOGGER_EMPTY)//output logic        Empty 
);

DUE_BUFFER #(.DATA_WIDTH(DATA_WIDTH)) POSTED_BUFF     
(
.clk(clk), 
.rst(rst), 

.WrEn(PWrEn),   
.RdEn(PRdEn),   

.HEADER_DATA(HEADER_DATA), 
.HEADER_DATA_OUT(HEADER_DATA_OUT),

.IN_TLP_DW(IN_TLP_DW), 
.OUT_EMPTY(POSTED_OUT_EMPTY),
.OUT_TLP_DW(POSTED_OUT_TLP_DW),
.OUT_TLP_DW_COMB(POSTED_OUT_TLP_DW_COMB)
);

DUE_BUFFER #(.DATA_WIDTH(DATA_WIDTH)) NON_POSTED_BUFF 
(
.clk(clk), 
.rst(rst), 

.WrEn(NPWrEn),  
.RdEn(NPRdEn),

.HEADER_DATA(HEADER_DATA),
.HEADER_DATA_OUT(HEADER_DATA_OUT),

.IN_TLP_DW(IN_TLP_DW), 
.OUT_EMPTY(NONPOSTED_OUT_EMPTY),
.OUT_TLP_DW(NONPOSTED_OUT_TLP_DW),
.OUT_TLP_DW_COMB(NONPOSTED_OUT_TLP_DW_COMB)
);

DUE_BUFFER #(.DATA_WIDTH(DATA_WIDTH)) CPL_BUFF        
(
.clk(clk),
.rst(rst), 

.WrEn(CPLWrEn), 
.RdEn(CPLRdEn), 

.HEADER_DATA(HEADER_DATA), 
.HEADER_DATA_OUT(HEADER_DATA_OUT),

.IN_TLP_DW(IN_TLP_DW), 
.OUT_EMPTY(CPL_OUT_EMPTY),
.OUT_TLP_DW(CPL_OUT_TLP_DW),
.OUT_TLP_DW_COMB(CPL_OUT_TLP_DW_COMB)
);


always@(*)
begin
    PWrEn = 0; NPWrEn = 0; CPLWrEn = 0;
    PRdEn = 0; NPRdEn = 0; CPLRdEn = 0;


    case(P_NP_CPL)
        POSTED:
        begin
            PWrEn = WR_EN;
            //PRdEn = RD_EN;
            //OUT_TLP_DW = POSTED_OUT_TLP_DW;
        end

        NONPOSTED:
        begin
            NPWrEn = WR_EN;
            //NPRdEn = RD_EN;
            //OUT_TLP_DW = NONPOSTED_OUT_TLP_DW;
        end

        CPL:
        begin
            CPLWrEn = WR_EN;
            //CPLRdEn = RD_EN;
            //OUT_TLP_DW = CPL_OUT_TLP_DW;
        end
    endcase

    case(P_NP_CPL_OUT)
        POSTED:
        begin
            //PWrEn = WR_EN;
            PRdEn = RD_EN && !SEQUENCE_LOGGER_EMPTY;
            //OUT_TLP_DW = POSTED_OUT_TLP_DW;
        end

        NONPOSTED:
        begin
            //NPWrEn = WR_EN;
            NPRdEn = RD_EN && !SEQUENCE_LOGGER_EMPTY;
            //OUT_TLP_DW = NONPOSTED_OUT_TLP_DW;
        end

        CPL:
        begin
            //CPLWrEn = WR_EN;
            CPLRdEn = RD_EN && !SEQUENCE_LOGGER_EMPTY;
            //OUT_TLP_DW = CPL_OUT_TLP_DW;
        end
    endcase
    
    
    case(P_NP_CPL_OUT)
        POSTED:
        begin
            //PWrEn = WR_EN;
            OUT_TLP_DW_COMB = POSTED_OUT_TLP_DW_COMB;
            //OUT_TLP_DW = POSTED_OUT_TLP_DW;
        end

        NONPOSTED:
        begin
            //NPWrEn = WR_EN;
            OUT_TLP_DW_COMB = NONPOSTED_OUT_TLP_DW_COMB;
            //OUT_TLP_DW = NONPOSTED_OUT_TLP_DW;
        end

        CPL:
        begin
            //CPLWrEn = WR_EN;
            OUT_TLP_DW_COMB = CPL_OUT_TLP_DW_COMB;
            //OUT_TLP_DW = CPL_OUT_TLP_DW;
        end
    endcase



     case(P_NP_CPL_OUT_REG)
        POSTED:
        begin
            //PWrEn = WR_EN;
            //PRdEn = RD_EN && !SEQUENCE_LOGGER_EMPTY;
            OUT_TLP_DW = POSTED_OUT_TLP_DW;   
            OUT_EMPTY = POSTED_OUT_EMPTY;
        end

        NONPOSTED:
        begin
            //NPWrEn = WR_EN;
            //NPRdEn = RD_EN && !SEQUENCE_LOGGER_EMPTY;
            OUT_TLP_DW = NONPOSTED_OUT_TLP_DW;   
            OUT_EMPTY = NONPOSTED_OUT_EMPTY;
        end

        CPL:
        begin
            //CPLWrEn = WR_EN;
            //CPLRdEn = RD_EN && !SEQUENCE_LOGGER_EMPTY;
            OUT_TLP_DW = CPL_OUT_TLP_DW;   
            OUT_EMPTY = CPL_OUT_EMPTY;
        end
        default:
        begin
            OUT_TLP_DW = 0;
            OUT_EMPTY = 0;
        end
    endcase
end

endmodule
