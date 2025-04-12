
module AXI_MANAGER
(
    // Global Signals
    input  wire         ACLK,
    input  wire         ARESETn,

    // Write Address Channel (Outputs)
    output wire [3:0]   AWID,
    output wire [63:0]  AWADDR,
    output wire [7:0]   AWLEN,
    output wire [2:0]   AWSIZE,
    output wire [1:0]   AWBURST,
    output wire         AWVALID,
    // Write Address Channel (Input)
    input  wire         AWREADY,

    // Write Data Channel (Outputs)
    output wire [127:0] WDATA,
    output wire [15:0]  WSTRB,
    output wire         WLAST,
    output wire         WVALID,
    // Write Data Channel (Input)
    input  wire         WREADY,

    // Write Response Channel (Inputs)
    input  wire [3:0]   BID,
    input  wire [1:0]   BRESP,
    input  wire         BVALID,
    // Write Response Channel (Output)
    output wire         BREADY,

    // Read Address Channel (Outputs)
    output wire [3:0]   ARID,
    output wire [63:0]  ARADDR,
    output wire [7:0]   ARLEN,
    output wire [2:0]   ARSIZE,
    output wire [1:0]   ARBURST,
    output wire         ARVALID,
    // Read Address Channel (Input)
    input  wire         ARREADY,

    // Read Data Channel (Inputs)
    input  wire [3:0]   RID,
    input  wire [127:0] RDATA,
    input  wire [1:0]   RRESP,
    input  wire         RLAST,
    input  wire         RVALID,
    // Read Data Channel (Output)
    output wire         RREADY
);


endmodule


module AXI_INTERCONNECT(
  // Global Signals
    input  wire         ACLK,
    input  wire         ARESETn,

    // Master Interface (Manager Side)
    // Write Address Channel
    input  wire [3:0]   m_awid,
    input  wire [63:0]  m_awaddr,
    input  wire [7:0]   m_awlen,
    input  wire [2:0]   m_awsize,
    input  wire [1:0]   m_awburst,
    input  wire         m_awvalid,
    output wire         m_awready,

    // Write Data Channel
    input  wire [127:0] m_wdata,
    input  wire [15:0]  m_wstrb,
    input  wire         m_wlast,
    input  wire         m_wvalid,
    output wire         m_wready,

    // Write Response Channel
    output wire [3:0]   m_bid,
    output wire [1:0]   m_bresp,
    output wire         m_bvalid,
    input  wire         m_bready,

    // Read Address Channel
    input  wire [3:0]   m_arid,
    input  wire [63:0]  m_araddr,
    input  wire [7:0]   m_arlen,
    input  wire [2:0]   m_arsize,
    input  wire [1:0]   m_arburst,
    input  wire         m_arvalid,
    output wire         m_arready,

    // Read Data Channel
    output wire [3:0]   m_rid,
    output wire [127:0] m_rdata,
    output wire [1:0]   m_rresp,
    output wire         m_rlast,
    output wire         m_rvalid,
    input  wire         m_rready,

    // Slave 0 Interface
    // Write Address Channel
    output wire [3:0]   s0_awid,
    output wire [63:0]  s0_awaddr,
    output wire [7:0]   s0_awlen,
    output wire [2:0]   s0_awsize,
    output wire [1:0]   s0_awburst,
    output wire         s0_awvalid,
    input  wire         s0_awready,

    // Write Data Channel
    output wire [127:0] s0_wdata,
    output wire [15:0]  s0_wstrb,
    output wire         s0_wlast,
    output wire         s0_wvalid,
    input  wire         s0_wready,

    // Write Response Channel
    input  wire [3:0]   s0_bid,
    input  wire [1:0]   s0_bresp,
    input  wire         s0_bvalid,
    output wire         s0_bready,

    // Read Address Channel
    output wire [3:0]   s0_arid,
    output wire [63:0]  s0_araddr,
    output wire [7:0]   s0_arlen,
    output wire [2:0]   s0_arsize,
    output wire [1:0]   s0_arburst,
    output wire         s0_arvalid,
    input  wire         s0_arready,

    // Read Data Channel
    input  wire [3:0]   s0_rid,
    input  wire [127:0] s0_rdata,
    input  wire [1:0]   s0_rresp,
    input  wire         s0_rlast,
    input  wire         s0_rvalid,
    output wire         s0_rready,

    // Slave 1 Interface (Same as Slave 0)
    // Write Address Channel
    output wire [3:0]   s1_awid,
    output wire [63:0]  s1_awaddr,
    output wire [7:0]   s1_awlen,
    output wire [2:0]   s1_awsize,
    output wire [1:0]   s1_awburst,
    output wire         s1_awvalid,
    input  wire         s1_awready,

    // Write Data Channel
    output wire [127:0] s1_wdata,
    output wire [15:0]  s1_wstrb,
    output wire         s1_wlast,
    output wire         s1_wvalid,
    input  wire         s1_wready,

    // Write Response Channel
    input  wire [3:0]   s1_bid,
    input  wire [1:0]   s1_bresp,
    input  wire         s1_bvalid,
    output wire         s1_bready,

    // Read Address Channel
    output wire [3:0]   s1_arid,
    output wire [63:0]  s1_araddr,
    output wire [7:0]   s1_arlen,
    output wire [2:0]   s1_arsize,
    output wire [1:0]   s1_arburst,
    output wire         s1_arvalid,
    input  wire         s1_arready,

    // Read Data Channel
    input  wire [3:0]   s1_rid,
    input  wire [127:0] s1_rdata,
    input  wire [1:0]   s1_rresp,
    input  wire         s1_rlast,
    input  wire         s1_rvalid,
    output wire         s1_rready

);

