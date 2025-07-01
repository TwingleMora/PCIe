module TL_RX_TB;
localparam DATA_WIDTH = 32;
//FIRST CLK, RST
bit clk, rst;
// SECOND NAMES
///---
// THIRD CONNECTIONS

logic               DPI_MM = 0;
logic  [9:0]        port_write_en;

logic  [2:0]        tlp_mem_io_msg_cpl_conf;
logic               tlp_address_32_64;
logic               tlp_read_write;


logic  [2:0]        TC = 0;
logic  [2:0]        ATTR = 0;
logic  [15:0]       device_id;
logic  [7:0]        tag = 0;
logic  [11:0]       byte_count;
logic  [31:0]       lower_addr;
logic  [31:0]       upper_addr;
logic  [15:0]       dest_bdf_id;

logic  [31:0]       data1;
logic  [31:0]       data2;
logic  [31:0]       data3;


logic  [9:0]        config_dw_number;
logic               valid;
logic               RD_EN;
wire                    VALID_FOR_DL;
wire                    ALL_BUFFS_EMPTY;
logic   [31:0]          OUT_TLP_DW;    
logic                   fsm_finished;
//-----------------------------------------

//TL_RX_DECODER
/*output*/ logic            DATA_BUFFER_WR_EN;
/*output*/ logic  [2:0]     rx_tlp_mem_io_msg_cpl_conf;
/*output*/ logic            rx_tlp_address_32_64;
/*output*/ logic            rx_tlp_read_write;

/*output*/  logic  [11:0]    rx_cpl_byte_count;
/*output*/  logic  [6:0]     rx_cpl_lower_address;
/*output*/  logic  [3:0]     rx_first_dw_be;
/*output*/  logic  [3:0]     rx_last_dw_be;
/*output*/  logic  [31:0]    rx_lower_addr;
/*output*/  logic  [31:0]    rx_upper_addr;
/*output*/  logic  [31:0]    rx_data;
/*output*/  logic  [11:0]    rx_config_dw_number;

/*input*/  logic   [31:0]   TLP;
/*input*/  logic            M_READY;
/*output*/ logic            M_ENABLE;

//---------------------------------------------------------
//FIFO
// /*input*/  logic        DATA_BUFF_WR_EN;
// /*input*/  logic        DATA_BUFF_RD_EN;
// /*input*/  logic [DATA_WIDTH-1:0] DATA_BUFF_DATA_IN;
// /*output*/ logic [DATA_WIDTH-1:0] DATA_BUFF_DATA_OUT;
 /*output*/ logic [DATA_WIDTH-1:0] DATA_BUFF_COMB_DATA_OUT;
// /*output*/ logic        DATA_BUFF_Full;
// /*output*/ logic        DATA_BUFF_Empty;

//--------------------------------------------------------------
//MASTER_BRIDGE

// /*input*/   logic               PENABLE;
// /*output*/  logic               PREADY;
// /*input*/   logic  [2:0]        tlp_mem_io_msg_cpl_conf;
// /*input*/   logic               tlp_address_32_64;
// /*input*/   logic               tlp_read_write;
// /*input*/   logic  [3:0]        first_dw_be;
// /*input*/   logic  [3:0]        last_dw_be;
// /*input*/   logic  [31:0]       lower_addr;
// /*input*/   logic  [31:0]       data;
/*input*/   logic               last_dw;
/*input*/  logic               DATA_BUFF_EMPTY;
/*output*/  logic               DATA_BUFF_RD_EN;
// /*input*/   logic  [9:0]        config_dw_number;
//                 <<APB INTF>>
/*input*/   logic [31:0]        M_PRDATA1;
/*input*/   logic [31:0]        M_PRDATA2;

/*output*/  logic               M_PSEL1;
/*output*/  logic               M_PSEL2;
/*output*/  logic [31:0]        M_PADDR;
/*output*/  logic               M_PENABLE;
/*output*/  logic               M_PWRITE;
/*output*/  logic [3:0]         M_PSTRB;
/*output*/  logic [31:0]        M_PWDATA;

