module TRANSACTION_TOP#(parameter ADDR_WIDTH = 16, DATA_WIDTH = 16, BUS_WIDTH = 128, DEPTH = 3)(
    input  logic                            clk,
    input  logic                            rst,
//RX
    input                               new_tlp_ready,
    input                               valid_tlp,
    input    [10-1:0]                   IN_TLP_DW,


    input                                   RD_EN,
//    output                                  VALID_FOR_DL,
    output    [3:0]                        OUT_TLP_DW
//    output                                 TLP_START_BIT_OUT_COMB
//    output  logic                            fsm_started,
//    output  logic                            fsm_finished,



//    output  logic [ADDR_WIDTH-1:0]           RX_awaddr,
//    output  logic [7:0]                      RX_awlen,   // number of transfers in transaction
//    output  logic [2:0]                      RX_awsize,  // number of bytes in transfer  //                            000=> 1, 001=>2, 010=>4, 011=>8, 100=>16, 101=>32, 110=>64, 111=>128
//    output  logic [1:0]                      RX_awburst,
//    input   logic                            RX_awready,
//    output  logic                            RX_awvalid,
//    output  logic [DATA_WIDTH-1:0]           RX_wdata, 
//    output  logic [(DATA_WIDTH/8)-1:0]       RX_wstrb, 
//    output  logic                            RX_wlast, 
//    output  logic                            RX_wvalid,
//    input   logic                            RX_wready,
//    input   logic [1:0]                      RX_bresp,                         
//    input   logic                            RX_bvalid,                         
//    output  logic                            RX_bready,                         
//    output  logic [ADDR_WIDTH-1:0]           RX_araddr,
//    output  logic [7:0]                      RX_arlen,
//    output  logic [2:0]                      RX_arsize,
//    output  logic [1:0]                      RX_arburst,
//    input   logic                            RX_arready,
//    output  logic                            RX_arvalid,                         
//    input   logic [DATA_WIDTH-1:0]           RX_rdata,
//    input   logic [1:0]                      RX_rresp,
//    input   logic                            RX_rlast,
//    input   logic                            RX_rvalid,
//    output  logic                            RX_rready,





//    // AW Channel
//    input   logic [ADDR_WIDTH-1:0]           TX_awaddr,  
//    input   logic [7:0]                      TX_awlen,   // number of transfers in transaction
//    input   logic [2:0]                      TX_awsize,  // number of bytes in transfer // 000=> 1, 001=>2, 010=>4, 011=>8, 100=>16, 101=>32, 110=>64, 111=>128
//    input   logic [1:0]                      TX_awburst,  
//    output  logic                            TX_awready, 
//    input   logic                            TX_awvalid, 
//    input   logic [DATA_WIDTH-1:0]           TX_wdata, 
//    input   logic [(DATA_WIDTH/8)-1:0]       TX_wstrb, 
//    input   logic                            TX_wlast, 
//    input   logic                            TX_wvalid,
//    output  logic                            TX_wready,
//    output  logic [1:0]                      TX_bresp,                         
//    output  logic                            TX_bvalid,                         
//    input   logic                            TX_bready,                         
//    input   logic [ADDR_WIDTH-1:0]           TX_araddr,
//    input   logic [7:0]                      TX_arlen,
//    input   logic [2:0]                      TX_arsize,
//    input   logic [1:0]                      TX_arburst,
//    output  logic                            TX_arready,
//    input   logic                            TX_arvalid,
//    output  logic [DATA_WIDTH-1:0]           TX_rdata,
//    output  logic [1:0]                      TX_rresp,
//    output  logic                            TX_rlast,
//    output  logic                            TX_rvalid,
//    input   logic                            TX_rready
);


wire new_tlp_ready = 1'b0;  // or 1'b1 as appropriate
wire valid_tlp = 1'b0;
wire [9:0] IN_TLP_DW  = 0;
wire RD_EN = 0;
 assign VALID_FOR_DL=0;  // Or another safe constant value
 assign OUT_TLP_DW = 0;
 assign TLP_START_BIT_OUT_COMB = 0;

// ---------------------------------------------------------------------------
// -----------------------------CPL TIMEOUT----------------------------------
// ---------------------------------------------------------------------------
    /* input  */   logic                            NP_RDEN     ;
    /* input  */   logic  [7:0]                     NP_TAG_IDX  ;
    /* input  */   logic  [15:0]                    NP_DEST_IDX ;
    /* output */   logic                            NP_REQ_EXIST;   


