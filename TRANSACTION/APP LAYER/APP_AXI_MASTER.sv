module APP_AXI_MASTER #(parameter DATA_WIDTH = 32 ,parameter ADDR_WIDTH = 32)
(
    //-----------------------------AXI-----------------------------------
    
    // Global Signals 
    input  logic                              aclk,
    input  logic                              aresetn,

    input  logic  [DATA_WIDTH-1:0]            i_data,    //data bus                        
    input  logic  [ADDR_WIDTH-1:0]            i_addr,    //address bus                            
    input  logic                              i_rd_wr, i_valid,   //control bus
    output logic                              o_ack,                             
    


    // AW Channel
    output logic [ADDR_WIDTH-1:0]           awaddr,
    // output logic [7:0]                   awlen,  // number of transfers in transaction
    // output logic [2:0]                   awsize,  // number of bytes in transfer  //                            000=> 1, 001=>2, 010=>4, 011=>8, 100=>16, 101=>32, 110=>64, 111=>128
    // output logic [1:0]                   awburst,
    input  logic                            awready,
    output logic                            awvalid,

    // W Channel
    output logic [DATA_WIDTH-1:0]           wdata, 
    output logic [(DATA_WIDTH/8)-1:0]       wstrb, 
    // output logic                            wlast, 
    output logic                            wvalid,
    input  logic                            wready,

    // B Channel
    input  logic [1:0]                      bresp,                         
    input  logic                            bvalid,                         
    output logic                            bready,                         

    // AR Channel
    output logic [ADDR_WIDTH-1:0]           araddr,
    // output logic [7:0]                      arlen,
    // output logic [2:0]                      arsize,
    // output logic [1:0]                      arburst,
    input  logic                            arready,
    output logic                            arvalid,
                                            

    // R Channel                            
    input  logic [DATA_WIDTH-1:0]           rdata,
    input  logic [1:0]                      rresp,
    // input  logic                            rlast,
    input  logic                            rvalid,
    output logic                            rready
);

localparam ADDR_LSB = $clog2(DATA_WIDTH)-3;

assign wstrb = 4'hf;

assign bready = 1;

always@(posedge aclk or negedge aresetn) begin
    if(!aresetn) begin
        awaddr  <= 0;
        awvalid <= 0;     
    end
    else begin
        // awaddr  <= 0;
        // awvalid <= 0;     
        if(i_valid&&i_rd_wr) begin
            awaddr <= i_addr;
            awvalid <= 1;
        end
        else if(arready) begin
            awvalid <=0;
        end
    end
end


always@(posedge aclk or negedge aresetn) begin
    if(!aresetn) begin
        wdata <= 0;
        // wstrb <= 0;
        wvalid <= 0;
    end
    else begin
        if(i_valid&&i_rd_wr) 
        begin
            wdata <= i_data;
            wvalid <= 1;
        end
        else if(wready) begin
            wvalid <= 0;
        end
    end
end

assign rready = 1;
always@(posedge aclk or negedge aresetn) begin
    if(!aresetn) begin
        araddr<=0;
        arvalid<=0;
    end
    else begin
        if(i_valid&&!i_rd_wr) 
        begin
            araddr<= i_addr;
            arvalid <= 1;
        end
        else if(arready) begin
            araddr <= 0;
            arvalid <= 0;
        end
    end
end


always@(*)
begin
    o_ack = 0;
 case(i_rd_wr)
 1'b0: begin
    o_ack = bready && bvalid;
 end
 1'b1: begin
    o_ack = rready && rvalid;
 end
 endcase

end




endmodule