module TL_RX_DECODER
(
    input logic clk,                              
    input logic rst,                              
    input  logic            TLP_BUFFER_EMPTY,
    output logic            TLP_BUFFER_RD_EN,
    
    
    output logic            DATA_BUFFER_WR_EN,          
    


    output  logic  [2:0]     tlp_mem_io_msg_cpl_conf,
    output  logic            tlp_address_32_64,
    output  logic            tlp_read_write,
    //output  logic            tlp_conf_type,

    output  logic  [11:0]    cpl_byte_count,
    output  logic  [6:0]     cpl_lower_address,

    output  logic  [3:0]     first_dw_be,
    output  logic  [3:0]     last_dw_be,

    output  logic  [9:0]     length,

    output  logic  [31:0]    lower_addr,
    output  logic  [31:0]    upper_addr,

    output  logic  [31:0]    data,
    output  logic  [11:0]    config_dw_number,



    input  logic   [31:0]   TLP,



    input  logic            M_READY,
    output logic            M_ENABLE

);
typedef enum reg [3:0] {IDLE=0, START, H0, H1_REQ, H_ADDR32, H_ADDR64, H_ID,  H1_CPL, H2_CPL, H1_MSG, DATA, FINISH} State;


State current;
reg [9:0] length;
reg [2:0] counter;

//H0
wire  [2:0] fmt_;
wire  [4:0] type_;
wire  [9:0] length_;

//REQ
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
assign fmt_ = TLP[31:29];
assign type_ = TLP[28:24];
assign length_ = TLP[9:0];

//REQ
assign first_dw_be_ = TLP[3:0];
assign last_dw_be_ = TLP[7:4];