//-------------------------------------------------------------------------- (4)
              /* input */   logic    [2:0]            ERR_CPL_TC;                      //.TC(TC);
              /* input */   logic    [2:0]            ERR_CPL_ATTR;                    //.ATTR(ATTR);
//---------------------------------------------------------------------------(6)
              /* input */   logic    [15:0]           ERR_CPL_requester_id;            //[[X]]  -- //COMPLETER ID 
              /* input */   logic    [7:0]            ERR_CPL_tag;                     //[[X]].
              /* input */   logic    [11:0]           ERR_CPL_byte_count;              //

//---------------------------------------------------------------------------(36)           
              /* input */   logic    [6:0]            ERR_CPL_lower_addr;              //[[X]]
                            logic    [2:0]            ERR_CPL_completion_status;
//---------------------------------------------------------------------------(7)  
//---------------------------------------------------------------------------(96)
             /* input */    logic                     ERR_CPL_Wr_En;                 //.valid(valid);
//---------------------------------------------------------------------------(1)

    //    //.\\//.\\//.\\//.\\ CPLD FROM RX BRIDGE  
              /* input */   logic                     RX_B_tlp_read_write;          //
              /* input */   logic    [2:0]            RX_B_TC;               //
              /* input */   logic    [2:0]            RX_B_ATTR;             //
              /* input */   logic    [15:0]           RX_B_requester_id;        //
              /* input */   logic    [7:0]            RX_B_tag;              //
              /* input */   logic    [11:0]           RX_B_byte_count;       //

//--------------------------------------------------------------------------------------
              /* input */   logic    [6:0]            RX_B_lower_addr;       //
                            logic    [2:0]            RX_B_completion_status;
//----------------------------------------------------------------------------------------- 
//-----------------------------------------------------------------------------------------          
              /* input */   logic    [31:0]           RX_B_data1;                 //
              /* input */   logic    [31:0]           RX_B_data2;                 //
              /* input */   logic    [31:0]           RX_B_data3;                 //
//-----------------------------------------------------------------------------------------                   
              /* input */   logic                     RX_B_Wr_En;                  //

     //////////////////////////////////////////////////////////////
    //////////////////////////TX_FIFO/////////////////////////////
           /* input */   logic    [31:0]               RX_B_TX_DATA_FIFO_data;
           /* input */   logic                         RX_B_TX_DATA_FIFO_WR_EN;
  //////////////////////////////////////////////////////////////
   


//-----------------------------------------------------------------------------------------


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
              /* output */   logic    [6:0]            CPL_lower_addr;              //[[CPL]]       //.lower_addr(lower_addr);
                             logic    [2:0]            CPL_completion_status;
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
   /* input */   logic                             CPL_ARB_ACK;      ////////////////////////////
   /* output */  logic                             CPL_ARB_VALID;   ////////////////////////////
    ///////////////////////////////////////////////////////////////////////////////////////////




TRANSACTION_RX_TOP #(.DATA_WIDTH(DATA_WIDTH), .ADDR_WIDTH(ADDR_WIDTH), .BUS_WIDTH(128), .DEPTH(DEPTH) ) tl_rx_top(

