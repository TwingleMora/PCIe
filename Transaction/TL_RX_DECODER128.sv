module TL_RX_DECODER128
(
    input logic clk,                              
    input logic rst,                              
    input  logic            TLP_BUFFER_EMPTY,
    output logic            TLP_BUFFER_RD_EN, //<<<<<<<<<<<<<<<<<<<
    
    
    output logic            DATA_BUFFER_WR_EN,          
    


    output  logic  [2:0]     tlp_mem_io_msg_cpl_conf,
    output  logic            tlp_address_32_64,
    output  logic            tlp_read_write, //CPL - CPLD



    //output  logic            tlp_conf_type,
    output  logic  [11:0]    cpl_byte_count,
    output  logic  [6:0]     cpl_lower_address,
    output  logic  [15:0]    requester_id,
    output  logic  [7:0]     tag,

    output  logic  [3:0]     first_dw_be,
    output  logic  [3:0]     last_dw_be,

    output  logic  [9:0]     tlp_length,

    output  logic  [31:0]    lower_addr,
    output  logic  [31:0]    upper_addr,

    output  logic  [31:0]    data,
    output  logic  [11:0]    config_dw_number,

    input  logic   [127:0]   TLP,
    
    input  logic             M_READY,
    output logic             M_ENABLE,

    input  logic            C_READY,
    output  logic            C_ENABLE



);
typedef enum reg [3:0] {IDLE, HEADER, DATA, FINISH} State;
localparam DH3 = 127, DL3 = 96, DH2 = 95, DL2 = 64, DH1 = 63 , DL1 = 32, DH0 = 31 , DL0 = 0;

State current;
// reg [9:0] tlp_length;
reg [9:0] counter; //<<<<<<<<<<<<<<<<<<<

//H0
wire  [2:0] fmt_;
wire  [4:0] type_;
wire  [9:0] length_;

//REQ
wire  [15:0]    requester_id_;
wire  [7:0]     tag_;
wire  [3:0]     first_dw_be_;
wire  [3:0]     last_dw_be_;

//MEM, IO
wire  [31:0]    lower_addr_;
wire  [31:0]    upper_addr_;

//CPL
wire  [11:0]    cpl_byte_count_;
wire  [6:0]     cpl_lower_address_;
wire  [11:0]    config_dw_number_;

//DATA
wire [31:0]     data_;
//-----------------

//H0
assign fmt_         = TLP[127:125] /* [31:29] */;//
assign type_        = TLP[124: 120] /* [28:24] */;//
//R[23]
assign TC_          = TLP[118:116];// /* [22:20] */
//R[19]
// assign attr_[2]     = TLP[114];//[18];//[114]
//R[17]
assign TH_          = TLP[112];//[16]; //[112]
assign TD_          = TLP[111];//[15];//[111]
assign EP_          = TLP[110];//[14];//[110]
// assign attr_[1:0]   = TLP[109:108];//[13:12];//[109::108]
assign AT_          = TLP[107:106];//[11:10];//[107:106]
assign length_      = TLP[105:96];//[9:0];//[105:96]

//H1_REQ
assign requester_id_ = TLP[95:80];//[31:16];//[95:80]
assign tag_          = TLP[79:72];//[15:8];//[79:72]
assign last_dw_be_   = TLP[71:68];//[7:4];//[71:68]
assign first_dw_be_  = TLP[67:64];//[3:0];//[67:64]

//MEM, IO
assign lower_addr_  = TLP[31:0];//[31:0];//[63:32] [31:0]//Check last 2 bits are 00
assign upper_addr_  = TLP[63:32];//[31:0];//[63:32] 

//CONF
assign BDF_         = TLP[63:48];//[31:16];//[63:48]
// R[15:12]
assign config_dw_number_ = TLP[43:32];//{TLP[11:0]};//[43:32] //Check last 2 bits are 00

//CPL1
assign cpl_completer_id_    = TLP[63:48];//[31:16]; //[63:48]
assign cpl_status_          = TLP[47:45];//[15:13]; //[47:45]
assign cpl_bcm_             = TLP[44];//[12];//[44]
assign cpl_byte_count_      = TLP[43:32];//[11:0];//[43:32]

//CPL2
assign cpl_requester_id_    = TLP[31:16];//[31:16];//[31:16]
assign cpl_tag_             = TLP[15:8];//[15:8]; //[15:8]
assign cpl_lower_address_   = TLP[6:0];// [6:0]
// R[7]


//MSG
assign message_request_id_  = TLP[95:80];//[31:16];//[95:80]
assign message_tag_         = TLP[79:72];//[15:8];//[79:72]
assign message_code_        = TLP[71:64];//[7:0];//[71:64]

//Data
assign data_                = TLP[31:0]; 


localparam REQ = 0, CPL = 1, MSG = 2;
localparam MEM = 'b00, IO = 'b01, CONF = 'b10;

//       .EMPTY(ALL_BUFFS_EMPTY), 
//       .OUT_EMPTY(OUT_EMPTY),   
//       .OUT_TLP_DW(OUT_TLP_DW)   


