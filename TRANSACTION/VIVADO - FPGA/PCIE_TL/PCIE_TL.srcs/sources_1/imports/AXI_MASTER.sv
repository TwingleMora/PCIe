module AXI_MASTER#(parameter ADDR_WIDTH = 32, parameter DATA_WIDTH = 32)
(
    //-------------------------------------------------------------------
    
    //  input  logic  [7:0]     tag,
    //  input  logic            EP,
    
    input  logic            VALID,
    output logic            ACK,

    input  logic  [2:0]     tlp_mem_io_msg_cpl_conf, //X;
    input  logic            tlp_address_32_64, //X;
    input  logic            tlp_read_write, 
    //input  logic          tlp_conf_type,
    input  logic  [15:0]    requester_id,
    input  logic  [7:0]     tag,
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

    // input  logic           valid,
    // input  logic           received_valid,

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
    output logic                            rready,


    // ----------------------------------------------------------------------
     
    // ----------------------------------------------------------------------
    output logic          RX_B_tlp_read_write,       //
    output logic [2:0]    RX_B_TC,                   //
    output logic [2:0]    RX_B_ATTR,                 //
    output logic [7:0]    RX_B_tag,                  //
    output logic [15:0]   RX_B_requester_id,         //
    output logic [11:0]   RX_B_byte_count,           //
    output logic [6:0]    RX_B_lower_addr,           //
    output logic [2:0]    RX_B_completion_status,    //
    //-----------------------------------------------------------------------------------------           
    output logic [31:0]   RX_B_data1,                //
    output logic [31:0]   RX_B_data3,                //
    output logic [31:0]   RX_B_data2,                //
    //-----------------------------------------------------------------------------------------                   
    output logic          RX_B_Wr_En,                 //
    //-----------------------------------------------------------------------------------------
    // ----------------------------------------------------------------------
    // ----------------------------------------------------------------------
    
    /////////////////////////////////////////////////////
    ////////////////////FIFO TX/////////////////////////
    /////////////////////////////////////////////////////

    output logic               RX_B_TX_DATA_FIFO_WR_EN,
    output logic [31:0]        RX_B_TX_DATA_FIFO_data

    /////////////////////////////////////////////////////
    /////////////////////////////////////////////////////





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


reg [9:0]                         wr_dw_number;
reg [9:0]                         rd_dw_number;

reg [9:0]                         rdata_to_cpl_counter;
reg                               rdata_last;
reg [9:0]                         r_data_length;

logic                             nxt_wr_dw_last;
logic                             nxt_rd_dw_last;

logic   [1:0]                     offset;
logic  [3:0]                      first_dw_be_calc;
logic  [3:0]                      last_dw_be_calc;

logic  [3:0]                      lower_addr_calc;
always@(*) begin
    if(first_dw_be[0]) offset = 0;
    else if(first_dw_be[1]) offset = 1;
    else if (first_dw_be[2]) offset = 2;
    else if(first_dw_be[3]) offset = 3;
    else offset = 0;
end
always@(*) begin
case(offset)
0:{last_dw_be_calc, first_dw_be_calc}  = {last_dw_be, first_dw_be};
1:{last_dw_be_calc, first_dw_be_calc}  = {last_dw_be, first_dw_be}>>1;
2:{last_dw_be_calc, first_dw_be_calc}  = {last_dw_be, first_dw_be}>>2;
3:{last_dw_be_calc, first_dw_be_calc}  = {last_dw_be, first_dw_be}>>3;
endcase
end

always@(*) begin
lower_addr_calc = lower_addr + offset;
end

always@(*) begin

nxt_wr_dw_last = (length - wr_dw_number) == 1;
nxt_rd_dw_last = (length - rd_dw_number) == 1;
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

/* initial begin
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

end */

/*
- awaddr, awvalid
- wdata, wstrb, wvalid
- araddr, arvalid
- rready, 
*/

// always@(*) begin
//     if(rvalid && rready) begin
//         Data_In = rdata;
//     end
// end


//localparam IDLE = 0, OPERANDS = 1, WRITE = 2, READ = 3;
localparam IDLE = 0, WRITE = 1, WRITE_MID = 2, WRITE_LAST = 3, READ = 4, READ_MID = 5, READ_LAST = 6;
logic [2:0] current, next;
assign bready = 1;

assign Empty = !(address<10);

reg finish;
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
    finish = 0;
    case (current) 
    IDLE: begin //0
        if((!ACK&&VALID)) begin //(!ACK&&VALID)
            if(tlp_read_write)
                next = WRITE;
            else
                next = READ;
        end

    end
    WRITE: begin //1
        if(!bvalid || bready) begin //???
            if(length == 1) begin
                next = IDLE;
                finish = 1;
            end
            else if(nxt_wr_dw_last)           
                next = WRITE_LAST;
            else
                next = WRITE_MID; 
        end
    end
    WRITE_MID: begin //3
        if(!bvalid || bready) begin
            if(nxt_wr_dw_last) begin
                next = WRITE_LAST;
            end
        end
    end
    WRITE_LAST: begin //4
        if(!bvalid || bready) begin
            next   = IDLE;      
            finish = 1;          
        end                      
    end


    READ: begin
        if(!rvalid||rready) begin
            if(length == 1) begin
                next = IDLE;
                finish = 1;
            end
            else if(nxt_rd_dw_last) begin
                next = READ_LAST;
            end
            else begin
                next = READ_MID;
            end
        end 
    end


    READ_MID: begin
        if(!rvalid||rready) begin
            if(nxt_rd_dw_last) begin
                next = READ_LAST;
            end
        end
    end


    READ_LAST: begin
        if(!rvalid||rready) begin
            next = IDLE;
            finish = 1;
        end
    end
    endcase

end

//Write
always@(*) begin
    DATA_BUFF_RD_EN = 0;
 case(next) 
    WRITE: begin
    if(/* (bvalid && bready)&& */(next!=current)) begin  //I'm writing @ the begin and I wait for bvalid to write next
    //so @ begininng there's no bvalid
         DATA_BUFF_RD_EN = 1;
    end
    end
    WRITE_MID: begin
         if((!bvalid || bready)) begin //(wready && wvalid) or (awready && awvalid)
         DATA_BUFF_RD_EN = 1;
    end
    end
    WRITE_LAST: begin
         if((!bvalid || bready)&&(next!=current)) begin
         DATA_BUFF_RD_EN = 1;
    end
    end
 endcase
end
always@(posedge aclk or negedge aresetn)
begin
    if(!aresetn) begin
        awaddr  <= 0;   
        awvalid <= 0;   
        wdata   <= 0;   
        wstrb   <= 0;   
        wvalid  <= 0;   
        current <= IDLE; 
        // DATA_BUFF_RD_EN <= 0;
        wr_dw_number <= 0;
        ACK<=0;
    end
    else begin
        ACK<=0;
        case(next)
        IDLE:
        begin //0
        if(finish)
        begin
            ACK <= 1;
        end
            // DATA_BUFF_RD_EN <= 0;
            awaddr  <= 0;
            awvalid <= 0;
            wdata   <= 0;
            wstrb   <= 0;
            wvalid  <= 0; 
        end
        WRITE: begin  //1
            // DATA_BUFF_RD_EN <= 0;
            if(/* !wvalid || (bvalid && bready) */ (next!=current)) begin
                wr_dw_number<=1;
                wdata   <= data;
                // DATA_BUFF_RD_EN <= 1;
                awaddr  <= lower_addr;
                wstrb   <= {(DATA_WIDTH/8){1'b1}};
                wvalid  <= 1;
                awvalid <= 1; //Start Transaction
            end
        end
        WRITE_MID: begin //3
                // DATA_BUFF_RD_EN <= 0;
           // if(/* !wvalid || (bvalid && bready) */ (next!=current)) begin 
                wr_dw_number    <= wr_dw_number + 1;
                wdata           <= data;
                // DATA_BUFF_RD_EN <= 1;
                awaddr          <= awaddr +4;
                wstrb           <= {(DATA_WIDTH/8){1'b1}};
                wvalid          <= 1;
                awvalid <= 1;
           // end
            end
        WRITE_LAST: begin //4
            // DATA_BUFF_RD_EN <= 0;
            if(/* !wvalid || (bvalid && bready) */ (next!=current)) begin
                wr_dw_number<= wr_dw_number + 1;
                wdata   <= data;
                // DATA_BUFF_RD_EN <= 1;
                awaddr  <= awaddr +4;
                wstrb   <= {(DATA_WIDTH/8){1'b1}};
                wvalid  <= 1;
                awvalid <= 1;
            end
        end
        endcase
    end
end


assign rready = 1;
always@(posedge aclk or negedge aresetn) begin
    if(!aresetn) begin
        arvalid <= 0;
        rd_dw_number <= 0;
        araddr <= 0;
        
    end
    else 
    begin
        
        case(next)
        IDLE: begin
            arvalid<=0;
            araddr<= 0;
            rd_dw_number <= 0;
        end
        READ: begin
            // if(current != next) begin
            rd_dw_number <= 1;
            araddr <= lower_addr;
            arvalid <= 1;
//            r_data_length <= length;
            // end
        end
        READ_MID: begin
            rd_dw_number <= rd_dw_number + 1;
            araddr <= lower_addr;
            arvalid <= 1;

        end
        READ_LAST: begin
            rd_dw_number <= rd_dw_number + 1;
            araddr <= lower_addr;
            arvalid <= 1; 
        end
        endcase

    end
end


always@(posedge aclk or negedge aresetn) begin
    if(!aresetn) begin
        RX_B_completion_status <= 0;
        rdata_to_cpl_counter <= 0;
        RX_B_tlp_read_write <= 0;
        RX_B_byte_count <= 0;
        RX_B_lower_addr <= 0;
        RX_B_data1 <= 0;
        RX_B_data2 <= 0;
        RX_B_data3 <= 0;
        RX_B_Wr_En <= 0;
        RX_B_ATTR <= 0;
        RX_B_TC <= 0;
//////////////////////////////////////////////
//////////////////TX FIFO////////////////////
        RX_B_TX_DATA_FIFO_data <= 0;
        RX_B_TX_DATA_FIFO_WR_EN <=0;
//////////////////////////////////////////////
//////////////////////////////////////////////
        r_data_length<=0;
    end
    else begin
        case(next)
        IDLE: begin
        end
        READ: begin
            r_data_length <= length;
        end
        READ_MID: begin
        end
        READ_LAST: begin
        end
        endcase

        rdata_last <= 0;
        RX_B_Wr_En <= 0;

          //////////////////////////////////////////////
         //////////////////TX FIFO////////////////////
        RX_B_TX_DATA_FIFO_data <= 0;
        RX_B_TX_DATA_FIFO_WR_EN <=0;
       //////////////////////////////////////////////
      //////////////////////////////////////////////

        if(rready && rvalid)
        begin
            rdata_to_cpl_counter    <= rdata_to_cpl_counter + 1;
            RX_B_byte_count         <= r_data_length<<2; //*****//
            RX_B_lower_addr         <= lower_addr[6:0];
            RX_B_tlp_read_write     <= 1'b1;//IT's write (1): CPLD
            RX_B_requester_id       <= requester_id;
            RX_B_tag                <= tag;

        //////////////////////////////////////////////
        //////////////////TX FIFO////////////////////
            RX_B_TX_DATA_FIFO_data <= rdata;
            RX_B_TX_DATA_FIFO_WR_EN <=1;
        //////////////////////////////////////////////
        //////////////////////////////////////////////
            case(rdata_to_cpl_counter)
            0: RX_B_data1 <= rdata;
            1: RX_B_data2 <= rdata;
            2: RX_B_data3 <= rdata;
            endcase
        end
        if(rdata_to_cpl_counter == (r_data_length-1))
        begin
            rdata_to_cpl_counter <= 0;
            rdata_last <= 1;
            RX_B_Wr_En <= 1;
            r_data_length <= 0;

        //////////////////////////////////////////////
        //////////////////TX FIFO////////////////////
            RX_B_TX_DATA_FIFO_WR_EN <= 1;
        //////////////////////////////////////////////
        end
    end
end


always@(*) begin
    if(rready && rvalid) begin
        case(rdata_to_cpl_counter)
        0:
        begin

        end
        1:
        begin

        end
        2:
        begin

        end

        endcase

    end
end
////////////////
// logic [3:0] counter;

////////////////

/* //Read
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
 */
//Read
endmodule