module TL_TX
(
input   logic                    clk, 
input   logic                    rst,

input   logic                    DPI_MM,

input   logic    [9:0]           port_write_en,
input   logic    [2:0]           tlp_mem_io_msg_cpl_conf,
input   logic                    tlp_address_32_64,
input   logic                    tlp_read_write,


input   logic    [2:0]          TC,
input   logic    [2:0]          ATTR,
//input   logic    [15:0]         device_id, Enable It Later, But For NoW Conf Space Remains inside the TL_TX
input   logic    [7:0]          tag,
input   logic    [11:0]         byte_count,
input   logic    [31:0]         lower_addr,
input   logic    [31:0]         upper_addr,
input   logic    [15:0]         dest_bdf_id,

input   logic    [31:0]         data1,
input   logic    [31:0]         data2,
input   logic    [31:0]         data3,

input   logic    [9:0]          config_dw_number,
input   logic                   valid,

input   logic                   RD_EN,


output  wire                    ALL_BUFFS_EMPTY,
output  logic                   VALID_FOR_DL,
output  logic    [31:0]         OUT_TLP_DW,

output  logic                   TLP_START_BIT_OUT_COMB,
output  logic                   TLP_END_BIT_OUT_COMB,

output  logic                   fsm_started,
output  logic                   fsm_finished,   


output  logic                   tlp_end_logic
);



//CONNECTIONS (MIDDLE OF THE CHAIN)
wire                            next_VALID_FOR_DL;


logic  [2:0]                    fmt_reg;
logic  [4:0]                    type_reg;
logic  [2:0]                    TC_reg;
logic  [2:0]                    ATTR_reg;
logic  [15:0]                   device_id_reg;
logic  [7:0]                    tag_reg;
logic  [11:0]                   byte_count_reg;
logic  [31:0]                   lower_addr_reg;
logic  [31:0]                   upper_addr_reg;
logic  [15:0]                   dest_bdf_id_reg;
logic  [31:0]                   data_reg;
logic  [9:0]                    config_dw_number_reg;
logic                           valid_reg;



///////// CONF SPACE //////////
logic    [15:0]         device_id;
///////////////////

logic   [31:0]          TLP;

// COMPLETION_REQUEST_HANDLER FIFO
logic   [45:0]          CPL_REQ_HNDL_OUT; //{CPL_REQUESTER_ID[15:0], CPL_REQUESTER_TAG[7:0], REQUESTED_BYTES[11:0], LOWER_ADDRESS[6:0]};
logic                   COMPLETION_RD_EN;
logic                   COMPLETION_WR_EN;
logic                   COMPLETION_FULL;
logic                   COMPLETION_EMPTY;
wire logic              CPL_HNDLR_FIFO_NOT_EMPTY;


wire logic  [15:0]      CPL_REQUESTER_ID;
wire logic  [7:0]       CPL_REQUESTER_TAG;
wire logic  [11:0]      REQUESTED_BYTES;
wire logic  [6:0]       LOWER_ADDRESS;
wire logic  [2:0]       CPL_STATE;


// logic                   fsm_started;
// logic                   fsm_finsihed;

//NPNCPL_BUFF
logic      [1:0]        P_NP_CPL;
logic                   HEADER_DATA;
logic                   PNPC_BUFF_WR_EN;

logic     [1:0]         data_address;


logic                   tlp_start_flag_enc_2_buff;
logic                   tlp_end_flag_enc_2_buff;

