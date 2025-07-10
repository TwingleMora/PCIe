module TL_RX_TB2;
localparam UPGRADED_DATA_WIDTH = 128;
localparam DATA_WIDTH = 32;
localparam ADDR_WIDTH = 32;
localparam BUS_WIDTH = 128;
//FIRST CLK, RST
bit                     clk, rst;
// SECOND NAMES
///---
// THIRD CONNECTIONS




logic  [2:0]            tlp_mem_io_msg_cpl_conf;
logic                   tlp_address_32_64;
logic                   tlp_read_write;


logic  [2:0]            TC;
logic  [2:0]            ATTR;
logic  [15:0]           device_id;
logic  [15:0]           requester_id;
logic  [7:0]            tag;
logic  [11:0]           byte_count;
logic  [31:0]           lower_addr;
logic  [31:0]           upper_addr;
logic  [15:0]           dest_bdf_id;

logic  [31:0]           data1;
logic  [31:0]           data2;
logic  [31:0]           data3;


logic  [31:0]           x_data;
logic                   x_wren;


logic  [9:0]            config_dw_number;
logic  [2:0]            completion_status;
logic  [7:0]            message_code;
logic                   valid;
logic                   RD_EN;
wire                    VALID_FOR_DL;
wire                    ALL_BUFFS_EMPTY;
logic  [BUS_WIDTH-1:0]  OUT_TLP_DW;    
logic                   fsm_finished;
logic                   TL_TX_ACK;
//-----------------------------------------

//TL_RX_DECODER <== RX_PNPC_BUFF
/*output*/ logic            DATA_BUFFER_WR_EN;
/*output*/ logic  [2:0]     rx_tlp_mem_io_msg_cpl_conf;
/*output*/ logic            rx_tlp_address_32_64;
/*output*/ logic            rx_tlp_read_write;

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

/*input*/   logic   [31:0]   TLP;
/*input*/   logic            M_READY;
/*output*/  logic            M_ENABLE;

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
/*input*/   logic               DATA_BUFF_EMPTY;
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
// //APB_ALU
// /*input*/  logic        PSEL;
// /*input*/  logic        PENABLE;
// /*input*/  logic        PWRITE;
// /*input*/  logic [31:0] PADDR;
// /*input*/  logic [3:0]  PSTRB;
// /*input*/  logic [31:0] PWDATA;
// /*output*/ logic [31:0] PRDATA;
// /*output*/ logic        PREADY;


// ---------------------------------------------------------------------------
// RX_AXI_MASTER
// ---------------------------------------------------------------------------

    logic [ADDR_WIDTH-1:0]           awaddr;
    logic [7:0]                      awlen;  // number of transfers in transaction
    logic [2:0]                      awsize;  // number of bytes in transfer  //                            000=> 1, 001=>2, 010=>4, 011=>8, 100=>16, 101=>32, 110=>64, 111=>128
    logic [1:0]                      awburst;
    logic                            awready;
    logic                            awvalid;

// W Channel
    logic [DATA_WIDTH-1:0]           wdata; 
    logic [(DATA_WIDTH/8)-1:0]       wstrb; 
    logic                            wlast; 
    logic                            wvalid;
    logic                            wready;

// B Channel
    logic [1:0]                      bresp;                         
    logic                            bvalid;                         
    logic                            bready;                         

// AR Channel
    logic [ADDR_WIDTH-1:0]           araddr;
    logic [7:0]                      arlen;
    logic [2:0]                      arsize;
    logic [1:0]                      arburst;
    logic                            arready;
    logic                            arvalid;
                                        

// R Channel                            
    logic [DATA_WIDTH-1:0]           rdata;
    logic [1:0]                      rresp;
    logic                            rlast;
    logic                            rvalid;
    logic                            rready;




// ---------------------------------------------------------------------------
// 
// ---------------------------------------------------------------------------
/////////////////////////////////////////////////////////////////////////////\\\---|
//////////////////////////////////////////////////////////////////////////////\\\  |
///////////////////////////////////////////////////////////////////////////////\\\ |
////////////////////////////////////////////////////////////////////////////////\\\|
// --------------------------------------------------------------------------- |||||
// TRIPLE IN ARB (Collect CPL/ Messages/ Req) that need to be transmitted      |||||
// --------------------------------------------------------------------------- |||||
///////////////////////////////////////////////////////////////////////////////////|
////////////////////////////////////////////////////////////////////////////////// |
/////////////////////////////////////////////////////////////////////////////////  |
////////////////////////////////////////////////////////////////////////////////---|
// ---------------------------------------------------------------------------
// 
// ---------------------------------------------------------------------------
/* input */   logic    [2:0]                        req_tlp_mem_io_msg_cpl_conf;
/* input */   logic                                 req_tlp_address_32_64;
/* input */   logic                                 req_tlp_read_write;
/* input */   logic    [2:0]                        req_TC;
/* input */   logic    [2:0]                        req_ATTR;
/* input */   logic    [15:0]                       req_requester_id;
/* input */   logic    [7:0]                        req_tag;
/* input */   logic    [11:0]                       req_byte_count;
/* input */   logic    [31:0]                       req_lower_addr;
/* input */   logic    [31:0]                       req_upper_addr;
/* input */   logic    [15:0]                       req_dest_bdf_id;
// /* input */   logic    [UPGRADED_DATA_WIDTH-1:0]    req_data;
/* input */   logic    [31:0]                       req_data1;
/* input */   logic    [31:0]                       req_data2;
/* input */   logic    [31:0]                       req_data3;

//////////////////////////////////////////////////////////////////
///////////////////////////FIFO TX////////////////////////////////
//////////////////////////////////////////////////////////////////
/* input */     logic    [DATA_WIDTH-1:0]             REQ_data;
/* input */     logic    [ADDR_WIDTH-1:0]             REQ_addr;
                logic                                 REQ_rd_wr;
                logic                                 REQ_valid;
/* input */     logic                                 REQ_WR_EN;
//////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////

/* input */   logic    [9:0]                        req_config_dw_number;
/* input */   logic    [2:0]                        req_completion_status;
/* input */   logic    [7:0]                        req_message_code;
/* input */   logic                                 req_valid;
// ---------------------------------------------------------------------------
// ---------------------------------------------------------------------------

    /* input */   logic [ADDR_WIDTH-1:0]           req_awaddr;  
    /* input */   logic [7:0]                      req_awlen;   // number of transfers in transaction
    /* input */   logic [2:0]                      req_awsize;  // number of bytes in transfer // 000=> 1; 001=>2; 010=>4; 011=>8; 100=>16; 101=>32; 110=>64; 111=>128
    /* input */   logic [1:0]                      req_awburst;  
    /* output */  logic                            req_awready; 
    /* input */   logic                            req_awvalid; 

    // W Channelreq_
    /* input */   logic [DATA_WIDTH-1:0]           req_wdata; 
    /* input */   logic [(DATA_WIDTH/8)-1:0]       req_wstrb; 
    /* input */   logic                            req_wlast; 
    /* input */   logic                            req_wvalid;
    /* output */  logic                            req_wready;

    // B Channelreq_
    /* output */  logic [1:0]                      req_bresp;                         
    /* output */  logic                            req_bvalid;                         
    /* input */   logic                            req_bready;                         

    // AR Channelreq_
    /* input */   logic [ADDR_WIDTH-1:0]           req_araddr;
    /* input */   logic [7:0]                      req_arlen;
    /* input */   logic [2:0]                      req_arsize;
    /* input */   logic [1:0]                      req_arburst;
    /* output */  logic                            req_arready;
    /* input */   logic                            req_arvalid;
                                            

    // R Channel                            req_
    /* output */  logic [DATA_WIDTH-1:0]           req_rdata;
    /* output */  logic [1:0]                      req_rresp;
    /* output */  logic                            req_rlast;
    /* output */  logic                            req_rvalid;
    /* input */   logic                            req_rready;


/////////////////////////////////////////////////////////////////////////////\\\---|
//////////////////////////////////////////////////////////////////////////////\\\  |
///////////////////////////////////////////////////////////////////////////////\\\ |
////////////////////////////////////////////////////////////////////////////////\\\|
// --------------------------------------------------------------------------- |||||
// DOUBLE_IN_ARB (RX USES TX TO TRANSMITS COMPLETIONS)                         |||||
// --------------------------------------------------------------------------- |||||
///////////////////////////////////////////////////////////////////////////////////|
////////////////////////////////////////////////////////////////////////////////// |
/////////////////////////////////////////////////////////////////////////////////  |
////////////////////////////////////////////////////////////////////////////////---|