//-------------------------------------------------------------
//APB_ALU
/*input*/  logic        PSEL;
/*input*/  logic        PENABLE;
/*input*/  logic        PWRITE;
/*input*/  logic [31:0] PADDR;
/*input*/  logic [3:0]  PSTRB;
/*input*/  logic [31:0] PWDATA;
/*output*/ logic [31:0] PRDATA;
/*output*/ logic        PREADY;

always #5 clk = ~clk;

// ----------------------------------------------------------------------------------------------------------------------------------------------------
TL_TX TL_TX0 
(           .clk(clk),                                  //input   logic                    clk, 
            .rst(rst),                                  //input   logic                    rst,
            .DPI_MM(DPI_MM),                            //input   logic                    DPI_MM,

            .port_write_en(port_write_en),                        //input   logic    [9:0]           port_write_en,
            .tlp_mem_io_msg_cpl_conf(tlp_mem_io_msg_cpl_conf),    //input   logic    [1:0]           tlp_mem_io_msg_cpl_conf,
            .tlp_address_32_64(tlp_address_32_64),                //input   logic                    tlp_address_32_64,
            .tlp_read_write(tlp_read_write),                      //input   logic                    tlp_read_write,


            .TC(TC),                                    //input   logic    [2:0]          TC,
            .ATTR(ATTR),                                //input   logic    [2:0]          ATTR,
            //.device_id(device_id),                    //input   logic    [15:0]         device_id,
            .tag(tag),                                  //input   logic    [7:0]          tag,

            .byte_count(byte_count),                    //input   logic    [11:0]         byte_count,
            .lower_addr(lower_addr),                    //input   logic    [31:0]         lower_addr,
            .upper_addr(upper_addr),                    //input   logic    [31:0]         upper_addr,
                                                        
            .dest_bdf_id(dest_bdf_id),                  //input   logic    [15:0]         dest_bdf_id,
            .config_dw_number(config_dw_number),        //input   logic    [9:0]          config_dw_number,

            .data1(data1),                                //input   logic    [31:0]         data1,
            .data2(data2),                                //input   logic    [31:0]         data2,
            .data3(data3),                                //input   logic    [31:0]         data3,

            .valid(valid),                              //input   logic                   start,


            .RD_EN(RD_EN),                              //input   logic                   RD_EN,
            .ALL_BUFFS_EMPTY(ALL_BUFFS_EMPTY),          //output  logic                   EMPTY,
            .VALID_FOR_DL(VALID_FOR_DL),                //output  logic                   VALID,
            .OUT_TLP_DW(OUT_TLP_DW),                     //output  logic    [31:0]         OUT_TLP_DW    );
            .fsm_finished(fsm_finished),
            .fsm_started(fsm_started)
);


TL_RX_DECODER tl_rx_decoder
(
    .clk(clk),
    .rst(rst),
    .TLP(OUT_TLP_DW),// input  logic   [31:0]   TLP,
    .TLP_BUFFER_EMPTY(ALL_BUFFS_EMPTY),// input  logic            TLP_BUFFER_EMPTY,
    .TLP_BUFFER_RD_EN(RD_EN),// output logic            TLP_BUFFER_RD_EN,
    
    
    .DATA_BUFFER_WR_EN(DATA_BUFFER_WR_EN),// output logic            DATA_BUFFER_WR_EN,          
    


    .tlp_mem_io_msg_cpl_conf(rx_tlp_mem_io_msg_cpl_conf),// output  logic  [2:0]     tlp_mem_io_msg_cpl_conf,
    .tlp_address_32_64(rx_tlp_address_32_64),// output  logic            tlp_address_32_64,
    .tlp_read_write(rx_tlp_read_write),// output  logic            tlp_read_write,
    // //output  logic            tlp_conf_type,

    .cpl_byte_count(rx_cpl_byte_count),// output  logic  [11:0]    cpl_byte_count,
    .cpl_lower_address(rx_cpl_lower_address),// output  logic  [6:0]     cpl_lower_address,

    .first_dw_be(rx_first_dw_be),  // output  logic  [3:0]     first_dw_be,
    .last_dw_be(rx_last_dw_be),    // output  logic  [3:0]     last_dw_be,

    .lower_addr(rx_lower_addr),            // output  logic  [31:0]    lower_addr,
    .upper_addr(rx_upper_addr),            // output  logic  [31:0]    upper_addr,
    
    .config_dw_number(rx_config_dw_number),// output  logic  [11:0]    config_dw_number,

    .data(rx_data),                        // output  logic  [31:0]    data,





    // Interface With Master
    .M_READY(M_READY), // input  logic            M_READY
    .M_ENABLE(M_ENABLE)// output logic            M_ENABLE,

);



