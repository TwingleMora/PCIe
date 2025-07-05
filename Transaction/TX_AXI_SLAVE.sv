module TX_AXI_SLAVE#(parameter DATA_WIDTH = 32, parameter ADDR_WIDTH = 32)
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
    input   logic                            rready,

    output  logic  [2:0]                     o_tlp_mem_io_msg_cpl_conf,
    output  logic                            o_tlp_address_32_64,
    output  logic                            o_tlp_read_write,
    output  logic                            o_config_type,//type 1, type 2 
    // output  logic  [15:0]                    o_device_id,
    // output  logic  [15:0]                    o_requester_id,
    // output  logic  [7:0]                     o_tag,
    output  logic  [11:0]                    o_byte_count,
    output  logic  [31:0]                    o_lower_addr,
    output  logic  [31:0]                    o_upper_addr,
    output  logic  [15:0]                    o_dest_bdf_id,
    output  logic  [9:0]                     o_config_dw_number,
    output  logic  [2:0]                     o_completion_status,
    output  logic  [7:0]                     o_message_code,
    output  logic                            o_valid,


    output  logic  [31:0]                    REQ_data_out,
    input  logic                             REQ_RD_EN,
    input  logic                             i_finished


);
localparam ADDR_LSB = $clog2(DATA_WIDTH) -3;

logic [15:0]        r_header;//0x0
logic [31:0]        r_addr32;//0x04
logic [31:0]        r_addr64;//0x08
logic [27:0]        r_conf;  //0x0C [ dw_number | bdf]

logic               r_valid; //0x10


logic [31:0]           w_tx_fifo_din;
logic                  c_tx_fifo_wren;
assign  w_tx_fifo_din  = wdata;
FIFO_D #(.DEPTH(32), .DATA_WIDTH(32)) REQ_TX_FIFO //0x10
(
/* input */                      .clk(aclk), 
/* input */                      .rst(aresetn),
/* input */                      .WrEn(c_tx_fifo_wren), 
/* input */                      .RdEn(REQ_RD_EN),
/* input  [DATA_WIDTH-1:0] */    .DataIn(w_tx_fifo_din),
/* output [DATA_WIDTH-1:0] */    .DataOut(),
/* output [DATA_WIDTH-1:0] */    .comb_DataOut(REQ_data_out),
/* output */                     .Full(), 
/* output */                     .Empty(REQ_TX_FIFO_EMPTY),
/* output */                     .AlmostEmpty(),
/* output */                     .AlmostFull()
);

logic  [1:0]        c_tlp_mem_io_msg_cpl_conf;

// 0x00
assign o_tlp_mem_io_msg_cpl_conf = c_tlp_mem_io_msg_cpl_conf;
assign o_tlp_address_32_64  = r_header [2];
assign o_tlp_read_write     = r_header [3];
assign o_byte_count         = r_header [15:4];

// 0x04
assign o_lower_addr         = r_addr32; 

// 0x08
assign o_upper_addr         = r_addr64; 

// 0x0c
assign o_dest_bdf_id        = r_conf   [15:0];
assign o_config_dw_number   = r_conf   [25:16];
assign o_config_type        = r_conf   [26];

// 0x10
assign o_valid              = r_valid;

always@(*) begin
    c_tlp_mem_io_msg_cpl_conf = 0;
    case(r_header[1:0])
    0: c_tlp_mem_io_msg_cpl_conf = 0;
    1: c_tlp_mem_io_msg_cpl_conf = 1;
    3: c_tlp_mem_io_msg_cpl_conf = 2;
    2: c_tlp_mem_io_msg_cpl_conf = 4;
    endcase
end

/////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////
//////////////////////////////AXI////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////

///////////////////////////////////////////////////////////////////////
////////////////////////// FUNCTIONS///////////////////////////////////
///////////////////////////////////////////////////////////////////////

function [DATA_WIDTH-1:0]	apply_wstrb;
input [DATA_WIDTH-1:0]        old_reg;
input [DATA_WIDTH-1:0]        new_reg;
input [(DATA_WIDTH/8)-1:0]    wsrtb;
for(int x =0 ;x< (DATA_WIDTH/8);x++) begin
    if(wstrb[x]) begin
        apply_wstrb[x*8+:8] <= new_reg[x*8+:8];
    end
    else begin
        apply_wstrb[x*8+:8] <= old_reg[x*8+:8];
    end
end
endfunction

logic awskd_valid, wskidbuffer_valid;
logic [ADDR_WIDTH-1:0] awskd_addr;  
logic [DATA_WIDTH-1:0] wskd_data;   
logic [(DATA_WIDTH/8)-1:0] wskd_strb;  

