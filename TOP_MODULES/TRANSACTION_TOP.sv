module TRANSACTION_TOP#(parameter ADDR_WIDTH = 32, DATA_WIDTH = 32)(
    input  logic                       clk,
    input  logic                       rst,
                                
    //DATA LINK INTERFACE          
    input  logic                       RD_EN,
    output logic                       VALID_FOR_DL,
    output logic                       ALL_BUFFS_EMPTY,
    output logic   [31:0]              OUT_TLP_DW,
    output logic                       fsm_finished,
    output logic                       TL_TX_ACK,

    // ---------------------------------------------------------------------------
    // TL - APPLICATION LAYER INTERFACE
    // ---------------------------------------------------------------------------
    input    logic    [2:0]                        REQ_tlp_mem_io_msg_cpl_conf,
    input    logic                                 REQ_tlp_address_32_64,
    input    logic                                 REQ_tlp_read_write,
    input    logic    [2:0]                        REQ_TC,
    input    logic    [2:0]                        REQ_ATTR,
    input    logic    [15:0]                       REQ_requester_id,
    input    logic    [7:0]                        REQ_tag,
    input    logic    [11:0]                       REQ_byte_count,
    input    logic    [31:0]                       REQ_lower_addr,
    input    logic    [31:0]                       REQ_upper_addr,
    input    logic    [15:0]                       REQ_dest_bdf_id,
    // /* input */   logic    [UPGRADED_DATA_WIDTH-1:0]    REQ_data,
    input    logic    [31:0]                       REQ_data1,
    input    logic    [31:0]                       REQ_data2,
    input    logic    [31:0]                       REQ_data3,

    input    logic    [9:0]                        REQ_config_dw_number,
    input    logic    [2:0]                        REQ_completion_status,
    input    logic    [7:0]                        REQ_message_code,
    input    logic                                 REQ_valid,






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



    input   logic [31:0]                    IN_TLP_DW,
    input   logic                           new_tlp_ready,
    input   logic                           valid_tlp

);




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
/* output */   logic    [2:0]            CPL_completion_status;
//---------------------------------------------------------------------------(7)
/* output */   logic    [31:0]           CPL_data1;                 //.data1(data1);
/* output */   logic    [31:0]           CPL_data2;                 //.data2(data2);
/* output */   logic    [31:0]           CPL_data3;                 //.data3(data3) ;  