// DL-TL Interface
/* input   logic */                             .clk(clk),
/* input   logic */                             .rst(rst),
////////////////////////////////////////////////.//////////////
// DATA LINK INTERFACE                          .
////////////////////////////////////////////////.//////////////
/* input   logic [31:0] */                .IN_TLP_DW    (IN_TLP_DW),
/* input   logic        */                .new_tlp_ready(new_tlp_ready),
/* input   logic        */                .valid_tlp    (valid_tlp),
//AXI Interface
/* output  logic [ADDR_WIDTH-1:0] */            .awaddr  (RX_awaddr),
/* output  logic [7:0]            */            .awlen   (RX_awlen),   // number of transfers in transaction
/* output  logic [2:0]            */            .awsize  (RX_awsize),  // number of bytes in transfer  //                            000=> 1(), 001=>2, 010=>4, 011=>8, 100=>16, 101=>32, 110=>64, 111=>128
/* output  logic [1:0]            */            .awburst (RX_awburst),
/* input   logic                  */            .awready (RX_awready),
/* output  logic                  */            .awvalid (RX_awvalid),
/* output logic [DATA_WIDTH-1:0]     */         .wdata   (RX_wdata), 
/* output logic [(DATA_WIDTH/8)-1:0] */         .wstrb   (RX_wstrb), 
/* output logic                      */         .wlast   (RX_wlast), 
/* output logic                      */         .wvalid  (RX_wvalid),
/* input  logic                      */         .wready  (RX_wready),
/* input  logic [1:0] */                        .bresp   (RX_bresp),                         
/* input  logic */                              .bvalid  (RX_bvalid),                         
/* output logic */                              .bready  (RX_bready),                         
/* output logic [ADDR_WIDTH-1:0] */             .araddr  (RX_araddr),
/* output logic [7:0] */                        .arlen   (RX_arlen),
/* output logic [2:0] */                        .arsize  (RX_arsize),
/* output logic [1:0] */                        .arburst (RX_arburst),
/* input  logic */                              .arready (RX_arready),
/* output */                                    .arvalid (RX_arvalid),                          
/* input   logic [DATA_WIDTH-1:0] */            .rdata   (RX_rdata),
/* input   logic [1:0] */                       .rresp   (RX_rresp),
/* input   logic */                             .rlast   (RX_rlast),
/* input   logic */                             .rvalid  (RX_rvalid),
/* output  logic */                             .rready  (RX_rready),
/* output  logic */              .RX_B_tlp_read_write    (RX_B_tlp_read_write),          //
/* output  logic    [2:0]  */    .RX_B_TC                (RX_B_TC            ),               //
/* output  logic    [2:0]  */    .RX_B_ATTR              (RX_B_ATTR          ),             //
/* output  logic    [15:0] */    .RX_B_requester_id      (RX_B_requester_id  ),        //
/* output  logic    [7:0]  */    .RX_B_tag               (RX_B_tag           ),              //
/* output  logic    [11:0] */    .RX_B_byte_count        (RX_B_byte_count    ),       //
//-----------------------------  ------------------------- ----------
/* output  logic    [6:0] */     .RX_B_lower_addr        (RX_B_lower_addr),       //
/* output  logic    [2:0] */     .RX_B_completion_status (RX_B_completion_status),
//----------------------------------------------------------------------------------------- 
//-----------------------------------------------------------------------------------------          
/* output  logic    [31:0] */                   .RX_B_data1(),                 //
/* output  logic    [31:0] */                   .RX_B_data2(),                 //
/* output  logic    [31:0] */                   .RX_B_data3(),                 //
//-------------------------------------------------------------------------------                   
/* output  logic */                             .RX_B_Wr_En(RX_B_Wr_En),                  //
//-----------------------------------------------------------------------------------------
//Internal Native Interface (FROM ERROR DETECTION TO TL_TX)
//-------------------------------------------------------------------------- (4)
/* output   logic    [2:0] */                   .ERR_CPL_TC  (),                      //.TC(TC);
/* output   logic    [2:0] */                   .ERR_CPL_ATTR(),                     //.ATTR(ATTR);
//-----------------------------------------------------------------(6)
/* output   logic    [15:0] */                  .ERR_CPL_requester_id(),            //[[X]]  -- //COMPLETER ID 
/* output   logic    [7:0]  */                  .ERR_CPL_tag(),                    //[[X]].
/* output   logic    [11:0] */                  .ERR_CPL_byte_count(),              //
//-----------------------------------------------------------------(36)           
/* output   logic    [6:0] */                   .ERR_CPL_lower_addr(),              //[[X]]
/* output   logic    [2:0] */                   .ERR_CPL_completion_status(),
//-----------------------------------------------------------------(7)  
//-----------------------------------------------------------------(6)
/* output    logic */                           .ERR_CPL_Wr_En(),                 //.valid(valid);
//--------------------------------------------------------------------
/* input    logic    [2:0] */                   .MSG_tlp_mem_io_msg_cpl(), //type // tlp_mem_io_msg_cpl_conf(tlp_mem_io_msg_cpl_conf)(),
/* input    logic */                            .MSG_tlp_address_32_64(),       //fmt[0]      //tlp_address_32_64(tlp_address_32_64)(),
/* input    logic */                            .MSG_tlp_read_write(),          //fmt[1]      // tlp_read_write(tlp_read_write)(),
//--------------------------------------------------------------------- (4)
/* input    logic    [2:0] */                   .MSG_TC(),                      //TC(TC)(), 
/* input    logic    [2:0] */                   .MSG_ATTR(),                    //ATTR(ATTR)(), 
//----------------------------------------------------------------(6)
/* input    logic    [15:0] */                  .MSG_requester_id(),            //[[MSG]]  -- //COMPLETER ID //device_id(device_id)(),
/* input    logic    [7:0]  */                  .MSG_tag(),                     //[[MSG]]tag(tag)(),
/* input    logic    [11:0] */                  .MSG_byte_count(),              //byte_count(byte_count)(),
//----------------------------------------------------------------(36)           
/* input    logic    [6:0] */                   .MSG_lower_addr(),              //[[MSG]]       //lower_addr(lower_addr)(),
/* input    logic    [2:0] */                   .MSG_completion_status(),
//----------------------------------------------.------------------(7)
/* input    logic    [31:0] */                  .MSG_data1(),                 //data1(data1)(),
/* input    logic    [31:0] */                  .MSG_data2(),                 //data2(data2)(),
/* input    logic    [31:0] */                  .MSG_data3(),                 //data3(data3) (),  
////////////////////////////////////////////////////////////////////////////////////////
/* input    logic */                            .MSG_ARB_VALID(),           ////////////////////////////////
/* output   logic */                            .MSG_ARB_ACK(),            ////////////////////////////////
////////////////////////////////////////////////.//////////////////////////////////////////
//----------------------------------------------.----------------------------(1)
/* output    logic */                           .RX_B_TX_DATA_FIFO_WR_EN(RX_B_TX_DATA_FIFO_WR_EN),
/* output    logic [31:0] */                    .RX_B_TX_DATA_FIFO_data (RX_B_TX_DATA_FIFO_data),
//---------------------------------------------------------------------------(1)
//---------------------------------------------------------------------------(1)
/* output    logic       */                     .NP_RDEN        (NP_RDEN),
/* output    logic [7:0] */                     .NP_TAG_IDX     (NP_TAG_IDX),
/* output    logic [15:0]*/                     .NP_DEST_IDX    (NP_DEST_IDX),
/* input     logic */                           .NP_REQ_EXIST   (NP_REQ_EXIST)
);

