
module TL_TX_ENCODER
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
    reg [31:0] next_TLP;
    reg [1:0]  next_P_NP_CPL;
    reg        next_PNPC_BUFF_WR_EN;
    reg        next_HEADER_DATA;
    reg        next_CPL_HNDLR_FIFO_RD_EN;


    reg        next_fsm_started;
    reg        next_fsm_finished;
    
    reg [1:0]  counter,
               next_counter;

    reg  [1:0] next_data_address;

    reg [1:0]  last_dw_be;

    State      current,
               next; 

    reg [11:0] length_mult_by_4;

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
        end
        else
        begin
            fsm_started <= next_fsm_started;
            fsm_finished <= next_fsm_finished;
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


        case(current)
            IDLE:
            begin
                if(valid)
                begin
                    next = H0;
                    next_TLP = {fmt, type_, R, TC, R, ATTR[2], R, 1'b0, 1'b0, 1'b0, ATTR[1:0], 2'b00, Length};
                    
                    // Extra Logic For VC Buffers
                    next_P_NP_CPL = packet_classification;
                    next_HEADER_DATA = 1'b0;
                    next_PNPC_BUFF_WR_EN = 1'b1;
                    

                    next_fsm_started = 1'b1;
                    next_fsm_finished = 1'b0;
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
                    next_PNPC_BUFF_WR_EN = 1'b0;
                    next = FINISH;
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



