// wire new_tlp_ready = TLP_START_BIT_OUT_COMB& ~ALL_BUFFS_EMPTY;
module TRANSACTION_RX_TOP #(parameter DATA_WIDTH = 32, parameter ADDR_WIDTH = 32, parameter BUS_WIDTH = 128 )(

// DL-TL Interface
input   logic                           clk,
input   logic                           rst,
//////////////////////////////////////////////////////////////
// DATA LINK INTERFACE
//////////////////////////////////////////////////////////////
input   logic [BUS_WIDTH-1:0]                    IN_TLP_DW,
input   logic                           new_tlp_ready,
input   logic                           valid_tlp,
//AXI Interface                         
output  logic [ADDR_WIDTH-1:0]          awaddr,
output  logic [7:0]                     awlen,   // number of transfers in transaction
output  logic [2:0]                     awsize,  // number of bytes in transfer  //                            000=> 1, 001=>2, 010=>4, 011=>8, 100=>16, 101=>32, 110=>64, 111=>128
output  logic [1:0]                     awburst,
input   logic                           awready,
output  logic                           awvalid,

// W Channel                            
output logic [DATA_WIDTH-1:0]           wdata, 
output logic [(DATA_WIDTH/8)-1:0]       wstrb, 
output logic                            wlast, 
output logic                            wvalid,
input  logic                            wready,

// B Channel                            
input  logic [1:0]                      bresp,                         
input  logic                            bvalid,                         
output logic                            bready,                         

// AR Channel                           
output logic [ADDR_WIDTH-1:0]           araddr,
output logic [7:0]                      arlen,
output logic [2:0]                      arsize,
output logic [1:0]                      arburst,
input  logic                            arready,
output                                  arvalid,
                                        
// R Channel                            
input   logic [DATA_WIDTH-1:0]          rdata,
input   logic [1:0]                     rresp,
input   logic                           rlast,
input   logic                           rvalid,
output  logic                           rready,
                    
//Internal Native Interface (FROM AXI MASTER TO TL_TX)
output  logic                     RX_B_tlp_read_write,   //
output  logic    [2:0]            RX_B_TC,               //
output  logic    [2:0]            RX_B_ATTR,             //
output  logic    [15:0]           RX_B_requester_id,     //
output  logic    [7:0]            RX_B_tag,              //
output  logic    [11:0]           RX_B_byte_count,       //
//--------------------------------------------------------------------------------------
output  logic    [6:0]            RX_B_lower_addr,       //
output  logic    [2:0]            RX_B_completion_status,
//----------------------------------------------------------------------------------------- 
//-----------------------------------------------------------------------------------------          
output  logic    [31:0]           RX_B_data1,                 //
output  logic    [31:0]           RX_B_data2,                 //
output  logic    [31:0]           RX_B_data3,                 //
//-----------------------------------------------------------------------------------------                   
output  logic                     RX_B_Wr_En,                 //
//-----------------------------------------------------------------------------------------

//Internal Native Interface (FROM ERROR DETECTION TO TL_TX)
//-------------------------------------------------------------------------- (4)
output   logic    [2:0]            ERR_CPL_TC,                      //.TC(TC);
output   logic    [2:0]            ERR_CPL_ATTR,                    //.ATTR(ATTR);
//---------------------------------------------------------------------------(6)
output   logic    [15:0]           ERR_CPL_requester_id,            //[[X]]  -- //COMPLETER ID 
output   logic    [7:0]            ERR_CPL_tag,                    //[[X]].
output   logic    [11:0]           ERR_CPL_byte_count,              //

//---------------------------------------------------------------------------(36)           
output   logic    [6:0]            ERR_CPL_lower_addr,              //[[X]]
output   logic    [2:0]            ERR_CPL_completion_status,
//---------------------------------------------------------------------------(7)  
//---------------------------------------------------------------------------(96)
output    logic                    ERR_CPL_Wr_En,                 //.valid(valid);
//------------------------------------------------------------------------------

