
module TL_TX_ENCODER_MAL
(
input   logic        clk, //1
input   logic        rst, //2
input   logic        valid, //3
input   logic  [2:0] fmt, //4
input   logic  [4:0] type_,//5
input   logic  [2:0] TC,//6
input   logic  [2:0] ATTR,//7
//input       EP,
input   logic  [15:0] device_id, //8
input   logic  [7:0]  tag,// 9

input   logic  [11:0] byte_count, //10 <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

input   logic  [31:0] upper_address,//11
input   logic  [31:0] lower_address,//12

input   logic  [15:0] bdf_id,//13
input   logic  [9:0]  config_dw_number, //14

input   logic  [31:0] data,//15

// Completion Protocol
input   logic  [15:0] CPL_REQUESTER_ID, // => H2_CPL (Requester ID) 17
input   logic  [7:0]  CPL_REQUESTER_TAG, // => H2_CPL (Tag) 18
input   logic  [2:0]  completion_status, //19
/* 
input   logic         BCM
*/
input   logic  [11:0] CPL_REQUESTER_TOTAL_BYTE_COUNT, // ?? 20
input   logic  [6:0]  CPL_LOWER_ADDRESS, // ?? 21

//Temporary INTF
    
input   logic         CPL_HNDLR_FIFO_NOT_EMPTY,
output  logic         CPL_HNDLR_FIFO_RD_EN, //16
output  logic  [1:0]  P_NP_CPL, //22
output  logic         HEADER_DATA, //23
output  logic         PNPC_BUFF_WR_EN,//24

output  logic         tlp_start_flag,
output  logic         tlp_end_flag,

output  logic         fsm_started,
output  logic         fsm_finished,
output  logic         data_address,

output  logic  [31:0]  TLP //25
);
typedef enum reg [3:0] {IDLE=0, H0, H1_REQ, H_ADDR32, H_ADDR64, H_ID,  H1_CPL, H2_CPL, H1_MSG, DATA, FINISH} State;
    localparam reg R = 1'b0;

    //localparam [1:0] MEMORY_TYPE = 2'b00, IO_TYPE = 2'b, CMPL_TYPE, MSG_TYPE
    
    logic  [11:0] completion_byte_count = 0; // ?? 20
    logic  [6:0]  completion_lower_address = 0; // ?? 21

    //logic  [31:0] TLP

    reg  [1:0] packet_classification;
    reg  [3:0] First_DW_BE, Last_DW_BE;
    reg  [9:0] Length; // <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
    /*
    Length
    WrIO: 1
    WrConf0_1: 1
    Msg: 1

    Mem: 1 ~ 1024
    */
    reg [31:0]  next_TLP;
    reg [1:0]   next_P_NP_CPL;
    reg         next_PNPC_BUFF_WR_EN;
    reg         next_HEADER_DATA;
    reg         next_CPL_HNDLR_FIFO_RD_EN;


    reg         next_fsm_started;
    reg         next_fsm_finished;
    

    reg         next_tlp_start_flag;
    reg         next_tlp_end_flag;

    reg [1:0]   counter,
                next_counter;

    reg  [1:0]  next_data_address;

    reg [1:0]   last_dw_be;

    State       current,
                next; 

    reg [11:0] length_mult_by_4;

            //////////////////////////////////////////////////////////////
           //////////////////////////////////////////////////////////////
          ///////////////////// MALFORMED //////////////////////////////
         /////////////////////    LIST   //////////////////////////////
        //////////////////////////////////////////////////////////////
       //////////////////////////////////////////////////////////////
