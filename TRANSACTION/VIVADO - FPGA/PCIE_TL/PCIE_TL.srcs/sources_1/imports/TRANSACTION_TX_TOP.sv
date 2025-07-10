module TRANSACTION_TX_TOP #(parameter DATA_WIDTH = 32, parameter ADDR_WIDTH = 32, parameter BUS_WIDTH = 128, parameter DEPTH = 10) (
input  logic                       clk,
input  logic                       rst,
                               
//DATA LINK INTERFACE          
input  logic                       RD_EN,
output logic                       VALID_FOR_DL,
output logic                       ALL_BUFFS_EMPTY,
output logic   [BUS_WIDTH-1:0]     OUT_TLP_DW,
output logic                       fsm_finished,
output logic                       TL_TX_ACK,
output logic                       fsm_started,

output logic                       TLP_END_BIT_OUT_COMB,




//FROM RX ERROR DETECTION TO TX MASTER

//\\\\\\\\\\\\\\\\\\\\\\\\\\\-----------------//////////////////////////////\\
 //\\\\\\\\\\\\\\\\\\\\\\\\\\\     |= =|     //////////////////////////////\\
  //\\\\\\\\\\\\\\\\\\\\\\\\\\\    |= =|    //////////////////////////////\\
   //\\\\\\\\\\\\\\\\\\\\\\\\\\\     |     //////////////////////////////\\
    //\\\\\\\\\\\\\\\\\\\\\\\\\\\    |    //////////////////////////////\\
     //\\\\\\\\\\\\\\\\\\\\\\\\\\\   |   //////////////////////////////\\
      //\\\\\\\\\\\\\\\\\\\\\\\\\\\  |  //////////////////////////////\\
       //\\\\\\\\\\\\\\\\\\\\\\\\\\\ | //////////////////////////////\\
        //\\\\\\\\\\\\\\\\\\\\\\\\\\\|//////////////////////////////\\

/* //FROM RX MASTER to TX MASTER
input    logic    [2:0]            CPL_tlp_mem_io_msg_cpl,   //tlp_mem_io_msg_cpl_conf(tlp_mem_io_msg_cpl_conf),
input    logic                     CPL_tlp_address_32_64,    //fmt[0]      //tlp_address_32_64(tlp_address_32_64),
input    logic                     CPL_tlp_read_write,       //fmt[1]      // tlp_read_write(tlp_read_write),
//-------------------------------------------------------------------------- (4)
input    logic    [2:0]            CPL_TC,                      //TC(TC), 
input    logic    [2:0]            CPL_ATTR,                    //ATTR(ATTR), 
//---------------------------------------------------------------------------(6)
input    logic    [15:0]           CPL_requester_id,            //[[CPL]]  -- //COMPLETER ID //device_id(device_id),
input    logic    [7:0]            CPL_tag,                     //[[CPL]]tag(tag),
input    logic    [11:0]           CPL_byte_count,              //byte_count(byte_count),
//---------------------------------------------------------------------------(36)           
input    logic    [6:0]            CPL_lower_addr,              //[[CPL]]       //lower_addr(lower_addr),
input    logic    [2:0]            CPL_completion_status,
//---------------------------------------------------------------------------(7)
input    logic    [31:0]           CPL_data1,                 //data1(data1),
input    logic    [31:0]           CPL_data2,                 //data2(data2),
input    logic    [31:0]           CPL_data3,                 //data3(data3) ,  



//////////////////////////////////////////////////////////////////
///////////////////////////FIFO TX////////////////////////////////
//////////////////////////////////////////////////////////////////
input    logic    [31:0]           CPL_data,
input    logic                     CPL_WR_EN,
output   logic                     CPL_RD_EN,
//////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////



////////////////////////////////////////////////////////////////////////////////////////////////
input    logic                     CPL_ARB_VALID,                    //////////////////////////
output   logic                     CPL_ARB_ACK,                     //////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////


 */

//------------------------------------------------------------------------------------------------------------------------------------------------------------
//------------------------------------------------------------------------------------------------------------------------------------------------------------
//                             DOUBLE_IN_CPL_ARB            
//------------------------------------------------------------------------------------------------------------------------------------------------------------
//------------------------------------------------------------------------------------------------------------------------------------------------------------


////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//------------------------------------------------------------------
// Errors CPL from Error Detection Block
//------------------------------------------------------------------
//-------------------------------------------------------------------------- (4)
              input   logic    [2:0]            ERR_CPL_TC,                      //.TC(TC);
              input   logic    [2:0]            ERR_CPL_ATTR,                    //.ATTR(ATTR);
//---------------------------------------------------------------------------(6)
              input   logic    [15:0]           ERR_CPL_requester_id,            //[[X]]  -- //COMPLETER ID 
              input   logic    [7:0]            ERR_CPL_tag,                     //[[X]].
              input   logic    [11:0]           ERR_CPL_byte_count,              //

//---------------------------------------------------------------------------(36)           
              input   logic    [6:0]            ERR_CPL_lower_addr,              //[[X]]
              input   logic    [2:0]            ERR_CPL_completion_status,
