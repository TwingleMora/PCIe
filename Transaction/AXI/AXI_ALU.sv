module APB_ALU #(parameter DATA_SIZE = 4, parameter REGISTER_SIZE = 4, parameter ADDR_WIDTH = 32, parameter MEMORY_DEPTH = 3) //Slave
(
    input  logic        ACLK, 
    input  logic        ARESETn,

  ///////////////////////////////////////
 //////////// AXI INTERFACE ////////////
///////////////////////////////////////
    ////AW
    input   logic   [ADDR_WIDTH-1:0]         S_AWADDR,
    input   logic   [1:0]                    S_AWBURST,
    input   logic   [2:0]                    S_AWSIZE,
    input   logic   [7:0]                    S_AWLEN,
    input   logic                            S_AWVALID,
    output  logic                            S_AWREADY,
    input   logic   [7:0]                    S_AWID,

    ////W
    input   logic   [DATA_WIDTH-1:0]         S_WDATA,
    input   logic   [(DATA_WIDTH/8)-1:0]     S_WSTRB,
    input   logic                            S_WLAST,
    input   logic                            S_WVALID,
    output  logic                            S_WREADY,

    ////B
    output  logic   [1:0]                    S_BRESP,
    output  logic                            S_BVALID,
    input   logic                            S_BREADY,
    output  logic   [7:0]                    S_BID,

    ////AR
    input  logic   [ADDR_WIDTH-1:0]          S_ARADDR,
    input  logic   [1:0]                     S_ARBURST,
    input  logic   [2:0]                     S_ARSIZE,
    input  logic   [7:0]                     S_ARLEN,
    input  logic                             S_ARVALID,
    output logic                             S_ARREADY,
    input  logic   [7:0]                     S_ARID,


    ////R
    output  logic  [DATA_WIDTH-1:0]          S_RDATA,
    output  logic  [1:0]                     S_RRESP,
    output  logic                            S_RLAST,
    output  logic                            S_RVALID,
    input   logic                            S_RREADY,
    output  logic  [7:0]                     S_RID,


///////////////////////////////////////

    output wire [31:0]      OUT1,
    output wire [31:0]      OUT2,
    output wire [31:0]      OUT3,
    output reg [15:0]       A, B, OP,
    output reg [15:0]       Valid,
    output reg [15:0]       OUT
);
parameter DATA_WIDTH = DATA_SIZE << 3;
parameter REGISTER_WIDTH = REGISTER_SIZE << 3;
parameter ADDR_LSB = $clog2(REGISTER_WIDTH) - 3;
reg [REGISTER_WIDTH-1:0] REGISTERS [MEMORY_DEPTH];