input    logic      [2:0]    MSG_tlp_mem_io_msg_cpl, //type // tlp_mem_io_msg_cpl_conf(tlp_mem_io_msg_cpl_conf),
input    logic               MSG_tlp_address_32_64,       //fmt[0]      //tlp_address_32_64(tlp_address_32_64),
input    logic               MSG_tlp_read_write,          //fmt[1]      // tlp_read_write(tlp_read_write),
//-------------------------------------------------------------------------- (4)
input    logic    [2:0]      MSG_TC,                      //TC(TC), 
input    logic    [2:0]      MSG_ATTR,                    //ATTR(ATTR), 
//---------------------------------------------------------------------(6)
input    logic    [15:0]     MSG_requester_id,            //[[MSG]]  -- //COMPLETER ID //device_id(device_id),
input    logic    [7:0]      MSG_tag,                     //[[MSG]]tag(tag),
input    logic    [11:0]     MSG_byte_count,              //byte_count(byte_count),
//---------------------------------------------------------------------(36)           
input    logic    [6:0]      MSG_lower_addr,              //[[MSG]]       //lower_addr(lower_addr),
input    logic    [2:0]      MSG_completion_status,
//---------------------------------------------------------------------(7)
input    logic    [31:0]     MSG_data1,                 //data1(data1),
input    logic    [31:0]     MSG_data2,                 //data2(data2),
input    logic    [31:0]     MSG_data3,                 //data3(data3) ,  
/////////////////////////////////////////////////////////////////////////////////////////////
input    logic               MSG_ARB_VALID,           ////////////////////////////////
output   logic               MSG_ARB_ACK,            ////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////






//---------------------------------------------------------------------------(1)
output    logic                     RX_B_TX_DATA_FIFO_WR_EN,
output    logic [31:0]              RX_B_TX_DATA_FIFO_data,
//---------------------------------------------------------------------------(1)
//---------------------------------------------------------------------------(1)

output    logic                            NP_RDEN,
output    logic  [7:0]                     NP_TAG_IDX,
output    logic  [15:0]                    NP_DEST_IDX,
input     logic                            NP_REQ_EXIST





);


//TL_RX_DECODER <== RX_PNPC_BUFF
/*output*/  logic            DATA_BUFFER_WR_EN;
/*output*/  logic  [2:0]     rx_tlp_mem_io_msg_cpl_conf;
/*output*/  logic            rx_tlp_address_32_64;
/*output*/  logic            rx_tlp_read_write;
/*output*/  logic  [11:0]    rx_cpl_byte_count;
/*output*/  logic  [6:0]     rx_cpl_lower_address;
/*output*/  logic  [15:0]    rx_requester_id;
/*output*/  logic  [7:0]     rx_tag;
/*output*/  logic  [3:0]     rx_first_dw_be;
/*output*/  logic  [3:0]     rx_last_dw_be;
/*output*/  logic  [31:0]    rx_lower_addr;
/*output*/  logic  [31:0]    rx_upper_addr;
/*output*/  logic  [31:0]    rx_data;
/*output*/  logic  [11:0]    rx_config_dw_number;
            logic  [9:0]     rx_tlp_length;

// /*input*/   logic   [31:0]   TLP;
/*input*/   logic            M_READY;
/*output*/  logic            M_ENABLE;

//---------------------------------------------------------
//FIFO
// /*input*/  logic        DATA_BUFF_WR_EN;
// /*input*/  logic        DATA_BUFF_RD_EN;
// /*input*/  logic [DATA_WIDTH-1:0] DATA_BUFF_DATA_IN;
// /*output*/ logic [DATA_WIDTH-1:0] DATA_BUFF_DATA_OUT;
// /*output*/ logic [DATA_WIDTH-1:0] DATA_BUFF_COMB_DATA_OUT;
// /*output*/ logic        DATA_BUFF_Full;
// /*output*/ logic        DATA_BUFF_Empty;

//--------------------------------------------------------------


//----------------------------------------------------------------
// DATA FIFO
//----------------------------------------------------------------

logic [DATA_WIDTH-1:0]          DATA_BUFF_COMB_DATA_OUT;
/*input*/   logic               last_dw;
/*input*/   logic               DATA_BUFF_EMPTY;
/*output*/  logic               DATA_BUFF_RD_EN;