//------------------------------------------------------------------
// Errors CPL from Error Detection Block
//------------------------------------------------------------------
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



//------------------------------------------------------------------
// Requests CPL from RX AXI MASTER to TX NATIVE SLAVE
//------------------------------------------------------------------
    //      .    .    .    .                        
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




// ---------------------------------------------------------------------------
// -----------------------------CPL TIMEOUT----------------------------------
// ---------------------------------------------------------------------------
    /* input  */   logic                            NP_RDEN     ;
    /* input  */   logic  [7:0]                     NP_TAG_IDX  ;
    /* input  */   logic  [15:0]                    NP_DEST_IDX ;
    /* output */   logic                            NP_REQ_EXIST;   



// ---------------------------------------------------------------------------
// ---------------------------------------------------------------------------


logic TLP_START_BIT_OUT_COMB;
logic TLP_END_BIT_OUT_COMB;

logic A_tlp_ready;
logic A_tlp_valid;

logic B_tlp_ready;
logic B_tlp_valid;
 
logic [BUS_WIDTH-1:0] TLPA2B;
logic [BUS_WIDTH-1:0] TLPB2A;
always #5 clk = ~clk;

wire [31:0] dumb_signal2;


APP_AXI_MASTER app_axi_master
(

    /* input  logic  [DATA_WIDTH-1:0] */            .i_data (REQ_data),    //data bus                        
    /* input  logic  [DATA_WIDTH-1:0] */            .i_addr (REQ_addr),    //address bus                            
    /* input  logic */                              .i_rd_wr(REQ_rd_wr), 
    /* input  logic */                              .i_valid(REQ_valid),   //control bus
    /* output logic */                              .o_ack  (),         
        // Global Signals 
    /* input logic */                              .aclk   (clk),
    /* input logic */                              .aresetn(rst),

    // AW Channel
    /* input   logic [ADDR_WIDTH-1:0] */           .awaddr  (req_awaddr),  
    // /* input   logic [7:0] */                      .awlen   (req_awlen),   // number of transfers in transaction
    // /* input   logic [2:0] */                      .awsize  (req_awsize),  // number of bytes in transfer // 000=> 1, 001=>2, 010=>4, 011=>8, 100=>16, 101=>32, 110=>64, 111=>128
    // /* input   logic [1:0] */                      .awburst (req_awburst),  
    /* output  logic */                            .awready (req_awready), 
    /* input   logic */                            .awvalid (req_awvalid), 

    // W Channel
    /* input   logic [DATA_WIDTH-1:0] */           .wdata   (req_wdata), 
    /* input   logic [(DATA_WIDTH/8)-1:0] */       .wstrb   (req_wstrb), 
    // /* input   logic */                            .wlast   (req_wlast), 
    /* input   logic */                            .wvalid  (req_wvalid),
    /* output  logic */                            .wready  (req_wready),

    // B Channel
    /* output  logic [1:0] */                      .bresp   (req_bresp),                           
    /* output  logic */                            .bvalid  (req_bvalid),                         
    /* input   logic */                            .bready  (req_bready),                          

    // AR Channel
    /* input   logic [ADDR_WIDTH-1:0] */           .araddr  (req_araddr),
    // /* input   logic [7:0] */                      .arlen   (req_arlen),
    // /* input   logic [2:0] */                      .arsize  (req_arsize),
    // /* input   logic [1:0] */                      .arburst (req_arburst),
    /* output  logic */                            .arready (req_arready),
    /* input   logic */                            .arvalid (req_arvalid),
                                            

    // R Channel                            
    /* output  logic [DATA_WIDTH-1:0] */           .rdata   (req_rdata),
    /* output  logic [1:0] */                      .rresp   (req_rresp),
    // /* output  logic */                            .rlast   (req_rlast),
    /* output  logic */                            .rvalid  (req_rvalid),
    /* input   logic */                            .rready  (req_rready)
);

TRANSACTION_TOP#(.ADDR_WIDTH(32), .DATA_WIDTH(32), .BUS_WIDTH(128)) Device_A(
    /* input  logic                       */       .clk(clk),
    /* input  logic                       */       .rst(rst),

                                          //       RX
    /* input   logic                      */       .new_tlp_ready(B_tlp_ready),
    /* input   logic                      */       .valid_tlp    (B_tlp_valid),
    /* input   logic [BUS_WIDTH-1:0]      */       .IN_TLP_DW    (TLPB2A),
    //
//                                                 TX
    /* output  logic   [BUS_WIDTH-1:0]    */       .OUT_TLP_DW              (TLPA2B),
    /* output  logic                      */       .TLP_START_BIT_OUT_COMB  (A_tlp_ready),
    /* output  logic                      */       .VALID_FOR_DL            (A_tlp_valid),
    /* input   logic                      */       .RD_EN                   (1'b1),
    /* output  logic */                            .fsm_started(fsm_started),
    /* output  logic */                            .fsm_finished(fsm_finished),



    /* output  logic [7:0]                */       .RX_awlen  (),   // number of transfers in transaction
    /* output  logic [ADDR_WIDTH-1:0]     */       .RX_awaddr (),
    /* output  logic [2:0]                */       .RX_awsize (),  // number of bytes in transfer  //                            000=> 1, 001=>2, 010=>4, 011=>8, 100=>16, 101=>32, 110=>64, 111=>128
    /* output  logic [1:0]                */       .RX_awburst(),
    /* input   logic                      */       .RX_awready(),
    /* output  logic                      */       .RX_awvalid(),
    /* output  logic [DATA_WIDTH-1:0]     */       .RX_wdata  (), 
    /* output  logic [(DATA_WIDTH/8)-1:0] */       .RX_wstrb  (), 
    /* output  logic                      */       .RX_wlast  (), 
    /* output  logic                      */       .RX_wvalid (),
    /* input   logic                      */       .RX_wready (),
    /* input   logic [1:0]                */       .RX_bresp  (),                         
    /* input   logic                      */       .RX_bvalid (),                         
    /* output  logic                      */       .RX_bready (),                         
    /* output  logic [ADDR_WIDTH-1:0]     */       .RX_araddr (),
    /* output  logic [7:0]                */       .RX_arlen  (),
    /* output  logic [2:0]                */       .RX_arsize (),
    /* output  logic [1:0]                */       .RX_arburst(),
    /* input   logic                      */       .RX_arready(),
    /* output  logic                      */       .RX_arvalid(),                         
    /* input   logic [DATA_WIDTH-1:0]     */       .RX_rdata  (),
    /* input   logic [1:0]                */       .RX_rresp  (),
    /* input   logic                      */       .RX_rlast  (),
    /* input   logic                      */       .RX_rvalid (),
    /* output  logic                      */       .RX_rready (),


    // AW Channel
    /* input   logic [ADDR_WIDTH-1:0]     */       .TX_awaddr  (req_awaddr ),  
    /* input   logic [7:0]                */       .TX_awlen   (req_awlen  ),   // number of transfers in transaction
    /* input   logic [2:0]                */       .TX_awsize  (req_awsize ),  // number of bytes in transfer // 000=> 1, 001=>2, 010=>4, 011=>8, 100=>16, 101=>32, 110=>64, 111=>128
    /* input   logic [1:0]                */       .TX_awburst (req_awburst),  
    /* output  logic                      */       .TX_awready (req_awready), 
    /* input   logic                      */       .TX_awvalid (req_awvalid), 
    /* input   logic [DATA_WIDTH-1:0]     */       .TX_wdata   (req_wdata  ), 
    /* input   logic [(DATA_WIDTH/8)-1:0] */       .TX_wstrb   (req_wstrb  ), 
    /* input   logic                      */       .TX_wlast   (req_wlast  ), 
    /* input   logic                      */       .TX_wvalid  (req_wvalid ),
    /* output  logic                      */       .TX_wready  (req_wready ),
    /* output  logic [1:0]                */       .TX_bresp   (req_bresp  ),                         
    /* output  logic                      */       .TX_bvalid  (req_bvalid ),                         
    /* input   logic                      */       .TX_bready  (req_bready ),                         
    /* input   logic [ADDR_WIDTH-1:0]     */       .TX_araddr  (req_araddr ),
    /* input   logic [7:0]                */       .TX_arlen   (req_arlen  ),
    /* input   logic [2:0]                */       .TX_arsize  (req_arsize ),
    /* input   logic [1:0]                */       .TX_arburst (req_arburst),
    /* output  logic                      */       .TX_arready (req_arready),
    /* input   logic                      */       .TX_arvalid (req_arvalid),
    /* output  logic [DATA_WIDTH-1:0]     */       .TX_rdata   (req_rdata  ),
    /* output  logic [1:0]                */       .TX_rresp   (req_rresp  ),
    /* output  logic                      */       .TX_rlast   (req_rlast  ),
    /* output  logic                      */       .TX_rvalid  (req_rvalid ),
    /* input   logic                      */       .TX_rready  (req_rready )
);