always@(posedge clk or negedge rst)
begin
    if(!rst)
    begin
        current <= IDLE;
        
        //H0
        tlp_mem_io_msg_cpl_conf <= 0;
        tlp_address_32_64 <= 0;
        tlp_read_write <= 0;
        tlp_length<=0;
        
        //REQ
        requester_id <= 0;
        tag<=0;
        first_dw_be  <= 0;
        last_dw_be   <= 0;

        //MEM, IO
        lower_addr <= 0;
        upper_addr <= 0;

        //CONFIG
        config_dw_number <= 0;

        //COMPL
        cpl_byte_count <= 0;
        cpl_lower_address <= 0;

        //DATA
        data <= 0;
        
        M_ENABLE <= 0;

        C_ENABLE <= 0;

        // DATA_BUFFER_WR_EN<=0;
        // TLP_BUFFER_RD_EN<=0;
    end
    else begin
        case(current)
        IDLE: 
        begin
            // TLP_BUFFER_RD_EN <= 0;
            if(!TLP_BUFFER_EMPTY) begin 
                case(fmt_[0])
                    0: tlp_address_32_64 <= 0;
                    1: tlp_address_32_64 <= 1;
                endcase
                case(fmt_[1])
                    0: tlp_read_write <= 0;
                    1: tlp_read_write <= 1;
                endcase
                case(type_[4:3])
                    REQ: begin
                        requester_id <= requester_id_;
                        tag <= tag_;
                        first_dw_be <= first_dw_be_;
                        last_dw_be <= last_dw_be_;
                    case(type_[2:1])
                        MEM:
                        begin
                            tlp_mem_io_msg_cpl_conf<= 0;
                            case(tlp_address_32_64)
                            0: begin
                                lower_addr <= upper_addr_;
                                
                            end
                            1: begin
                                upper_addr <= upper_addr_;
                                lower_addr <= lower_addr_;
                                
                            end
                            endcase
                        end
                        IO: begin
                            lower_addr <= upper_addr_;
                            tlp_mem_io_msg_cpl_conf<= 1;

                        end
                        CONF: begin
                            config_dw_number <= config_dw_number_;
                            tlp_mem_io_msg_cpl_conf<= 4;

                        end
                    endcase 
                    end
                    CPL: begin
                        cpl_byte_count <= cpl_byte_count_;
                        cpl_lower_address <= cpl_lower_address_;
                        tlp_mem_io_msg_cpl_conf<= 3;
                    end
                    MSG: begin
                        tlp_mem_io_msg_cpl_conf<= 2;
                    end
                endcase
                tlp_length <= length_;
                current<=HEADER;
            end
        end
        HEADER: 
        begin
            if(tlp_read_write)
            begin
                // DATA_BUFFER_WR_EN <= 1;
                data <= TLP[DH3:DL3];
                current <= DATA;
                counter <= 1;
            end
            else
            begin
                // TLP_BUFFER_RD_EN <= 0;
                // DATA_BUFFER_WR_EN <= 0;
                case(tlp_mem_io_msg_cpl_conf)
                0,1,4: begin
                    M_ENABLE <= 1;
                end
                3: begin
                    C_ENABLE <= 1;
                end
                2: begin
                end
                endcase
                
                counter  <= 0;
                current  <= FINISH;
            end
        end
        DATA: 
        begin
            if(counter==tlp_length)
            begin
                // TLP_BUFFER_RD_EN <= 0;
                // DATA_BUFFER_WR_EN <= 0;
                case(tlp_mem_io_msg_cpl_conf)
                0,1,4: begin
                    M_ENABLE <= 1;
                end
                3: begin
                    C_ENABLE <= 1;
                end
                2: begin
                end
                endcase
                current <= FINISH;
            end
            else
            begin
                case(counter[1:0])
                0: data <= TLP[DH3:DL3];
                1: data <= TLP[DH2:DL2];
                2: data <= TLP[DH1:DL1];
                3: data <= TLP[DH0:DL0];
                endcase
                counter <= counter + 1;
            end
        end
        FINISH: begin
            if(M_READY&&M_ENABLE)
            begin
                current <= IDLE;
                M_ENABLE <= 0;
            end
            if(C_READY&&C_ENABLE)
            begin
                current <= IDLE;
                C_ENABLE <= 0;
            end
        end
        endcase
    end
end
    always@(*)
    begin
        case(current)
            IDLE: 
            begin
                if(!TLP_BUFFER_EMPTY) begin
                    TLP_BUFFER_RD_EN = 1;
                end
                else begin
                    TLP_BUFFER_RD_EN = 0;
                end
            end
            HEADER: 
            begin
                if(tlp_read_write)
                begin
                    if(tlp_length == 1)
                    TLP_BUFFER_RD_EN = 1; //The 4 DW has only 1 dw so read it and set rden to move to next 4DW
                    else 
                    TLP_BUFFER_RD_EN = 0;
                end
                else
                begin
                    TLP_BUFFER_RD_EN = 0;
                end
            end
            DATA: 
            begin      
                if(counter==tlp_length) begin
                    // TLP_BUFFER_RD_EN = 0;
                    TLP_BUFFER_RD_EN = 1;
                end
                else begin
                    if(counter[1:0] == 2'b11)
                    begin
                        TLP_BUFFER_RD_EN = 1;
                    end
                end
            end
            FINISH: 
            begin
                TLP_BUFFER_RD_EN = 0;
            end
            
        endcase
    end
    



    always@(posedge clk or negedge rst)
    begin
        if(!rst)
        begin
            DATA_BUFFER_WR_EN <= 0;
        end
        else
        begin
            case(current)
                IDLE: begin
                end
                DATA: begin
                    if(counter==tlp_length)
                    begin
                        // TLP_BUFFER_RD_EN <= 0;
                        DATA_BUFFER_WR_EN <= 0;
                    end
                    else
                    begin

                    end
                end
                HEADER: begin
                    if(tlp_read_write) begin
                        DATA_BUFFER_WR_EN <= 1;

                    end
                    else begin
                        DATA_BUFFER_WR_EN <= 0;
                    end
                end
            endcase
        end
    end


endmodule