module AXI_MASTER#(parameter ADDR_WIDTH = 32, parameter DATA_WIDTH = 32)
(
    //-------------------------------------------------------------------
    
    //  input  logic  [7:0]     tag,
    //  input  logic            EP,
    
    input  logic            VALID,
    output logic            ACK,

    input  logic  [2:0]     tlp_mem_io_msg_cpl_conf,
    input  logic            tlp_address_32_64,
    input  logic            tlp_read_write,
    //input  logic          tlp_conf_type,
    
    input  logic  [3:0]     first_dw_be,
    input  logic  [3:0]     last_dw_be,
    input  logic  [31:0]    lower_addr,

    //calculate OFFSET and M_PSTRB

    input  logic  [9:0]      length,
    input  logic             last_dw,
    input  logic  [31:0]     data,
    input  logic             DATA_BUFF_EMPTY,
    output logic             DATA_BUFF_RD_EN,

    input  logic  [11:0]     config_dw_number,

    //input  logic  [2:0]     TC,
    //input  logic  [2:0]     ATTR,
    //input  logic  [15:0]    device_id,

    //input  logic  [11:0]    byte_count,
    //input  logic  [31:0]    upper_addr,


    //input  logic  [15:0]    dest_bdf_id,

    // input  logic            valid,
    // input  logic            received_valid,

    //input logic             first;
    
    
    
    
    
    
    
    //-----------------------------AXI-----------------------------------
    
    // Global Signals 
    input logic                             aclk,
    input logic                             aresetn,

    // AW Channel
    output logic [ADDR_WIDTH-1:0]           awaddr,
    output logic [7:0]                      awlen,  // number of transfers in transaction
    output logic [2:0]                      awsize,  // number of bytes in transfer  //                            000=> 1, 001=>2, 010=>4, 011=>8, 100=>16, 101=>32, 110=>64, 111=>128
    output logic [1:0]                      awburst,
    input  logic                            awready,
    output logic                            awvalid,

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
    output logic                            arvalid,
                                            

    // R Channel                            
    input  logic [DATA_WIDTH-1:0]           rdata,
    input  logic [1:0]                      rresp,
    input  logic                            rlast,
    input  logic                            rvalid,
    output logic                            rready
);


// MEMORY 1
logic                             RdEn;
logic [(DATA_WIDTH+8)-1:0]        comb_DataOut;
logic [4:0]                       address;
logic                             Full;

logic                             Empty;


// MEMORY 2
logic                             WrEn;
logic [4:0]                       address2;
logic [(DATA_WIDTH)-1:0]          Data_In;
logic [(DATA_WIDTH)-1:0]          Data_Out;

always@(*) begin


end

// FIFO #(.DEPTH(10), .DATA_WIDTH(DATA_WIDTH+8)) fifo 
// (
//     .clk(aclk), 
//     .rst(aresetn), 
//     /* input  logic */                    .WrEn(), 
//     /* input  logic */                    .RdEn(RdEn),
//     /* input  logic [DATA_WIDTH-1:0] */   .DataIn(),
//     /* output logic [DATA_WIDTH-1:0] */   .comb_DataOut(comb_DataOut),
//     /* output logic */                    .Full(Full), 
//     /* output logic */                    .Empty(Empty)
//     // /* output logic [DATA_WIDTH-1:0] */   .DataOut(),
//     // /* output logic */                    AlmostEmpty,
//     // /* output logic */                    AlmostFull
// );

MEM #(.DEPTH(32), .DATA_WIDTH(DATA_WIDTH+8)) MEM_MODULE
( 
/* input logic */                       .clk(aclk),
/* input logic */                       .rst(aresetn),
/* input logic [ADDR_WIDTH-1:0] */      .address(address),
/* input logic [DATA_WIDTH-1:0] */      .data_in(),
/* input logic */                       .wr_en(),

/* output logic [DATA_WIDTH-1:0] */     .data_out(comb_DataOut)

);

MEM #(.DEPTH(32), .DATA_WIDTH(DATA_WIDTH)) MEM_MODULE2
( 
/* input logic */                       .clk(aclk),
/* input logic */                       .rst(aresetn),
/* input logic [ADDR_WIDTH-1:0] */      .address(address2),
/* input logic [DATA_WIDTH-1:0] */      .data_in(Data_In),
/* input logic */                       .wr_en(WrEn),

/* output logic [DATA_WIDTH-1:0] */     .data_out(Data_Out)

);