//---------------------------------------------------------------------------(7)  
//---------------------------------------------------------------------------(96)
             input    logic                     ERR_CPL_Wr_En,    //FOR Control             //.valid(valid);
//---------------------------------------------------------------------------(1)



//------------------------------------------------------------------
// Requests CPL from RX AXI MASTER to TX NATIVE SLAVE
//------------------------------------------------------------------
    //      .    .    .    .                        
    //    //.\\//.\\//.\\//.\\ CPLD FROM RX BRIDGE  
              input   logic                     RX_B_tlp_read_write,          //
              input   logic    [2:0]            RX_B_TC,               //
              input   logic    [2:0]            RX_B_ATTR,             //
              input   logic    [15:0]           RX_B_requester_id,        //
              input   logic    [7:0]            RX_B_tag,              //
              input   logic    [11:0]           RX_B_byte_count,       //

//--------------------------------------------------------------------------------------
              input   logic    [6:0]            RX_B_lower_addr,       //
              input   logic    [2:0]            RX_B_completion_status,
//----------------------------------------------------------------------------------------- 
//-----------------------------------------------------------------------------------------          
              input   logic    [31:0]           RX_B_data1,                 //
              input   logic    [31:0]           RX_B_data2,                 //
              input   logic    [31:0]           RX_B_data3,                 //
//-----------------------------------------------------------------------------------------                   
              input   logic                     RX_B_Wr_En,                  //

     //////////////////////////////////////////////////////////////
    //////////////////////////TX_FIFO/////////////////////////////
  //////////////////////////////////////////////////////////////
              input   logic    [31:0]               RX_B_TX_DATA_FIFO_data,
              input   logic                         RX_B_TX_DATA_FIFO_WR_EN,
  //////////////////////////////////////////////////////////////


//------------------------------------------------------------------------------------------------------------------------------------------------------------
//------------------------------------------------------------------------------------------------------------------------------------------------------------
// ^^^^^^UP^^^^^^^^^UP^^^^^^^^^UP^^^^^^^^^^^^^UP^^^^^^ DOUBLE_IN_CPL_ARB  ^^^^^UP^^^^^^^^^UP^^^^^^^^^^^^^^UP^^^^^^^^^UP^^^^^         
//------------------------------------------------------------------------------------------------------------------------------------------------------------
//------------------------------------------------------------------------------------------------------------------------------------------------------------



input    logic    [2:0]            MSG_tlp_mem_io_msg_cpl, //type // tlp_mem_io_msg_cpl_conf(tlp_mem_io_msg_cpl_conf),
input    logic                     MSG_tlp_address_32_64,       //fmt[0]      //tlp_address_32_64(tlp_address_32_64),
input    logic                     MSG_tlp_read_write,          //fmt[1]      // tlp_read_write(tlp_read_write),
//-------------------------------------------------------------------------- (4)
input    logic    [2:0]            MSG_TC,                      //TC(TC), 
input    logic    [2:0]            MSG_ATTR,                    //ATTR(ATTR), 
//---------------------------------------------------------------------------(6)
input    logic    [15:0]           MSG_requester_id,            //[[MSG]]  -- //COMPLETER ID //device_id(device_id),
input    logic    [7:0]            MSG_tag,                     //[[MSG]]tag(tag),
input    logic    [11:0]           MSG_byte_count,              //byte_count(byte_count),
//---------------------------------------------------------------------------(36)           
input    logic    [6:0]            MSG_lower_addr,              //[[MSG]]       //lower_addr(lower_addr),
input    logic    [2:0]            MSG_completion_status,
//---------------------------------------------------------------------------(7)
input    logic    [31:0]           MSG_data1,                 //data1(data1),
input    logic    [31:0]           MSG_data2,                 //data2(data2),
input    logic    [31:0]           MSG_data3,                 //data3(data3) ,  
/////////////////////////////////////////////////////////////////////////////////////////////
input    logic                     MSG_ARB_VALID,           ////////////////////////////////
output   logic                     MSG_ARB_ACK,             ////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////



// ---------------------------------------------------------------------------
// ---------------------------------------------------------------------------
// /////////////////////////////////////////////AXI///////////////////////////
// ---------------------------------------------------------------------------
// ---------------------------------------------------------------------------

     // Global Signals 
    // input logic                              aclk,
    // input logic                              aresetn,

    // AW Channel
    input   logic [ADDR_WIDTH-1:0]           awaddr,  
    input   logic [7:0]                      awlen,   // number of transfers in transaction
    input   logic [2:0]                      awsize,  // number of bytes in transfer // 000=> 1, 001=>2, 010=>4, 011=>8, 100=>16, 101=>32, 110=>64, 111=>128
    input   logic [1:0]                      awburst,  
    output  logic                            awready, 
    input   logic                            awvalid, 
    input   logic [DATA_WIDTH-1:0]           wdata, 
    input   logic [(DATA_WIDTH/8)-1:0]       wstrb, 
    input   logic                            wlast, 
    input   logic                            wvalid,
    output  logic                            wready,
    output  logic [1:0]                      bresp,                         
    output  logic                            bvalid,                         
    input   logic                            bready,                         
    input   logic [ADDR_WIDTH-1:0]           araddr,
    input   logic [7:0]                      arlen,
    input   logic [2:0]                      arsize,
    input   logic [1:0]                      arburst,
    output  logic                            arready,
    input   logic                            arvalid,                          
    output  logic [DATA_WIDTH-1:0]           rdata,
    output  logic [1:0]                      rresp,
    output  logic                            rlast,
    output  logic                            rvalid,
    input   logic                            rready,