//////////////////////////////////////////////////////////////////////////////////////////////
/* input */   logic                             CPL_ARB_ACK;      ////////////////////////////
/* output */  logic                             CPL_ARB_VALID;   ////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////
TRANSACTION_TX_TOP transaction_tx_top (
/* input  logic                        */.clk(clk),
/* input  logic                        */.rst(rst),
                               
//DATA LINK INTERFACE          
/* input  logic                        */.RD_EN(RD_EN),
/* output logic                        */.VALID_FOR_DL(VALID_FOR_DL),
/* output logic                        */.ALL_BUFFS_EMPTY(ALL_BUFFS_EMPTY),
/* output logic   [31:0]               */.OUT_TLP_DW(OUT_TLP_DW),
/* output logic                        */.fsm_finished(fsm_finished),
/* output logic                        */.TL_TX_ACK(TL_TX_ACK),


//FROM RX ERROR DETECTION TO TX MASTER

//\\\\\\\\\\\\\\\\\\\\\\\\\\\                 //////////////////////////////\\
 //\\\\\\\\\\\\\\\\\\\\\\\\\\\               //////////////////////////////\\
  //\\\\\\\\\\\\\\\\\\\\\\\\\\\             //////////////////////////////\\

//FROM RX MASTER to TX MASTER
/* input    logic    [2:0]             */.CPL_tlp_mem_io_msg_cpl(CPL_tlp_mem_io_msg_cpl),   //tlp_mem_io_msg_cpl_conf(tlp_mem_io_msg_cpl_conf)(),
/* input    logic                      */.CPL_tlp_address_32_64(CPL_tlp_address_32_64),    //fmt[0]      //tlp_address_32_64(tlp_address_32_64)(),
/* input    logic                      */.CPL_tlp_read_write(CPL_tlp_read_write),       //fmt[1]      // tlp_read_write(tlp_read_write)(),
//-------------------------------------------------------------------------- (4)
/* input    logic    [2:0]             */.CPL_TC(CPL_TC),                      //TC(TC)(), 
/* input    logic    [2:0]             */.CPL_ATTR(CPL_ATTR),                    //ATTR(ATTR)(), 
//---------------------------------------------------------------------------(6)
/* input    logic    [15:0]            */.CPL_requester_id(CPL_requester_id),            //[[CPL]]  -- //COMPLETER ID //device_id(device_id)(),
/* input    logic    [7:0]             */.CPL_tag(CPL_tag),                     //[[CPL]]tag(tag)(),
/* input    logic    [11:0]            */.CPL_byte_count(CPL_byte_count),              //byte_count(byte_count)(),
//---------------------------------------------------------------------------(36)           
/* input    logic    [6:0]             */.CPL_lower_addr(CPL_lower_addr),              //[[CPL]]       //lower_addr(lower_addr)(),
/* input    logic    [2:0]             */.CPL_completion_status(CPL_completion_status),
//---------------------------------------------------------------------------(7)
/* input    logic    [31:0]            */.CPL_data1(CPL_data1),                 //data1(data1)(),
/* input    logic    [31:0]            */.CPL_data2(CPL_data2),                 //data2(data2)(),
/* input    logic    [31:0]            */.CPL_data3(CPL_data3),                 //data3(data3) (),  

////////////////////////////////////////////////////////////////////////////////////////////////
/* input    logic                      */.CPL_ARB_VALID(CPL_ARB_VALID),                    //////////////////////////
/* output   logic                      */.CPL_ARB_ACK(CPL_ARB_ACK),                     //////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////




/* input    logic    [2:0]             */.MSG_tlp_mem_io_msg_cpl(MSG_tlp_mem_io_msg_cpl), //type // tlp_mem_io_msg_cpl_conf(tlp_mem_io_msg_cpl_conf)(),
/* input    logic                      */.MSG_tlp_address_32_64(MSG_tlp_address_32_64),       //fmt[0]      //tlp_address_32_64(tlp_address_32_64)(),
/* input    logic                      */.MSG_tlp_read_write(MSG_tlp_read_write),          //fmt[1]      // tlp_read_write(tlp_read_write)(),
//-------------------------------------------------------------------------- (4)
/* input    logic    [2:0]             */.MSG_TC(MSG_TC),                      //TC(TC)(), 
/* input    logic    [2:0]             */.MSG_ATTR(MSG_ATTR),                    //ATTR(ATTR)(), 
//---------------------------------------------------------------------------(6)
/* input    logic    [15:0]            */.MSG_requester_id(MSG_requester_id),            //[[MSG]]  -- //COMPLETER ID //device_id(device_id)(),
/* input    logic    [7:0]             */.MSG_tag(MSG_tag),                     //[[MSG]]tag(tag)(),
/* input    logic    [11:0]            */.MSG_byte_count(MSG_byte_count),              //byte_count(byte_count)(),
//---------------------------------------------------------------------------(36)           
/* input    logic    [6:0]             */.MSG_lower_addr(MSG_lower_addr),              //[[MSG]]       //lower_addr(lower_addr)(),
/* input    logic    [2:0]             */.MSG_completion_status(MSG_completion_status),
//---------------------------------------------------------------------------(7)
/* input    logic    [31:0]            */.MSG_data1(MSG_data1),                 //data1(data1)(),
/* input    logic    [31:0]            */.MSG_data2(MSG_data2),                 //data2(data2)(),
/* input    logic    [31:0]            */.MSG_data3(MSG_data3),                 //data3(data3) (),  
/////////////////////////////////////////////////////////////////////////////////////////////
/* input    logic                      */.MSG_ARB_VALID(MSG_ARB_VALID),           ////////////////////////////////
/* output   logic                      */.MSG_ARB_ACK(MSG_ARB_ACK),             ////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////



// ---------------------------------------------------------------------------
// 
// ---------------------------------------------------------------------------
/* input    logic    [2:0]                         */.REQ_tlp_mem_io_msg_cpl_conf(REQ_tlp_mem_io_msg_cpl_conf),
/* input    logic                                  */.REQ_tlp_address_32_64(REQ_tlp_address_32_64),
/* input    logic                                  */.REQ_tlp_read_write(REQ_tlp_read_write),
/* input    logic    [2:0]                         */.REQ_TC(REQ_TC),
/* input    logic    [2:0]                         */.REQ_ATTR(REQ_ATTR),
/* input    logic    [15:0]                        */.REQ_requester_id(REQ_requester_id),
/* input    logic    [7:0]                         */.REQ_tag(REQ_tag),
/* input    logic    [11:0]                        */.REQ_byte_count(REQ_byte_count),
/* input    logic    [31:0]                        */.REQ_lower_addr(REQ_lower_addr),
/* input    logic    [31:0]                        */.REQ_upper_addr(REQ_upper_addr),
/* input    logic    [15:0]                        */.REQ_dest_bdf_id(REQ_dest_bdf_id),
// /* input */.   logic    [UPGRADED_DATA_WIDTH-1:0]    REQ_data(),
/* input    logic    [31:0]                        */.REQ_data1(REQ_data1),
/* input    logic    [31:0]                        */.REQ_data2(REQ_data2),
/* input    logic    [31:0]                        */.REQ_data3(REQ_data3),

/* input    logic    [9:0]                         */.REQ_config_dw_number(REQ_config_dw_number),
/* input    logic    [2:0]                         */.REQ_completion_status(REQ_completion_status),
/* input    logic    [7:0]                         */.REQ_message_code(REQ_message_code),
/* input    logic                                  */.REQ_valid(REQ_valid)
// ---------------------------------------------------------------------------
// ---------------------------------------------------------------------------

);


