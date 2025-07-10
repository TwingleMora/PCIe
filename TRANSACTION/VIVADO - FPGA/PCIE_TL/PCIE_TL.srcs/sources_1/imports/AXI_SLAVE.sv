module AXI_SLAVE#(parameter ADDR_WIDTH = 32, parameter DATA_WIDTH = 32)
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





	localparam ADDRLSB = $clog2(DATA_WIDTH)-3;
    localparam INPUTS_BYTES = 8;
    localparam INPUTS_DEPTH = INPUTS_BYTES / 4 /* Word */;

//  [A][B]
//  [Valid][Op]
//  [Out]
//


wire [15:0] A, B, OUT;
wire [7:0]  OP;
wire Valid;
logic [31:0] INPUTS  [INPUTS_DEPTH];
logic [31:0] OUTPUTS               ;
logic        Valid_Out;

always@(negedge aresetn) begin
    if(!aresetn) begin
        for(int x = 0; x < INPUTS_DEPTH; x++) begin
            INPUTS[x] <= 0;
        end
        OUTPUTS <= 0;
    end
end


/* wire write_req = awready && awvalid;
wire write_ack = bready && bvalid;

wire write_transfer = wready && wvalid;

reg write_requested; */



   /////////////////////////////////////////////////////////////////////////////////////////////////////////////
  //////////////////////////////////////////////// AXI STRB ///////////////////////////////////////////////////
 /////////////////////////////////////////////////////////////////////////////////////////////////////////////
function logic [DATA_WIDTH-1: 0] return_stribed;
input logic [(DATA_WIDTH/8)-1:0]    strb;
input logic [DATA_WIDTH-1:0]        current_data;
input logic [DATA_WIDTH-1:0]        assigned_data;

    logic [DATA_WIDTH-1:0] RET;
    for(int x = 0; x<(DATA_WIDTH/8); x++) begin
        RET[(x*8)+:8] = strb[x]?assigned_data[(x*8)+:8] : current_data[(x*8)+:8];
    end
    return RET;

endfunction

    /////////////////////////////////////////////////////////////////////////////////////////////////////////////
   /////////////////////////////////////////////////////////////////////////////////////////////////////////////
  /////////////////////////////////////////////// AXI WRITE ///////////////////////////////////////////////////
 /////////////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////////////////////
logic                                       axil_write_ready;
logic [ADDR_WIDTH - ADDRLSB -1 : 0]         awskd_addr;
logic [DATA_WIDTH-1 : 0]                    wskd_data;
logic [(DATA_WIDTH/8)-1 : 0]                wskd_strb;

logic                                       awskd_valid;
logic                                       wskd_valid;

logic axil_awready;
logic axil_wready;

logic axil_bvalid;



assign bvalid           = axil_bvalid;
// assign axil_write_ready = axil_awready;
assign axil_write_ready = (awskd_valid && wskd_valid) &&(!bvalid||bready);

  ////////////////////////////////////////////////////////////
 ///////////////////// AXI WR(B) RESP ///////////////////////
/////////////////////////////////////////////////////////////
    assign bresp  = 0;
//  assign bready = 1; in master
always@(posedge aclk or negedge aresetn) begin
    if(!aresetn) begin
        axil_bvalid <= 0;
    end
    else begin
        if(axil_write_ready) //bvalid 1 saying there's  a transaction going on here and when bvalid is asserted and bready is not you can't accept another write
            axil_bvalid <= 1;
        else if(bready)
            axil_bvalid <= 0;
    end


end
    
  ///////////////////////////////////////////////////////////
 ///////////////////// AXI AW & W CH ///////////////////////
///////////////////////////////////////////////////////////

 skid_buffer #(.OPT_OUTREG(0), .DATA_WIDTH(ADDR_WIDTH-ADDRLSB)) axilawskid
 (.clk(aclk), .rst(aresetn), .i_valid(awvalid), .i_ready(axil_write_ready), .i_data(awaddr[ADDR_WIDTH-1:ADDRLSB]), 
 .o_valid(awskd_valid), .o_ready(awready), .o_data(awskd_addr)); 

 skid_buffer #(.OPT_OUTREG(0), .DATA_WIDTH(DATA_WIDTH + (DATA_WIDTH/8))) axilwskid 
 (.clk(aclk), .rst(aresetn), .i_valid(wvalid), .i_ready(axil_write_ready), .i_data({wdata, wstrb}), 
 .o_valid(wskd_valid), .o_ready(wready), .o_data({wskd_data, wskd_strb}));

	// assign 	awskd_addr = awaddr[ADDR_WIDTH-1:ADDRLSB];
    // assign   awskd_valid = awvalid;

	// assign	wskd_data  = wdata;
	// assign	wskd_strb  = wstrb;
    // assign   wskd_valid = wvalid

    // assign   axil_write_ready    = axil_awready; (axil_write = axil_awready)
    // assign   awready             = axil_awready;
    // assign   wready              = axil_wready;