FIFO DATA_BUFFER
(
    .clk            (clk),//input  logic        clk, 
    .rst            (rst),//input  logic        rst,
    .WrEn           (DATA_BUFFER_WR_EN),//input  logic        DATA_BUFF_WR_EN, 
    .RdEn           (DATA_BUFF_RD_EN),//input  logic        DATA_BUFF_RD_EN,
    .DataIn         (rx_data),//input  logic [DATA_WIDTH-1:0] DATA_BUFF_DATA_IN,
    // .DataOut        (),//output logic [DATA_WIDTH-1:0] DATA_BUFF_DATA_OUT,
    .comb_DataOut   (DATA_BUFF_COMB_DATA_OUT), //output logic [DATA_WIDTH-1:0] DATA_BUFF_COMB_DATA_OUT
    .Full           (),//output logic        DATA_BUFF_Full, 
    .Empty          (DATA_BUFF_EMPTY),//output logic        DATA_BUFF_Empty 
    .AlmostEmpty    (last_dw)
); 







MASTER_BRIDGE master_bridge
(
    .PCLK(clk),     //     input logic         PCLK,
    .PRESETn(rst),  //     input logic         PRESETn,



    
    // //SLAVE Interface (APB-Like Interface FROM Transaction )

    .PENABLE(M_ENABLE), //     input   logic           PENABLE,
    .PREADY(M_READY),   //     output  logic           PREADY,

        

        
    .tlp_mem_io_msg_cpl_conf(rx_tlp_mem_io_msg_cpl_conf),   //     input  logic  [2:0]     tlp_mem_io_msg_cpl_conf,
    .tlp_address_32_64(rx_tlp_address_32_64),               //     input  logic            tlp_address_32_64,
    .tlp_read_write(rx_tlp_read_write),                     //     input  logic            tlp_read_write,

        
    .first_dw_be(rx_first_dw_be),   //     input  logic  [3:0]     first_dw_be,
    .last_dw_be(rx_last_dw_be),     //     input  logic  [3:0]     last_dw_be,
    .lower_addr(rx_lower_addr),     //     input  logic  [31:0]    lower_addr,

    // //calculate OFFSET and M_PSTRB

    .data(DATA_BUFF_COMB_DATA_OUT), //     input  logic  [31:0]    data,
    .last_dw(last_dw),              //     input  logic            last_dw,

    .DATA_BUFF_EMPTY(DATA_BUFF_EMPTY),  //     input logic            DATA_BUFF_EMPTY,
    .DATA_BUFF_RD_EN(DATA_BUFF_RD_EN),                 //     output logic            DATA_BUFF_RD_EN,

    .config_dw_number(rx_config_dw_number),//     input  logic  [9:0]     config_dw_number,


    // // Master Interface (TO APPLICATION & CONF MEMORY)

    .M_PRDATA1(M_PRDATA1),  //     input  logic [31:0] M_PRDATA1,
    .M_PRDATA2(),           //     input  logic [31:0] M_PRDATA2,

    .M_PREADY1(M_PREADY1),  //     input  logic        M_PREADY1,
    .M_PREADY2(),           //     input  logic        M_PREADY2,
    

    .M_PSEL1(M_PSEL1),      //     output logic        M_PSEL1,
    .M_PSEL2(),             //     output logic        M_PSEL2,

    .M_PADDR(M_PADDR),      //     output logic [31:0] M_PADDR,
    .M_PENABLE(M_PENABLE),  //     output logic        M_PENABLE,
    .M_PWRITE(M_PWRITE),    //     output logic        M_PWRITE,
    .M_PSTRB(M_PSTRB),      //     output logic [3:0]  M_PSTRB,
    .M_PWDATA(M_PWDATA)     //     output logic [31:0] M_PWDATA 


    //////////////TRANSMITER///////////// FOR COMPLETION //////////////
);