TX_NP_REQ_BUFF #(.TIMEOUT(50_000),.PERIOD(10), .DATA_WIDTH(32), .MEMORY_DEPTH(16)) tx_np_req_buff
(
/* input   logic */          .clk(clk),
/* input   logic */          .rst(rst),

/* input   logic */          .WR_EN(),
/* input   logic */          .RD_EN(),

//SEL
/* input   logic   [7:0] */  .TAG(),

/* input   logic   [7:0] */  .DEST(),
// input   logic  [14:0]  START_TIME,
// input   logic          EXIST

/* output  logic */          .EXIST(),



/* output  logic */          .EMPTY(),

/* output  logic */          .FULL(),

/* output  logic    [31:0] */ .OUT()

);


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
/* input   logic                         */.ACK(CPL_ARB_ACK),    ///////////////////////////////
/* output  logic                         */.VALID(CPL_ARB_VALID)   ////////////////////////////
    //////////////////////////////////////////////////////////////////////////////////////////
);

TRANSACTION_RX_TOP #(.DATA_WIDTH(32), .ADDR_WIDTH(32) )(

// DL-TL Interface
/* input   logic                .*/.clk(clk),
/* input   logic                .*/.rst(rst),
/* input   logic [31:0]         .*/.IN_TLP_DW(IN_TLP_DW),
/* input   logic                */.new_tlp_ready(new_tlp_ready),
/* input   logic                */.valid_tlp(valid_tlp),



//AXI Interface
/* output  logic [ADDR_WIDTH-1:0]           */.awaddr(awaddr),
/* output  logic [7:0]                      */.awlen(awlen),   // number of transfers in transaction
/* output  logic [2:0]                      */.awsize(awsize),  // number of bytes in transfer  //                            000=> 1(), 001=>2(), 010=>4(), 011=>8(), 100=>16(), 101=>32(), 110=>64(), 111=>128
/* output  logic [1:0]                      */.awburst(awburst),
/* input   logic                            */.awready(awready),
/* output  logic                            */.awvalid(awvalid),