CONF_SPACE CONF_SPACE0
    //#(
    //parameter             DW_COUNT          = 16,
    //parameter reg [15:0]  DEV_ID            = 16'b0000_0001_00000_000,
    //parameter reg [15:0]  VENDOR_ID         = 16'b0000_0001_00000_000,
    //parameter reg [7:0]   HEADER_TYPE       = 8'b0000,
    
    // parameter reg        BAR0EN            = 1,
    // parameter reg        BAR0MM_IO         = 0,
    // parameter reg        BAR0_32_64        = 2'b00,
    // parameter reg        BAR0_NONPRE_PRE   = 1'b0,
    // parameter            BAR0_BYTES_COUNT  = 4096,

    // parameter reg        BAR1EN            = 0,
    // parameter reg        BAR1MM_IO         = 0,
    // parameter reg        BAR1_32_64        = 2'b00,
    // parameter reg        BAR1_NONPRE_PRE   = 1'b0,
    // parameter            BAR1_BYTES_COUNT  = 4096,  

    // parameter reg        BAR2EN            = 0,
    // parameter reg        BAR2MM_IO         = 0,
    // parameter reg        BAR2_32_64        = 2'b00,
    // parameter reg        BAR2_NONPRE_PRE   = 1'b0,
    // parameter            BAR2_BYTES_COUNT  = 4096
    //)
    (
        .clk(clk),                    //input       logic                           clk,
        .rst(rst),                    //input       logic                           rst,
        //.wr_en(),                   //input       logic                           wr_en,
        //data_in(),                  //input       logic [31:0]                    data_in,
        //addr(),                     //input       logic [$clog2(DW_COUNT)-1:0]    addr,

        //.data_out(),                //output      logic [31:0]                    data_out,  
        .device_id(device_id)//,      //output wire logic [15:0]                    device_id,
        //.vendor_id(),               //output wire logic [15:0]                    vendor_id,  
        //.header_type(),             //output wire logic [7:0]                     header_type,

        //.BAR0(),                    //output wire logic [31:0]                    BAR0,
        //.BAR1(),                    //output wire logic [31:0]                    BAR1,
        //.BAR2(),                    //output wire logic [31:0]                    BAR2,
        //.BridgeSubBusNum(),         //output wire logic [7:0]                     BridgeSubBusNum,
        //.BridgeSecBusNum(),         //output wire logic [7:0]                     BridgeSecBusNum,
        //.BridgePriBusNum(),         //output wire logic [7:0]                     BridgePriBusNum

        //.BridgeIOLimit(),           //output wire logic [7:0]                     BridgeIOLimit,
        //.BridgeIOBase(),            //output wire logic [7:0]                     BridgeIOBase,

        //.BridgeMemLimit(),          //output wire logic [7:0]                     BridgeMemLimit,
        //.BridgeMemBase(),           //output wire logic [7:0]                     BridgeMemBase,

        //.BridgePrefMemLimit(),      //output wire logic [7:0]                     BridgePrefMemLimit,
        //.BridgePrefMemBase(),       //output wire logic [7:0]                     BridgePrefMemBase,

        //.BridgePrefMemBaseUpper(),  //output wire logic [31:0]                    BridgePrefMemBaseUpper,
        //.BridgePrefMemLimitUpper(), //output wire logic [31:0]                    BridgePrefMemLimitUpper,

        //.BridgeIOLimitUpper(),      //output wire logic [15:0]                    BridgeIOLimitUpper,
        //.BridgeIOBaseUpper()        //output wire logic [15:0]                    BridgeIOBaseUpper
    );