//MEM, IO
assign lower_addr_ = {TLP[31:2],2'b00};
assign upper_addr_ =  TLP[31:0];
//CONF
assign config_dw_number_ = {TLP[11:2],2'b00};

//COMPL
assign cpl_byte_count_ = TLP[11:0];
assign cpl_lower_address_ = TLP[6:0];

//Data
assign data_ = TLP[31:0]; 

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
        length<=0;
        
        //REQ
        first_dw_be <= 0;
        last_dw_be <= 0;

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

        // DATA_BUFFER_WR_EN<=0;
        // TLP_BUFFER_RD_EN<=0;
    end
    else begin

        case(current)
        IDLE: begin
            // TLP_BUFFER_RD_EN <= 0;
            if(!TLP_BUFFER_EMPTY) begin
                // TLP_BUFFER_RD_EN <= 1;
                current<= START;
            end
        end
        START: begin
            case(fmt_[0])
                0: tlp_address_32_64 = 0;
                1: tlp_address_32_64 = 1;
            endcase
            case(fmt_[1])
                0: tlp_read_write = 0;
                1: tlp_read_write = 1;
            endcase
            case(type_[4:3])
                REQ: begin
                case(type_[2:1])
                    MEM:
                        tlp_mem_io_msg_cpl_conf<= 0;
                    IO:
                        tlp_mem_io_msg_cpl_conf<= 1;
                    CONF:
                        tlp_mem_io_msg_cpl_conf<= 4;
                endcase 
                end
                CPL: begin
                    tlp_mem_io_msg_cpl_conf<= 3;
                end
                MSG: begin
                    tlp_mem_io_msg_cpl_conf<= 2;
                end
            endcase
            length <= length_;
            current<=H0;
        end
        H0: begin
            case(type_[4:3])
                REQ: begin
                    first_dw_be <= first_dw_be_;
                    last_dw_be <= last_dw_be_;
                    current<=H1_REQ;
                end
                CPL: begin
                    cpl_byte_count <= cpl_byte_count_;
                    current<=H1_CPL;
                end
                MSG: begin
                   
                end
            endcase
        end

        H1_REQ: begin
            case(tlp_mem_io_msg_cpl_conf)
            0,1: begin
                case(tlp_address_32_64)
                0: begin
                    lower_addr <= lower_addr_;
                    current<=H_ADDR32;
                end
                1: begin
                    upper_addr <= upper_addr_;
                    current<=H_ADDR64;
                end
                endcase
            end
            4: begin
                config_dw_number <= config_dw_number_;
                current<=H_ID;
            end
            endcase
            
        end

        H_ADDR64: begin
            lower_addr<=lower_addr_;
            current <= H_ADDR32;
        end

        H_ADDR32: begin
            //XXX
            if(tlp_read_write)
            begin
                // DATA_BUFFER_WR_EN <= 1;
                data <= data_;
                current <= DATA;
                counter <= 1;
            end
            else
            begin
                // TLP_BUFFER_RD_EN <= 0;
                // DATA_BUFFER_WR_EN <= 0;
                M_ENABLE <= 1;
                counter <= 0;
                current <= FINISH;
            end

        end
        H_ID: begin
            //XXX
            if(tlp_read_write)
            begin
                // DATA_BUFFER_WR_EN <= 1;
                data <= data_;
                current <= DATA;
                counter <= 1;
            end
            else
            begin
                // TLP_BUFFER_RD_EN <= 0;
                // DATA_BUFFER_WR_EN <= 0;
                M_ENABLE <= 1;
                current <= FINISH;
            end
        end

        H1_CPL: begin
            cpl_byte_count <= cpl_byte_count_;
            current <= H2_CPL;
        end
        //H1_MSG:
        H2_CPL: begin
            //XXX
            cpl_lower_address <= cpl_lower_address_;
            if(tlp_read_write) begin
                // DATA_BUFFER_WR_EN <= 1;
                data <= data_;
                current <= DATA;
                counter <= 1;
            end
            else begin
                // TLP_BUFFER_RD_EN <= 0;
                // DATA_BUFFER_WR_EN <= 0;
                M_ENABLE <= 1;
                current <= FINISH;
                //counter <= 0;
            end
        end
        
        DATA: begin
            
            if(counter==length)
            begin
                // TLP_BUFFER_RD_EN <= 0;
                // DATA_BUFFER_WR_EN <= 0;
                M_ENABLE <= 1;
                current <= FINISH;
            end
            else
            begin
                data <= data_;
                counter <= counter + 1;
            end
        end
        FINISH: begin
            if(M_READY)
            begin
                current <= IDLE;
                M_ENABLE <= 0;
            end
        end
        endcase
    end
end
    always@(posedge clk or negedge rst)
    begin
        if(!rst)
        begin
            TLP_BUFFER_RD_EN <= 0;
        end
        else
        begin
            case(current)
                IDLE: begin
                    if(!TLP_BUFFER_EMPTY) begin
                        TLP_BUFFER_RD_EN <= 1;
                    end
                    else begin
                        TLP_BUFFER_RD_EN <= 0;
                    end
                end
                DATA: begin      
                    if(counter==length-1) begin
                        TLP_BUFFER_RD_EN <= 0;
                    end
                    else begin
                        TLP_BUFFER_RD_EN <= TLP_BUFFER_RD_EN;
                    end
                end
                H_ADDR32, H2_CPL, H_ID: begin
                    if(tlp_read_write) begin
                        if(length == 1) begin
                            TLP_BUFFER_RD_EN <= 0;
                        end
                        else begin
                            TLP_BUFFER_RD_EN <= 1;
                        end
                    end
                    else begin
                        TLP_BUFFER_RD_EN <= 0;
                    end
                end
            endcase
        end
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
                    if(!TLP_BUFFER_EMPTY) begin
                        TLP_BUFFER_RD_EN <= 1;
                    end
                    else begin
                        TLP_BUFFER_RD_EN <= 0;
                    end
                end
                DATA: begin
                    if(counter==length)
                    begin
                        // TLP_BUFFER_RD_EN <= 0;
                        DATA_BUFFER_WR_EN <= 0;
                    end
                    else
                    begin
                        data <= data_;
                        counter <= counter + 1;
                    end
                end
                H_ADDR32, H2_CPL, H_ID: begin
                    if(tlp_read_write) begin
                        DATA_BUFFER_WR_EN <= 1;
                        // if(length == 1) begin
                        //     TLP_BUFFER_RD_EN <= 0;
                        // end
                        // else begin
                        //     TLP_BUFFER_RD_EN <= 1;
                        // end
                    end
                    else begin
                        DATA_BUFFER_WR_EN <= 0;
                    end
                end
            endcase
        end
    end


endmodule