// W Channel
/* output logic [DATA_WIDTH-1:0]            */.wdata(wdata), 
/* output logic [(DATA_WIDTH/8)-1:0]        */.wstrb(wstrb), 
/* output logic                             */.wlast(wlast), 
/* output logic                             */.wvalid(wvalid),
/* input  logic                             */.wready(wready),

// B Channel
/* input  logic [1:0]                       */.bresp(bresp),                         
/* input  logic                             */.bvalid(bvalid),                         
/* output logic                             */.bready(bready),                         

// AR Channel
/* output logic [ADDR_WIDTH-1:0]            */.araddr(araddr),
/* output logic [7:0]                       */.arlen(arlen),
/* output logic [2:0]                       */.arsize(arsize),
/* output logic [1:0]                       */.arburst(arburst),
/* input  logic                             */.arready(arready),
/* output                                   */.arvalid(arvalid),
                                        

// R Channel                            
/* input   logic [DATA_WIDTH-1:0]           */.rdata(rdata),
/* input   logic [1:0]                      */.rresp(rresp),
/* input   logic                            */.rlast(rlast),
/* input   logic                            */.rvalid(rvalid),
/* output  logic                            */.rready(rready),

//Internal Native Interface (FROM AXI MASTER TO TL_TX)
/* output  logic                      */.RX_B_tlp_read_write(RX_B_tlp_read_write),          //
/* output  logic    [2:0]             */.RX_B_TC(RX_B_TC),               //
/* output  logic    [2:0]             */.RX_B_ATTR(RX_B_ATTR),             //
/* output  logic    [15:0]            */.RX_B_requester_id(RX_B_requester_id),        //
/* output  logic    [7:0]             */.RX_B_tag(RX_B_tag),              //
/* output  logic    [11:0]            */.RX_B_byte_count(RX_B_byte_count),       //

//--------------------------------------------------------------------------------------
/* output  logic    [6:0]             */.RX_B_lower_addr(RX_B_lower_addr),       //
/* output  logic    [2:0]             */.RX_B_completion_status(RX_B_completion_status),
//----------------------------------------------------------------------------------------- 
//-----------------------------------------------------------------------------------------          
/* output  logic    [31:0]            */.RX_B_data1(RX_B_data1),                 //
/* output  logic    [31:0]            */.RX_B_data2(RX_B_data2),                 //
/* output  logic    [31:0]            */.RX_B_data3(RX_B_data3),                 //
//-----------------------------------------------------------------------------------------                   
/* output  logic                      */.RX_B_Wr_En(RX_B_Wr_En),                  //
//-----------------------------------------------------------------------------------------

//Internal Native Interface (FROM ERROR DETECTION TO TL_TX)
//-------------------------------------------------------------------------- (4)
/* output   logic    [2:0]             */.ERR_CPL_TC(ERR_CPL_TC),                      //.TC(TC);
/* output   logic    [2:0]             */.ERR_CPL_ATTR(ERR_CPL_ATTR),                    //.ATTR(ATTR);
//---------------------------------------------------------------------------(6)
/* output   logic    [15:0]            */.ERR_CPL_requester_id(ERR_CPL_requester_id),            //[[X]]  -- //COMPLETER ID 
/* output   logic    [7:0]             */.ERR_CPL_tag(ERR_CPL_tag),                    //[[X]].
/* output   logic    [11:0]            */.ERR_CPL_byte_count(ERR_CPL_byte_count),              //

//---------------------------------------------------------------------------(36)           
/* output   logic    [6:0]             */.ERR_CPL_lower_addr(ERR_CPL_lower_addr),              //[[X]]
/* output   logic    [2:0]             */.ERR_CPL_completion_status(ERR_CPL_completion_status),
//---------------------------------------------------------------------------(7)  
//---------------------------------------------------------------------------(96)
/* output    logic                     */.ERR_CPL_Wr_En(ERR_CPL_Wr_En)                 //.valid(valid);
//---------------------------------------------------------------------------(1)

);


endmodule