// ---------------------------------------------------------------------------
// -----------------------------CPL TIMEOUT----------------------------------
// ---------------------------------------------------------------------------
    input   logic                               NP_RDEN,
    input   logic  [7:0]                        NP_TAG_IDX,
    input   logic  [15:0]                       NP_DEST_IDX,
    output  logic                               NP_REQ_EXIST,

    //////////////////////////////////////////////////////////////////////////
///////////////////  FLOW CONTROL + NP REQ BUFF //////////////////////////
//////////////////////////////////////////////////////////////////////////
    output logic  [1:0]                         P_NP_CPL_OUT,
    output logic                                TLP_START_BIT_OUT_COMB,
// ---------------------------------------------------------------------------
// ----------------------------------FLOW CONTROL-----------------------------
// ---------------------------------------------------------------------------
    output logic [9:0]                          REQUIRED_CREDITS









    

);
logic    [2:0]                   TLP_MEM_IO_MSG_CPL_COMP_OUT;

              /* output */   logic    [2:0]            CPL_tlp_mem_io_msg_cpl; //type // .tlp_mem_io_msg_cpl_conf(tlp_mem_io_msg_cpl_conf);
              /* output */   logic                     CPL_tlp_address_32_64;       //fmt[0]      //.tlp_address_32_64(tlp_address_32_64);
              /* output */   logic                     CPL_tlp_read_write;          //fmt[1]      // .tlp_read_write(tlp_read_write);
//-------------------------------------------------------------------------- (4)
              /* output */   logic    [2:0]            CPL_TC;                      //.TC(TC); 
              /* output */   logic    [2:0]            CPL_ATTR;                    //.ATTR(ATTR); 
//---------------------------------------------------------------------------(6)
              /* output */   logic    [15:0]           CPL_requester_id;            //[[CPL]]  -- //COMPLETER ID //.device_id(device_id);
              /* output */   logic    [7:0]            CPL_tag;                     //[[CPL]].tag(tag);
              /* output */   logic    [11:0]           CPL_byte_count;              //.byte_count(byte_count);
//---------------------------------------------------------------------------(36)           
              // /* output */   logic    [6:0]            CPL_lower_addr;              //[[CPL]]       //.lower_addr(lower_addr);
              /* output */   logic    [31:0]            CPL_lower_addr;              //[[CPL]]       //.lower_addr(lower_addr);
                             logic    [2:0]            CPL_completion_status;

                             logic    [15:0]           CPL_dest_bdf_id;
                             logic    [9:0]            CPL_config_dw_number;
                             
//---------------------------------------------------------------------------(7)
              /* output */   logic    [31:0]           CPL_data1;                 //.data1(data1);
              /* output */   logic    [31:0]           CPL_data2;                 //.data2(data2);
              /* output */   logic    [31:0]           CPL_data3;                 //.data3(data3) ;  
//////////////////////////////////////////////////////////////////
///////////////////////////FIFO TX////////////////////////////////
//////////////////////////////////////////////////////////////////
              /* input */    logic    [31:0]           CPL_data;
              /* input */    logic                     CPL_WR_EN;

//////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////

    //////////////////////////////////////////////////////////////////////////////////////////////
   /* input */   logic                               CPL_ARB_ACK;      ////////////////////////////
   /* output */  logic                               CPL_ARB_VALID;   ////////////////////////////
    ///////////////////////////////////////////////////////////////////////////////////////////


///////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////
/* input */    logic    [2:0]                         REQ_tlp_mem_io_msg_cpl_conf;
/* input */    logic                                  REQ_tlp_address_32_64;
/* input */    logic                                  REQ_tlp_read_write;
/* input */    logic    [2:0]                         REQ_TC;
/* input */    logic    [2:0]                         REQ_ATTR;
/* input */    logic    [15:0]                        REQ_requester_id;
/* input */    logic    [7:0]                         REQ_tag;
/* input */    logic    [11:0]                        REQ_byte_count;
/* input */    logic    [31:0]                        REQ_lower_addr;
/* input */    logic    [31:0]                        REQ_upper_addr; 
/* input */    logic    [15:0]                        REQ_dest_bdf_id;



//////////////////////////////////////////////////////////////////
///////////////////////////FIFO TX////////////////////////////////
//////////////////////////////////////////////////////////////////
/* input */    logic    [31:0]                       REQ_data ;
/* input */    logic                                 REQ_WR_EN ;
//////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////
/* input */    logic    [9:0]                        REQ_config_dw_number;
/* input */    logic    [2:0]                        REQ_completion_status;
/* input */    logic    [7:0]                        REQ_message_code;
/* input */    logic                                 REQ_valid;

