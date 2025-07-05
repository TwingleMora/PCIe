module APP_TL_TX_BRIDGE
(
    input  logic            clk,
    input  logic            rst,



//  INPUTS FROM THE ENCODER
    input  logic            fsm_started,
    input  logic            fsm_finished, //from encoder
    input  logic  [9:0]     data_address,
// Interface 1: Dedicated Port Interface




    /*  
    input  logic  [2:0] fmt, 
    input  logic  [4:0] type_,
    */
    input  logic  [2:0]     tlp_mem_io_msg_cpl_conf,//0: mem, 1: io, 2: msg, 3: cpl, 4: conf
    input  logic            tlp_address_32_64,
    input  logic            tlp_read_write,
    input  logic            config_type,
    input  logic  [2:0]     TC,
    input  logic  [2:0]     ATTR,
  //input  logic            EP,
    input  logic  [15:0]    device_id,
    input  logic  [15:0]    requester_id,
    input  logic  [7:0]     tag,

    input  logic  [11:0]    byte_count,
    input  logic  [31:0]    lower_addr,
    input  logic  [31:0]    upper_addr,

    input  logic  [31:0]    data1,
    input  logic  [31:0]    data2,
    input  logic  [31:0]    data3,

      //////////////////////////////////////////////
     ///////////////// NEW FIFO TX ////////////////
    //////////////////////////////////////////////
    // input   logic [31:0]    data_in,
    // input   logic           wr_en,
    // input   logic           rd_en,
    // output  logic [31:0]    data_out,
    // output  logic           data_out_valid,
     /////////////////////////////////////////////////
    /////////////////////////////////////////////////

    input  logic  [15:0]    dest_bdf_id,
    input  logic  [9:0]     config_dw_number,
    
    //COMPLETION
    input   logic  [2:0]    completion_status,
    input   logic  [7:0]    message_code,

    input   logic           valid,
    input   logic           received_valid,

    //MESSAGE
//-------------------------------------------




// Interface 2: Memory-Mapped
    input  wire [3:0]       mem_addr,             // 4-bit address to select one of 4 registers //16 Bytes
    input  wire             mem_write_en,         // Write enable for memory-mapped interface
    input  wire [31:0]      mem_write_data,       // Data to write
    input  wire             mem_read_en,          // Read enable for memory-mapped interface
    output reg  [31:0]      mem_read_data,        // Data read from selected register

//-------------------------------------------

    output logic  [2:0]     fmt_reg,
    output logic  [4:0]     type_reg,
    output logic  [2:0]     TC_reg,
    output logic  [2:0]     ATTR_reg,

    output logic  [15:0]    device_id_reg,
    output logic  [15:0]    requester_id_reg,
    output logic  [7:0]     tag_reg,

    output logic  [11:0]    byte_count_reg,
    output logic  [31:0]    lower_addr_reg,
    output logic  [31:0]    upper_addr_reg,
    output logic  [31:0]    data_reg,

    

    output logic  [15:0]    dest_bdf_id_reg,
    output logic  [9:0]     config_dw_number_reg,

    output logic  [2:0]     completion_status_reg,
    output logic  [7:0]     message_code_reg,

    output logic            valid_reg

/////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////
////////////////ACK TO CPL ARB///////////////////////////////////
////////////////Double In ARB////////////////////////////////////
/////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////
    // output logic            ACK


);

logic       [2:0]   fmt; 
logic       [4:0]   type_;
// logic       [7:0]   tag;

logic       [31:0] data_file [3];
localparam  [3:0]   CONF_DW_NUM_EN  = 4'd10,
                    FMT_WR_EN       = 4'd9,
                    TYPE_WR_EN      = 4'd8,
                    TC_WR_EN        = 4'd7,
                    ATTR_WR_EN      = 4'd6,
                    REQ_ID_WR_EN    = 4'd5,
                    TAG_WR_EN       = 4'd4,
                    BYTECOUNT_WR_EN = 4'd3,
                    ADDR_WR_EN      = 4'd2,
                    DATA_WR_EN      = 4'd1,
                    VALID_WR_EN     = 4'd0;