TRANSACTION_TOP#(.ADDR_WIDTH(32), .DATA_WIDTH(32), .BUS_WIDTH(128)) Device_B
(
    /* input  logic                          */    .clk(clk),
    /* input  logic                       */       .rst(rst),
                                                // RX
    /* input   logic                      */       .new_tlp_ready(A_tlp_ready),
    /* input   logic                      */       .valid_tlp(A_tlp_valid),
    /* input   logic [BUS_WIDTH-1:0]      */       .IN_TLP_DW   (TLPA2B),
                                                // TX
    /* output  logic                      */       .VALID_FOR_DL(B_tlp_valid),
    /* output  logic                      */       .TLP_START_BIT_OUT_COMB(B_tlp_ready),
    /* output  logic   [BUS_WIDTH-1:0]    */       .OUT_TLP_DW  (TLPB2A),
    /* input   logic                      */       .RD_EN       (1'b1),

    /* output  logic [7:0]                */       .RX_awlen  (awlen),   // number of transfers in transaction
    /* output  logic [ADDR_WIDTH-1:0]     */       .RX_awaddr (awaddr),
    /* output  logic [2:0]                */       .RX_awsize (awsize),  // number of bytes in transfer  //                            000=> 1, 001=>2, 010=>4, 011=>8, 100=>16, 101=>32, 110=>64, 111=>128
    /* output  logic [1:0]                */       .RX_awburst(awburst),
    /* input   logic                      */       .RX_awready(awready),
    /* output  logic                      */       .RX_awvalid(awvalid),
    /* output  logic [DATA_WIDTH-1:0]     */       .RX_wdata  (wdata), 
    /* output  logic [(DATA_WIDTH/8)-1:0] */       .RX_wstrb  (wstrb), 
    /* output  logic                      */       .RX_wlast  (wlast), 
    /* output  logic                      */       .RX_wvalid (wvalid),
    /* input   logic                      */       .RX_wready (wready),
    /* input   logic [1:0]                */       .RX_bresp  (bresp),                         
    /* input   logic                      */       .RX_bvalid (bvalid),                         
    /* output  logic                      */       .RX_bready (bready),                         
    /* output  logic [ADDR_WIDTH-1:0]     */       .RX_araddr (araddr),
    /* output  logic [7:0]                */       .RX_arlen  (arlen),
    /* output  logic [2:0]                */       .RX_arsize (arsize),
    /* output  logic [1:0]                */       .RX_arburst(arburst),
    /* input   logic                      */       .RX_arready(arready),
    /* output  logic                      */       .RX_arvalid(arvalid),                         
    /* input   logic [DATA_WIDTH-1:0]     */       .RX_rdata  (rdata),
    /* input   logic [1:0]                */       .RX_rresp  (rresp),
    /* input   logic                      */       .RX_rlast  (rlast),
    /* input   logic                      */       .RX_rvalid (rvalid),
    /* output  logic                      */       .RX_rready (rready),


    // AW Channel
    /* input   logic [ADDR_WIDTH-1:0]     */       .TX_awaddr  (),  
    /* input   logic [7:0]                */       .TX_awlen   (),   // number of transfers in transaction
    /* input   logic [2:0]                */       .TX_awsize  (),  // number of bytes in transfer // 000=> 1, 001=>2, 010=>4, 011=>8, 100=>16, 101=>32, 110=>64, 111=>128
    /* input   logic [1:0]                */       .TX_awburst (),  
    /* output  logic                      */       .TX_awready (), 
    /* input   logic                      */       .TX_awvalid (), 
    /* input   logic [DATA_WIDTH-1:0]     */       .TX_wdata   (), 
    /* input   logic [(DATA_WIDTH/8)-1:0] */       .TX_wstrb   (), 
    /* input   logic                      */       .TX_wlast   (), 
    /* input   logic                      */       .TX_wvalid  (),
    /* output  logic                      */       .TX_wready  (),
    /* output  logic [1:0]                */       .TX_bresp   (),                         
    /* output  logic                      */       .TX_bvalid  (),                         
    /* input   logic                      */       .TX_bready  (),                         
    /* input   logic [ADDR_WIDTH-1:0]     */       .TX_araddr  (),
    /* input   logic [7:0]                */       .TX_arlen   (),
    /* input   logic [2:0]                */       .TX_arsize  (),
    /* input   logic [1:0]                */       .TX_arburst (),
    /* output  logic                      */       .TX_arready (),
    /* input   logic                      */       .TX_arvalid (),
    /* output  logic [DATA_WIDTH-1:0]     */       .TX_rdata   (),
    /* output  logic [1:0]                */       .TX_rresp   (),
    /* output  logic                      */       .TX_rlast   (),
    /* output  logic                      */       .TX_rvalid  (),
    /* input   logic                      */       .TX_rready  ()

);
// TRANSACTION_TX_TOP  tl_tx_top(
// /* inpinut  logic */                        .clk(clk),
// /* inpinut  logic */                        .rst(rst),
                               
// //DATA LINK INTERFACE          
// /* input  logic */                          .RD_EN(RD_EN),
// /* output logic */                          .VALID_FOR_DL(VALID_FOR_DL),
// /* output logic */                          .ALL_BUFFS_EMPTY(ALL_BUFFS_EMPTY),
// /* output logic */   /* [31:0] */           .OUT_TLP_DW(OUT_TLP_DW),
// /* output logic */                          .fsm_finished(fsm_finished),
// /* output logic */                          .TL_TX_ACK(TL_TX_ACK),
//                                             .fsm_started(fsm_started),
//                                             .TLP_START_BIT_OUT_COMB(TLP_START_BIT_OUT_COMB),


// //FROM RX ERROR DETECTION TO TX MASTER

// //\\\\\\\\\\\\\\\\\\\\\\\\\\\--------|--------//////////////////////////////\\
//  //\\\\\\\\\\\\\\\\\\\\\\\\\\\    |= | =|    //////////////////////////////\\
//   //\\\\\\\\\\\\\\\\\\\\\\\\\\\    |=|=|    //////////////////////////////\\
//    //\\\\\\\\\\\\\\\\\\\\\\\\\\\    |||    //////////////////////////////\\
//     //\\\\\\\\\\\\\\\\\\\\\\\\\\\   \|/   //////////////////////////////\\
//      //\\\\\\\\\\\\\\\\\\\\\\\\\\\   |   //////////////////////////////\\
//       //\\\\\\\\\\\\\\\\\\\\\\\\\\\  |  //////////////////////////////\\
//        //\\\\\\\\\\\\\\\\\\\\\\\\\\\ | //////////////////////////////\\
//         //\\\\\\\\\\\\\\\\\\\\\\\\\\\|//////////////////////////////\\

// //FROM RX MASTER to TX MASTER




// //------------------------------------------------------------------------------------------------------------------------------------------------------------
// //------------------------------------------------------------------------------------------------------------------------------------------------------------
// //                             DOUBLE_IN_CPL_ARB            
// //------------------------------------------------------------------------------------------------------------------------------------------------------------
// //------------------------------------------------------------------------------------------------------------------------------------------------------------
// ////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// ////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// ////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// //------------------------------------------------------------------
// // Errors CPL from Error Detection Block
// //------------------------------------------------------------------
// //-------------------------------------------------------------------------- (4)
//               /* input   logic    [2:0] */            .ERR_CPL_TC               (ERR_CPL_TC),                      //.TC(TC);
//               /* input   logic    [2:0] */            .ERR_CPL_ATTR             (ERR_CPL_ATTR),                    //.ATTR(ATTR);
// //----------------------------------------------------.-----------------------(6)
//               /* input   logic    [15:0] */           .ERR_CPL_requester_id     (ERR_CPL_requester_id),            //[[X]]  -- //COMPLETER ID 
//               /* input   logic    [7:0] */            .ERR_CPL_tag              (ERR_CPL_tag),                     //[[X]].
//               /* input   logic    [11:0] */           .ERR_CPL_byte_count       (ERR_CPL_byte_count),              //
// //---------------------------------------------------------------------------(36)           
//               /* input   logic    [6:0] */            .ERR_CPL_lower_addr       (ERR_CPL_lower_addr),              //[[X]]
//               /* input   logic    [2:0] */            .ERR_CPL_completion_status(ERR_CPL_completion_status),
// //---------------------------------------------------------------------------(7)  
// //---------------------------------------------------------------------------(96)
//              /* input    logic */                     .ERR_CPL_Wr_En            (ERR_CPL_Wr_En),    //FOR CONTROL             //.valid(valid);
// //---------------------------------------------------------------------------(1)



// //------------------------------------------------------------------
// // Requests CPL from RX AXI MASTER to TX NATIVE SLAVE
// //------------------------------------------------------------------
//     //      .    .    .    .                        
//     //    //.\\//.\\//.\\//.\\ CPLD FROM RX BRIDGE  
//               /* input   logic */                     .RX_B_tlp_read_write(RX_B_tlp_read_write),          //
//               /* input   logic [2:0] */               .RX_B_TC(RX_B_TC),               //
//               /* input   logic [2:0] */               .RX_B_ATTR(RX_B_ATTR),             //
//               /* input   logic [15:0] */              .RX_B_requester_id(RX_B_requester_id),        //
//               /* input   logic [7:0] */               .RX_B_tag(RX_B_tag),              //
//               /* input   logic [11:0] */              .RX_B_byte_count(RX_B_byte_count),       //
// //--------------------------------------------------------------------------------------
//               /* input   logic    [6:0] */            .RX_B_lower_addr(RX_B_lower_addr),        //
//               /* input   logic    [2:0] */            .RX_B_completion_status(RX_B_completion_status),
// //----------------------------------------------------------------------------------------- 
// //-----------------------------------------------------------------------------------------          
//               /* input   logic    [31:0] */           .RX_B_data1(),                 //
//               /* input   logic    [31:0] */           .RX_B_data2(),                 //
//               /* input   logic    [31:0] */           .RX_B_data3(),                 //
// //-----------------------------------------------------------------------------------------                   
//               /* input   logic */                     .RX_B_Wr_En(RX_B_Wr_En),                  //
//      /////////////////////////////////////////////////////////////////////////////
//     //////////////////////////TX_FIFO////////////////////////////////////////////
//         /* input   logic    [DATA_WIDTH2-1:0] */     .RX_B_TX_DATA_FIFO_data(RX_B_TX_DATA_FIFO_data),
//         /* input   logic */                          .RX_B_TX_DATA_FIFO_WR_EN(RX_B_TX_DATA_FIFO_WR_EN),
//   /////////////////////////////////////////////////////////////////////////////



// ////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// ////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// ////////////////////////////////////////////////////////////////////////////////////////////////////////////////

// //------------------------------------------------------------------------------------------------------------------------------------------------------------
// //------------------------------------------------------------------------------------------------------------------------------------------------------------
// //                         >>>>>>>>>>>>        DOUBLE_IN_CPL_ARB        <<<<<<<<<<<<<
// //------------------------------------------------------------------------------------------------------------------------------------------------------------
// //------------------------------------------------------------------------------------------------------------------------------------------------------------



// /* input    logic */    /* [2:0] */      .MSG_tlp_mem_io_msg_cpl(), //type // tlp_mem_io_msg_cpl_conf(tlp_mem_io_msg_cpl_conf)(),
// /* input    logic */                     .MSG_tlp_address_32_64(),       //fmt[0]      //tlp_address_32_64(tlp_address_32_64)(),
// /* input    logic */                     .MSG_tlp_read_write(),          //fmt[1]      // tlp_read_write(tlp_read_write)(),
// //-------------------------------------------------------------------------- (4)
// /* input    logic */    /* [2:0] */      .MSG_TC(),                      //TC(TC)(), 
// /* input    logic */    /* [2:0] */      .MSG_ATTR(),                    //ATTR(ATTR)(), 
// //---------------------------------------------------------------------(6)
// /* input    logic */    /* [15:0] */     .MSG_requester_id(),            //[[MSG]]  -- //COMPLETER ID //device_id(device_id)(),
// /* input    logic */    /* [7:0] */      .MSG_tag(),                     //[[MSG]]tag(tag)(),
// /* input    logic */    /* [11:0] */     .MSG_byte_count(),              //byte_count(byte_count)(),
// //---------------------------------------------------------------------(36)           
// /* input    logic */    /* [6:0] */      .MSG_lower_addr(),              //[[MSG]]       //lower_addr(lower_addr)(),
// /* input    logic */    /* [2:0] */      .MSG_completion_status(),
// //---------------------------------------------------------------------(7)
// /* input    logic */    /* [31:0] */     .MSG_data1(),                 //data1(data1)(),
// /* input    logic */    /* [31:0] */     .MSG_data2(),                 //data2(data2)(),
// /* input    logic */    /* [31:0] */     .MSG_data3(),                 //data3(data3) (),  
// /////////////////////////////////////////////////////////////////////////////////////////////
// /* input    logic */                     .MSG_ARB_VALID(),           ////////////////////////////////
// /* output   logic */                     .MSG_ARB_ACK(),             ////////////////////////////////
// //////////////////////////////////////////////////////////////////////////////////////////



// // // ---------------------------------------------------------------------------
// // // AXI
// // // ---------------------------------------------------------------------------
// // /* input    logic */    /* [2:0] */                        .REQ_tlp_mem_io_msg_cpl_conf(req_tlp_mem_io_msg_cpl_conf),
// // /* input    logic */                                       .REQ_tlp_address_32_64(req_tlp_address_32_64),
// // /* input    logic */                                       .REQ_tlp_read_write(req_tlp_read_write),
// // /* input    logic */    /* [2:0] */                        .REQ_TC(req_TC),
// // /* input    logic */    /* [2:0] */                        .REQ_ATTR(req_ATTR),
// // /* input    logic */    /* [15:0] */                       .REQ_requester_id(req_requester_id),
// // /* input    logic */    /* [7:0] */                        .REQ_tag(req_tag),
// // /* input    logic */    /* [11:0] */                       .REQ_byte_count(req_byte_count),
// // /* input    logic */    /* [31:0] */                       .REQ_lower_addr(req_lower_addr),
// // /* input    logic */    /* [31:0] */                       .REQ_upper_addr(req_upper_addr),
// // /* input    logic */    /* [15:0] */                       .REQ_dest_bdf_id(req_dest_bdf_id),
// // // /* input */   logic    [UPGRADED_DATA_WIDTH-1:0]        .REQ_data(),
// // /* input    logic */    /* [31:0] */                       .REQ_data1(req_data1),
// // /* input    logic */    /* [31:0] */                       .REQ_data2(req_data2),
// // /* input    logic */    /* [31:0] */                       .REQ_data3(req_data3),

// // //////////////////////////////////////////////////////////////////
// // ///////////////////////////FIFO TX////////////////////////////////
// // //////////////////////////////////////////////////////////////////
// // /* input    logic    [31:0] */                              .REQ_data (REQ_data),
// // /* input    logic */                                        .REQ_WR_EN(REQ_WR_EN),
// // //////////////////////////////////////////////////////////////////
// // //////////////////////////////////////////////////////////////////
// // /* input    logic */    /* [9:0] */                        .REQ_config_dw_number (req_config_dw_number),
// // /* input    logic */    /* [2:0] */                        .REQ_completion_status(req_completion_status),
// // /* input    logic */    /* [7:0] */                        .REQ_message_code(req_message_code),
// // /* input    logic */                                       .REQ_valid(req_valid)
// // // ---------------------------------------------------------------------------
// // // ---------------------------------------------------------------------------

//     // AR Channel
                                            

//     // R Channel                            



//     // AW Channel
//     /* input   logic [ADDR_WIDTH-1:0] */           .awaddr  (req_awaddr),  
//     /* input   logic [7:0] */                      .awlen   (req_awlen),   // number of transfers in transaction
//     /* input   logic [2:0] */                      .awsize  (req_awsize),  // number of bytes in transfer // 000=> 1, 001=>2, 010=>4, 011=>8, 100=>16, 101=>32, 110=>64, 111=>128
//     /* input   logic [1:0] */                      .awburst (req_awburst),  
//     /* output  logic */                            .awready (req_awready), 
//     /* input   logic */                            .awvalid (req_awvalid), 

//     // W Channel
//     /* input   logic [DATA_WIDTH-1:0] */           .wdata   (req_wdata), 
//     /* input   logic [(DATA_WIDTH/8)-1:0] */       .wstrb   (req_wstrb), 
//     /* input   logic */                            .wlast   (req_wlast), 
//     /* input   logic */                            .wvalid  (req_wvalid),
//     /* output  logic */                            .wready  (req_wready),

//     // B Channel
//     /* output  logic [1:0] */                      .bresp   (req_bresp),                           
//     /* output  logic */                            .bvalid  (req_bvalid),                         
//     /* input   logic */                            .bready  (req_bready),                          

//     // AR Channel
//     /* input   logic [ADDR_WIDTH-1:0] */           .araddr  (req_araddr),
//     /* input   logic [7:0] */                      .arlen   (req_arlen),
//     /* input   logic [2:0] */                      .arsize  (req_arsize),
//     /* input   logic [1:0] */                      .arburst (req_arburst),
//     /* output  logic */                            .arready (req_arready),
//     /* input   logic */                            .arvalid (req_arvalid),
                                            

//     // R Channel                            
//     /* output  logic [DATA_WIDTH-1:0] */           .rdata   (req_rdata),
//     /* output  logic [1:0] */                      .rresp   (req_rresp),
//     /* output  logic */                            .rlast   (req_rlast),
//     /* output  logic */                            .rvalid  (req_rvalid),
//     /* input   logic */                            .rready  (req_rready),

// // ---------------------------------------------------------------------------
// // -----------------------------CPL TIMEOUT----------------------------------
// // ---------------------------------------------------------------------------
//     /* input    logic         */                      .NP_RDEN     (NP_RDEN),
//     /* input    logic  [7:0]  */                      .NP_TAG_IDX  (NP_TAG_IDX),
//     /* input    logic  [15:0] */                      .NP_DEST_IDX (NP_DEST_IDX),
//     /* output   logic         */                      .NP_REQ_EXIST(NP_REQ_EXIST)   
// );


// wire valid_tlp;
// assign valid_tlp = !ALL_BUFFS_EMPTY;


// /* input */  logic                     RX_HEADER_DATA; // 0: Header; 1: Data
// /* input */  logic [1:0]               RX_P_NP_CPL; // Posted: 00; Non-Posted: 01; Completion: 11
// /* input */  logic [DATA_WIDTH-1:0]    RX_IN_TLP_DW;
// /* input */  logic                     RX_WR_EN;
// /* input */  logic                     RX_RD_EN;
// /* input */  logic                     RX_commit;
// /* input */  logic                     RX_flush;
// /* output */ wire                      RX_EMPTY;
// /* output */ logic                     RX_OUT_EMPTY;
// /* output */ logic [BUS_WIDTH-1:0]    RX_OUT_TLP_DW;      
// /* output */ logic [BUS_WIDTH-1:0]    RX_OUT_TLP_DW_COMB; 

// wire new_tlp_ready = TLP_START_BIT_OUT_COMB;

// TRANSACTION_RX_TOP #(.DATA_WIDTH(32), .ADDR_WIDTH(32), .BUS_WIDTH(128) ) tl_rx_top(

// // DL-TL Interface
// /* input   logic */                             .clk(clk),
// /* input   logic */                             .rst(rst),
// ////////////////////////////////////////////////.//////////////
// // DATA LINK INTERFACE                          .
// ////////////////////////////////////////////////.//////////////
// /* input   logic [31:0] */                      .IN_TLP_DW(OUT_TLP_DW),
// /* input   logic        */                      .new_tlp_ready(new_tlp_ready),
// /* input   logic        */                      .valid_tlp(valid_tlp),
// //AXI Interface                                 .
// /* output  logic [ADDR_WIDTH-1:0] */            .awaddr(awaddr),
// /* output  logic [7:0]            */            .awlen(awlen),   // number of transfers in transaction
// /* output  logic [2:0]            */            .awsize(awsize),  // number of bytes in transfer  //                            000=> 1(), 001=>2, 010=>4, 011=>8, 100=>16, 101=>32, 110=>64, 111=>128
// /* output  logic [1:0]            */            .awburst(awburst),
// /* input   logic                  */            .awready(awready),
// /* output  logic                  */            .awvalid(awvalid),

// // W Channel                                    .
// /* output logic [DATA_WIDTH-1:0]     */         .wdata (wdata), 
// /* output logic [(DATA_WIDTH/8)-1:0] */         .wstrb (wstrb), 
// /* output logic                      */         .wlast (wlast), 
// /* output logic                      */         .wvalid(wvalid),
// /* input  logic                      */         .wready(wready),

// // B Channel                                    .
// /* input  logic [1:0] */                              .bresp (bresp),                         
// /* input  logic */                                    .bvalid(bvalid),                         
// /* output logic */                                    .bready(bready),                         

// // AR Channel                                   .
// /* output logic [ADDR_WIDTH-1:0] */                        .araddr (araddr),
// /* output logic [7:0] */                                   .arlen  (arlen),
// /* output logic [2:0] */                                   .arsize (arsize),
// /* output logic [1:0] */                                   .arburst(arburst),
// /* input  logic */                                         .arready(arready),
// /* output */                                               .arvalid(arvalid),                          
// // R Channel                                    .
// /* input   logic [DATA_WIDTH-1:0] */                       .rdata (rdata),
// /* input   logic [1:0] */                                  .rresp (rresp),
// /* input   logic */                                        .rlast (rlast),
// /* input   logic */                                        .rvalid (rvalid),
// /* output  logic */                                        .rready (rready),
// //Internal Native Interface (FROM AXI MASTER TO .TL_TX)
// /* output  logic */                                        .RX_B_tlp_read_write(RX_B_tlp_read_write),          //
// /* output  logic    [2:0]  */                              .RX_B_TC            (RX_B_TC            ),               //
// /* output  logic    [2:0]  */                              .RX_B_ATTR          (RX_B_ATTR          ),             //
// /* output  logic    [15:0] */                              .RX_B_requester_id  (RX_B_requester_id  ),        //
// /* output  logic    [7:0]  */                              .RX_B_tag           (RX_B_tag           ),              //
// /* output  logic    [11:0] */                              .RX_B_byte_count    (RX_B_byte_count    ),       //
// //----------------------------------------------.-----     -----------------------------------
// /* output  logic    [6:0] */                               .RX_B_lower_addr(RX_B_lower_addr),       //
// /* output  logic    [2:0] */                               .RX_B_completion_status(RX_B_completion_status),
// //----------------------------------------------------------------------------------------- 
// //-----------------------------------------------------------------------------------------          
// /* output  logic    [31:0] */                             .RX_B_data1(),                 //
// /* output  logic    [31:0] */                             .RX_B_data2(),                 //
// /* output  logic    [31:0] */                             .RX_B_data3(),                 //
// //-----------------------------------------------------------------------------------------                   
// /* output  logic */                                       .RX_B_Wr_En(RX_B_Wr_En),                  //
// //-----------------------------------------------------------------------------------------
// //Internal Native Interface (FROM ERROR DETECTION TO TL_TX)
// //-------------------------------------------------------------------------- (4)
// /* output   logic    [2:0] */                             .ERR_CPL_TC(),                      //.TC(TC);
// /* output   logic    [2:0] */                             .ERR_CPL_ATTR(),                    //.ATTR(ATTR);
// //---------------------------------------------------------------------------(6)
// /* output   logic    [15:0] */                            .ERR_CPL_requester_id(),            //[[X]]  -- //COMPLETER ID 
// /* output   logic    [7:0]  */                            .ERR_CPL_tag(),                    //[[X]].
// /* output   logic    [11:0] */                            .ERR_CPL_byte_count(),              //
// //---------------------------------------------------------------------------(36)           
// /* output   logic    [6:0] */                             .ERR_CPL_lower_addr(),              //[[X]]
// /* output   logic    [2:0] */                             .ERR_CPL_completion_status(),
// //---------------------------------------------------------------------------(7)  
// //---------------------------------------------------------------------------(96)
// /* output    logic */                                     .ERR_CPL_Wr_En(),                 //.valid(valid);
// //------------------------------------------------------------------------------
// /* input    logic    [2:0] */                             .MSG_tlp_mem_io_msg_cpl(), //type // tlp_mem_io_msg_cpl_conf(tlp_mem_io_msg_cpl_conf)(),
// /* input    logic */                                      .MSG_tlp_address_32_64(),       //fmt[0]      //tlp_address_32_64(tlp_address_32_64)(),
// /* input    logic */                                      .MSG_tlp_read_write(),          //fmt[1]      // tlp_read_write(tlp_read_write)(),
// //----------------------------------------------.-----    ----------------------- (4)
// /* input    logic    [2:0] */                             .MSG_TC(),                      //TC(TC)(), 
// /* input    logic    [2:0] */                             .MSG_ATTR(),                    //ATTR(ATTR)(), 
// //----------------------------------------------.-----    ------------------(6)
// /* input    logic    [15:0] */                            .MSG_requester_id(),            //[[MSG]]  -- //COMPLETER ID //device_id(device_id)(),
// /* input    logic    [7:0]  */                            .MSG_tag(),                     //[[MSG]]tag(tag)(),
// /* input    logic    [11:0] */                            .MSG_byte_count(),              //byte_count(byte_count)(),
// //----------------------------------------------.-----    ------------------(36)           
// /* input    logic    [6:0] */                             .MSG_lower_addr(),              //[[MSG]]       //lower_addr(lower_addr)(),
// /* input    logic    [2:0] */                             .MSG_completion_status(),
// //----------------------------------------------.-----    ------------------(7)
// /* input    logic    [31:0] */                            .MSG_data1(),                 //data1(data1)(),
// /* input    logic    [31:0] */                            .MSG_data2(),                 //data2(data2)(),
// /* input    logic    [31:0] */                            .MSG_data3(),                 //data3(data3) (),  
// ////////////////////////////////////////////////./////    ////////////////////////////////////////
// /* input    logic */                                      .MSG_ARB_VALID(),           ////////////////////////////////
// /* output   logic */                                      .MSG_ARB_ACK(),            ////////////////////////////////
// ////////////////////////////////////////////////.//////////////////////////////////////////






// //---------------------------------------------------------------------------(1)
// /* output    logic */                             .RX_B_TX_DATA_FIFO_WR_EN(RX_B_TX_DATA_FIFO_WR_EN),
// /* output    logic [31:0] */                      .RX_B_TX_DATA_FIFO_data(RX_B_TX_DATA_FIFO_data),
// //---------------------------------------------------------------------------(1)
// //---------------------------------------------------------------------------(1)

// /* output    logic       */                     .NP_RDEN(NP_RDEN),
// /* output    logic [7:0] */                     .NP_TAG_IDX(NP_TAG_IDX),
// /* output    logic [15:0]*/                     .NP_DEST_IDX(NP_DEST_IDX),
// /* input     logic */                           .NP_REQ_EXIST(NP_REQ_EXIST)





// );


// /* TL_RX_ERROR_CHECK */ TL_RX_ERROR_CHECK128 #(.DATA_WIDTH(32)) tl_rx_error_check
// (
//     /* input   logic */                         .clk(clk),
//     /* input   logic */                         .rst(rst),

// ///////////FROM DL///////////////////////
//     /* input  logic   [31:0] */                 .TLP(OUT_TLP_DW),
//     /* input  logic */                          .new_tlp_ready(new_tlp_ready), 
//     /* input  logic */                          .valid(valid_tlp),
// ///////////P_NP_CPL BUFFER////////////////////
// //Write (H||D)(), Read (H)

//     // input   logic                          TLP_BUFFER_EMPTY(),
//     /* output  logic */                       .HEADER_DATA(RX_HEADER_DATA), // 0: Header; 1: Data
//     /* output  logic [1:0] */                 .P_NP_CPL(RX_P_NP_CPL), // Posted: 00; Non-Posted: 01; Completion: 11
//     // /* output  logic [DATA_WIDTH-1:0] */      .IN_TLP_DW(RX_IN_TLP_DW),
//     /* output  logic */                       .WR_EN(RX_WR_EN),
//     /* output  logic */                       .flush(RX_flush),
//     /* output  logic */                       .commit(RX_commit),
//     // output  logic                       TLP_BUFFER_RD_EN(), //Not Busy
//     ////////////////////////////////////
//     // output  logic                       DATA_BUFFER_WR_EN(),          
//     ////////////////////////////////////
//     // /* output  logic  [2:0] */     .tlp_mem_io_msg_cpl_conf(),
//     // /* output  logic */            .tlp_address_32_64(),
//     // /* output  logic */            .tlp_read_write(),
//     //  //output  logic               tlp_conf_type(),
//     // /* output  logic  [11:0] */    .cpl_byte_count(),
//     // /* output  logic  [6:0] */     .cpl_lower_address(),
//     // /* output  logic  [3:0] */     .first_dw_be(),
//     // /* output  logic  [3:0] */     .last_dw_be(),
//     // /* output  logic  [31:0] */    .lower_addr(),
//     // /* output  logic  [31:0] */    .upper_addr(),
//     // /* output  logic  [31:0] */    .data(),
//     // /* output  logic  [11:0] */    .config_dw_number()


//         //------------------------------------------------------------------------------------
//     //------------------------------------------------------------------------------------
//     //------------------------------------------------------------------------------------
//     /* output    logic         */                      .NP_RDEN     (NP_RDEN),
//     /* output    logic  [7:0]  */                      .NP_TAG_IDX  (NP_TAG_IDX),
//     /* output    logic  [15:0] */                      .NP_DEST_IDX (NP_DEST_IDX),
//     /* input   logic         */                        .NP_REQ_EXIST(NP_REQ_EXIST)
// );


// RX_PNPC_BUFF #(.DATA_WIDTH(BUS_WIDTH)) PNPC_BUFF0
// (
//     .clk(clk),                            //input  logic                     clk,
//     .rst(rst),                            //input  logic                     rst,
//     .HEADER_DATA(RX_HEADER_DATA),            //input  logic                     HEADER_DATA, // 0: Header, 1: Data
//     .P_NP_CPL(RX_P_NP_CPL),                  //input  logic [1:0]               P_NP_CPL, // Posted: 00, Non-Posted: 01, Completion: 11
//     .IN_TLP_DW(OUT_TLP_DW),                //input  logic [DATA_WIDTH-1:0]    IN_TLP_DW
//     .WR_EN(RX_WR_EN),              //input  logic                     WrEn,
//     .RD_EN(RX_RD_EN),                        //input  logic                     RdEn,
//     .commit(RX_commit),
//     .flush(RX_flush),
//     .EMPTY(RX_ALL_BUFFS_EMPTY),
//     .OUT_TLP_DW(),               //output logic [DATA_WIDTH-1:0]    OUT_TLP_DW     
//     .OUT_TLP_DW_COMB(RX_OUT_TLP_DW) ,
//     .P_H_CREDIT(),//output logic  [9:0]
//     .P_D_CREDIT(),//output logic  [9:0]
//     .NP_H_CREDIT(),//output logic  [9:0]
//     .NP_D_CREDIT(),//output logic  [9:0]
//     .CPL_H_CREDIT(),//output logic  [9:0]
//     .CPL_D_CREDIT()    //output logic  [9:0] 
// );

// /* TL_RX_DECODER */TL_RX_DECODER128 tl_rx_decoder
// (
//     .clk(clk),
//     .rst(rst),
    
//     .TLP(RX_OUT_TLP_DW),// input  logic   [31:0]   TLP,
//     .TLP_BUFFER_EMPTY(RX_ALL_BUFFS_EMPTY),// input  logic            TLP_BUFFER_EMPTY,
//     .TLP_BUFFER_RD_EN(RX_RD_EN),// output logic            TLP_BUFFER_RD_EN,
    
    
//     .DATA_BUFFER_WR_EN(DATA_BUFFER_WR_EN),// output logic            DATA_BUFFER_WR_EN,          
    


//     .tlp_mem_io_msg_cpl_conf(rx_tlp_mem_io_msg_cpl_conf),// output  logic  [2:0]     tlp_mem_io_msg_cpl_conf,
//     .tlp_address_32_64(rx_tlp_address_32_64),// output  logic            tlp_address_32_64,
//     .tlp_read_write(rx_tlp_read_write),// output  logic            tlp_read_write,
//     // //output  logic            tlp_conf_type,

//     .cpl_byte_count(rx_cpl_byte_count),// output  logic  [11:0]    cpl_byte_count,
//     .cpl_lower_address(rx_cpl_lower_address),// output  logic  [6:0]     cpl_lower_address,

//     .first_dw_be(rx_first_dw_be),  // output  logic  [3:0]     first_dw_be,
//     .last_dw_be(rx_last_dw_be),    // output  logic  [3:0]     last_dw_be,
//     .requester_id(rx_requester_id),
//     .tag(rx_tag),

//     .lower_addr(rx_lower_addr),            // output  logic  [31:0]    lower_addr,
//     .upper_addr(rx_upper_addr),            // output  logic  [31:0]    upper_addr,
//     .tlp_length (rx_tlp_length),
//     .config_dw_number(rx_config_dw_number),// output  logic  [11:0]    config_dw_number,

//     .data(rx_data),                        // output  logic  [31:0]    data,





//     // Interface With Master
//     .M_READY(M_READY), // input  logic            M_READY
//     .M_ENABLE(M_ENABLE)// output logic            M_ENABLE,

// );






// FIFO DATA_BUFFER
// (
//     .clk            (clk),//input  logic        clk, 
//     .rst            (rst),//input  logic        rst,
//     .WrEn           (DATA_BUFFER_WR_EN),//input  logic        DATA_BUFF_WR_EN, 
//     .RdEn           (DATA_BUFF_RD_EN),//input  logic        DATA_BUFF_RD_EN,
//     .DataIn         (rx_data),//input  logic [DATA_WIDTH-1:0] DATA_BUFF_DATA_IN,
//     // .DataOut        (),//output logic [DATA_WIDTH-1:0] DATA_BUFF_DATA_OUT,
//     .comb_DataOut   (DATA_BUFF_COMB_DATA_OUT), //output logic [DATA_WIDTH-1:0] DATA_BUFF_COMB_DATA_OUT
//     .Full           (),//output logic        DATA_BUFF_Full, 
//     .Empty          (DATA_BUFF_EMPTY),//output logic        DATA_BUFF_Empty 
//     .AlmostEmpty    (last_dw)
// ); 




// AXI_MASTER #(.ADDR_WIDTH(ADDR_WIDTH), .DATA_WIDTH(DATA_WIDTH)) axi_master
// (   
//     // Global Signals 
//     /* input logic */                            .aclk(clk),
//     /* input logic */                            .aresetn(rst),
    
//                                                  .VALID(M_ENABLE),
//                                                  .ACK(M_READY),

//             .tlp_mem_io_msg_cpl_conf(rx_tlp_mem_io_msg_cpl_conf),   //     input  logic  [2:0]     tlp_mem_io_msg_cpl_conf,
//             .tlp_address_32_64(rx_tlp_address_32_64),               //     input  logic            tlp_address_32_64,
//             .tlp_read_write(rx_tlp_read_write),                     //     input  logic            tlp_read_write,

// /* input  logic  [15:0] */ .requester_id(rx_requester_id),
// /* input  logic  [7:0]  */ .tag(rx_tag),       
//             .first_dw_be(rx_first_dw_be),   //     input  logic  [3:0]     first_dw_be,
//             .last_dw_be(rx_last_dw_be),     //     input  logic  [3:0]     last_dw_be,
//             .lower_addr(rx_lower_addr),     //     input  logic  [31:0]    lower_addr,

//             // //calculate OFFSET and M_PSTRB
//             .length(rx_tlp_length),
//             .data(DATA_BUFF_COMB_DATA_OUT),        //     input  logic  [31:0]    data,
//             .last_dw(last_dw),                     //     input  logic            last_dw,

//             .DATA_BUFF_EMPTY(DATA_BUFF_EMPTY),     //     input logic            DATA_BUFF_EMPTY,
//             .DATA_BUFF_RD_EN(DATA_BUFF_RD_EN),     //     output logic            DATA_BUFF_RD_EN,

//             .config_dw_number(rx_config_dw_number),//     input  logic  [9:0]     config_dw_number,
                


//     // AW Channel
//     /* output logic [ADDR_WIDTH-1:0] */           .awaddr(awaddr),
//     /* output logic [7:0] */                      .awlen(awlen),  // number of transfers in transaction
//     /* output logic [2:0] */                      .awsize(awsize),  // number of bytes in transfer  //                            000=> 1, 001=>2, 010=>4, 011=>8, 100=>16, 101=>32, 110=>64, 111=>128
//     /* output logic [1:0] */                      .awburst(awburst),
//     /* input  logic */                            .awready(awready),
//     /* output logic */                            .awvalid(awvalid),

//     // W Channel
//     /* output logic [DATA_WIDTH-1:0] */           .wdata(wdata), 
//     /* output logic [(DATA_WIDTH/8)-1:0] */       .wstrb(wstrb), 
//     /* output logic */                            .wlast(wlast), 
//     /* output logic */                            .wvalid(wvalid),
//     /* input  logic */                            .wready(wready),

//     // B Channel
//     /* input  logic [1:0] */                      .bresp(bresp),                         
//     /* input  logic */                            .bvalid(bvalid),                         
//     /* output logic */                            .bready(bready),                         

//     // AR Channel
//     /* output logic [ADDR_WIDTH-1:0] */           .araddr(araddr),
//     /* output logic [7:0] */                      .arlen(arlen),
//     /* output logic [2:0] */                      .arsize(arsize),
//     /* output logic [1:0] */                      .arburst(arburst),
//     /* input  logic */                            .arready(arready),
//     /* output logic */                            .arvalid(arvalid),
                                            

//     // R Channel                            
//     /* input  logic [DATA_WIDTH-1:0] */           .rdata(rdata),
//     /* input  logic [1:0] */                      .rresp(rresp),
//     /* input  logic */                            .rlast(rlast),
//     /* input  logic */                            .rvalid(rvalid),
//     /* output logic */                            .rready(rready),
//     // ----------------------------------------------------------------------
//     // ----------------------------------------------------------------------
//             .RX_B_tlp_read_write(RX_B_tlp_read_write),
//             .RX_B_TC(RX_B_TC),
//             .RX_B_ATTR(RX_B_ATTR),
//             .RX_B_tag(RX_B_tag),
//             .RX_B_requester_id(RX_B_requester_id),
//             .RX_B_byte_count(RX_B_byte_count),
//             .RX_B_lower_addr(RX_B_lower_addr),
//             .RX_B_completion_status(RX_B_completion_status),
//     //-----------------------------------------------------------------------------------------           
//     /* input   logic    [31:0] */ .RX_B_data1(RX_B_data1),                 //
//     /* input   logic    [31:0] */ .RX_B_data2(RX_B_data2),                 //
//     /* input   logic    [31:0] */ .RX_B_data3(RX_B_data3),                 //
// //-----------------------------------------------------------------------------------------                   
//     /* input   logic           */ .RX_B_Wr_En(RX_B_Wr_En),                  //
// //-----------------------------------------------------------------------------------------
//     // ----------------------------------------------------------------------
//     // ----------------------------------------------------------------------

//     /////////////////////////////////////////////////////
//     ////////////////////FIFO TX/////////////////////////
//     /////////////////////////////////////////////////////

//     /* output logic                */ .RX_B_TX_DATA_FIFO_WR_EN(RX_B_TX_DATA_FIFO_WR_EN),
//     /* output logic [31:0]         */ .RX_B_TX_DATA_FIFO_data(RX_B_TX_DATA_FIFO_data)

//     /////////////////////////////////////////////////////
//     /////////////////////////////////////////////////////

// ); 


AXI_SLAVE #(.ADDR_WIDTH(ADDR_WIDTH), .DATA_WIDTH(DATA_WIDTH)) axi_slave
(
    // Global Signals 
    /* input logic */                              .aclk(clk),
    /* input logic */                              .aresetn(rst),

    // AW Channel
    /* input   logic [ADDR_WIDTH-1:0] */           .awaddr(awaddr),  
    /* input   logic [7:0] */                      .awlen(awlen),   // number of transfers in transaction
    /* input   logic [2:0] */                      .awsize(awsize),  // number of bytes in transfer // 000=> 1, 001=>2, 010=>4, 011=>8, 100=>16, 101=>32, 110=>64, 111=>128
    /* input   logic [1:0] */                      .awburst(awburst),  
    /* output  logic */                            .awready(awready), 
    /* input   logic */                            .awvalid(awvalid), 

    // W Channel
    /* input   logic [DATA_WIDTH-1:0] */           .wdata(wdata), 
    /* input   logic [(DATA_WIDTH/8)-1:0] */       .wstrb(wstrb), 
    /* input   logic */                            .wlast(wlast), 
    /* input   logic */                            .wvalid(wvalid),
    /* output  logic */                            .wready(wready),

    // B Channel
    /* output  logic [1:0] */                      .bresp(bresp),                           
    /* output  logic */                            .bvalid(bvalid),                         
    /* input   logic */                            .bready(bready),                          

    // AR Channel
    /* input   logic [ADDR_WIDTH-1:0] */           .araddr(araddr),
    /* input   logic [7:0] */                      .arlen(arlen),
    /* input   logic [2:0] */                      .arsize(arsize),
    /* input   logic [1:0] */                      .arburst(arburst),
    /* output  logic */                            .arready(arready),
    /* input   logic */                            .arvalid(arvalid),
                                            

    // R Channel                            
    /* output  logic [DATA_WIDTH-1:0] */           .rdata(rdata),
    /* output  logic [1:0] */                      .rresp(rresp),
    /* output  logic */                            .rlast(rlast),
    /* output  logic */                            .rvalid(rvalid),
    /* input   logic */                            .rready(rready)

    //------------------------------------------------------------------------
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
bit [31:0] data_arr [] = new [3];
int max=0;
task send_req_packet(int tlp_type_, int tlp_read_write_, int byte_count_, int address_, int tag_, int device_id_=0, int data1_, int data2_ = 0, int data3_ =0);
    bit b_tlp_read_write;
    bit [11:0] b_byte_count;
    bit [31:0] b_address;
    req_tlp_mem_io_msg_cpl_conf <= tlp_type_;        //0: memory, 1: io, 2: completion
    req_tlp_address_32_64  <= 0;          //0: 32-bit, 1: 64-bit
    req_tlp_read_write     <= tlp_read_write_;       //0: read, 1: write

    //Number Of Written Bytes 
    req_byte_count <= byte_count_;
    
    //Destination
    req_lower_addr <= address_;    
    req_upper_addr <= 32'h0000_0000; 

    req_dest_bdf_id <= 16'h0000;
    req_config_dw_number <= 10'd0;

    req_tag <= tag_;

    b_tlp_read_write = tlp_read_write_;
    b_byte_count = byte_count_;
    b_address = address_;
    REQ_addr  <= 32'h0;
    REQ_rd_wr <= 1;
    REQ_data  <= {b_byte_count, b_tlp_read_write, 1'b0, 2'b00};
    REQ_valid <= 1;
    @(posedge clk);
    REQ_addr  <= 32'h4;
    REQ_rd_wr <= 1;
    REQ_data  <= b_address;
    REQ_valid <= 1;
    @(posedge clk);


    max = ((byte_count_-1)>>2) + 1;
    data_arr[0] = data1_;
    data_arr[1] = data2_;
    data_arr[2] = data3_;
for(int x = 0; x < max/* 3 */; x++)
    begin
        REQ_addr  <= 32'h14;
        REQ_rd_wr <= 1;
        REQ_data  <= data_arr[x]/* data_arr[x] */;
        REQ_valid <= 1;
        // REQ_WR_EN = 1;
        @(posedge clk);
    end


    REQ_addr  <= 32'h10;
    REQ_data  <= 1;
    REQ_valid<=1;
    @(posedge clk);
    REQ_valid<=0;

    // req_device_id <= device_id_;



    req_data1 <= data1_;
    req_data2 <= data2_;
    req_data3 <= data3_;
    begin

    // REQ_WR_EN = 0; 
    // for(int x = 0; x < max/* 3 */; x++)
    // begin
    //     REQ_data  = data_arr[x]/* data_arr[x] */;
    //     REQ_WR_EN = 1;
    //     @(posedge clk);
    // end
    // REQ_WR_EN = 0;
    @(posedge clk);
    end

    req_valid <= 1;         //Initiate Transaction Generation FSM
    wait(fsm_started);
    wait(fsm_finished);
    req_valid <= 0; 
    @(posedge clk);

endtask

initial begin


    reset();
    RD_EN <= 1;
    //(1) #################### POSTED MEMORY 2-BYTES MEMORY WRITE TLP ##########################
    send_req_packet(.tlp_type_(0), .tlp_read_write_(1), .byte_count_(8), .address_(32'h00_00_00_00), .tag_(1), .data1_(32'h0003_0007)
    ,.data2_(32'h0001_0000));

    send_req_packet(.tlp_type_(0), .tlp_read_write_(1), .byte_count_(4), .address_(32'h00_00_00_00),  .tag_(2), .data1_(32'h0004_0004)
    ,.data2_(32'h0001_0000));

    send_req_packet(.tlp_type_(0), .tlp_read_write_(1), .byte_count_(4), .address_(32'h00_00_00_04),  .tag_(2), .data1_(32'h0001_0000)
    ,.data2_(32'h0001_0000));

    

    send_req_packet(.tlp_type_(0), .tlp_read_write_(1), .byte_count_(4), .address_(32'h00_00_00_00),  .tag_(2), .data1_(32'h0003_0002)
    ,.data2_(32'h0001_0000));

    send_req_packet(.tlp_type_(0), .tlp_read_write_(1), .byte_count_(4), .address_(32'h00_00_00_04),  .tag_(2), .data1_(32'h0001_0000)
    ,.data2_(32'h0001_0000));


    send_req_packet(.tlp_type_(0), .tlp_read_write_(1), .byte_count_(4), .address_(32'h00_00_00_00),  .tag_(2), .data1_(32'h0001_0001)
    ,.data2_(32'h0001_0000));

    send_req_packet(.tlp_type_(0), .tlp_read_write_(1), .byte_count_(4), .address_(32'h00_00_00_04),  .tag_(2), .data1_(32'h0001_0000)
    ,.data2_(32'h0001_0000));

    send_req_packet(.tlp_type_(0), .tlp_read_write_(1), .byte_count_(4), .address_(32'h00_00_00_00),  .tag_(2), .data1_(32'h000a_0002)
    ,.data2_(32'h0001_0000));

    send_req_packet(.tlp_type_(0), .tlp_read_write_(1), .byte_count_(4), .address_(32'h00_00_00_04),  .tag_(2), .data1_(32'h0001_0000)
    ,.data2_(32'h0001_0000));


    send_req_packet(.tlp_type_(0), .tlp_read_write_(0), .byte_count_(20), .address_(32'h00_00_00_08),  .tag_(3), .data1_(32'h0003_0007)
    ,.data2_(32'h0001_0000), .data3_(32'h0001_0001));
    // send_req_packet(.tlp_type_(0), .tlp_read_write_(1), .byte_count_(4), .address_(32'h00_00_00_04), .data1_(32'h0100_0200)
    // ,.data2_(32'h0000_0001));
    
    // send_req_packet(.tlp_type_(0), .tlp_read_write_(1), .byte_count_(1), .address_(32'h00_00_00_06), .data1_(32'h0000_0001)
    // ,.data2_(32'h0000_0000));
    @(posedge clk);
    @(posedge clk);
    // send_req_packet(.tlp_type_(0), .tlp_read_write_(1), .byte_count_(1), .address_(32'h00_00_00_06), .data1_(32'h0000_0001)
    // ,.data2_(32'h0000_0001));
    
    // //(2) #################### POSTED MEMORY 2-BYTES 32-BIT MEMORY WRITE TLP #########################
    // @(posedge clk);
    // send_req_packet(.tlp_type_(0), .tlp_read_write_(1), .byte_count_(2), .address_(32'h00_00_00_02), .data1_(32'h05));
    
    // //(3) #################### POSTED MEMORY 2-BYTES 32-BIT MEMORY WRITE TLP #########################
    // @(posedge clk);
    // send_req_packet(.tlp_type_(0), .tlp_read_write_(1), .byte_count_(2), .address_(32'h00_00_00_04), .data1_(32'h00));

    // //(3) #################### POSTED MEMORY 2-BYTES 32-BIT MEMORY WRITE TLP #########################
    // @(posedge clk);
    // send_req_packet(.tlp_type_(0), .tlp_read_write_(1), .byte_count_(2), .address_(32'h00_00_00_06), .data1_(32'h01));



    // while(!M_PREADY1)
    // begin
    //     @(posedge clk);

    // end

    

    repeat(125)
        @(posedge clk);

    // @(posedge clk);
    // @(posedge clk);
    // @(posedge clk);
    $stop; 
end


endmodule