///////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////



logic  [2:0]        tlp_mem_io_msg_cpl_conf;
logic               tlp_address_32_64;
logic               tlp_read_write;

logic               config_type;

logic  [2:0]        TC;
logic  [2:0]        ATTR;
logic  [15:0]       device_id;
logic  [15:0]       requester_id;
logic  [7:0]        tag;
logic  [11:0]       byte_count;
logic  [31:0]       lower_addr;
logic  [31:0]       upper_addr;
logic  [15:0]       dest_bdf_id;

logic  [31:0]       data1;
logic  [31:0]       data2;
logic  [31:0]       data3;

//////////////////////////////////////////////////////////////////
///////////////////////////FIFO TX////////////////////////////////
//////////////////////////////////////////////////////////////////
logic   [31:0]          x_data2;
logic                   x_wr_en;
logic                   x_rd_en;
logic                   REQ_RD_EN;
logic                   REQ_ARB_ACK;
//////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////

logic  [9:0]        config_dw_number;

logic  [2:0]        completion_status;
logic  [7:0]        message_code;

logic               valid;


logic   [31:0]          REQ_data_out;//TL_ENCODER

    //////////////////////////////////////////////////////////////////////////
   //////////////////////////////////////////////////////////////////////////
  ///////////////////////////// COMPLETION TIMEOUT /////////////////////////
 //////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////

        /* output */ logic [7:0]                      NP_TLP_TAG;
        /* output */ logic [15:0]                     NP_TLP_REQ_ID;


wire NP_REQ_WR_EN;
assign NP_REQ_WR_EN = (P_NP_CPL_OUT == 1) && TLP_START_BIT_OUT_COMB;


TX_NP_REQ_BUFF #(.TIMEOUT(50_000),.PERIOD(10), .DATA_WIDTH(32), .MEMORY_DEPTH(16)) tx_np_req_buff
(
/* input   logic */          .clk(clk),
/* input   logic */          .rst(rst),

/* input   logic */          .WR_EN(NP_REQ_WR_EN),
/* input   logic   [7:0] */  .TAG_IN(NP_TLP_TAG),
/* input   logic   [7:0] */  .DEST_IN(NP_TLP_REQ_ID),

//SEL

// input   logic  [14:0]  START_TIME,
// input   logic          EXIST
/* input   logic */          .RD_EN(NP_RDEN),
                            .TAG_IDX(NP_TAG_IDX),
                            .DEST_IDX(NP_DEST_IDX),
/* output  logic */          .EXIST(NP_REQ_EXIST),



/* output  logic */          .EMPTY(),

/* output  logic */          .FULL(),

/* output  logic    [31:0] */ .OUT()

);




    ////////////////////////////////////////////////////////////////////////
   ////////////////////////////////////////////////////////////////////////
  ////////////////////////////// AXI /////////////////////////////////////
 ////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////

TX_AXI_SLAVE #(.DATA_WIDTH(DATA_WIDTH), .ADDR_WIDTH(ADDR_WIDTH)) tx_axi_slave
(
     // Global Signals 
    .aclk(clk),
    .aresetn(rst),

    // AW Channel
    /* input   logic [ADDR_WIDTH-1:0] */           .awaddr(awaddr),  
    /* input   logic [7:0]   */                    .awlen(awlen),   // number of transfers in transaction
    /* input   logic [2:0]   */                    .awsize(awsize),  // number of bytes in transfer // 000=> 1, 001=>2, 010=>4, 011=>8, 100=>16, 101=>32, 110=>64, 111=>128
    /* input   logic [1:0]   */                    .awburst(awburst),  
    /* output  logic */                            .awready(awready), 
    /* input   logic */                            .awvalid(awvalid), 

    // W Channel
    /* input   logic [DATA_WIDTH-1:0]     */       .wdata(wdata), 
    /* input   logic [(DATA_WIDTH/8)-1:0] */       .wstrb(wstrb), 
    /* input   logic                      */       .wlast(wlast), 
    /* input   logic                      */       .wvalid(wvalid),
    /* output  logic                      */       .wready(wready),

    // B Channel
    /* output  logic [1:0] */                      .bresp(bresp),                         
    /* output  logic       */                      .bvalid(bvalid),                         
    /* input   logic       */                      .bready(bready),                         

    // AR Channel
    /* input   logic [ADDR_WIDTH-1:0] */           .araddr (araddr),
    /* input   logic [7:0]            */           .arlen  (arlen),
    /* input   logic [2:0]            */           .arsize (arsize),
    /* input   logic [1:0]            */           .arburst(arburst),
    /* output  logic                  */           .arready(arready),
    /* input   logic                  */           .arvalid(arvalid),
                                            

    // R Channel                            
    /* output  logic [DATA_WIDTH-1:0] */           .rdata(rdata),
    /* output  logic [1:0]            */           .rresp(rresp),
    /* output  logic                  */           .rlast(rlast),
    /* output  logic                  */           .rvalid(rvalid),
    /* input   logic                  */           .rready(rready),

    /* output  logic  [2:0] */                     .o_tlp_mem_io_msg_cpl_conf(REQ_tlp_mem_io_msg_cpl_conf),
    /* output  logic        */                     .o_tlp_address_32_64(REQ_tlp_address_32_64),
    /* output  logic        */                     .o_tlp_read_write(REQ_tlp_read_write),
    /* output  logic        */                     .o_config_type(REQ_config_type),//type 1, type 2 
    /* output  logic  [11:0] */                    .o_byte_count(REQ_byte_count),
    /* output  logic  [31:0] */                    .o_lower_addr(REQ_lower_addr),
    /* output  logic  [31:0] */                    .o_upper_addr(REQ_upper_addr),
    /* output  logic  [15:0] */                    .o_dest_bdf_id(REQ_dest_bdf_id),
    /* output  logic  [9:0]  */                    .o_config_dw_number(REQ_config_dw_number),
    /* output  logic  [2:0]  */                    .o_completion_status(REQ_completion_status),
    /* output  logic  [7:0]  */                    .o_message_code(REQ_message_code),
    /* output  logic         */                    .o_valid(REQ_valid),
    /* output  logic  [31:0] */                    .REQ_data_out(REQ_data_out),
    /* input  logic */                             .REQ_RD_EN(REQ_RD_EN),
                                                   .i_finished(REQ_ARB_ACK)


);