//------------------------------------------------------------------
// Requests CPL from RX AXI MASTER
//------------------------------------------------------------------
    //      .    .    .    .                        
    //    //. \\//.\\//.\\//.\\ CPLD FROM RX BRIDGE  
    //   // . //\\ //\\.//\\//\\
    //   \\ //
    //    ===
// wire valid_tlp;
// assign valid_tlp = !ALL_BUFFS_EMPTY;


/* input */  logic                     RX_HEADER_DATA; // 0: Header; 1: Data
/* input */  logic [1:0]               RX_P_NP_CPL; // Posted: 00; Non-Posted: 01; Completion: 11
/* input */  logic [DATA_WIDTH-1:0]    RX_IN_TLP_DW;
/* input */  logic                     RX_WR_EN;
/* input */  logic                     RX_RD_EN;
/* input */  logic                     RX_commit;
/* input */  logic                     RX_flush;
/* output */ wire                      RX_EMPTY;
/* output */ logic                     RX_OUT_EMPTY;
/* output */ logic [BUS_WIDTH-1:0]     RX_OUT_TLP_DW;      
/* output */ logic [BUS_WIDTH-1:0]     RX_OUT_TLP_DW_COMB; 




/* TL_RX_ERROR_CHECK */ TL_RX_ERROR_CHECK128 #(.DATA_WIDTH(32)) tl_rx_error_check
(
    /* input   logic */                         .clk(clk),
    /* input   logic */                         .rst(rst),

///////////FROM DL///////////////////////
    /* input  logic   [31:0] */                .TLP(IN_TLP_DW),
    /* input  logic */                         .new_tlp_ready(new_tlp_ready), 
    /* input  logic */                         .valid(valid_tlp),
///////////P_NP_CPL BUFFER////////////////////
//Write (H||D)(), Read (H)

    // input   logic                          TLP_BUFFER_EMPTY(),
    /* output  logic */                       .HEADER_DATA(RX_HEADER_DATA), // 0: Header; 1: Data
    /* output  logic [1:0] */                 .P_NP_CPL(RX_P_NP_CPL), // Posted: 00; Non-Posted: 01; Completion: 11
    // /* output  logic [DATA_WIDTH-1:0] */      .IN_TLP_DW(RX_IN_TLP_DW),
    /* output  logic */                       .WR_EN(RX_WR_EN),
    /* output  logic */                       .flush(RX_flush),
    /* output  logic */                       .commit(RX_commit),
    // output  logic                       TLP_BUFFER_RD_EN(), //Not Busy
    ////////////////////////////////////
    // output  logic                       DATA_BUFFER_WR_EN(),          
    ////////////////////////////////////
    // /* output  logic  [2:0] */     .tlp_mem_io_msg_cpl_conf(),
    // /* output  logic */            .tlp_address_32_64(),
    // /* output  logic */            .tlp_read_write(),
    //  //output  logic               tlp_conf_type(),
    // /* output  logic  [11:0] */    .cpl_byte_count(),
    // /* output  logic  [6:0] */     .cpl_lower_address(),
    // /* output  logic  [3:0] */     .first_dw_be(),
    // /* output  logic  [3:0] */     .last_dw_be(),
    // /* output  logic  [31:0] */    .lower_addr(),
    // /* output  logic  [31:0] */    .upper_addr(),
    // /* output  logic  [31:0] */    .data(),
    // /* output  logic  [11:0] */    .config_dw_number()


        //------------------------------------------------------------------------------------
    //------------------------------------------------------------------------------------
    //------------------------------------------------------------------------------------
    /* output    logic         */                      .NP_RDEN     (NP_RDEN),
    /* output    logic  [7:0]  */                      .NP_TAG_IDX  (NP_TAG_IDX),
    /* output    logic  [15:0] */                      .NP_DEST_IDX (NP_DEST_IDX),
    /* input   logic         */                        .NP_REQ_EXIST(NP_REQ_EXIST)
);


