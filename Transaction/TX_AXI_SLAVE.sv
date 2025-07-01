module TX_AXI_SLAVE
(
     // Global Signals 
    input logic                              aclk,
    input logic                              aresetn,

    // AW Channel
    input   logic [ADDR_WIDTH-1:0]           awaddr,  
    input   logic [7:0]                      awlen,   // number of transfers in transaction
    input   logic [2:0]                      awsize,  // number of bytes in transfer // 000=> 1, 001=>2, 010=>4, 011=>8, 100=>16, 101=>32, 110=>64, 111=>128
    input   logic [1:0]                      awburst,  
    output  logic                            awready, 
    input   logic                            awvalid, 

    // W Channel
    input   logic [DATA_WIDTH-1:0]           wdata, 
    input   logic [(DATA_WIDTH/8)-1:0]       wstrb, 
    input   logic                            wlast, 
    input   logic                            wvalid,
    output  logic                            wready,

    // B Channel
    output  logic [1:0]                      bresp,                         
    output  logic                            bvalid,                         
    input   logic                            bready,                         

    // AR Channel
    input   logic [ADDR_WIDTH-1:0]           araddr,
    input   logic [7:0]                      arlen,
    input   logic [2:0]                      arsize,
    input   logic [1:0]                      arburst,
    output  logic                            arready,
    input   logic                            arvalid,
                                            

    // R Channel                            
    output  logic [DATA_WIDTH-1:0]           rdata,
    output  logic [1:0]                      rresp,
    output  logic                            rlast,
    output  logic                            rvalid,
    input   logic                            rready


);






endmodule