APP_TL_TX_BRIDGE TL_TX_REG_FILE0
(
    .clk(clk), 
    .rst(rst),//input logic clk, rst,

    //INPUTS FROM ENCODER
    .fsm_started(fsm_started),      //input  logic            fsm_started,
    .fsm_finished(fsm_finished),    //input  logic            fsm_finished,
    .data_address(data_address),
    .DPI_MM(DPI_MM),//input logic DPI_MM,  //DPI = 0, MM = 1
    
    // ----- Interface 1: Dedicated Port Interface -----
    .port_write_en(port_write_en),  //input  logic  [9:0] port_write_en,

    /*
    .fmt(fmt),                      //input  logic  [2:0] fmt, 
    .type_(type_),                  //input  logic  [4:0] type_, 
    */

    .tlp_mem_io_msg_cpl_conf(tlp_mem_io_msg_cpl_conf),             //input  logic  [1:0]     tlp_mem_io_msg_cpl_conf, //0: mem, 1: io, 2: msg, 3: cpl
    .tlp_address_32_64(tlp_address_32_64),               //input  logic            tlp_address_32_64,  //0: 32-bit address, 1: 64-bit address
    .tlp_read_write(tlp_read_write),                     //input  logic            tlp_read_write,     //0: read, 1: write
    
    // .TC(TC),                        //input  logic  [2:0] TC,
    // .ATTR(ATTR),                    //input  logic  [2:0] ATTR,
    
    .device_id(device_id),          //input  logic  [15:0] device_id,
    // .tag(tag),                      //input  logic  [7:0]  tag,

    .byte_count(byte_count),        //input  logic  [11:0] byte_count;
    .lower_addr(lower_addr),        //input  logic  [31:0] lower_addr,
    .upper_addr(upper_addr),        //input  logic  [31:0] upper_addr,
    
    .dest_bdf_id(dest_bdf_id),                              //input  logic  [15:0]    dest_bdf_id,
    .config_dw_number(config_dw_number),                    //input  logic  [9:0]  configuration_dw_number,
    
    .data1(data1),                                            //input  logic  [31:0] data,
    .data2(data2),
    .data3(data3),
    
    .valid(valid),                                          //input  logic         valid,

//    ---------------------------------

// Interface 2: Memory-Mapped
   /*
    .mem_addr(),        //input  wire [3:0]   mem_addr,             // 4-bit address to select one of 4 registers //16 Bytes
    .mem_write_en(),    //input  wire         mem_write_en,         // Write enable for memory-mapped interface
    .mem_write_data(),  //input  wire [31:0]  mem_write_data,       // Data to write
    .mem_read_en(),     //input  wire         mem_read_en,          // Read enable for memory-mapped interface
    .mem_read_data(),   //output reg  [31:0]  mem_read_data,        // Data read from selected register
     */

//-------------------------------------------

    .fmt_reg(fmt_reg),//output logic  [2:0] fmt_reg,
    .type_reg(type_reg),//output logic  [4:0] type_reg,
    .TC_reg(TC_reg),//output logic  [2:0] TC_reg,
    .ATTR_reg(ATTR_reg),//output logic  [2:0] ATTR_reg,

    .device_id_reg(device_id_reg),//output logic  [15:0] requester_id_reg,
    .tag_reg(tag_reg),//output logic  [7:0]  tag_reg,

    .byte_count_reg(byte_count_reg),    //output logic  [11:0] byte_count_reg,
    .lower_addr_reg(lower_addr_reg),    //input  logic  [31:0] lower_addr_reg,
    .upper_addr_reg(upper_addr_reg),    //input  logic  [31:0] upper_addr_reg,
    .data_reg (data_reg),               //output logic  [31:0] data_reg,
    .dest_bdf_id_reg(dest_bdf_id_reg),                      //input  logic  [15:0]    dest_bdf_id_reg,
    .config_dw_number_reg (config_dw_number_reg),           //output logic [9:0] configuration_dw_number_reg 
    .valid_reg(valid_reg)                                   //output logic         valid_reg
);



assign CPL_HNDLR_FIFO_NOT_EMPTY = ~COMPLETION_EMPTY;
assign {CPL_REQUESTER_ID, CPL_REQUESTER_TAG, REQUESTED_BYTES, LOWER_ADDRESS, CPL_STATE} = CPL_REQ_HNDL_OUT;
FIFO #(.DATA_WIDTH(46)) COMPLETION_REQUEST_HANDLER
(
.clk            (clk),//input  logic        clk, 
.rst            (rst),//input  logic        rst,
.WrEn           (COMPLETION_WR_EN),//input  logic        WrEn, 
.RdEn           (COMPLETION_RD_EN),//input  logic        RdEn,
.DataIn         (),//input  logic [DATA_WIDTH-1:0] DataIn,
.DataOut        (),//output logic [DATA_WIDTH-1:0] DataOut,
.comb_DataOut   (CPL_REQ_HNDL_OUT),
.Full           (COMPLETION_FULL),//output logic        Full, 
.Empty          (COMPLETION_EMPTY)//output logic        Empty 
); 