RX_PNPC_BUFF #(.DATA_WIDTH(BUS_WIDTH)) PNPC_BUFF0
(
    .clk(clk),                            //input  logic                     clk,
    .rst(rst),                            //input  logic                     rst,
    .HEADER_DATA(RX_HEADER_DATA),            //input  logic                     HEADER_DATA, // 0: Header, 1: Data
    .P_NP_CPL(RX_P_NP_CPL),                  //input  logic [1:0]               P_NP_CPL, // Posted: 00, Non-Posted: 01, Completion: 11
    .IN_TLP_DW(IN_TLP_DW),                //input  logic [DATA_WIDTH-1:0]    IN_TLP_DW
    .WR_EN(RX_WR_EN),              //input  logic                     WrEn,
    .RD_EN(RX_RD_EN),                        //input  logic                     RdEn,
    .commit(RX_commit),
    .flush(RX_flush),
    .EMPTY(RX_ALL_BUFFS_EMPTY),
    .OUT_TLP_DW(),               //output logic [DATA_WIDTH-1:0]    OUT_TLP_DW     
    .OUT_TLP_DW_COMB(RX_OUT_TLP_DW) ,
    .P_H_CREDIT(),//output logic  [9:0]
    .P_D_CREDIT(),//output logic  [9:0]
    .NP_H_CREDIT(),//output logic  [9:0]
    .NP_D_CREDIT(),//output logic  [9:0]
    .CPL_H_CREDIT(),//output logic  [9:0]
    .CPL_D_CREDIT()    //output logic  [9:0] 
);