/////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////

wire [31:0] dumb_signal;
DOUBLE_IN_CPL_ARB #(.DATA_WIDTH(128)) double_in_cpl_arb
(
    .clk(clk),
    .rst(rst),

    //    I'll use this block to generate CPL/ CPLD 
    //      .    .    .    .                        
    //    //.\\//.\\//.\\//.\\ CPL FROM ERROR BLOCK     
    
    //-------------------------------------------------------------------------- (4)
    /* input   logic    [2:0]           */.ERR_CPL_TC(ERR_CPL_TC),                      //.TC(TC)(),
    /* input   logic    [2:0]           */.ERR_CPL_ATTR(ERR_CPL_ATTR),                    //.ATTR(ATTR)(),
    //---------------------------------------------------------------------------(6)
    /* input   logic    [15:0]          */.ERR_CPL_requester_id(ERR_CPL_requester_id),            //[[X]]  -- //COMPLETER ID 
    /* input   logic    [7:0]           */.ERR_CPL_tag(ERR_CPL_tag),                     //[[X]].
    /* input   logic    [11:0]          */.ERR_CPL_byte_count(ERR_CPL_byte_count),              //
    //---------------------------------------------------------------------------(36)           
    /* input   logic    [6:0]           */.ERR_CPL_lower_addr(ERR_CPL_lower_addr),              //[[X]]
    //---------------------------------------------------------------------------(7)    
                                          .ERR_CPL_completion_status(ERR_CPL_completion_status),
    //---------------------------------------------------------------------------(96)
    /* input   logic                    */.ERR_CPL_Wr_En(ERR_CPL_Wr_En),                 //.valid(valid)(),
    //---------------------------------------------------------------------------(1)




    //      .    .    .    .                        
    //    //.\\//.\\//.\\//.\\ CPLD FROM RX BRIDGE  
    /* input   logic                    */.RX_B_tlp_read_write(RX_B_tlp_read_write),          //
    /* input   logic    [2:0]           */.RX_B_TC(RX_B_TC),               //
    /* input   logic    [2:0]           */.RX_B_ATTR(RX_B_ATTR),             //
    /* input   logic    [15:0]          */.RX_B_requester_id(RX_B_requester_id),        //
    /* input   logic    [7:0]           */.RX_B_tag(RX_B_tag),              //
    /* input   logic    [11:0]          */.RX_B_byte_count(RX_B_byte_count),       //
//--------------------------------------------------------------------------------------
    /* input   logic    [6:0]           */ .RX_B_lower_addr(RX_B_lower_addr),       //
                                           .RX_B_completion_status(RX_B_completion_status),
//-----------------------------------------------------------------------------------------           
    // /* input   logic    [31:0]          */.RX_B_data1(RX_B_data1),                 //
    // /* input   logic    [31:0]          */.RX_B_data2(RX_B_data2),                 //
    // /* input   logic    [31:0]          */.RX_B_data3(RX_B_data3),                 //
                                           .RX_B_data({32'h0, RX_B_data3, RX_B_data2, RX_B_data1}),
//-----------------------------------------------------------------------------------------                   
    /* input   logic                    */ .RX_B_Wr_En(RX_B_Wr_En),                  //
//-----------------------------------------------------------------------------------------

     //////////////////////////////////////////////////////////////
    //////////////////////////TX_FIFO/////////////////////////////
    /* input   logic    [DATA_WIDTH2-1:0] */    .RX_B_TX_DATA_FIFO_data(RX_B_TX_DATA_FIFO_data),
    /* input   logic */                         .RX_B_TX_DATA_FIFO_WR_EN(RX_B_TX_DATA_FIFO_WR_EN),
  //////////////////////////////////////////////////////////////

    /* output   logic    [1:0]           */.X_tlp_mem_io_msg_cpl(CPL_tlp_mem_io_msg_cpl), //type // .tlp_mem_io_msg_cpl_conf(tlp_mem_io_msg_cpl_conf)(),
    /* output   logic                    */.X_tlp_address_32_64(CPL_tlp_address_32_64),       //fmt[0]      //.tlp_address_32_64(tlp_address_32_64)(),
    /* output   logic                    */.X_tlp_read_write(CPL_tlp_read_write),          //fmt[1]      // .tlp_read_write(tlp_read_write)(),
//-------------------------------------------------------------------------- (4)
    /* output   logic    [2:0]           */.X_TC(CPL_TC),                      //.TC(TC)(), 
    /* output   logic    [2:0]           */.X_ATTR(CPL_ATTR),                    //.ATTR(ATTR)(), 
//---------------------------------------------------------------------------(6)
    /* output   logic    [15:0]          */.X_requester_id(CPL_requester_id),            //[[X]]  -- //COMPLETER ID //.device_id(device_id)(),
    /* output   logic    [7:0]           */.X_tag(CPL_tag),                     //[[X]].tag(tag)(),
    /* output   logic    [11:0]          */.X_byte_count(CPL_byte_count),              //.byte_count(byte_count)(),
//---------------------------------------------------------------------------(36)           
    /* output   logic    [6:0]           */.X_lower_addr(CPL_lower_addr),              //[[X]]       //.lower_addr(lower_addr)(),
                                           .X_completion_status(CPL_completion_status),
//---------------------------------------------------------------------------(7)
    // /* output   logic    [31:0]          */.X_data1(CPL_data1),                 //.data1(data1)(),
    // /* output   logic    [31:0]          */.X_data2(CPL_data2),                 //.data2(data2)(),
    // /* output   logic    [31:0]          */.X_data3(CPL_data3),                 //.data3(data3),  
                                           .X_data({dumb_signal, CPL_data3, CPL_data2, CPL_data1}),
    /////////////////////////////////////////////////////////////////////////////////////////////
/* output  logic                         */.VALID(CPL_ARB_VALID),   ////////////////////////////
    //////////////////////////////////////////////////////////////////////////////////////////

     /////////////////////////////////////////////////////////////////////////////////////////////////
    ///////////////////////////////////////////////TX_FIFO///////////////////////////////////////////
   /* input   logic */                        .X_ACK(CPL_ARB_ACK),    
   /* input   logic */                        .X_TX_FIFO_RD_EN(CPL_RD_EN),
   /* output  logic   [DATA_WIDTH2-1:0] */    .X_data2(CPL_data) 
     
  ///////////////////////////////////////////////////////////////////////////////////////////
   

);



TX_TRIPLE_IN_ARB #(.DATA_WIDTH(128)) tx_triple_in_arb
(
/* input   logic    [2:0]               */.cpl_tlp_mem_io_msg_cpl_conf(CPL_tlp_mem_io_msg_cpl),
/* input   logic                        */.cpl_tlp_address_32_64(CPL_tlp_address_32_64),
/* input   logic                        */.cpl_tlp_read_write(CPL_tlp_read_write),
/* input   logic    [2:0]               */.cpl_TC(CPL_TC),
/* input   logic    [2:0]               */.cpl_ATTR(CPL_ATTR),
/* input   logic    [15:0]              */.cpl_requester_id(CPL_requester_id),
/* input   logic    [7:0]               */.cpl_tag(CPL_tag),
/* input   logic    [11:0]              */.cpl_byte_count(CPL_byte_count),
/* input   logic    [31:0]              */.cpl_lower_addr(CPL_lower_addr),
// /* input   logic    [31:0]              */.cpl_upper_addr(cpl_upper_addr),
/* input   logic    [15:0]              */.cpl_dest_bdf_id(CPL_dest_bdf_id),

// input   logic    [31:0]         cpl_data1(),
// input   logic    [31:0]         cpl_data2(),
// input   logic    [31:0]         cpl_data3(),

/* input   logic   [DATA_WIDTH-1:0]     */.cpl_data({32'h0, CPL_data3, CPL_data2, CPL_data1}),
  /////////////////////////////////////////////////////
 ////////////////////FIFO TX/////////////////////////
/////////////////////////////////////////////////////
/* input   logic    [DATA_WIDTH2-1:0]    */.cpl_data2(CPL_data),
// /* input   logic                         */.cpl_wr_en(CPL_WR_EN),
/* output  logic                        */ .cpl_rd_en(CPL_RD_EN),
//                                          .data_out_valid
/////////////////////////////////////////////////////
/////////////////////////////////////////////////////
/* input   logic    [9:0]               */.cpl_config_dw_number(cpl_config_dw_number),

/* input   logic    [2:0]               */.cpl_completion_status(CPL_completion_status),
/* input   logic    [7:0]               */.cpl_message_code(),
/* input   logic                        */.cpl_valid(CPL_ARB_VALID),
/* output  logic                        */.CPL_ARB_ACK(CPL_ARB_ACK),
//-------------------------------------------------------------


//MSG_INTF
/* input   logic    [2:0]               */.msg_tlp_mem_io_msg_cpl_conf(MSG_tlp_mem_io_msg_cpl),
/* input   logic                        */.msg_tlp_address_32_64(MSG_tlp_address_32_64),
/* input   logic                        */.msg_tlp_read_write(msg_tlp_read_write),
/* input   logic    [2:0]               */.msg_TC(msg_TC),
/* input   logic    [2:0]               */.msg_ATTR(msg_ATTR),
/* input   logic    [15:0]              */.msg_requester_id(msg_requester_id),
/* input   logic    [7:0]               */.msg_tag(msg_tag),
/* input   logic    [11:0]              */.msg_byte_count(msg_byte_count),
/* input   logic    [31:0]              */.msg_lower_addr(msg_lower_addr),
/* input   logic    [31:0]              */.msg_upper_addr(msg_upper_addr),
/* input   logic    [15:0]              */.msg_dest_bdf_id(msg_dest_bdf_id),

// input   logic    [31:0]          msg_data1(),
// input   logic    [31:0]          msg_data2(),
// input   logic    [31:0]          msg_data3(),

/* input   logic   [DATA_WIDTH-1:0]     */.msg_data({msg_data3, msg_data2, msg_data1}),

/* input   logic    [9:0]               */.msg_config_dw_number(),

/* input   logic    [2:0]               */.msg_completion_status(),
/* input   logic    [7:0]               */.msg_message_code(msg_message_code),
/* input   logic                        */.msg_valid(MSG_ARB_VALID),
/* output  logic                        */.MSG_ARB_ACK(MSG_ARB_ACK),
//-------------------------------------------------------------


//REQ_INTF
/* input   logic    [2:0]               */.req_tlp_mem_io_msg_cpl_conf(REQ_tlp_mem_io_msg_cpl_conf),
/* input   logic                        */.req_tlp_address_32_64(REQ_tlp_address_32_64),
/* input   logic                        */.req_tlp_read_write(REQ_tlp_read_write),
/* input   logic    [2:0]               */.req_TC(REQ_TC),
/* input   logic    [2:0]               */.req_ATTR(REQ_ATTR),
/* input   logic    [15:0]              */.req_requester_id(REQ_requester_id),
/* input   logic    [7:0]               */.req_tag(REQ_tag),
/* input   logic    [11:0]              */.req_byte_count(REQ_byte_count),
/* input   logic    [31:0]              */.req_lower_addr(REQ_lower_addr),
/* input   logic    [31:0]              */.req_upper_addr(REQ_upper_addr),
/* input   logic    [15:0]              */.req_dest_bdf_id(REQ_dest_bdf_id),

// input   logic    [31:0]             req_data1(),
// input   logic    [31:0]             req_data2(),
// input   logic    [31:0]             req_data3(),
/* input   logic   [DATA_WIDTH-1:0]     */.req_data({32'h0, REQ_data3, REQ_data2, REQ_data1}),
  /////////////////////////////////////////////////////
 ////////////////////FIFO TX/////////////////////////
/////////////////////////////////////////////////////
/* input   logic    [DATA_WIDTH2-1:0]    */.req_data2(REQ_data_out),
/* input   logic                         */.req_wr_en(req_wr_en),
/* output    logic */                      .req_rd_en(REQ_RD_EN),
//                                          .data_out_valid
/////////////////////////////////////////////////////
/////////////////////////////////////////////////////
/* input   logic    [9:0]               */.req_config_dw_number(config_dw_number),

// /* input   logic    [2:0]               */.req_completion_status(),
// /* input   logic    [7:0]               */.req_message_code(),
/* input   logic                        */.req_valid(REQ_valid),
/* output  logic                        */.REQ_ARB_ACK(REQ_ARB_ACK),
//-------------------------------------------------------------
//-------------------------------------------------------------

/* output   logic    [2:0]              */.x_tlp_mem_io_msg_cpl_conf(tlp_mem_io_msg_cpl_conf),
/* output   logic                       */.x_tlp_address_32_64(tlp_address_32_64),
/* output   logic                       */.x_tlp_read_write(tlp_read_write),
/* output   logic    [2:0]              */.x_TC(TC),
/* output   logic    [2:0]              */.x_ATTR(ATTR),
/* output   logic    [15:0]             */.x_requester_id(requester_id),
/* output   logic    [7:0]              */.x_tag(tag),
/* output   logic    [11:0]             */.x_byte_count(byte_count),
/* output   logic    [31:0]             */.x_lower_addr(lower_addr),
/* output   logic    [31:0]             */.x_upper_addr(upper_addr),
/* output   logic    [15:0]             */.x_dest_bdf_id(dest_bdf_id),

// output   logic    [31:0]         x_data1(),
// output   logic    [31:0]         x_data2(),
// output   logic    [31:0]         x_data3(),
/* output   logic   [DATA_WIDTH-1:0]    */.x_data({dumb_signal2 ,data3, data2, data1}),

  /////////////////////////////////////////////////////
 ////////////////////FIFO TX/////////////////////////
/////////////////////////////////////////////////////
/* output   logic    [DATA_WIDTH2-1:0]   */.x_data2(x_data2),
/* output   logic                        */.x_wr_en(x_wr_en),
/* input    logic                        */.x_rd_en(x_rd_en),
///* input    logic                        */.x_finish(x_rd_en),

/////////////////////////////////////////////////////
/////////////////////////////////////////////////////

/* output   logic    [9:0]              */.x_config_dw_number(config_dw_number),

/* output   logic    [2:0]              */.x_completion_status(completion_status),
/* output   logic    [7:0]              */.x_message_code(message_code),
/* output   logic                       */.x_valid(valid),
/* input    logic                       */.X_ARB_ACK(TL_TX_ACK)


);

wire [9:0] DATA_REQUIRED_CREDIT_OUT;
assign REQUIRED_CREDITS = DATA_REQUIRED_CREDIT_OUT + 1/*Header*/;
wire TLP_START_BIT_OUT;
assign TLP_START_BIT_OUT_COMB = TLP_START_BIT_OUT && !ALL_BUFFS_EMPTY;
TL_TX_MAL #(.BUS_WIDTH(BUS_WIDTH), .DEPTH(DEPTH)) TL_TX0 
(           .clk(clk),                                  //input   logic                    clk, 
            .rst(rst),                                  //input   logic                    rst,
            .DPI_MM(DPI_MM),                            //input   logic                    DPI_MM,

            .port_write_en(port_write_en),                        //input   logic    [9:0]           port_write_en,
            .tlp_mem_io_msg_cpl_conf(tlp_mem_io_msg_cpl_conf),    //input   logic    [1:0]           tlp_mem_io_msg_cpl_conf,
            .tlp_address_32_64(tlp_address_32_64),                //input   logic                    tlp_address_32_64,
            .tlp_read_write(tlp_read_write),                      //input   logic                    tlp_read_write,

            .config_type(config_type),

            .TC(TC),                                    //input   logic    [2:0]          TC,
            .ATTR(ATTR),                                //input   logic    [2:0]          ATTR,
            .requester_id(requester_id),                    //input   logic    [15:0]         device_id,
            .tag(tag),                                  //input   logic    [7:0]          tag,
            .byte_count(byte_count),                    //input   logic    [11:0]         byte_count,
            .lower_addr(lower_addr),                    //input   logic    [31:0]         lower_addr,
            .upper_addr(upper_addr),                                               //input   logic    [31:0]         upper_addr,
            .config_dw_number(config_dw_number),        //input   logic    [9:0]          config_dw_number,


            .data1(data1),                                //input   logic    [31:0]         data1,
            .data2(data2),                                //input   logic    [31:0]         data2,
            .data3(data3),                                //input   logic    [31:0]         data3,

            .dest_bdf_id(dest_bdf_id),                  //input   logic    [15:0]         dest_bdf_id,
            
            .completion_status(completion_status),
            .message_code(message_code),
            
            .valid(valid),                              //input   logic                   valid,


            .RD_EN(RD_EN),                              //input   logic                   RD_EN,
            .ALL_BUFFS_EMPTY(ALL_BUFFS_EMPTY),          //output  logic                   EMPTY,
            .VALID_FOR_DL(VALID_FOR_DL),                //output  logic                   VALID,
            .OUT_TLP_DW(OUT_TLP_DW),                     //output  logic    [31:0]         OUT_TLP_DW    );

            .TLP_START_BIT_OUT_COMB(TLP_START_BIT_OUT), //output
            .TLP_END_BIT_OUT_COMB(TLP_END_BIT_OUT_COMB), //output

            // .CPL_ARB_ACK(CPL_ARB_ACK),

            ////////////////////////////////////////////////////////////
            /////////////////////////FIFO TX//////////////////////////
            //////////////////////////////////////////////////////////
            /* input   logic    [31:0]*/    .tx_fifo_data_in(x_data2),//from arbiter to encoder
            /* output   logic          */   .tx_fifo_rd_en(x_rd_en),//from encoder to arbiter
            ///////////////////////////////////////////////////////////
            /////////////////////////////////////////////////////////
            /////////////////////////////////////////////////////////

            .fsm_finished(fsm_finished),
            .fsm_started(fsm_started),
            .ACK(TL_TX_ACK),

//---------------------------------------------------------------------------------------------
//---------------------------------------------------------------------------------------------
//---------------------------------------------------------------------------------------------
            .NP_TLP_TAG(NP_TLP_TAG),
            .NP_TLP_REQ_ID(NP_TLP_REQ_ID),//,

            // .TLP_MEM_IO_MSG_CPL_COMP_OUT(TLP_MEM_IO_MSG_CPL_COMP_OUT)

//---------------------------------------------------------------------------------------------
//---------------------------------------------------------------------------------------------
            .P_NP_CPL_OUT(P_NP_CPL_OUT),
            .DATA_REQUIRED_CREDIT_OUT(DATA_REQUIRED_CREDIT_OUT) /* output logic [9:0] */
            // .fsm_finished_pulse(),
);
endmodule