TL_TX_ENCODER TXCONTROLLER
(
    .clk(clk), //input  logic        clk, 1
    .rst(rst), //input  logic        rst, 2



    .valid(valid_reg), //input  logic        valid,3
    .fmt(fmt_reg), //input  logic  [2:0] fmt, 4
    .type_(type_reg),//input  logic  [4:0] type_, 5
    .TC(TC_reg),//input  logic  [2:0] TC, 6
    .ATTR(ATTR_reg),//input  logic  [2:0] Attr, 7

    .device_id                      (device_id_reg),//input  logic  [15:0] requester_id, 8
    .tag                            (tag_reg),//input  logic  [7:0] tag, 9

    .byte_count                     (byte_count_reg),//input  logic  [11:0] byte_count; 10
    
    .lower_address                  (lower_addr_reg),           //input  logic  [31:0] lower_address, 11
    .upper_address                  (upper_addr_reg),           //input  logic  [31:0] upper_address, 12
    .bdf_id                         (dest_bdf_id_reg),                                         //input  logic  [15:0] bdf_id, 13
    .config_dw_number               (config_dw_number_reg),          //input  logic  [9:0]  configuration_dw_number, 14
    .data                           (data_reg),                                                    //input  logic  [31:0] data, 15

    // Completion Protocol
    .CPL_REQUESTER_ID               (CPL_REQUESTER_ID),          //input  logic  [15:0] CPL_REQUESTER_ID, // => H2_CPL (Requester ID) 17
    .CPL_REQUESTER_TAG              (CPL_REQUESTER_TAG),         //input  logic  [7:0]  CPL_REQUESTER_TAG, // => H2_CPL (Tag) 18
    .CPL_REQUESTER_TOTAL_BYTE_COUNT (REQUESTED_BYTES),           //input  logic  [11:0] CPL_REQUESTER_TOTAL_BYTE_COUNT, //total requested bytes 20
    .CPL_LOWER_ADDRESS              (LOWER_ADDRESS),             //input  logic  [6:0]  CPL_LOWER_ADDRESS, // ?? 21
    .CPL_HNDLR_FIFO_NOT_EMPTY       (CPL_HNDLR_FIFO_NOT_EMPTY),  //input  logic         CPL_HNDLR_FIFO_NOT_EMPTY

    .completion_status              (),                         //input  logic     completion_status, 19
    .CPL_HNDLR_FIFO_RD_EN           (),                         //output  logic    CPL_HNDLR_FIFO_RD_EN, 16
    
    .P_NP_CPL(P_NP_CPL),                                        //output logic  [1:0] P_NP_CPL, //22
    .HEADER_DATA(HEADER_DATA),                                  //output logic        HEADER_DATA, //23
    .PNPC_BUFF_WR_EN(PNPC_BUFF_WR_EN),                          //output logic        WR_EN,//24
    
    
    .tlp_start_flag(tlp_start_flag_enc_2_buff),// output  logic         tlp_start_flag,
    .tlp_end_flag(tlp_end_flag_enc_2_buff),// output  logic         tlp_end_flag,


    .fsm_started(fsm_started),     //output  logic         fsm_started,
    .fsm_finished(fsm_finished),    //output  logic         fsm_finsihed,
    
    .data_address(data_address),
    
    .TLP(TLP)                       //output logic  [31:0] TLP 25

    
);

/*

*/
wire OUT_EMPTY;

assign next_VALID_FOR_DL = ~ALL_BUFFS_EMPTY && RD_EN?1'b1:1'b0;
always@(posedge clk or negedge rst)
begin
    if(!rst)
    begin
        VALID_FOR_DL<=0;
    end
    else
    begin
        VALID_FOR_DL<=next_VALID_FOR_DL;
    end
end
PNPC_BUFF #(.DATA_WIDTH(32)) PNPC_BUFF0
(
    .clk(clk),                              //input  logic                     clk,
    .rst(rst),                              //input  logic                     rst,
    .HEADER_DATA(HEADER_DATA),              //input  logic                     HEADER_DATA, // 0: Header, 1: Data
    .P_NP_CPL(P_NP_CPL),                    //input  logic [1:0]               P_NP_CPL, // Posted: 00, Non-Posted: 01, Completion: 11
    .IN_TLP_DW(TLP),                        //input  logic [DATA_WIDTH-1:0]    IN_TLP_DW
    .WR_EN(PNPC_BUFF_WR_EN),                //input  logic                     WrEn,
    .RD_EN(RD_EN),                          //input  logic                     RdEn,

.TLP_START_BIT_IN(tlp_start_flag_enc_2_buff),// input   logic                       TLP_START_BIT_IN,
.TLP_END_BIT_IN(tlp_end_flag_enc_2_buff),// input   logic                       TLP_END_BIT_IN, 

    .TLP_START_BIT_OUT_COMB(TLP_START_BIT_OUT_COMB),      //output  logic                       TLP_START_BIT_OUT_COMB,
    .TLP_END_BIT_OUT_COMB(TLP_END_BIT_OUT_COMB),         // output  logic                       TLP_END_BIT_OUT_COMB

    .EMPTY(ALL_BUFFS_EMPTY),
    //.OUT_EMPTY(OUT_EMPTY),
    // .OUT_TLP_DW(OUT_TLP_DW),               //output logic [DATA_WIDTH-1:0]    OUT_TLP_DW    
    .OUT_TLP_DW_COMB(OUT_TLP_DW)       
);

endmodule