TRANSACTION_TX_TOP #(.DATA_WIDTH(DATA_WIDTH), .ADDR_WIDTH(ADDR_WIDTH), .BUS_WIDTH(128), .DEPTH(DEPTH) )  tl_tx_top (
/* inpinut  logic */                        .clk(clk),
/* inpinut  logic */                        .rst(rst),
                               
//DATA LINK INTERFACE          
/* input  logic */                          .RD_EN                  (RD_EN),
/* output logic */                          .VALID_FOR_DL           (VALID_FOR_DL),
/* output logic */                          .ALL_BUFFS_EMPTY        (ALL_BUFFS_EMPTY),
/* output logic */   /* [31:0] */           .OUT_TLP_DW             (OUT_TLP_DW),
                                            .fsm_started            (fsm_started),
/* output logic */                          .fsm_finished           (fsm_finished),
/* output logic */                          .TL_TX_ACK              (TL_TX_ACK),
                                            .TLP_START_BIT_OUT_COMB (TLP_START_BIT_OUT_COMB),


//FROM RX ERROR DETECTION TO TX MASTER

//\\\\\\\\\\\\\\\\\\\\\\\\\\\--------|--------//////////////////////////////\\
 //\\\\\\\\\\\\\\\\\\\\\\\\\\\    |= | =|    //////////////////////////////\\
  //\\\\\\\\\\\\\\\\\\\\\\\\\\\    |=|=|    //////////////////////////////\\
   //\\\\\\\\\\\\\\\\\\\\\\\\\\\    |||    //////////////////////////////\\
    //\\\\\\\\\\\\\\\\\\\\\\\\\\\   \|/   //////////////////////////////\\
     //\\\\\\\\\\\\\\\\\\\\\\\\\\\   |   //////////////////////////////\\
      //\\\\\\\\\\\\\\\\\\\\\\\\\\\  |  //////////////////////////////\\
       //\\\\\\\\\\\\\\\\\\\\\\\\\\\ | //////////////////////////////\\
        //\\\\\\\\\\\\\\\\\\\\\\\\\\\|//////////////////////////////\\

