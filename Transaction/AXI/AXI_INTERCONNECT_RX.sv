module AXI_INTERCONNECT_RX#(parameter DATA_WIDTH = 64, parameter ADDR_WIDTH = 32)
(
    
///////MASTER
    //AW
    input  logic   [ADDR_WIDTH-1:0]        M_AWADDR,
    input  logic   [1:0]                   M_AWBURST,
    input  logic   [2:0]                   M_AWSIZE,
    input  logic   [7:0]                   M_AWLEN,
    input  logic                           M_AWVALID,
    output logic                           M_AWREADY,
    input  logic   [7:0]                   M_AWID,

    //W
    input  logic   [DATA_WIDTH-1:0]        M_WDATA,
    input  logic   [(DATA_WIDTH/8)-1:0]    M_WSTRB,
    input  logic                           M_WLAST,
    input  logic                           M_WVALID,
    output logic                           M_WREADY,

    //B
    output logic   [1:0]                  M_BRESP,
    output logic                          M_BVALID,
    input  logic                          M_BREADY,
    output logic   [7:0]                  M_BID,

    //AR
    input  logic   [ADDR_WIDTH-1:0]        M_ARADDR,
    input  logic   [1:0]                   M_ARBURST,
    input  logic   [2:0]                   M_ARSIZE,
    input  logic   [7:0]                   M_ARLEN,
    input  logic                           M_ARVALID,
    output logic                           M_ARREADY,
    input  logic   [7:0]                   M_ARID,


    //R
    output logic  [DATA_WIDTH-1:0]         M_RDATA,
    output logic  [1:0]                    M_RRESP,
    output logic                           M_RLAST,
    output logic                           M_RVALID,
    input  logic                           M_RREADY,
    output logic   [7:0]                   M_RID,
    

///////SLAVE 0
    //AW
    output logic   [ADDR_WIDTH-1:0]         S0_AWADDR,
    output logic   [1:0]                    S0_AWBURST,
    output logic   [2:0]                    S0_AWSIZE,
    output logic   [7:0]                    S0_AWLEN,
    output logic                            S0_AWVALID,
    input  logic                            S0_AWREADY,
    output logic   [7:0]                    S0_AWID,

    //W
    output logic   [DATA_WIDTH-1:0]         S0_WDATA,
    output logic   [(DATA_WIDTH/8)-1:0]     S0_WSTRB,
    output logic                            S0_WLAST,
    output logic                            S0_WVALID,
    input  logic                            S0_WREADY,

    //B
    input  logic   [1:0]                   S0_BRESP,
    input  logic                           S0_BVALID,
    output logic                           S0_BREADY,
    input  logic   [7:0]                   S0_BID,

    //AR
    output logic   [ADDR_WIDTH-1:0]        S0_ARADDR,
    output logic   [1:0]                   S0_ARBURST,
    output logic   [2:0]                   S0_ARSIZE,
    output logic   [7:0]                   S0_ARLEN,
    output logic                           S0_ARVALID,
    input  logic                           S0_ARREADY,
    output logic   [7:0]                   S0_ARID,


    //R
    input  logic  [DATA_WIDTH-1:0]         S0_RDATA,
    input  logic  [1:0]                    S0_RRESP,
    input  logic                           S0_RLAST,
    input  logic                           S0_RVALID,
    output logic                           S0_RREADY,
    input  logic   [7:0]                   S0_RID,



    ///////SLAVE 1
    //AW
    output logic   [ADDR_WIDTH-1:0]         S1_AWADDR,
    output logic   [1:0]                    S1_AWBURST,
    output logic   [2:0]                    S1_AWSIZE,
    output logic   [7:0]                    S1_AWLEN,
    output logic                            S1_AWVALID,
    input  logic                            S1_AWREADY, 
    output logic   [7:0]                    S1_AWID,

    //W
    output logic   [DATA_WIDTH-1:0]         S1_WDATA,
    output logic   [(DATA_WIDTH/8)-1:0]     S1_WSTRB,
    output logic                            S1_WLAST,
    output logic                            S1_WVALID,
    input logic                             S1_WREADY,

    //B
    input  logic   [1:0]                    S1_BRESP,
    input  logic                            S1_BVALID,
    output logic                            S1_BREADY,
    input  logic   [7:0]                    S1_BID,

    //AR
    output logic   [ADDR_WIDTH-1:0]         S1_ARADDR,
    output logic   [1:0]                    S1_ARBURST,
    output logic   [2:0]                    S1_ARSIZE,
    output logic   [7:0]                    S1_ARLEN,
    output logic                            S1_ARVALID,
    input  logic                            S1_ARREADY,
    output logic   [7:0]                    S1_ARID,


    //R
    input  logic  [DATA_WIDTH-1:0]          S1_RDATA,
    input  logic  [1:0]                     S1_RRESP,
    input  logic                            S1_RLAST,
    input  logic                            S1_RVALID,
    output logic                            S1_RREADY,
    input  logic   [7:0]                    S1_RID


);
/*

            +-----------------------------+
            |        AXI Master           |
            +-----------------------------+
                          ^     ^
                    |  |  |  |  |  |  |  |
   [AW Channel]─────┘  |  |  |  |  |  |  |
   [W Channel]─────────┘  |  |  |  |  |  |
   [B Channel]────────────┘  |  |  |  |  |
   [AR Channel]──────────────┘  |  |  |  |
   [R Channel]──────────────────┘  |  |  |
                    |  |  |  |  |  |  |  |
                    v  v     v     v  v  v
            +-----------------------------+
            |     AXI Interconnect/Slave  |
            +-----------------------------+

*/