always@(posedge aclk or negedge aresetn) begin
    if(!aresetn) begin
        axil_awready <= 0;
        axil_wready  <= 0;
    end
    else begin
        axil_awready <= /* ~axil_awready  && */ ((awskd_valid) && (wskd_valid)) && ((!bvalid) || (bready)); // bvalid && ~bready brings that to zero
        axil_wready  <= /* ~axil_awready  && */ ((awskd_valid) && (wskd_valid)) && ((!bvalid) || (bready)); // if(bready) then bvalid will be 0 the next cycle;
        //but there's no problem                                                                                                        
        //no there's a transaction after that for some reason awvalid is high and wvalid is high and bready is high you can't continue
        //~awready, why? whyyyyyyyyy? why??   
        //when every thing is ready no stall and awready is true 
        //(now i have ) "no back pressure" bready=1,"new wr request" valids=1, awready=1  == make ==> awready = 0; why?
        // If I gave ready for these transaction what happen? I get "axil_write_ready" which means -next cyc- I write "wdata" @ "awaddr"
        // What the problem
    end
end

  ///////////////////////////////////////////////////////////
 ////////////////////// REAL WRITING ///////////////////////
///////////////////////////////////////////////////////////
always@(posedge aclk or negedge aresetn)
begin
    if(!aresetn) begin
        for(int x = 0; x < INPUTS_DEPTH; x++) begin
            INPUTS[x] <= 0;
        end
    end
    else begin
        if(axil_write_ready) begin //you're not allowed to write once any problem happen
            if(awskd_addr!=1) begin
                INPUTS[1][16]<=1'b0;//it doesn't matter whether it's 
            end
            INPUTS[awskd_addr] <= return_stribed(wskd_strb, INPUTS[awskd_addr], wskd_data);
        end
        else begin
            INPUTS[1][16]<=1'b0;//0x0
        end
    end
end

// ------------------------------------------------------------------------------------------------------------------- //





// ------------------------------------------------------------------------------------------------------------------- //
// ------------------------------------------------------------------------------------------------------------------- //
// ------------------------------------------------------------------------------------------------------------------- //
// ------------------------------------------------------------------------------------------------------------------- //
// ------------------------------------------------------------------------------------------------------------------- //





// ------------------------------------------------------------------------------------------------------------------- //


    /////////////////////////////////////////////////////////////////////////////////////////////////////////////
   ///////////////////////////////////////////////////////////////////////////////////////////////////////////// 
  /////////////////////////////////////////////// AXI READ ////////////////////////////////////////////////////  
 /////////////////////////////////////////////////////////////////////////////////////////////////////////////   
/////////////////////////////////////////////////////////////////////////////////////////////////////////////

/* set [rvalid, arready] */
/* notes:
rvalid act as acknowledge (acknowledge supposed to be (rvalid && rready))
*/
logic                                       axil_read_ready;
logic [ADDR_WIDTH - ADDRLSB -1 : 0]         arskd_addr;
logic                                       arskd_valid;

logic                                       axil_arready;
logic                                       axil_rvalid;
logic  [DATA_WIDTH-1:0]                     axil_rdata;


logic FIFO_RdEn;
logic FIFO_WrEn;

logic [DATA_WIDTH-1 : 0] FIFO_DataIn;
logic [DATA_WIDTH-1 : 0] FIFO_DataOut;

logic FIFO_Empty;




/*  
rvalid is registered
 <axil_read_ready = arvalid && (arready=~rvalid)>: rvalid 
*/






  ////////////////////////////////////////////////////////////
 ////////////////////// AXI AR & R CH ///////////////////////
////////////////////////////////////////////////////////////

 skid_buffer #(.OPT_OUTREG(0), .DATA_WIDTH(ADDR_WIDTH-ADDRLSB)) axilarskid
 (.clk(aclk), .rst(aresetn), .i_valid(arvalid), .i_ready(axil_read_ready), .i_data(araddr[ADDR_WIDTH-1:ADDRLSB]), 
 .o_valid(arskd_valid), .o_ready(arready), .o_data(arskd_addr)); 

// assign	axil_read_ready = (arvalid && arready);
assign	axil_read_ready = (arskd_valid && (!rvalid || rready));
//arskd_valid is i_valid || tr_valid
// assign  arskd_addr = araddr[ADDR_WIDTH-1:ADDRLSB]; 
// assign  arready = axil_arready;


assign  rvalid = axil_rvalid;
assign  rdata = axil_rdata;