//FROM RX MASTER to TX MASTER




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
              /* input   logic    [2:0] */            .ERR_CPL_TC               (ERR_CPL_TC),                      //.TC(TC);
              /* input   logic    [2:0] */            .ERR_CPL_ATTR             (ERR_CPL_ATTR),                    //.ATTR(ATTR);
//----------------------------------------------------.-----------------------(6)
              /* input   logic    [15:0] */           .ERR_CPL_requester_id     (ERR_CPL_requester_id),            //[[X]]  -- //COMPLETER ID 
              /* input   logic    [7:0] */            .ERR_CPL_tag              (ERR_CPL_tag),                     //[[X]].
              /* input   logic    [11:0] */           .ERR_CPL_byte_count       (ERR_CPL_byte_count),              //
//---------------------------------------------------------------------------(36)           
              /* input   logic    [6:0] */            .ERR_CPL_lower_addr       (ERR_CPL_lower_addr),              //[[X]]
              /* input   logic    [2:0] */            .ERR_CPL_completion_status(ERR_CPL_completion_status),
//---------------------------------------------------------------------------(7)  
//---------------------------------------------------------------------------(96)
             /* input    logic */                     .ERR_CPL_Wr_En            (ERR_CPL_Wr_En),    //FOR CONTROL             //.valid(valid);
//---------------------------------------------------------------------------(1)



//------------------------------------------------------------------
// Requests CPL from RX AXI MASTER to TX NATIVE SLAVE
//------------------------------------------------------------------
    //      .    .    .    .                        
    //    //.\\//.\\//.\\//.\\ CPLD FROM RX BRIDGE  
              /* input   logic */                     .RX_B_tlp_read_write      (RX_B_tlp_read_write),          //
              /* input   logic [2:0] */               .RX_B_TC                  (RX_B_TC),               //
              /* input   logic [2:0] */               .RX_B_ATTR                (RX_B_ATTR),             //
              /* input   logic [15:0] */              .RX_B_requester_id        (RX_B_requester_id),        //
              /* input   logic [7:0] */               .RX_B_tag                 (RX_B_tag),              //
              /* input   logic [11:0] */              .RX_B_byte_count          (RX_B_byte_count),       //
//--------------------------------------------------------------------------------------
              /* input   logic    [6:0] */            .RX_B_lower_addr          (RX_B_lower_addr),        //
              /* input   logic    [2:0] */            .RX_B_completion_status   (RX_B_completion_status),
//----------------------------------------------------------------------------------------- 
//-----------------------------------------------------------------------------------------          
              /* input   logic    [31:0] */           .RX_B_data1(),                 //
              /* input   logic    [31:0] */           .RX_B_data2(),                 //
              /* input   logic    [31:0] */           .RX_B_data3(),                 //
//-----------------------------------------------------------------------------------------                   
              /* input   logic */                     .RX_B_Wr_En(RX_B_Wr_En),                  //

     /////////////////////////////////////////////////////////////////////////////
    //////////////////////////TX_FIFO////////////////////////////////////////////
        /* input   logic    [DATA_WIDTH2-1:0] */     .RX_B_TX_DATA_FIFO_data (RX_B_TX_DATA_FIFO_data),
        /* input   logic */                          .RX_B_TX_DATA_FIFO_WR_EN(RX_B_TX_DATA_FIFO_WR_EN),
  /////////////////////////////////////////////////////////////////////////////



////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////////////

//------------------------------------------------------------------------------------------------------------------------------------------------------------
//------------------------------------------------------------------------------------------------------------------------------------------------------------
//                         >>>>>>>>>>>>        DOUBLE_IN_CPL_ARB        <<<<<<<<<<<<<
//------------------------------------------------------------------------------------------------------------------------------------------------------------
//------------------------------------------------------------------------------------------------------------------------------------------------------------