/*  */
    wire [9:0] mal_length = Length /* + 1'b1 */ /* - 1'b1 */;




    //packet classification
    always@(*)
    begin
        case({fmt[1],type_[4:3],type_[1]})
                    4'b1_00_0, 4'b1_10_0, 4'b1_10_1: //Posted
                    begin
                        packet_classification = 2'b00;
                        
                    end
                    4'b0_00_1, 4'b1_00_1, 4'b0_00_0: //Non Posted
                    begin
                        packet_classification = 2'b01;
                        
                    end
                    4'b0_01_1, 4'b1_01_1: //Completion
                    begin
                        packet_classification = 2'b11;
                    end
                    endcase
    end

    //RF - FSM Handshake
    always@(posedge clk or negedge rst)
    begin
        if(!rst)
        begin
            fsm_started <= 1'b0;
            fsm_finished <= 1'b1;

            tlp_start_flag <= 1'b0;
            tlp_end_flag <= 1'b0;
        end
        else
        begin
            fsm_started <= next_fsm_started;
            fsm_finished <= next_fsm_finished;

            tlp_start_flag <= next_tlp_start_flag;
            tlp_end_flag <= next_tlp_end_flag;
        end
    end
    //Completion Buffer
    always@(posedge clk or negedge rst)
    begin
        if(!rst)
        begin
            CPL_HNDLR_FIFO_RD_EN <= 0;
        end
        else
        begin
            CPL_HNDLR_FIFO_RD_EN <= next_CPL_HNDLR_FIFO_RD_EN;
        end
    end

    //VC Buffer
    always@(posedge clk or negedge rst)
    begin
        if(!rst)
        begin
            P_NP_CPL              <= 0;
            HEADER_DATA           <= 0;
            PNPC_BUFF_WR_EN       <= 0;
        end
        else
        begin
            P_NP_CPL              <= next_P_NP_CPL;
            HEADER_DATA           <= next_HEADER_DATA;
            PNPC_BUFF_WR_EN       <= next_PNPC_BUFF_WR_EN;
        end
    end


     /////////////////////////////////////////////////////////////////
    ///////////////////// DONT CHANGE ///////////////////////////////
   /////////////////////////////////////////////////////////////////

    wire logic [11:0] byte_count_sub_one =  byte_count-1'b1;
    // wire logic [11:0] shifted_byte_count_sub_one =  byte_count_sub_one>>2;
    // wire logic [11:0] shifted_byte_count_sub_one_plus_one =  shifted_byte_count_sub_one+1;


    reg [1:0] offset;
    reg [3:0] BYTECOUNT_TO_First_DW_BE;
    reg [3:0] BYTECOUNT_TO_Last_DW_BE;
    

    reg       byte_count_gte_dw;
    reg       byte_count_gt_dw;
    always@(*)
    begin
        if(current == IDLE && valid)
            begin
               offset = lower_address[1:0];
               byte_count_gte_dw = |byte_count[11:2];
               byte_count_gt_dw = (|byte_count[11:3]) | (byte_count[2] & |byte_count[1:0]);
               if(byte_count_gte_dw==0) begin                
                    case(byte_count[1:0])
                        2'b00:
                            BYTECOUNT_TO_First_DW_BE = 4'b0000;
                        2'b01:
                            BYTECOUNT_TO_First_DW_BE = 4'b0001;
                        2'b10:
                            BYTECOUNT_TO_First_DW_BE = 4'b0011;
                        2'b11:
                            BYTECOUNT_TO_First_DW_BE = 4'b0111;
                    endcase
               end
               else begin
                    BYTECOUNT_TO_First_DW_BE = 4'b1111;
               end

                Length     = (byte_count_sub_one>>2)+1;
                
                length_mult_by_4 = (({2'b00,Length}-12'b1)<<2);
                
                //last_dw_be = ((({2'b00,Length})<<2) - ((byte_count)))&({12{byte_count_gte_dw}});
                //last_dw_be = ((byte_count-1)>>2 + 1)<<2-byte_count - lower_address[1:0];
                last_dw_be = byte_count[1:0];
                
                case({byte_count_gt_dw, last_dw_be})
                    4'b000, 3'b001, 3'b010, 3'b011: 
                        BYTECOUNT_TO_Last_DW_BE = 4'b0000;
                    4'b100:
                        BYTECOUNT_TO_Last_DW_BE = 4'b1111;
                    3'b101:
                        BYTECOUNT_TO_Last_DW_BE = 4'b0001;
                    3'b110:
                        BYTECOUNT_TO_Last_DW_BE = 4'b0011;
                    3'b111:
                        BYTECOUNT_TO_Last_DW_BE = 4'b0111;
                    default:
                        BYTECOUNT_TO_Last_DW_BE = 4'b0000;
                endcase

                case(offset)
                    2'b00: {Last_DW_BE, First_DW_BE} = {BYTECOUNT_TO_Last_DW_BE, BYTECOUNT_TO_First_DW_BE};
                    2'b01: {Last_DW_BE, First_DW_BE} = {BYTECOUNT_TO_Last_DW_BE, BYTECOUNT_TO_First_DW_BE}<<1;
                    2'b10: {Last_DW_BE, First_DW_BE} = {BYTECOUNT_TO_Last_DW_BE, BYTECOUNT_TO_First_DW_BE}<<2;
                    2'b11: {Last_DW_BE, First_DW_BE} = {BYTECOUNT_TO_Last_DW_BE, BYTECOUNT_TO_First_DW_BE}<<3;
                endcase

            end
    end

    always@(posedge clk or negedge rst)
    begin 
        if(!rst)
        begin 
            TLP         <= 0;
            current     <= IDLE;
            counter     <= 0;
            data_address <= 0;
        end
        else
        begin
            
            TLP     <= next_TLP; 
            current <= next;
            counter <= next_counter;
            data_address <= next_data_address;

            
        end
    end
   
    always@(*)
    begin
        next_TLP = TLP;
        next = current;
        next_counter = 0;
        next_data_address = 0;
        next_CPL_HNDLR_FIFO_RD_EN = 0;
        
        next_fsm_started = fsm_started;
        next_fsm_finished = fsm_finished;
        
        next_P_NP_CPL = P_NP_CPL;
        next_HEADER_DATA = HEADER_DATA;
        next_PNPC_BUFF_WR_EN = PNPC_BUFF_WR_EN;

        
        next_tlp_start_flag = 1'b0;
        next_tlp_end_flag = 1'b0;

        case(current)
            IDLE:
            begin
                if(valid)
                begin
                    next = H0;
                    next_TLP = {fmt, type_, R, TC, R, ATTR[2], R, 1'b0, 1'b0, 1'b0, ATTR[1:0], 2'b00, (mal_length)};
                    
                    // Extra Logic For VC Buffers
                    next_P_NP_CPL = packet_classification;
                    next_HEADER_DATA = 1'b0;
                    next_PNPC_BUFF_WR_EN = 1'b1;
                    

                    next_fsm_started = 1'b1;
                    next_fsm_finished = 1'b0;

                    next_tlp_start_flag = 1'b1;
                    next_tlp_end_flag = 1'b0;
                end
            end
            H0:
            begin
                
                case(type_[4:3])
                    2'b00: //Memory Or IO
                    begin
                        next = H1_REQ;
                        next_TLP = {device_id, tag, Last_DW_BE, First_DW_BE};
                    end
                    2'b01: //Completion
                    begin
                        next_CPL_HNDLR_FIFO_RD_EN = 1;
                        if(CPL_HNDLR_FIFO_NOT_EMPTY)
                        begin
                            
                        end
                        next = H1_CPL;
                        next_TLP = {device_id, completion_status, 1'b0, byte_count};
                    end
                    2'b10: //Message
                    begin
                        next = H1_MSG;
                        //next_TLP = {};
                    end
                endcase
            end

            H1_REQ:
            begin
                case(type_[2:1])
                    2'b00:
                    begin
                        if (fmt[0])
                        begin
                            next = H_ADDR64;
                            next_TLP = {upper_address[31:0]};
                        end
                        else
                        begin
                            next = H_ADDR32; //To End Node
                            next_TLP = {lower_address[31:2],2'b00};
                        end
                    end
                    2'b01: //IO
                    begin
                        next = H_ADDR32; //To End Node
                        next_TLP = {lower_address[31:2],2'b00};
                    end
                    2'b10: //CONF
                    begin
                        next = H_ID; //To End Node
                        next_TLP <= {bdf_id, 4'b0000, config_dw_number, 2'b00};
                    end
                endcase
            end

            H_ADDR32: // End Node   
            begin
                if(fmt[1])
                begin
                    next_HEADER_DATA = 1'b1; 
                    next = DATA;
                    next_data_address = data_address + 1;
                    next_TLP = data;
                end
                else
                begin
                    //next_TLP = nothing and next_PNPC_BUFF_WR_EN is not save that nothing TLP
                    next = FINISH;

                    next_tlp_start_flag = 1'b0;
                    next_PNPC_BUFF_WR_EN = 1'b0;
                    next_tlp_end_flag = 1'b1;     //sfr w wa7d hytl3o m3 b3d

                end
            end

            H_ADDR64:
            begin
                next = H_ADDR32; //To End Node    
                next_TLP = {lower_address[31:2],2'b00};
            end


            H1_CPL: //Pre End Node
            begin
                next = H2_CPL; //To End Node
                next_TLP = {CPL_REQUESTER_ID, CPL_REQUESTER_TAG, 1'b0, completion_lower_address};


/*                 
                if(!fmt[1])
                begin
                    next_PNPC_BUFF_WR_EN = 1'b0;
                end 
                */
            end

            H2_CPL: // End Node
            begin
                if(fmt[1])
                begin
                    next_HEADER_DATA = 1'b1;
                    next = DATA;
                    next_data_address = data_address + 1;
                    next_TLP = data;
                end
                else
                begin
                    //next_TLP = nothing and next_PNPC_BUFF_WR_EN is not save that nothing TLP
                    next_PNPC_BUFF_WR_EN = 1'b0;
                    next = FINISH;

                    next_tlp_start_flag = 1'b0;
                    next_tlp_end_flag = 1'b1;
                end
            end

            H1_MSG:
            begin
                //....
            end

            H_ID: begin
                if(fmt[1])
                begin
                    next_data_address = data_address + 1;
                    next_HEADER_DATA = 1'b1;
                    next = DATA;
                    next_TLP = data;
                end
                else
                begin
                //  next_TLP = nothing and next_PNPC_BUFF_WR_EN is not save that nothing TLP
                    next_PNPC_BUFF_WR_EN = 1'b0;
                    next = FINISH;

                    next_tlp_start_flag = 1'b0;
                    next_tlp_end_flag = 1'b1;
                end
            end
            DATA: //fmt[1]=1 (wr)
            begin
                next_counter = counter + 1;
                next_data_address = data_address + 1;
                if(counter<(Length-1))//0(Done), 1, 2
                begin
                    next_HEADER_DATA = 1'b1;
                    next_TLP = data;
                end
                else
                begin
                    next_counter = 0;

                    //next_TLP = nothing and next_PNPC_BUFF_WR_EN is not save that nothing TLP
                    next_PNPC_BUFF_WR_EN = 1'b0;
                    next = FINISH;

                    next_tlp_start_flag = 1'b0;
                    next_tlp_end_flag = 1'b1;
                end
            end

            FINISH:
            begin
                next_fsm_started = 1'b0;
                next_fsm_finished = 1'b1;
                next = IDLE;

            end
        endcase



    end




endmodule




module TL_TX_MAL
(
input   logic                    clk, 
input   logic                    rst,

input   logic                    DPI_MM,

input   logic    [9:0]           port_write_en,
input   logic    [2:0]           tlp_mem_io_msg_cpl_conf,
input   logic                    tlp_address_32_64,
input   logic                    tlp_read_write,


input   logic    [2:0]          TC,
input   logic    [2:0]          ATTR,
//input   logic    [15:0]         device_id, Enable It Later, But For NoW Conf Space Remains inside the TL_TX
input   logic    [7:0]          tag,
input   logic    [11:0]         byte_count,
input   logic    [31:0]         lower_addr,
input   logic    [31:0]         upper_addr,
input   logic    [15:0]         dest_bdf_id,

input   logic    [31:0]         data1,
input   logic    [31:0]         data2,
input   logic    [31:0]         data3,

input   logic    [9:0]          config_dw_number,
input   logic                   valid,

input   logic                   RD_EN,


output  wire                    ALL_BUFFS_EMPTY,
output  logic                   VALID_FOR_DL,
output  logic    [31:0]         OUT_TLP_DW,

output  logic                   TLP_START_BIT_OUT_COMB,
output  logic                   TLP_END_BIT_OUT_COMB,

output  logic                   fsm_started,
output  logic                   fsm_finished,   


output  logic                   tlp_end_logic
);



//CONNECTIONS (MIDDLE OF THE CHAIN)
wire                            next_VALID_FOR_DL;


logic  [2:0]                    fmt_reg;
logic  [4:0]                    type_reg;
logic  [2:0]                    TC_reg;
logic  [2:0]                    ATTR_reg;
logic  [15:0]                   device_id_reg;
logic  [7:0]                    tag_reg;
logic  [11:0]                   byte_count_reg;
logic  [31:0]                   lower_addr_reg;
logic  [31:0]                   upper_addr_reg;
logic  [15:0]                   dest_bdf_id_reg;
logic  [31:0]                   data_reg;
logic  [9:0]                    config_dw_number_reg;
logic                           valid_reg;



///////// CONF SPACE //////////
logic    [15:0]         device_id;
///////////////////

logic   [31:0]          TLP;

// COMPLETION_REQUEST_HANDLER FIFO
logic   [45:0]          CPL_REQ_HNDL_OUT; //{CPL_REQUESTER_ID[15:0], CPL_REQUESTER_TAG[7:0], REQUESTED_BYTES[11:0], LOWER_ADDRESS[6:0]};
logic                   COMPLETION_RD_EN;
logic                   COMPLETION_WR_EN;
logic                   COMPLETION_FULL;
logic                   COMPLETION_EMPTY;
wire logic              CPL_HNDLR_FIFO_NOT_EMPTY;


wire logic  [15:0]      CPL_REQUESTER_ID;
wire logic  [7:0]       CPL_REQUESTER_TAG;
wire logic  [11:0]      REQUESTED_BYTES;
wire logic  [6:0]       LOWER_ADDRESS;
wire logic  [2:0]       CPL_STATE;


// logic                   fsm_started;
// logic                   fsm_finsihed;

//NPNCPL_BUFF
logic      [1:0]        P_NP_CPL;
logic                   HEADER_DATA;
logic                   PNPC_BUFF_WR_EN;

logic     [1:0]         data_address;


logic                   tlp_start_flag_enc_2_buff;
logic                   tlp_end_flag_enc_2_buff;

CONF_SPACE CONF_SPACE0
    //#(
    //parameter             DW_COUNT          = 16,
    //parameter reg [15:0]  DEV_ID            = 16'b0000_0001_00000_000,
    //parameter reg [15:0]  VENDOR_ID         = 16'b0000_0001_00000_000,
    //parameter reg [7:0]   HEADER_TYPE       = 8'b0000,
    
    // parameter reg        BAR0EN            = 1,
    // parameter reg        BAR0MM_IO         = 0,
    // parameter reg        BAR0_32_64        = 2'b00,
    // parameter reg        BAR0_NONPRE_PRE   = 1'b0,
    // parameter            BAR0_BYTES_COUNT  = 4096,

    // parameter reg        BAR1EN            = 0,
    // parameter reg        BAR1MM_IO         = 0,
    // parameter reg        BAR1_32_64        = 2'b00,
    // parameter reg        BAR1_NONPRE_PRE   = 1'b0,
    // parameter            BAR1_BYTES_COUNT  = 4096,  

    // parameter reg        BAR2EN            = 0,
    // parameter reg        BAR2MM_IO         = 0,
    // parameter reg        BAR2_32_64        = 2'b00,
    // parameter reg        BAR2_NONPRE_PRE   = 1'b0,
    // parameter            BAR2_BYTES_COUNT  = 4096
    //)
    (
        .clk(clk),                    //input       logic                           clk,
        .rst(rst),                    //input       logic                           rst,
        //.wr_en(),                   //input       logic                           wr_en,
        //data_in(),                  //input       logic [31:0]                    data_in,
        //addr(),                     //input       logic [$clog2(DW_COUNT)-1:0]    addr,

        //.data_out(),                //output      logic [31:0]                    data_out,  
        .device_id(device_id)//,      //output wire logic [15:0]                    device_id,
        //.vendor_id(),               //output wire logic [15:0]                    vendor_id,  
        //.header_type(),             //output wire logic [7:0]                     header_type,

        //.BAR0(),                    //output wire logic [31:0]                    BAR0,
        //.BAR1(),                    //output wire logic [31:0]                    BAR1,
        //.BAR2(),                    //output wire logic [31:0]                    BAR2,
        //.BridgeSubBusNum(),         //output wire logic [7:0]                     BridgeSubBusNum,
        //.BridgeSecBusNum(),         //output wire logic [7:0]                     BridgeSecBusNum,
        //.BridgePriBusNum(),         //output wire logic [7:0]                     BridgePriBusNum

        //.BridgeIOLimit(),           //output wire logic [7:0]                     BridgeIOLimit,
        //.BridgeIOBase(),            //output wire logic [7:0]                     BridgeIOBase,

        //.BridgeMemLimit(),          //output wire logic [7:0]                     BridgeMemLimit,
        //.BridgeMemBase(),           //output wire logic [7:0]                     BridgeMemBase,

        //.BridgePrefMemLimit(),      //output wire logic [7:0]                     BridgePrefMemLimit,
        //.BridgePrefMemBase(),       //output wire logic [7:0]                     BridgePrefMemBase,

        //.BridgePrefMemBaseUpper(),  //output wire logic [31:0]                    BridgePrefMemBaseUpper,
        //.BridgePrefMemLimitUpper(), //output wire logic [31:0]                    BridgePrefMemLimitUpper,

        //.BridgeIOLimitUpper(),      //output wire logic [15:0]                    BridgeIOLimitUpper,
        //.BridgeIOBaseUpper()        //output wire logic [15:0]                    BridgeIOBaseUpper
    );

APP_TL_TX_BRIDGE TL_TX_REG_FILE0
(
    .clk(clk), 
    .rst(rst),//input logic clk, rst,

    //INPUTS FROM ENCODER
    .fsm_started(fsm_started),      //input  logic            fsm_started,
    .fsm_finished(fsm_finished),    //input  logic            fsm_finished,
    .data_address(data_address),
    .DPI_MM(DPI_MM),//input logic DPI_MM,  //DPI = 0, MM = 1
    
    // ----- Interface 1: Dedicated Port Interface -----
    .port_write_en(port_write_en),  //input  logic  [9:0] port_write_en,

    /*
    .fmt(fmt),                      //input  logic  [2:0] fmt, 
    .type_(type_),                  //input  logic  [4:0] type_, 
    */

    .tlp_mem_io_msg_cpl_conf(tlp_mem_io_msg_cpl_conf),             //input  logic  [1:0]     tlp_mem_io_msg_cpl_conf, //0: mem, 1: io, 2: msg, 3: cpl
    .tlp_address_32_64(tlp_address_32_64),               //input  logic            tlp_address_32_64,  //0: 32-bit address, 1: 64-bit address
    .tlp_read_write(tlp_read_write),                     //input  logic            tlp_read_write,     //0: read, 1: write
    
    // .TC(TC),                        //input  logic  [2:0] TC,
    // .ATTR(ATTR),                    //input  logic  [2:0] ATTR,
    
    .device_id(device_id),          //input  logic  [15:0] device_id,
    // .tag(tag),                      //input  logic  [7:0]  tag,

    .byte_count(byte_count),        //input  logic  [11:0] byte_count;
    .lower_addr(lower_addr),        //input  logic  [31:0] lower_addr,
    .upper_addr(upper_addr),        //input  logic  [31:0] upper_addr,
    
    .dest_bdf_id(dest_bdf_id),                              //input  logic  [15:0]    dest_bdf_id,
    .config_dw_number(config_dw_number),                    //input  logic  [9:0]  configuration_dw_number,
    
    .data1(data1),                                            //input  logic  [31:0] data,
    .data2(data2),
    .data3(data3),
    
    .valid(valid),                                          //input  logic         valid,

//    ---------------------------------

// Interface 2: Memory-Mapped
   /*
    .mem_addr(),        //input  wire [3:0]   mem_addr,             // 4-bit address to select one of 4 registers //16 Bytes
    .mem_write_en(),    //input  wire         mem_write_en,         // Write enable for memory-mapped interface
    .mem_write_data(),  //input  wire [31:0]  mem_write_data,       // Data to write
    .mem_read_en(),     //input  wire         mem_read_en,          // Read enable for memory-mapped interface
    .mem_read_data(),   //output reg  [31:0]  mem_read_data,        // Data read from selected register
     */

//-------------------------------------------

    .fmt_reg(fmt_reg),//output logic  [2:0] fmt_reg,
    .type_reg(type_reg),//output logic  [4:0] type_reg,
    .TC_reg(TC_reg),//output logic  [2:0] TC_reg,
    .ATTR_reg(ATTR_reg),//output logic  [2:0] ATTR_reg,

    .device_id_reg(device_id_reg),//output logic  [15:0] requester_id_reg,
    .tag_reg(tag_reg),//output logic  [7:0]  tag_reg,

    .byte_count_reg(byte_count_reg),    //output logic  [11:0] byte_count_reg,
    .lower_addr_reg(lower_addr_reg),    //input  logic  [31:0] lower_addr_reg,
    .upper_addr_reg(upper_addr_reg),    //input  logic  [31:0] upper_addr_reg,
    .data_reg (data_reg),               //output logic  [31:0] data_reg,
    .dest_bdf_id_reg(dest_bdf_id_reg),                      //input  logic  [15:0]    dest_bdf_id_reg,
    .config_dw_number_reg (config_dw_number_reg),           //output logic [9:0] configuration_dw_number_reg 
    .valid_reg(valid_reg)                                   //output logic         valid_reg
);



assign CPL_HNDLR_FIFO_NOT_EMPTY = ~COMPLETION_EMPTY;
assign {CPL_REQUESTER_ID, CPL_REQUESTER_TAG, REQUESTED_BYTES, LOWER_ADDRESS, CPL_STATE} = CPL_REQ_HNDL_OUT;
FIFO #(.DATA_WIDTH(46)) COMPLETION_REQUEST_HANDLER
(
.clk            (clk),//input  logic        clk, 
.rst            (rst),//input  logic        rst,
.WrEn           (COMPLETION_WR_EN),//input  logic        WrEn, 
.RdEn           (COMPLETION_RD_EN),//input  logic        RdEn,
.DataIn         (),//input  logic [DATA_WIDTH-1:0] DataIn,
.DataOut        (),//output logic [DATA_WIDTH-1:0] DataOut,
.comb_DataOut   (CPL_REQ_HNDL_OUT),
.Full           (COMPLETION_FULL),//output logic        Full, 
.Empty          (COMPLETION_EMPTY)//output logic        Empty 
); 


TL_TX_ENCODER_MAL TXCONTROLLER
(
    .clk(clk), //input  logic        clk, 1
    .rst(rst), //input  logic        rst, 2



    .valid(valid_reg), //input  logic        valid,3
    .fmt(fmt_reg), //input  logic  [2:0] fmt, 4
    .type_(type_reg),//input  logic  [4:0] type_, 5
    .TC(TC_reg),//input  logic  [2:0] TC, 6
    .ATTR(ATTR_reg),//input  logic  [2:0] Attr, 7

    .device_id                      (device_id_reg),//input  logic  [15:0] requester_id, 8
    .tag                            (tag_reg),//input  logic  [7:0] tag, 9

    .byte_count                     (byte_count_reg),//input  logic  [11:0] byte_count; 10
    
    .lower_address                  (lower_addr_reg),           //input  logic  [31:0] lower_address, 11
    .upper_address                  (upper_addr_reg),           //input  logic  [31:0] upper_address, 12
    .bdf_id                         (dest_bdf_id_reg),                                         //input  logic  [15:0] bdf_id, 13
    .config_dw_number               (config_dw_number_reg),          //input  logic  [9:0]  configuration_dw_number, 14
    .data                           (data_reg),                                                    //input  logic  [31:0] data, 15

    // Completion Protocol
    .CPL_REQUESTER_ID               (CPL_REQUESTER_ID),          //input  logic  [15:0] CPL_REQUESTER_ID, // => H2_CPL (Requester ID) 17
    .CPL_REQUESTER_TAG              (CPL_REQUESTER_TAG),         //input  logic  [7:0]  CPL_REQUESTER_TAG, // => H2_CPL (Tag) 18
    .CPL_REQUESTER_TOTAL_BYTE_COUNT (REQUESTED_BYTES),           //input  logic  [11:0] CPL_REQUESTER_TOTAL_BYTE_COUNT, //total requested bytes 20
    .CPL_LOWER_ADDRESS              (LOWER_ADDRESS),             //input  logic  [6:0]  CPL_LOWER_ADDRESS, // ?? 21
    .CPL_HNDLR_FIFO_NOT_EMPTY       (CPL_HNDLR_FIFO_NOT_EMPTY),  //input  logic         CPL_HNDLR_FIFO_NOT_EMPTY

    .completion_status              (),                         //input  logic     completion_status, 19
    .CPL_HNDLR_FIFO_RD_EN           (),                         //output  logic    CPL_HNDLR_FIFO_RD_EN, 16
    
    .P_NP_CPL(P_NP_CPL),                                        //output logic  [1:0] P_NP_CPL, //22
    .HEADER_DATA(HEADER_DATA),                                  //output logic        HEADER_DATA, //23
    .PNPC_BUFF_WR_EN(PNPC_BUFF_WR_EN),                          //output logic        WR_EN,//24
    
    
    .tlp_start_flag(tlp_start_flag_enc_2_buff),// output  logic         tlp_start_flag,
    .tlp_end_flag(tlp_end_flag_enc_2_buff),// output  logic         tlp_end_flag,


    .fsm_started(fsm_started),     //output  logic         fsm_started,
    .fsm_finished(fsm_finished),    //output  logic         fsm_finsihed,
    
    .data_address(data_address),
    
    .TLP(TLP)                       //output logic  [31:0] TLP 25

    
);

/*

*/
wire OUT_EMPTY;

assign next_VALID_FOR_DL = ~ALL_BUFFS_EMPTY && RD_EN?1'b1:1'b0;
always@(posedge clk or negedge rst)
begin
    if(!rst)
    begin
        VALID_FOR_DL<=0;
    end
    else
    begin
        VALID_FOR_DL<=next_VALID_FOR_DL;
    end
end
PNPC_BUFF #(.DATA_WIDTH(32)) PNPC_BUFF0
(
    .clk(clk),                              //input  logic                     clk,
    .rst(rst),                              //input  logic                     rst,
    .HEADER_DATA(HEADER_DATA),              //input  logic                     HEADER_DATA, // 0: Header, 1: Data
    .P_NP_CPL(P_NP_CPL),                    //input  logic [1:0]               P_NP_CPL, // Posted: 00, Non-Posted: 01, Completion: 11
    .IN_TLP_DW(TLP),                        //input  logic [DATA_WIDTH-1:0]    IN_TLP_DW
    .WR_EN(PNPC_BUFF_WR_EN),                //input  logic                     WrEn,
    .RD_EN(RD_EN),                          //input  logic                     RdEn,

.TLP_START_BIT_IN(tlp_start_flag_enc_2_buff),// input   logic                       TLP_START_BIT_IN,
.TLP_END_BIT_IN(tlp_end_flag_enc_2_buff),// input   logic                       TLP_END_BIT_IN, 

    .TLP_START_BIT_OUT_COMB(TLP_START_BIT_OUT_COMB),      //output  logic                       TLP_START_BIT_OUT_COMB,
    .TLP_END_BIT_OUT_COMB(TLP_END_BIT_OUT_COMB),         // output  logic                       TLP_END_BIT_OUT_COMB

    .EMPTY(ALL_BUFFS_EMPTY),
    //.OUT_EMPTY(OUT_EMPTY),
    // .OUT_TLP_DW(OUT_TLP_DW),               //output logic [DATA_WIDTH-1:0]    OUT_TLP_DW    
    .OUT_TLP_DW_COMB(OUT_TLP_DW)       
);

endmodule