//////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////
/* || */    logic [15:0]        wskd_header;//0x0                              /// 
/* || */    logic [31:0]        wskd_addr32;//0x04                             /// 
/* || */    logic [31:0]        wskd_addr64;//0x08                             ///         
/* || */    logic [27:0]        wskd_conf;  //0x0C [ dw_number | bdf]          ///     
/* || */    logic               wskd_valid; //0x0F                             /// 
/* || */                                                                       /// 
/* || */    assign wskd_header = wskd_data;//apply_wstrb(r_header, wskd_data, wskd_strb);  ///     
/* || */    assign wskd_addr32 = wskd_data;//apply_wstrb(r_addr32, wskd_data, wskd_strb);  ///     
/* || */    assign wskd_addr64 = wskd_data;//apply_wstrb(r_addr64, wskd_data, wskd_strb);  ///     
/* || */    assign wskd_conf   = wskd_data;//apply_wstrb(r_conf, wskd_data, wskd_strb);    ///     
/* || */    assign wskd_valid  = wskd_data;//apply_wstrb(r_valid, wskd_data, wskd_strb);   ///     
/* || *///////////////////////////////////////////////////////////////////////////
/* || */////////////////////////// WRITE /////////////////////////////////////////
assign bresp = 0;
/* || *///////////////////////////////////////////////////////////////////////////

 
logic axil_write_ready;             
// assign awskd_addr = {awaddr[ADDR_WIDTH-1:ADDR_LSB],{ADDR_LSB{1'b0}}};
skid_buffer #(.OPT_OUTREG(0), .DATA_WIDTH(ADDR_WIDTH)) axilawskid
(
.clk(aclk), .rst(aresetn), .i_valid(awvalid), .i_ready(axil_write_ready), .i_data({awaddr[ADDR_WIDTH-1:ADDR_LSB], {ADDR_LSB{1'b0}}}),
.o_valid(awskd_valid), .o_ready(awready), .o_data(awskd_addr)

);


skid_buffer #(.OPT_OUTREG(0), .DATA_WIDTH(DATA_WIDTH + (DATA_WIDTH/8))) axilwskid
(
    .clk(aclk), .rst(aresetn), .i_valid(wvalid), .i_ready(axil_write_ready), .i_data({wdata, wstrb}), .o_valid(wskidbuffer_valid), .o_ready(wready),
    .o_data({wskd_data, wskd_strb})
);

/* || *///////////////////////////////////////////////////////////////////////////


assign axil_write_ready = (awskd_valid && wskidbuffer_valid) && (!bvalid||bready); //toz





// always@(posedge aclk or negedge aresetn) begin
//     if(!aresetn) begin
//         awready <= 0;
//         wready <= 0;
//     end
//     else begin
//         awready <= /* !awready && */ (awskd_valid && wskidbuffer_valid) && (!bvalid || bready);
//         wready <= /* !wready && */ (awskd_valid && wskidbuffer_valid) && (!bvalid || bready);
//     end
// end



always@(posedge aclk or negedge aresetn) begin
    if(!aresetn) begin
        bvalid <= 0;
    end
    else if(axil_write_ready) begin
        bvalid <= 1; //the next cycle after (axil_write_ready) 
    end
    else if(bready) begin 
        bvalid <= 0;
    end
end




// assign axil_write_ready = awready; //toz
//Valid Can't Change until ready is asserted

always@(posedge aclk or negedge aresetn) begin
    if(!aresetn) begin
        r_header <= 0;
        r_addr32 <= 0;
        r_addr64 <= 0;
        r_conf   <= 0;
    end
    else 
    begin
        if(axil_write_ready) begin
            case(awskd_addr)
            32'h0: r_header<= wskd_header;
            32'h4: r_addr32<= wskd_addr32;
            32'h8: r_addr64<= wskd_addr64;
            32'hc: r_conf  <= wskd_conf;
            endcase
        end
    end
end

always@(posedge aclk or negedge aresetn) begin
    if(!aresetn) begin
        r_valid  <= 0;
    end
    else begin
        if(axil_write_ready) begin
            case(awskd_addr)
                32'h10: r_valid <= wskd_valid;
            endcase
        end
        else if(i_finished) begin
            r_valid <= 0;
        end
/*         else begin
            r_valid <= 0;
        end */

    end
end
always@(*) begin

        c_tx_fifo_wren = 0;
        
        if(axil_write_ready) begin
            case(awskd_addr)
            32'h14: c_tx_fifo_wren = 1; 
            endcase
        end

end
    






///////////////////////////////////////////////////////////////////////
////////////////////////// READ //////////////////////////////////////
///////////////////////////////////////////////////////////////////////
assign rresp = 0;
///////////////////////////////////////////////////////////////////////
	
    logic                  arskd_valid;
    logic [ADDR_WIDTH-1:0] arskd_addr;
    logic axil_read_ready;
    // assign arskd_addr = {araddr[31:ADDR_LSB],{ADDR_LSB{1'b0}}};
///////////////////////////////////////////////////////////////////////
    skid_buffer #(.OPT_OUTREG(0), .DATA_WIDTH(ADDR_WIDTH)) axilarskid
    (
        .clk(aclk), .rst(aresetn), .i_valid(arvalid), .i_ready(axil_read_ready),
        .i_data({araddr[ADDR_WIDTH-1:ADDR_LSB],{ADDR_LSB{1'b0}}}), .o_valid(arskd_valid), .o_ready(arready), .o_data(arskd_addr)
    );
///////////////////////////////////////////////////////////////////////
    assign axil_read_ready = arskd_valid && (!rvalid || rready); 


    // axil_read_ready <= 0;
    always@(posedge aclk or negedge aresetn) begin
        if(aresetn) begin
            rvalid <= 0;
        end
        else begin
            if(axil_read_ready/* arvalid && arready */) begin
                rvalid <= 1;//sure ... if not then why on earth we've this "axil_read_ready"
                //next cycle
            end
            else if(rready) begin
                rvalid <= 0; //why 
            end
        end
    end

    // always@(*) begin
    //     arready  = !rvalid;
    // end

    // assign axil_read_ready = (arvalid && arready); 
    always @(posedge aclk or negedge aresetn) begin
        if (!rvalid || rready)
        begin
            case(arskd_addr)
                32'h0: rdata <= r_header;
                32'h4: rdata <= r_addr32;
                32'h8: rdata <= r_addr64;
                32'hc: rdata <= r_conf  ;
                32'h10: rdata <= r_valid ;
            endcase
        end
    end







endmodule