/* input    logic */    /* [2:0] */      .MSG_tlp_mem_io_msg_cpl(), //type // tlp_mem_io_msg_cpl_conf(tlp_mem_io_msg_cpl_conf)(),
/* input    logic */                     .MSG_tlp_address_32_64(),       //fmt[0]      //tlp_address_32_64(tlp_address_32_64)(),
/* input    logic */                     .MSG_tlp_read_write(),          //fmt[1]      // tlp_read_write(tlp_read_write)(),
//-------------------------------------------------------------------------- (4)
/* input    logic */    /* [2:0] */      .MSG_TC(),                      //TC(TC)(), 
/* input    logic */    /* [2:0] */      .MSG_ATTR(),                    //ATTR(ATTR)(), 
//---------------------------------------------------------------------(6)
/* input    logic */    /* [15:0] */     .MSG_requester_id(),            //[[MSG]]  -- //COMPLETER ID //device_id(device_id)(),
/* input    logic */    /* [7:0] */      .MSG_tag(),                     //[[MSG]]tag(tag)(),
/* input    logic */    /* [11:0] */     .MSG_byte_count(),              //byte_count(byte_count)(),
//---------------------------------------------------------------------(36)           
/* input    logic */    /* [6:0] */      .MSG_lower_addr(),              //[[MSG]]       //lower_addr(lower_addr)(),
/* input    logic */    /* [2:0] */      .MSG_completion_status(),
//---------------------------------------------------------------------(7)
/* input    logic */    /* [31:0] */     .MSG_data1(),                 //data1(data1)(),
/* input    logic */    /* [31:0] */     .MSG_data2(),                 //data2(data2)(),
/* input    logic */    /* [31:0] */     .MSG_data3(),                 //data3(data3) (),  
/////////////////////////////////////////////////////////////////////////////////////////////
/* input    logic */                     .MSG_ARB_VALID(),           ////////////////////////////////
/* output   logic */                     .MSG_ARB_ACK(),             ////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////


    // AW Channel
    /* input   logic [ADDR_WIDTH-1:0] */           .awaddr  (TX_awaddr ),  
    /* input   logic [7:0] */                      .awlen   (TX_awlen  ),   // number of transfers in transaction
    /* input   logic [2:0] */                      .awsize  (TX_awsize ),  // number of bytes in transfer // 000=> 1, 001=>2, 010=>4, 011=>8, 100=>16, 101=>32, 110=>64, 111=>128
    /* input   logic [1:0] */                      .awburst (TX_awburst),  
    /* output  logic */                            .awready (TX_awready), 
    /* input   logic */                            .awvalid (TX_awvalid), 
    /* input   logic [DATA_WIDTH-1:0] */           .wdata   (TX_wdata  ), 
    /* input   logic [(DATA_WIDTH/8)-1:0] */       .wstrb   (TX_wstrb  ), 
    /* input   logic */                            .wlast   (TX_wlast  ), 
    /* input   logic */                            .wvalid  (TX_wvalid ),
    /* output  logic */                            .wready  (TX_wready ),
    /* output  logic [1:0] */                      .bresp   (TX_bresp  ),                           
    /* output  logic */                            .bvalid  (TX_bvalid ),                         
    /* input   logic */                            .bready  (TX_bready ),                          
    /* input   logic [ADDR_WIDTH-1:0] */           .araddr  (TX_araddr ),
    /* input   logic [7:0] */                      .arlen   (TX_arlen  ),
    /* input   logic [2:0] */                      .arsize  (TX_arsize ),
    /* input   logic [1:0] */                      .arburst (TX_arburst),
    /* output  logic */                            .arready (TX_arready),
    /* input   logic */                            .arvalid (TX_arvalid),
    /* output  logic [DATA_WIDTH-1:0] */           .rdata   (TX_rdata  ),
    /* output  logic [1:0] */                      .rresp   (TX_rresp  ),
    /* output  logic */                            .rlast   (TX_rlast  ),
    /* output  logic */                            .rvalid  (TX_rvalid ),
    /* input   logic */                            .rready  (TX_rready ),

    // ---------------------------------------------------------------------------
// -----------------------------CPL TIMEOUT----------------------------------
// ---------------------------------------------------------------------------
    /* input    logic         */                   .NP_RDEN     (NP_RDEN),
    /* input    logic  [7:0]  */                   .NP_TAG_IDX  (NP_TAG_IDX),
    /* input    logic  [15:0] */                   .NP_DEST_IDX (NP_DEST_IDX),
    /* output   logic         */                   .NP_REQ_EXIST(NP_REQ_EXIST)   
);

endmodule