localparam [3:0]    FMT_ADDR           = 4'hA,
                    TYPE_ADDR          = 4'h9,
                    TC_ADDR            = 4'h8,
                    ATTR_ADDR          = 4'h7,
                    REQ_ID_ADDR        = 4'h6,
                    TAG_ADDR           = 4'h5,
                    BYTECOUNT_ADDR     = 4'h4,
                    UPPER_ADDRESS_ADDR = 4'h3,
                    LOWER_ADDRESS_ADDR = 4'h2,
                    DATA_ADDR          = 4'h1,
                    VALID_ADDR         = 4'h0;


always@(*)
begin
    data_reg = data_file[data_address];
end


always@(*)
begin
//if(!DPI_MM)
begin
    fmt[2] = 1'b0;
    fmt[1] = tlp_read_write;
    fmt[0] = 1'b0;
    case(tlp_mem_io_msg_cpl_conf)
        3'd0:
        begin
            type_ = 5'b0_0000; 
            case(tlp_address_32_64)
            0: fmt[0] = 1'b0; //32bit
            1: fmt[0] = 1'b1; //64bit
            endcase
        end
        3'd1:
        begin
            type_ = 5'b0_0010;
        end
        3'd2:
        begin
            type_ = 5'b1_0010;
        end
        3'd3:
        begin
            type_ = 5'b0_1010;                    
        end
        3'd4:
        begin
             type_ = {4'b00_10,config_type};
        end
    endcase
end
end
//TAG
always@(*)
begin
    // tag = 0;
    case(tlp_mem_io_msg_cpl_conf)
        2'd0,2'd1:
        begin
            if(valid_reg) //valid_reg will stay
            begin
                if({upper_addr, lower_addr} == {upper_addr_reg, lower_addr_reg})
                begin
                    // tag = tag_reg + 1;
                end
            end
        end

        2'd3:
        begin
            if(valid_reg)
            begin
                if({device_id} == {device_id_reg})
                    begin
                        // tag = tag_reg + 1;
                    end
            end
        end
        2'd3:
        begin
            type_ = 5'b0_1010;                    
        end
    endcase

end
logic fsm_finished_stage2; 
always@(posedge clk or negedge rst)
begin
    if(!rst)
    begin

        fmt_reg                         <= 0;
        type_reg                        <= 0;
        
        
        TC_reg                          <= 0;
        ATTR_reg                        <= 0;
        device_id_reg                   <= 0;

        requester_id_reg                <= 0;
        tag_reg                         <= 0;
        dest_bdf_id_reg                 <= 0;

        byte_count_reg                  <= 0;
        
        lower_addr_reg                  <= 0;
        upper_addr_reg                  <= 0;

        // data_reg                        <= 0;
        config_dw_number_reg            <= 0;
        completion_status_reg           <= 0;
        message_code_reg                <= 0;

        fsm_finished_stage2             <= 0;

        valid_reg                       <= 0;
        // ACK                             <=0;

    end
    else
    begin
                fsm_finished_stage2 <= fsm_finished;
                
                if(valid && fsm_finished_stage2)
                begin
                    fmt_reg                     <= fmt;
                    type_reg                    <= type_;
                    TC_reg                      <= 0;        
                    ATTR_reg                    <= 0;        
                    device_id_reg               <= device_id;
                    //for the same address or ID
                    requester_id_reg            <= requester_id;
                    case(tlp_mem_io_msg_cpl_conf)
                    3: begin
                        tag_reg <= tag;
                    end
                    default: begin
                        tag_reg                     <= tag_reg + 1; ///* tag */;
                    end
                    endcase
                                     
                    dest_bdf_id_reg             <= dest_bdf_id;  
                    byte_count_reg              <= byte_count;
                    lower_addr_reg              <= lower_addr;
                    upper_addr_reg              <= upper_addr;
                    data_file[0]                <= data1;
                    data_file[1]                <= data2;
                    data_file[2]                <= data3;
                    config_dw_number_reg        <= config_dw_number;
                    completion_status_reg       <= completion_status;
                    message_code_reg            <= message_code;
                end
                if(fsm_finished_stage2) begin
                    valid_reg                   <= valid;
                    // ACK                         <= ~ACK&&valid;
                end
                else if(fsm_started) begin
                    valid_reg                   <= 1'b0;
                    // ACK                         <= 1'b0;
                end 
    end
end

endmodule