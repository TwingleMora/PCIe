
module TL_RX_TB3;

localparam DATA_WIDTH = 32, ADDR_WIDTH = 32;
// ---------------------------------------------------------------------------
// DL-TL Interface
// ---------------------------------------------------------------------------

    logic                            clk;
    logic                            rst;
    logic [31:0]                     IN_TLP_DW;
    logic                            new_tlp_ready;
    logic                            valid_tlp;
                                     
                                     
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



//------------------------------------------------------------------
// Requests CPL from RX AXI MASTER to TL TX
//------------------------------------------------------------------
    //      .    .    .    .                        
    //    //.\\//.\\//.\\//.\\ CPLD FROM RX BRIDGE  
    logic                     RX_B_tlp_read_write;         
    logic    [2:0]            RX_B_TC;               
    logic    [2:0]            RX_B_ATTR;             
    logic    [15:0]           RX_B_requester_id;     
    logic    [7:0]            RX_B_tag;              
    logic    [11:0]           RX_B_byte_count;       

//--------------------------------------------------------------------------------------
    logic    [6:0]            RX_B_lower_addr;       //
    logic    [2:0]            RX_B_completion_status;
//----------------------------------------------------------------------------------------- 
//-----------------------------------------------------------------------------------------          
    logic    [31:0]           RX_B_data1;                 //
    logic    [31:0]           RX_B_data2;                 //
    logic    [31:0]           RX_B_data3;                 //
//-----------------------------------------------------------------------------------------                   
    logic                     RX_B_Wr_En;                  //
//-----------------------------------------------------------------------------------------

//------------------------------------------------------------------
// Errors CPL from Error Detection Block
//------------------------------------------------------------------
//-------------------------------------------------------------------------- (4)
    logic    [2:0]            ERR_CPL_TC;                      //.TC(TC);
    logic    [2:0]            ERR_CPL_ATTR;                    //.ATTR(ATTR);
//---------------------------------------------------------------------------(6)
    logic    [15:0]           ERR_CPL_requester_id;            //[[X]]  -- //COMPLETER ID 
    logic    [7:0]            ERR_CPL_tag;                     //[[X]].
    logic    [11:0]           ERR_CPL_byte_count;              //

//---------------------------------------------------------------------------(36)           
    logic    [6:0]            ERR_CPL_lower_addr;              //[[X]]
    logic    [2:0]            ERR_CPL_completion_status;
//---------------------------------------------------------------------------(7)  
//---------------------------------------------------------------------------(96)
    logic                     ERR_CPL_Wr_En;                 //.valid(valid);
//---------------------------------------------------------------------------(1)



TRANSACTION_RX_TOP #(.DATA_WIDTH(DATA_WIDTH), .ADDR_WIDTH(ADDR_WIDTH)) transaction_rx_top (

// DL-TL Interface
/* input   logic                            */.clk(clk),
/* input   logic                            */.rst(rst),
/* input   logic [31:0]                     */.IN_TLP_DW(IN_TLP_DW),
/* input   logic                            */.new_tlp_ready(new_tlp_ready),
/* input   logic                            */.valid_tlp(valid_tlp),



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

//Internal Native Interface
/* output  logic                            */.RX_B_tlp_read_write(RX_B_tlp_read_write),          
/* output  logic    [2:0]                   */.RX_B_TC(RX_B_TC),               
/* output  logic    [2:0]                   */.RX_B_ATTR(RX_B_ATTR),             
/* output  logic    [15:0]                  */.RX_B_requester_id(RX_B_requester_id),       
/* output  logic    [7:0]                   */.RX_B_tag(RX_B_tag),              
/* output  logic    [11:0]                  */.RX_B_byte_count(RX_B_byte_count),

//--------------------------------------------------------------------------------------
/* output  logic    [6:0]                   */.RX_B_lower_addr(RX_B_lower_addr),
/* output  logic    [2:0]                   */.RX_B_completion_status(RX_B_completion_status),
//----------------------------------------------------------------------------------------- 
//-----------------------------------------------------------------------------------------          
/* output  logic    [31:0]                  */.RX_B_data1(RX_B_data1),          
/* output  logic    [31:0]                  */.RX_B_data2(RX_B_data2),          
/* output  logic    [31:0]                  */.RX_B_data3(RX_B_data3),          
//-----------------------------------------------------------------------------------------                   
/* output  logic                            */.RX_B_Wr_En(RX_B_Wr_En),           
//-----------------------------------------------------------------------------------------

//------------------------------------------------------------------
// Errors CPL from Error Detection Block
//------------------------------------------------------------------
//-------------------------------------------------------------------------- (4)
/* input    logic    [2:0]                  */.ERR_CPL_TC(ERR_CPL_TC),                      //.TC(TC)(),
/* input    logic    [2:0]                  */.ERR_CPL_ATTR(ERR_CPL_ATTR),                    //.ATTR(ATTR)(),
//---------------------------------------------------------------------------(6)
/* input    logic    [15:0]                 */.ERR_CPL_requester_id(ERR_CPL_requester_id),            //[[X]]  -- //COMPLETER ID 
/* input    logic    [7:0]                  */.ERR_CPL_tag(ERR_CPL_tag),                     //[[X]].
/* input    logic    [11:0]                 */.ERR_CPL_byte_count(ERR_CPL_byte_count),              //
              
//---------------------------------------------------------------------------(36)           
/* input    logic    [6:0]                  */.ERR_CPL_lower_addr(ERR_CPL_lower_addr),              //[[X]]
/* input    logic    [2:0]                  */.ERR_CPL_completion_status(ERR_CPL_completion_status),
//---------------------------------------------------------------------------(7)  
//---------------------------------------------------------------------------(96)
/* input     logic                          */.ERR_CPL_Wr_En(ERR_CPL_Wr_En)                  //.valid(valid);
//---------------------------------------------------------------------------(1)
);

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






endmodule