initial begin
logic [15:0] A =2, B=0;
logic [7:0] OP=0;
@(negedge aclk)
for (int x = 0; x < 10; x++) begin

MEM_MODULE.mem[x] = {OP,A,B};
A++;B++;
OP = $urandom_range(0,1);
end
//@(negedge aclk)
// fifo.NextWrCounter = 10;

//$stop;

end

/*
- awaddr, awvalid
- wdata, wstrb, wvalid
- araddr, arvalid
- rready, 
*/

always@(*) begin
    if(rvalid && rready) begin
        Data_In = rdata;
    end
end


localparam IDLE = 0, OPERANDS = 1, OP_VALID = 2, READ = 3;
logic [2:0] current, next;
assign bready = 1;

assign Empty = !(address<10);
always@(posedge aclk or negedge aresetn) begin
    if(!aresetn) begin
        current<=IDLE;
    end
    else begin
        current<= next;
    end
end
always@(*) begin
    next = current;
    case (current) 
    IDLE: begin
        if(VALID) begin
            next = OPERANDS;
        end

    end
    OPERANDS: begin
        if(bvalid&&bready) begin
            next <= OP_VALID;
        end 
    end
    OP_VALID: begin
        if(Empty) begin 
            next <= IDLE;
        end
        else if(bvalid&&bready) begin
            next <= OPERANDS;
        end
    end
    endcase

end
//Write
always@(posedge aclk or negedge aresetn)
begin
    if(!aresetn) begin
        awaddr  <= 0;
        awvalid <= 0;
        wdata   <= 0;
        wstrb   <= 0;
        wvalid  <= 0;
        current <= IDLE;
    end
    else begin
        case(next)
        IDLE:
        begin
            awaddr  <= 0;
            awvalid <= 0;
            wdata   <= 0;
            wstrb   <= 0;
            wvalid  <= 0;
        end
        OPERANDS: begin
            if(!wvalid || (bvalid && bready)) begin
                wdata   <= comb_DataOut[31:0];
                awaddr  <= 0;
                wstrb   <= {(DATA_WIDTH/8){1'b1}};
                wvalid  <= ~Empty;
                awvalid <= 1;
            end
        end
        OP_VALID: begin
            if(!wvalid || (bvalid && bready)) begin
                wdata   <= {{15{1'b0}},1'b1,{8{1'b0}}, comb_DataOut[39:32]};
                awaddr  <= 4;
                wstrb   <= {(DATA_WIDTH/8){1'b1}};
                wvalid  <= ~Empty;
                awvalid <= 1;
            end
            end
        endcase
    end
end

////////////////
logic [3:0] counter;

////////////////

//Read
assign rready = 1;
always@(posedge aclk or negedge aresetn)
begin
    if(!aresetn) begin
        araddr  <=0;
        arvalid <=0;
        counter <=1;
        // wdata<=0;
        // wstrb<=0;
        
    end
    else begin
        if(counter != 0) begin
            counter <= counter + 1;
        end
        // case(current)
        // IDLE:
        // begin
        //     araddr <=0;
        //     arvalid <=0;
        //     // wdata<= 0;
        //     // wstrb<= 0;     
        // end
        // OP_VALID: begin
        //     araddr  <= 8;
        //     arvalid <= 1; // Transaction;
        // end
        // READ: begin
        //     arvalid <= 0;
        // end
        // endcase
        if(counter == 0)
        begin
            arvalid <= 1;
            araddr  <= 8;
        end
    end
end
always@(*) begin
    if(rready && rvalid) begin
        WrEn = 1;
    end
    else begin
        WrEn = 0;
    end

end

always@(posedge aclk or negedge aresetn) begin// I mistakenly wrote clk instead of aclk
    if(!aresetn) begin
        address <= 0;
        address2 <= 0;
    end
    else begin

        //---------------------WRITE------------------------------    
        case(next)
        IDLE: begin
        
        end
        OPERANDS: begin
            
        end
        OP_VALID: begin
            if(bvalid && bready)
                address<= address+1;//next operands
        end
        
        endcase


        //---------------------READ------------------------------    
        if(rready && rvalid) begin
            address2 <= address2 + 1;
        end

    end
    
end

//Read
endmodule