wire [31:0] WR_REG_ADDR = {{LSB{1'b0}}, S_AWADDR[31:ADDR_LSB]};
wire [31:0] RD_REG_ADDR = {{LSB{1'b0}}, S_ARADDR[31:ADDR_LSB]};






    reg [3:0]  ENABLES[2];
    reg [31:0] SHIFTED_PWDATA;
    reg [31:0] CURRENT_BASE_ADDRESS;
    reg        output_ready;

    wire   [1:0]     OFFSET;
    wire   [1:0]     BASE;
    reg              CURRENT_CYCLE;
    logic            OVERFLOW;
    //  wire   [31:0]      OUT1;
    //  wire   [31:0]      OUT2;
    reg    [3:0]      LARGER_THAN_RO_START;
    reg    [3:0]      SMALLER_THAN_RO_END;
    reg    [3:0]      RO_REGION;
    reg    [31:0]     EFFECTIVE_ADDRESS;



assign OUT1 = REGISTERS[0];
assign OUT2 = REGISTERS[1];
assign OUT3 = REGISTERS[2];


function reg [DATA_WIDTH-1:0] WSTRB_REG;
    input reg [DATA_WIDTH-1 : 0] OLD_REG;
    input reg [DATA_WIDTH-1 : 0] NEW_REG;
    input reg [(DATA_WIDTH/8)-1 : 0] STRB;
    output reg [DATA_WIDTH-1:0] WSTRB_REG;
    for(int x = 0; x<(DATA_WIDTH/8); x++) begin
        if(STRB[x]) begin
            wstrb[(8*x)+7 : x*8] = NEW_REG[(8*x)+7 : x*8];
        end else begin
            wstrb[(8*x)+7 : x*8] = OLD_REG[(8*x)+7 : x*8];
        end
    end
endfunction

typedef enum logic [3:0] {WR_IDLE=0, WR_REQ=1, FIRST_WRITE=2, WR_INC} STATE;
STATE current_write_state, next_write_state;


////// [AW] //////
/*     
    input   logic   [ADDR_WIDTH-1:0]         S_AWADDR,
    input   logic   [1:0]                    S_AWBURST,
    input   logic   [2:0]                    S_AWSIZE,
    input   logic   [7:0]                    S_AWLEN,
    input   logic                            S_AWVALID,
    output  logic                            S_AWREADY,
    input   logic   [7:0]                    S_AWID, 
*/

////// [W] //////
/*
    input   logic   [DATA_WIDTH-1:0]         S_WDATA,
    input   logic   [(DATA_WIDTH/8)-1:0]     S_WSTRB,
    input   logic                            S_WLAST,
    input   logic                            S_WVALID,
    output  logic                            S_WREADY
*/

///// [B] //////
/*    
    output  logic   [1:0]                    S_BRESP,
    output  logic                            S_BVALID,
    input   logic                            S_BREADY,
    output  logic   [7:0]                    S_BID,
*/





wire        write_request;
wire        write_data_transport;
reg  [2:0]  write_iterations;//does each iteration I increase the address 
// yeah let's assume at first that master always provide AxSIZE = REGISTER_SIZE, so write iteration tells how many times I WDATA before
// asserting ready for the next data;
reg [2:0]   write_iterations_counter;

// how to increase address;
reg [7:0] ADDR_INC_COUNTER;

//Iteration_Calc and REQ / Transport Detection 
always@(*) begin
    // Write Iteration Logic
    write_iterations = (DATA_SIZE - AWSIZE)<<2;

    //Write REQ & Write Data Transport
    if(S_AWREADY && S_AWVALID) begin
        write_request = 1;
    end else begin
        write_request = 0;
    end
    if(S_WREADY && S_WVALID) begin

        write_data_transport = 1;
    end else begin 

        write_data_transport = 0;
    end
end
// next_write_state logic
always@(*) begin
    next_write_state = current_write_state;
    if(write_request) begin
            next_write_state = WR_REQ;// else if (!write_data_transport)
            
            if(write_data_transport) begin
                next_write_state = FIRST_WRITE;
            end
    end
    else begin
            case(current_write_state)
                WR_REQ: begin //AWREADY, AWVALID were high, the write response hasn't been sent yet
                    if(write_data_transport) begin
                        next_write_state = FIRST_WRITE;
                    end
                end
                WR_ACC: begin
                // if() begin
                next_write_state = WR_IDLE;
                // end
                end 
            endcase
    end
end



always@(posedge ACLK or negedge ARESETn) begin
    if(!ARESETn) begin
        // for(int x = 0; x < MEMORY_DEPTH; x++) begin
        //     REGISTERS[x] <= 0;
        // end
        current_write_state <= IDLE; 
        S_WREADY <= 0;
        ADDR_INC_COUNTER <= 0;
        write_iterations_counter <= 0;
    end
    else begin
        current_write_state<=next_write_state;
        write_iterations_counter <= 0;
        case(next_write_state)
        
        WR_IDLE: begin

        end
        WR_REQ: begin
            S_AWREADY <= 0;

        end
        WR_ACC: begin//(REQ + VALID TRANSPORT)
            write_iterations_counter <= write_iterations_counter + 1;
            S_AWREADY <= 0;
            //ALL REQ SIGNALS ARE VALID (i used SIZE to calc iterations for the single data entry (wr_itr_counter == itr_counter) stay ready)
            //ALL WR  SIGNALS ARE VALID (WDATA, WSTRB, WLAST)
            //S_WREADY
            if(write_iterations_counter == (write_iterations))
            begin
                S_WREADY <= 1;//Now Master see this and do S_WDATA <= DATA, what about (BUFF_WR_EN)?? "SKID BUFFER"
            end
            REGISTERS[WR_REG_ADDR] <= WSTRB_REG(REGISTERS[REG_ADDR], S_WDATA, S_WSTRB);
        end
        
        endcase

    end

end

//////[ AR ]//////
/*  
    input  logic   [ADDR_WIDTH-1:0]          S_ARADDR,
    input  logic   [1:0]                     S_ARBURST,
    input  logic   [2:0]                     S_ARSIZE,
    input  logic   [7:0]                     S_ARLEN,
    input  logic                             S_ARVALID,
    output logic                             S_ARREADY,
    input  logic   [7:0]                     S_ARID, 
*/


//////[ R ]//////
/* 
    output  logic  [DATA_WIDTH-1:0]          S_RDATA,
    output  logic  [1:0]                     S_RRESP,
    output  logic                            S_RLAST,
    output  logic                            S_RVALID,
    input   logic                            S_RREADY,
    output  logic  [7:0]                     S_RID,
*/


always@(posedge ACLK or negedge ARESETn) begin
    if(!ARESETn) begin
        S_RDATA <= 0;        
    end
    else begin
        //if
        S_RDATA <= REGISTERS[RDD_REG_ADDR];
    end

end



always@(*)
begin
    A     =  REGISTERS[0][15:0];
    B     =  REGISTERS[0][31:16];
    OP    =  REGISTERS[1][15:0];
    Valid =  REGISTERS[1][31:16];
//-----------------------------------
    OUT = 0;
    if(OP==0)
        OUT = A+B;
    if(OP==1)
        OUT = A-B;
    if(OP==2)
        OUT = A&B;
    if(OP==3)
        OUT = A|B;
end






endmodule