APB_ALU #(
//   .RO_START(),           // parameter [31:0] RO_START =    'b11_11,
//   .RO_END(),             // parameter [31:0] RO_END   =     'b00_00,
     .MEMORY_DEPTH(3)       // parameter        MEMORY_DEPTH = 3 
) core_layer
(

    .PCLK(clk),// input  logic PCLK, 
    .PRESETn(rst),// input  logic PRESETn,

    // //APB INTERFACE
    .PSEL(M_PSEL1),    // input  logic        PSEL, 
    .PENABLE(M_PENABLE), // input  logic        PENABLE,
    .PWRITE(M_PWRITE),  // input  logic        PWRITE,
    .PADDR(M_PADDR),   // input  logic [31:0] PADDR,
    .PSTRB(M_PSTRB),   // input  logic [3:0]  PSTRB,
    .PWDATA(M_PWDATA),  // input  logic [31:0] PWDATA,

    .PREADY(M_PREADY1),  // output logic        PREADY,
    .PRDATA(M_PRDATA1)  // output logic [31:0] PRDATA,

);

CONF_SPACE #(
    // parameter            DW_COUNT          = 16,
    .DEV_ID(16'b0000_0001_00000_000)// parameter reg [15:0] DEV_ID            = 16'b0000_0001_00000_000,
    // parameter reg [15:0] VENDOR_ID         = 16'b0000_0001_00000_000,
    // parameter reg [7:0]  HEADER_TYPE       = 8'b0000,
    
    // parameter reg        BAR0EN            = 1,
    // parameter reg        BAR0MM_IO         = 0,
    // parameter reg        BAR0_32_64        = 2'b00,
    // parameter reg        BAR0_NONPRE_PRE   = 1'b0,
    // parameter            BAR0_BYTES_COUNT  = 4096,

    // parameter reg        BAR1EN            = 0,
    // parameter reg        BAR1MM_IO         = 0,
    // parameter reg        BAR1_32_64        = 2'b00,
    // parameter reg        BAR1_NONPRE_PRE   = 1'b0,
    // parameter            BAR1_BYTES_COUNT  = 4096, //  

    // parameter reg        BAR2EN            = 0,
    // parameter reg        BAR2MM_IO         = 0,
    // parameter reg        BAR2_32_64        = 2'b00,
    // parameter reg        BAR2_NONPRE_PRE   = 1'b0,
    // parameter            BAR2_BYTES_COUNT  = 4096 // 
) conf_space
    (
    .clk(clk),//     input       logic                           clk,
    .rst(rst) //     input       logic                           rst,
    //     input       logic                           wr_en,
    //     input       logic [31:0]                    data_in,
    //     input       logic [$clog2(DW_COUNT)-1:0]    addr,

    //     output      logic [31:0]                    data_out,  
    //.device_id()//     output wire logic [15:0]                    device_id,
    //     output wire logic [15:0]                    vendor_id,
    //     output wire logic [7:0]                     header_type,

    //     output wire logic [31:0]                    BAR0,
    //     output wire logic [31:0]                    BAR1,
    //     output wire logic [31:0]                    BAR2,
    //     output wire logic [7:0]                     BridgeSubBusNum,
    //     output wire logic [7:0]                     BridgeSecBusNum,
    //     output wire logic [7:0]                     BridgePriBusNum,

    //     output wire logic [7:0]                     BridgeIOLimit,
    //     output wire logic [7:0]                     BridgeIOBase,

    //     output wire logic [7:0]                     BridgeMemLimit,
    //     output wire logic [7:0]                     BridgeMemBase,

    //     output wire logic [7:0]                     BridgePrefMemLimit,
    //     output wire logic [7:0]                     BridgePrefMemBase,

    //     output wire logic [31:0]                    BridgePrefMemBaseUpper,
    //     output wire logic [31:0]                    BridgePrefMemLimitUpper,

    //     output wire logic [15:0]                     BridgeIOLimitUpper,
    //     output wire logic [15:0]                     BridgeIOBaseUpper

    );


