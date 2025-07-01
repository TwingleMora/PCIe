module AXI_TOP;

    localparam ADDR_WIDTH = 32;
    localparam DATA_WIDTH = 32;



     bit     clk;
     logic   rst;

     // AW Channel
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




    logic                             start;





AXI_MASTER #(.ADDR_WIDTH(ADDR_WIDTH), .DATA_WIDTH(DATA_WIDTH)) axi_master
(   /* input logic */                            .aclk(clk),
    /* input logic */                            .aresetn(rst),
    
                                                 .VALID(start),
                                                 .ACK(),

                                                // .tlp_mem_io_msg_cpl_conf(rx_tlp_mem_io_msg_cpl_conf),   //     input  logic  [2:0]     tlp_mem_io_msg_cpl_conf,
                                                // .tlp_address_32_64(rx_tlp_address_32_64),               //     input  logic            tlp_address_32_64,
                                                // .tlp_read_write(rx_tlp_read_write),                     //     input  logic            tlp_read_write,

                                                    
                                                // .first_dw_be(rx_first_dw_be),   //     input  logic  [3:0]     first_dw_be,
                                                // .last_dw_be(rx_last_dw_be),     //     input  logic  [3:0]     last_dw_be,
                                                // .lower_addr(rx_lower_addr),     //     input  logic  [31:0]    lower_addr,

                                                // // //calculate OFFSET and M_PSTRB

                                                // .data(DATA_BUFF_COMB_DATA_OUT), //     input  logic  [31:0]    data,
                                                // .last_dw(last_dw),              //     input  logic            last_dw,

                                                // .DATA_BUFF_EMPTY(DATA_BUFF_EMPTY),  //     input logic            DATA_BUFF_EMPTY,
                                                // .DATA_BUFF_RD_EN(DATA_BUFF_RD_EN),                 //     output logic            DATA_BUFF_RD_EN,

                                                // .config_dw_number(rx_config_dw_number),//     input  logic  [9:0]     config_dw_number,
                                                 
    // Global Signals 

    // AW Channel
    /* output logic [ADDR_WIDTH-1:0] */           .awaddr(awaddr),
    /* output logic [7:0] */                      .awlen(awlen),  // number of transfers in transaction
    /* output logic [2:0] */                      .awsize(awsize),  // number of bytes in transfer  //                            000=> 1, 001=>2, 010=>4, 011=>8, 100=>16, 101=>32, 110=>64, 111=>128
    /* output logic [1:0] */                      .awburst(awburst),
    /* input  logic */                            .awready(awready),
    /* output logic */                            .awvalid(awvalid),

    // W Channel
    /* output logic [DATA_WIDTH-1:0] */           .wdata(wdata), 
    /* output logic [(DATA_WIDTH/8)-1:0] */       .wstrb(wstrb), 
    /* output logic */                            .wlast(wlast), 
    /* output logic */                            .wvalid(wvalid),
    /* input  logic */                            .wready(wready),

    // B Channel
    /* input  logic [1:0] */                      .bresp(bresp),                         
    /* input  logic */                            .bvalid(bvalid),                         
    /* output logic */                            .bready(bready),                         

    // AR Channel
    /* output logic [ADDR_WIDTH-1:0] */           .araddr(araddr),
    /* output logic [7:0] */                      .arlen(arlen),
    /* output logic [2:0] */                      .arsize(arsize),
    /* output logic [1:0] */                      .arburst(arburst),
    /* input  logic */                            .arready(arready),
    /* output logic */                            .arvalid(arvalid),
                                            

    // R Channel                            
    /* input  logic [DATA_WIDTH-1:0] */           .rdata(rdata),
    /* input  logic [1:0] */                      .rresp(rresp),
    /* input  logic */                            .rlast(rlast),
    /* input  logic */                            .rvalid(rvalid),
    /* output logic */                            .rready(rready)
);


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
);

always #5 clk = ~clk;
initial begin
    rst = 0;
    @(posedge clk)
    rst = 1;
    start = 1;

    repeat(45) 
    begin
    	@(negedge clk);
    end
    $stop;


end

endmodule