assign rresp = 0;
// always@(*) begin
//     axil_arready = ~ axil_rvalid; // why?? , you can't have read transaction when already there's a transaction
// end
always@(posedge aclk or negedge aresetn) begin
    if(!aresetn) begin
        axil_rvalid <= 0;
    end
    else begin
        if(axil_read_ready) begin
            axil_rvalid <= 1&&!FIFO_Empty;
        end
        else if(rready) begin //rready => !rvalid
            axil_rvalid <= 0;
        end
    end
end

//

  ///////////////////////////////////////////////////////////
 ////////////////////// REAL READING ///////////////////////
///////////////////////////////////////////////////////////





FIFO_D #(.DEPTH(32), .DATA_WIDTH(DATA_WIDTH)) fifo 
(
.clk(aclk), 
.rst(aresetn), 
/* input  logic */                    .WrEn(FIFO_WrEn), 
/* input  logic */                    .RdEn(FIFO_RdEn),
/* input  logic [DATA_WIDTH-1:0] */   .DataIn(FIFO_DataIn),
/* output logic [DATA_WIDTH-1:0] */   .comb_DataOut(FIFO_DataOut),
// /* output logic */                    .Full(), 
/* output logic */                    .Empty(FIFO_Empty)
// /* output logic [DATA_WIDTH-1:0] */   .DataOut(),
// /* output logic */                    .AlmostEmpty,
// /* output logic */                    .AlmostFull
);

always@(posedge aclk or negedge aresetn) 
begin
    if(!aresetn) begin
        axil_rdata <= 0;
    end
    //rvalid = 1: there's a read request, rready = 1: I'm ready to accept it::: if (rvalid && !rready) that mean there's a read request and the master is not 
    //ready for the completion, if rvalid is 1 it doesn't matter whether there's rvalid(rd req) or not => you update rdata
    // !rvalid -> rready(master), !rvalid -> !rready(master)
 	else if (!rvalid || rready) //RVALID means there's read request, !RREADY means if there's RVALID it's not accepted yet in the Master
	begin
		case(arskd_addr)
		0,1:	axil_rdata	<= INPUTS[arskd_addr];
		2: 
        begin
        	    //if(Valid_Out) begin
            axil_rdata	        <= FIFO_DataOut;
            OUTPUTS[16]         <= 1'b0   ;
                //end 
        end
		endcase
end
end

always@(*) begin
    begin
        FIFO_RdEn = 0;
        if (!rvalid || rready) begin
            case(arskd_addr)
            2: 
            begin
                    //if(Valid_Out) begin
                FIFO_RdEn           =  axil_read_ready   ;
                    //end 
            end
            endcase
        end
    end

end
reg Value_Stored;
//internal logic
assign A            =  INPUTS[0][31:16]  ;
assign B            =  INPUTS[0][15:0]   ;
assign Valid        =  INPUTS[1][16]     ;
assign OP           =  INPUTS[1][15:0]   ;
assign OUT          =  OUTPUTS[15:0]     ;
assign Valid_Out    =  OUTPUTS[16]       ;
logic [15:0] ALU_OUT;
always@(*) begin
    case(OP)
    0: ALU_OUT = A + B;
    1: ALU_OUT = A - B;
    endcase
end

// reg [1:0] transaction_num;
// always@(posedge aclk or negedge aresetn) begin
//     if(!aresetn) begin
//         transaction_num<=0;
//     end
//     else begin
//         if(!awskd_valid)
//         begin
//             Value_Stored<=0;
//         end
//         else if(Valid) begin
//             Value_Stored<=1;
//         end
//     end
// end
always@(*) begin
    if(Valid) begin
        FIFO_WrEn = 1;
        FIFO_DataIn = ALU_OUT;
        
    end
    else begin
        FIFO_WrEn = 0;
        FIFO_DataIn = 0;
    end
end

// always@(posedge aclk or negedge aresetn) begin
//     if(!aresetn) begin
//         OUTPUTS <= 0;
//     end
//     else begin
//        if(Valid) begin
//         OUTPUTS         <= ALU_OUT;
//         INPUTS[1][16]   <= 1'b0;

//         if(!Valid_Out) begin
//             OUTPUTS[16]     <= 1'b1;
//         end
//        end 

//     end
// end


// MEM #(.DEPTH(3), .DATA_WIDTH(DATA_WIDTH))
// ( 
//     /* input logic */                       .clk(clk),

//     /* input logic [ADDR_WIDTH-1:0] */      .address(),
//     /* input logic [DATA_WIDTH-1:0] */      .data_in(),
//     /* input logic */                       .wr_en(),

//     /* output logic [DATA_WIDTH-1:0] */     .data_out()

// );


endmodule