/* TL_RX_DECODER */TL_RX_DECODER128 tl_rx_decoder
(
    .clk(clk),
    .rst(rst),
    
    .TLP(RX_OUT_TLP_DW),// input  logic   [31:0]   TLP,
    .TLP_BUFFER_EMPTY(RX_ALL_BUFFS_EMPTY),// input  logic            TLP_BUFFER_EMPTY,
    .TLP_BUFFER_RD_EN(RX_RD_EN),// output logic            TLP_BUFFER_RD_EN,
    .DATA_BUFFER_WR_EN(DATA_BUFFER_WR_EN),// output logic            DATA_BUFFER_WR_EN,          
    


    .tlp_mem_io_msg_cpl_conf(rx_tlp_mem_io_msg_cpl_conf),// output  logic  [2:0]     tlp_mem_io_msg_cpl_conf,
    .tlp_address_32_64(rx_tlp_address_32_64),// output  logic            tlp_address_32_64,
    .tlp_read_write(rx_tlp_read_write),// output  logic            tlp_read_write,
    // //output  logic            tlp_conf_type,

    .cpl_byte_count(rx_cpl_byte_count),// output  logic  [11:0]    cpl_byte_count,
    .cpl_lower_address(rx_cpl_lower_address),// output  logic  [6:0]     cpl_lower_address,

    .first_dw_be(rx_first_dw_be),  // output  logic  [3:0]     first_dw_be,
    .last_dw_be(rx_last_dw_be),    // output  logic  [3:0]     last_dw_be,
    .requester_id(rx_requester_id),
    .tag(rx_tag),

    .lower_addr(rx_lower_addr),            // output  logic  [31:0]    lower_addr,
    .upper_addr(rx_upper_addr),            // output  logic  [31:0]    upper_addr,
    .tlp_length (rx_tlp_length),
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




AXI_MASTER #(.ADDR_WIDTH(ADDR_WIDTH), .DATA_WIDTH(DATA_WIDTH)) axi_master
(   // Global Signals 
    /* input logic */                  
    /* input logic */                  
            .aclk(clk),
            .aresetn(rst),
            .VALID(M_ENABLE),
            .ACK(M_READY),
            .tlp_mem_io_msg_cpl_conf(rx_tlp_mem_io_msg_cpl_conf),   //     input  logic  [2:0]     tlp_mem_io_msg_cpl_conf,
            .tlp_address_32_64(rx_tlp_address_32_64),               //     input  logic            tlp_address_32_64,
            .tlp_read_write(rx_tlp_read_write),                     //     input  logic            tlp_read_write,

/* input  logic  [15:0] */ .requester_id(rx_requester_id),
/* input  logic  [7:0]  */ .tag(rx_tag),       
            .first_dw_be(rx_first_dw_be),   //     input  logic  [3:0]     first_dw_be,
            .last_dw_be(rx_last_dw_be),     //     input  logic  [3:0]     last_dw_be,
            .lower_addr(rx_lower_addr),     //     input  logic  [31:0]    lower_addr,

            // //calculate OFFSET and M_PSTRB
            .length(rx_tlp_length),
            .data(DATA_BUFF_COMB_DATA_OUT),        //     input  logic  [31:0]    data,
            .last_dw(last_dw),                     //     input  logic            last_dw,

            .DATA_BUFF_EMPTY(DATA_BUFF_EMPTY),     //     input logic            DATA_BUFF_EMPTY,
            .DATA_BUFF_RD_EN(DATA_BUFF_RD_EN),     //     output logic            DATA_BUFF_RD_EN,

            .config_dw_number(rx_config_dw_number),//     input  logic  [9:0]     config_dw_number,
                


    // AW Channel
    /* output logic [ADDR_WIDTH-1:0] */           .awaddr(awaddr),
    /* output logic [7:0] */                      .awlen(awlen),  // number of transfers in transaction
    /* output logic [2:0] */                      .awsize(awsize),  // number of bytes in transfer  //                            000=> 1, 001=>2, 010=>4, 011=>8, 100=>16, 101=>32, 110=>64, 111=>128
    /* output logic [1:0] */                      .awburst(awburst),
    /* input  logic */                            .awready(awready),
    /* output logic */                            .awvalid(awvalid),

    // W Channel
    /* output logic [DATA_WIDTH-1:0] */           .wdata(wdata), 
    /* output logic [(DATA_WIDTH/8)-1:0] */       .wstrb(wstrb), 
    /* output logic */                            .wlast(wlast), 
    /* output logic */                            .wvalid(wvalid),
    /* input  logic */                            .wready(wready),

    // B Channel
    /* input  logic [1:0] */                      .bresp(bresp),                         
    /* input  logic */                            .bvalid(bvalid),                         
    /* output logic */                            .bready(bready),                         

    // AR Channel
    /* output logic [ADDR_WIDTH-1:0] */           .araddr(araddr),
    /* output logic [7:0] */                      .arlen(arlen),
    /* output logic [2:0] */                      .arsize(arsize),
    /* output logic [1:0] */                      .arburst(arburst),
    /* input  logic */                            .arready(arready),
    /* output logic */                            .arvalid(arvalid),
                                            

    // R Channel                            
    /* input  logic [DATA_WIDTH-1:0] */           .rdata(rdata),
    /* input  logic [1:0] */                      .rresp(rresp),
    /* input  logic */                            .rlast(rlast),
    /* input  logic */                            .rvalid(rvalid),
    /* output logic */                            .rready(rready),
    // ----------------------------------------------------------------------
    // ----------------------------------------------------------------------
            .RX_B_tlp_read_write    (RX_B_tlp_read_write),
            .RX_B_TC                (RX_B_TC),
            .RX_B_ATTR              (RX_B_ATTR),
            .RX_B_tag               (RX_B_tag),
            .RX_B_requester_id      (RX_B_requester_id),
            .RX_B_byte_count        (RX_B_byte_count),
            .RX_B_lower_addr        (RX_B_lower_addr),
            .RX_B_completion_status (RX_B_completion_status),
    //-----------------------------------------------------------------------------------------           
    /* input   logic    [31:0] */.RX_B_data1(RX_B_data1),                 //
    /* input   logic    [31:0] */.RX_B_data2(RX_B_data2),                 //
    /* input   logic    [31:0] */.RX_B_data3(RX_B_data3),                 //
//----------------------------------------------------------------------------------------                   
    /* input   logic           */.RX_B_Wr_En(RX_B_Wr_En),                  //
//----------------------------------------------------------------------------------------
    // ---------------------------------------------------------------------
    // ---------------------------------------------------------------------
    ////////////////////////////////////////////////////
    ////////////////////FIFO TX////////////////////////
    ////////////////////////////////////////////////////
    /* output logic            */.RX_B_TX_DATA_FIFO_WR_EN(RX_B_TX_DATA_FIFO_WR_EN),
    /* output logic [31:0]     */.RX_B_TX_DATA_FIFO_data(RX_B_TX_DATA_FIFO_data)

    /////////////////////////////////////////////////////
    /////////////////////////////////////////////////////

); 



endmodule