// PNPC_BUFF #(
// .DATA_WIDTH(32)    // parameter DATA_WIDTH = 32
// ) pnpc_rx_buff
// (
// .clk(clk)// input  logic                     clk,
// .rst(rst),// input  logic                     rst,
// // input  logic                     HEADER_DATA, // 0: Header, 1: Data
// // input  logic [1:0]               P_NP_CPL, // Posted: 00, Non-Posted: 01, Completion: 11
// // input  logic [DATA_WIDTH-1:0]    IN_TLP_DW,
// // input  logic                     WR_EN,
// // input  logic                     RD_EN,


// // output wire                      EMPTY,
// // output logic                     OUT_EMPTY,
// // output logic [DATA_WIDTH-1:0]    OUT_TLP_DW      
// );

task reset();
    rst <= 0;
    @(posedge clk)
    rst <= 1;
endtask

//32 bit
task send_req_packet(int tlp_type_, int tlp_read_write_, int byte_count_, int address_, int data1_, int data2_ = 0, int data3_ =0);
    tlp_mem_io_msg_cpl_conf <= tlp_type_;        //0: memory, 1: io, 2: completion
    tlp_address_32_64  <= 0;          //0: 32-bit, 1: 64-bit
    tlp_read_write     <= tlp_read_write_;       //0: read, 1: write

    //Number Of Written Bytes 
    byte_count <= byte_count_;
    
    //Destination
    lower_addr <= address_;    
    upper_addr <= 32'h0000_0000; 

    dest_bdf_id <= 16'h0000;
    config_dw_number <= 10'd0;

    data1 <= data1_;
    data2 <= data2_;
    data3 <= data3_;

    valid <= 1;         //Initiate Transaction Generation FSM
    wait(fsm_started);
    valid <= 0; 
    wait(fsm_finished);
    @(posedge clk);

endtask

initial begin


    reset();

    //(1) #################### POSTED MEMORY 2-BYTES MEMORY WRITE TLP ##########################
    send_req_packet(.tlp_type_(0), .tlp_read_write_(1), .byte_count_(6), .address_(32'h00_00_00_00), .data1_(32'h0002_0007)
    ,.data2_(32'h0000_0001));
    
    send_req_packet(.tlp_type_(0), .tlp_read_write_(1), .byte_count_(1), .address_(32'h00_00_00_06), .data1_(32'h0000_0001)
    ,.data2_(32'h0000_0001));
    
    // //(2) #################### POSTED MEMORY 2-BYTES 32-BIT MEMORY WRITE TLP #########################
    // @(posedge clk);
    // send_req_packet(.tlp_type_(0), .tlp_read_write_(1), .byte_count_(2), .address_(32'h00_00_00_02), .data1_(32'h05));
    
    // //(3) #################### POSTED MEMORY 2-BYTES 32-BIT MEMORY WRITE TLP #########################
    // @(posedge clk);
    // send_req_packet(.tlp_type_(0), .tlp_read_write_(1), .byte_count_(2), .address_(32'h00_00_00_04), .data1_(32'h00));

    // //(3) #################### POSTED MEMORY 2-BYTES 32-BIT MEMORY WRITE TLP #########################
    // @(posedge clk);
    // send_req_packet(.tlp_type_(0), .tlp_read_write_(1), .byte_count_(2), .address_(32'h00_00_00_06), .data1_(32'h01));



    while(!M_PREADY1)
    begin
        @(posedge clk);

    end
    repeat(15)
        @(posedge clk);
    $stop; 
end


endmodule