wire WR_SLAVE_SEL; //0: SLAVE 0, 1: SLAVE 1
wire RD_SLAVE_SEL; //0: SLAVE 0, 1: SLAVE 1

assign WR_SLAVE_SEL = M_AWADDR[ADDR_WIDTH-1];
assign RD_SLAVE_SEL = M_ARADDR[ADDR_WIDTH-1];


//AW
    /* output logic   [ADDR_WIDTH-1:0]         Sn_AWADDR, */
    assign S0_AWADDR = M_AWADDR;
    assign S1_AWADDR = M_AWADDR;
    /* output logic   [1:0]                    Sn_AWBURST, */
    assign S0_AWBURST = M_AWBURST;
    assign S1_AWBURST = M_AWBURST;
    /* output logic   [2:0]                    Sn_AWSIZE, */
    assign S0_AWSIZE = M_AWSIZE;
    assign S1_AWSIZE = M_AWSIZE;
    /* output logic   [7:0]                    Sn_AWLEN, */
    assign S0_AWLEN = M_AWLEN;
    assign S1_AWLEN = M_AWLEN;
    /* output logic                            Sn_AWVALID, */
    assign S0_AWVALID = WR_SLAVE_SEL? 1'b0 : M_AWVALID;
    assign S1_AWVALID = WR_SLAVE_SEL? M_AWVALID : 1'b0;
    /* input  logic                            Sn_AWREADY,  */
    assign M_AWREADY = WR_SLAVE_SEL? S1_AWREADY : S0_AWREADY;
    /* output logic   [7:0]                    Sn_AWID, */
    assign S0_AWID = M_AWID;
    assign S1_AWID = M_AWID;

//W
    /* output logic   [DATA_WIDTH-1:0]         Sn_WDATA, */
    assign S0_WDATA = M_WDATA;
    assign S1_WDATA = M_WDATA;
    /* output logic   [(DATA_WIDTH/8)-1:0]     Sn_WSTRB, */
    assign S0_WSTRB = M_WSTRB;
    assign S1_WSTRB = M_WSTRB;
    /* output logic                            Sn_WLAST, */
    assign S0_WLAST = M_WLAST;
    assign S1_WLAST = M_WLAST;
    /* output logic                            Sn_WVALID, */
    assign S0_WVALID = WR_SLAVE_SEL? 1'b0 : M_WVALID;
    assign S1_WVALID = WR_SLAVE_SEL? M_WVALID : 1'b0;
    /* input logic                             Sn_WREADY, */
    assign M_AWREADY = W_SLAVE_SEL? S1_WREADY : S0_WREADY;


//B
    /* input  logic   [1:0]                    Sn_BRESP, */
    assign M_BRESP  = WR_SLAVE_SEL? S1_BRESP : S0_BRESP; 
    /* input  logic                            Sn_BVALID, */
    assign M_BVALID = WR_SLAVE_SEL? S1_BVALID : S0_BVALID;
    /* output logic                            Sn_BREADY, */
    assign S0_BREADY = WR_SLAVE_SEL? 1'b0 : M_BREADY;
    assign S1_BREADY = WR_SLAVE_SEL? M_BREADY : 1'b0;
    /* input  logic   [7:0]                    Sn_BID, */
    assign S0_BID    = M_BID; 
    assign S1_BID    = M_BID; 

//AR
    /* output logic   [ADDR_WIDTH-1:0]         Sn_ARADDR, */
    assign S0_ARADDR = M_ARADDR;
    assign S1_ARADDR = M_ARADDR;
    
    /* output logic   [1:0]                    Sn_ARBURST, */
    assign S0_ARBURST = M_ARBURST;
    assign S1_ARBURST = M_ARBURST;
    /* output logic   [2:0]                    Sn_ARSIZE, */
    assign S0_ARSIZE = M_ARSIZE;
    assign S1_ARSIZE = M_ARSIZE;
    /* output logic   [7:0]                    Sn_ARLEN, */
    assign S0_ARLEN = M_ARLEN;
    assign S1_ARLEN = M_ARLEN;

    /* output logic                            Sn_ARVALID, */
    assign S0_ARVALID = RD_SLAVE_SEL? 1'b0 : M_ARVALID;
    assign S1_ARVALID = RD_SLAVE_SEL? M_ARVALID : 1'b0;

    /* input  logic                            Sn_ARREADY, */
    assign M_ARREADY = RD_SLAVE_SEL? S1_ARREADY : S0_ARREADY;

    /* output logic   [7:0]                    Sn_ARID, */
    assign S0_ARID = M_ARID;
    assign S1_ARID = M_ARID;



//R
    /* input  logic  [DATA_WIDTH-1:0]          Sn_RDATA, */
    assign M_RDATA = RD_SLAVE_SEL? S1_RDATA : S0_RDATA;
    /* input  logic  [1:0]                     Sn_RRESP, */
    assign M_RRESP = RD_SLAVE_SEL? S1_RRESP : S0_RRESP;
    /* input  logic                            Sn_RLAST, */
    assign M_RLAST = RD_SLAVE_SEL? S1_RLAST : S0_RLAST;
    /* input  logic                            Sn_RVALID, */
    assign RVALID = RD_SLAVE_SEL? S1_RVALID : S0_RVALID;
    /* output logic                            Sn_RREADY, */
    assign RVALID = RD_SLAVE_SEL? S1_RVALID : S0_RVALID;

    /* input  logic   [7:0]                    Sn_RID */
    assign S0_RID = M_RID;
    assign S1_RID = M_RID;    









endmodule