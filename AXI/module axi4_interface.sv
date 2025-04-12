module axi4_interface #( //APP LAYER
    parameter DATA_WIDTH = 64,    // 64-bit AXI data bus
    parameter ADDR_WIDTH = 32,    // 32-bit address
    parameter ID_WIDTH   = 4,     // Transaction ID width
    parameter MAX_BURST  = 16     // Max burst length (AXI restriction: 1-256)
) (
    // Global signals
    input  wire                     aclk,
    input  wire                     aresetn,

    // Write Address Channel (AW)
    // input  wire [ID_WIDTH-1:0]      awid,
    input  wire [ADDR_WIDTH-1:0]    awaddr,
    input  wire [7:0]               awlen,      // Burst length (0=1 beat, 255=256 beats)
    input  wire [2:0]               awsize,     // Bytes per beat (0=1B, 1=2B, ..., 7=128B)
    input  wire [1:0]               awburst,    // Burst type (00=FIXED, 01=INCR, 10=WRAP)
    input  wire                     awvalid,
    output reg                      awready,

    // Write Data Channel (W)
    input  wire [DATA_WIDTH-1:0]    wdata,
    input  wire [(DATA_WIDTH/8)-1:0] wstrb,     // Byte strobes
    input  wire                     wlast,      // Last beat in burst
    input  wire                     wvalid,
    output reg                      wready,

    // Write Response Channel (B)
    // output reg [ID_WIDTH-1:0]       bid,
    output reg [1:0]                bresp,      // 00=OKAY, 01=EXOKAY, 10=SLVERR, 11=DECERR
    output reg                      bvalid,
    input  wire                     bready,

    // Read Address Channel (AR)
    // input  wire [ID_WIDTH-1:0]      arid,
    input  wire [ADDR_WIDTH-1:0]    araddr,
    input  wire [7:0]               arlen,
    input  wire [2:0]               arsize,
    input  wire [1:0]               arburst,
    input  wire                     arvalid,
    output reg                      arready,

    // Read Data Channel (R)
    // output reg [ID_WIDTH-1:0]       rid,
    output reg [DATA_WIDTH-1:0]     rdata,
    output reg [1:0]                rresp,
    output reg                      rlast,      // Last beat in burst
    output reg                      rvalid,
    input  wire                     rready,

    // PCIe Transaction Layer Interface
    output reg [ADDR_WIDTH-1:0]     tl_addr,
    output reg [DATA_WIDTH-1:0]     tl_wdata,
    output reg [(DATA_WIDTH/8)-1:0] tl_wstrb,
    output reg                      tl_write,
    output reg                      tl_read,
    output reg [7:0]                tl_burst_len,
    input  wire [DATA_WIDTH-1:0]    tl_rdata,
    input  wire                     tl_ready,
    input  wire                     tl_error    // PCIe transaction failed
);

// Burst write state machine
localparam WR_IDLE   = 0;
localparam WR_ADDR   = 1;
localparam WR_DATA   = 2;
localparam WR_RESP   = 3;

reg [1:0] wr_state;
reg [7:0] burst_counter;

always @(posedge aclk or negedge aresetn) begin
    if (!aresetn) begin
        wr_state <= WR_IDLE;
        awready <= 0;
        wready <= 0;
        bvalid <= 0;
    end else begin
        case (wr_state)
            WR_IDLE: begin
                awready <= 1;  // Accept new write address
                if (awvalid && awready) begin
                    tl_addr <= awaddr;
                    tl_burst_len <= awlen + 1;  // Convert to actual length
                    awready <= 0;
                    wr_state <= WR_ADDR;
                end
            end

            WR_ADDR: begin
                wready <= 1;  // Accept write data
                if (wvalid && wready) begin
                    tl_wdata <= wdata;
                    tl_wstrb <= wstrb;
                    tl_write <= 1;
                    burst_counter <= burst_counter + 1;
                    if (wlast) begin
                        wready <= 0; // ????
                        wr_state <= WR_RESP;
                    end
                end
            end

            WR_RESP: begin
                tl_write <= 0;
                if (tl_ready) begin
                    bid <= awid;
                    bresp <= tl_error ? 2'b10 : 2'b00;  // SLVERR or OKAY
                    bvalid <= 1;
                    if (bready) begin
                        bvalid <= 0;
                        wr_state <= WR_IDLE;
                    end
                end
            end
        endcase
    end
end

// Burst read state machine
localparam RD_IDLE   = 0;
localparam RD_ADDR   = 1;
localparam RD_DATA   = 2;

reg [1:0] rd_state;
reg [7:0] rd_burst_counter;

always @(posedge aclk or negedge aresetn) begin
    if (!aresetn) begin
        rd_state <= RD_IDLE;
        arready <= 0;
        rvalid <= 0;
    end else begin
        case (rd_state)
            RD_IDLE: begin
                arready <= 1;  // Accept new read address
                if (arvalid && arready) begin
                    tl_addr <= araddr;
                    tl_burst_len <= arlen + 1;
                    arready <= 0;
                    rd_state <= RD_ADDR;
                end
            end

            RD_ADDR: begin
                tl_read <= 1;
                if (tl_ready) begin
                    rid <= arid;
                    rdata <= tl_rdata;
                    rresp <= tl_error ? 2'b10 : 2'b00;
                    rvalid <= 1;
                    rd_burst_counter <= rd_burst_counter + 1;
                    if (rd_burst_counter == arlen) begin
                        rlast <= 1;
                        tl_read <= 0;
                        rd_state <= RD_IDLE;
                    end
                end
            end
        endcase
    end
end

// FIFO for write IDs
reg [ID_WIDTH-1:0] awid_fifo [0:7];
reg [2:0] awid_wptr, awid_rptr;

always @(posedge aclk) begin
    if (awvalid && awready) begin
        awid_fifo[awid_wptr] <= awid;
        awid_wptr <= awid_wptr + 1;
    end
    if (bvalid && bready) begin
        bid <= awid_fifo[awid_rptr];
        awid_rptr <= awid_rptr + 1;
    end
end

// Example: AXI Write Data Channel Pipeline
reg [DATA_WIDTH-1:0] wdata_pipe;
reg [(DATA_WIDTH/8)-1:0] wstrb_pipe;
reg wvalid_pipe, wlast_pipe;

always @(posedge aclk) begin
    wdata_pipe <= wdata;
    wstrb_pipe <= wstrb;
    wvalid_pipe <= wvalid;
    wlast_pipe <= wlast;
end

endmodule