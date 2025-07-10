

module TL_TOP#(parameter ADDR_WIDTH = 5, DATA_WIDTH = 5, BUS_WIDTH = 128, DEPTH = 3)(
input logic clk,
input logic rst,
output logic [32:0] TLPB2A,
output logic [32:0] TLPA2B
    );
 
    logic TLP_START_BIT_OUT_COMB;
    logic TLP_END_BIT_OUT_COMB;
    
    logic A_tlp_ready=1;
    logic A_tlp_valid=0;
    
    logic B_tlp_ready=1;
    logic B_tlp_valid=0;
     
    // logic [BUS_WIDTH-1:0]                       TLPA2B;
    // logic [BUS_WIDTH-1:0]                       TLPB2A;
    /* input */   logic [ADDR_WIDTH-1:0]           req_awaddr  = 1;  
    /* input */   logic [7:0]                      req_awlen   = 1;   // number of transfers in transaction
    /* input */   logic [2:0]                      req_awsize  = 1;  // number of bytes in transfer // 000=> 1; 001=>2; 010=>4; 011=>8; 100=>16; 101=>32; 110=>64; 111=>128
    /* input */   logic [1:0]                      req_awburst = 1;  
    /* output */  logic                            req_awready = 1; 
    /* input */   logic                            req_awvalid = 1; 

    // W Channelreq_
    /* input */   logic [DATA_WIDTH-1:0]           req_wdata  =  1; 
    /* input */   logic [(DATA_WIDTH/8)-1:0]       req_wstrb  =  1; 
    /* input */   logic                            req_wlast  =  1; 
    /* input */   logic                            req_wvalid =  1;
    /* output */  logic                            req_wready =  1;

    // B Channelreq_
    /* output */  logic [1:0]                      req_bresp  =  1;                         
    /* output */  logic                            req_bvalid =  1;                         
    /* input */   logic                            req_bready =  1;                         

    // AR Channelreq_
    /* input */   logic [ADDR_WIDTH-1:0]           req_araddr  = 1;
    /* input */   logic [7:0]                      req_arlen   = 1;
    /* input */   logic [2:0]                      req_arsize  = 1;
    /* input */   logic [1:0]                      req_arburst = 1;
    /* output */  logic                            req_arready = 1;
    /* input */   logic                            req_arvalid = 1;
                                            

    // R Channel                            req_
    /* output */  logic [DATA_WIDTH-1:0]           req_rdata  = 1;
    /* output */  logic [1:0]                      req_rresp  = 1;
    /* output */  logic                            req_rlast  = 1;
    /* output */  logic                            req_rvalid = 1;
    /* input */   logic                            req_rready = 1;
 

                    logic                           RX_awlen   = 1;
                    logic                           RX_awaddr  = 1;
                    logic                           RX_awsize  = 1;
                    logic                           RX_awburst = 1;
                    logic                           RX_awready = 1;
                    logic                           RX_awvalid = 1;
                    logic                           RX_wdata   = 1;
                    logic                           RX_wstrb   = 1;
                    logic                           RX_wlast   = 1;
                    logic                           RX_wvalid  = 1;
                    logic                           RX_wready  = 1;
                    logic                           RX_bresp   = 1;
                    logic                           RX_bvalid  = 1;
                    logic                           RX_bready  = 1;
                    logic                           RX_araddr  = 1;
                    logic                           RX_arlen   = 1;
                    logic                           RX_arsize  = 1;
                    logic                           RX_arburst = 1;
                    logic                           RX_arready = 1;
                    logic                           RX_arvalid = 1;
                    logic                           RX_rdata   = 1;
                    logic                           RX_rresp   = 1;
                    logic                           RX_rlast   = 1;
                    logic                           RX_rvalid  = 1;
                    logic                           RX_rready  = 1;


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
    
    
    
        /* output  logic [7:0]                */       .RX_awlen  (RX_awlen),   // number of transfers in transaction
        /* output  logic [ADDR_WIDTH-1:0]     */       .RX_awaddr (RX_awaddr),
        /* output  logic [2:0]                */       .RX_awsize (RX_awsize),  // number of bytes in transfer  //                            000=> 1, 001=>2, 010=>4, 011=>8, 100=>16, 101=>32, 110=>64, 111=>128
        /* output  logic [1:0]                */       .RX_awburst(RX_awburst),
        /* input   logic                      */       .RX_awready(RX_awready),
        /* output  logic                      */       .RX_awvalid(RX_awvalid),
        /* output  logic [DATA_WIDTH-1:0]     */       .RX_wdata  (RX_wdata), 
        /* output  logic [(DATA_WIDTH/8)-1:0] */       .RX_wstrb  (RX_wstrb), 
        /* output  logic                      */       .RX_wlast  (RX_wlast), 
        /* output  logic                      */       .RX_wvalid (RX_wvalid),
        /* input   logic                      */       .RX_wready (RX_wready),
        /* input   logic [1:0]                */       .RX_bresp  (RX_bresp),                         
        /* input   logic                      */       .RX_bvalid (RX_bvalid),                         
        /* output  logic                      */       .RX_bready (RX_bready),                         
        /* output  logic [ADDR_WIDTH-1:0]     */       .RX_araddr (RX_araddr),
        /* output  logic [7:0]                */       .RX_arlen  (RX_arlen),
        /* output  logic [2:0]                */       .RX_arsize (RX_arsize),
        /* output  logic [1:0]                */       .RX_arburst(RX_arburst),
        /* input   logic                      */       .RX_arready(RX_arready),
        /* output  logic                      */       .RX_arvalid(RX_arvalid),                         
        /* input   logic [DATA_WIDTH-1:0]     */       .RX_rdata  (RX_rdata),
        /* input   logic [1:0]                */       .RX_rresp  (RX_rresp),
        /* input   logic                      */       .RX_rlast  (RX_rlast),
        /* input   logic                      */       .RX_rvalid (RX_rvalid),
        /* output  logic                      */       .RX_rready (RX_rready),
    
    
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
endmodule