endmodule

module AXI_SLAVE1(
    // Global Signals
    input  wire         ACLK,
    input  wire         ARESETn,

    // Write Address Channel (Inputs)
    input  wire [3:0]   AWID,
    input  wire [63:0]  AWADDR,
    input  wire [7:0]   AWLEN,
    input  wire [2:0]   AWSIZE,
    input  wire [1:0]   AWBURST,
    input  wire         AWVALID,
    // Write Address Channel (Output)
    output wire         AWREADY,

    // Write Data Channel (Inputs)
    input  wire [127:0] WDATA,
    input  wire [15:0]  WSTRB,
    input  wire         WLAST,
    input  wire         WVALID,
    // Write Data Channel (Output)
    output wire         WREADY,

    // Write Response Channel (Outputs)
    output wire [3:0]   BID,
    output wire [1:0]   BRESP,
    output wire         BVALID,
    // Write Response Channel (Input)
    input  wire         BREADY,

    // Read Address Channel (Inputs)
    input  wire [3:0]   ARID,
    input  wire [63:0]  ARADDR,
    input  wire [7:0]   ARLEN,
    input  wire [2:0]   ARSIZE,
    input  wire [1:0]   ARBURST,
    input  wire         ARVALID,
    // Read Address Channel (Output)
    output wire         ARREADY,

    // Read Data Channel (Outputs)
    output wire [3:0]   RID,
    output wire [127:0] RDATA,
    output wire [1:0]   RRESP,
    output wire         RLAST,
    output wire         RVALID,
    // Read Data Channel (Input)
    input  wire         RREADY

);

endmodule


module AXI_SLAVE2(
   // Global Signals
    input  wire         ACLK,
    input  wire         ARESETn,

    // Write Address Channel (Inputs)
    input  wire [3:0]   AWID,
    input  wire [63:0]  AWADDR,
    input  wire [7:0]   AWLEN,
    input  wire [2:0]   AWSIZE,
    input  wire [1:0]   AWBURST,
    input  wire         AWVALID,
    // Write Address Channel (Output)
    output wire         AWREADY,

    // Write Data Channel (Inputs)
    input  wire [127:0] WDATA,
    input  wire [15:0]  WSTRB,
    input  wire         WLAST,
    input  wire         WVALID,
    // Write Data Channel (Output)
    output wire         WREADY,

    // Write Response Channel (Outputs)
    output wire [3:0]   BID,
    output wire [1:0]   BRESP,
    output wire         BVALID,
    // Write Response Channel (Input)
    input  wire         BREADY,

    // Read Address Channel (Inputs)
    input  wire [3:0]   ARID,
    input  wire [63:0]  ARADDR,
    input  wire [7:0]   ARLEN,
    input  wire [2:0]   ARSIZE,
    input  wire [1:0]   ARBURST,
    input  wire         ARVALID,
    // Read Address Channel (Output)
    output wire         ARREADY,

    // Read Data Channel (Outputs)
    output wire [3:0]   RID,
    output wire [127:0] RDATA,
    output wire [1:0]   RRESP,
    output wire         RLAST,
    output wire         RVALID,
    // Read Data Channel (Input)
    input  wire         RREADY

);

endmodule



module AXI_TOP;




endmodule