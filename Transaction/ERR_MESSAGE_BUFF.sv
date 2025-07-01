//               /* output */   logic    [1:0]            X_tlp_mem_io_msg_cpl; //type // .tlp_mem_io_msg_cpl_conf(tlp_mem_io_msg_cpl_conf);
//               /* output */   logic                     X_tlp_address_32_64;       //fmt[0]      //.tlp_address_32_64(tlp_address_32_64);
//               /* output */   logic                     X_tlp_read_write;          //fmt[1]      // .tlp_read_write(tlp_read_write);
// //-------------------------------------------------------------------------- (4)
//               /* output */   logic    [2:0]            X_TC;                      //.TC(TC); 
//               /* output */   logic    [2:0]            X_ATTR;                    //.ATTR(ATTR); 
// //---------------------------------------------------------------------------(6)
//               /* output */   logic    [15:0]           X_requester_id;            //[[X]]  -- //COMPLETER ID //.device_id(device_id);
//               /* output */   logic    [7:0]            X_tag;                     //[[X]].tag(tag);
//               /* output */   logic    [11:0]           X_byte_count;              //.byte_count(byte_count);
// //---------------------------------------------------------------------------(36)           
//               /* output */   logic    [6:0]            X_lower_addr;              //[[X]]       //.lower_addr(lower_addr);
//                              logic    [2:0]            X_completion_status;


module ERR_MESSAGE_BUFF
(
    input                    clk,
    input                    rst,
    input  logic [1:0]       err_cor_nonfatal_fatal,
    input  logic [2:0]       ERR_MSG_tlp_mem_io_msg_cpl_conf,
    input  logic             ERR_MSG_tlp_address_32_64,
    input  logic             ERR_MSG_tlp_read_write,
    input  logic [2:0]       ERR_MSG_X_TC,
    input  logic [2:0]       ERR_MSG_X_ATTR,
    input  logic [15:0]      ERR_MSG_requester_id,
    input  logic [7:0]       ERR_MSG_tag,



    output logic [1:0]       ERR_MSG_tlp_mem_io_msg_cpl_out,
    output logic             ERR_MSG_tlp_address_32_64_out,
    output logic             ERR_MSG_tlp_read_write_out,
    output logic             ERR_MSG_X_TC_out,
    output logic             ERR_MSG_X_ATTR_out,
    output logic             ERR_MSG_requester_id_out,
    output logic             ERR_MSG_tag_out






);

reg [7:0] message_code;

always@(*) begin
    case(err_cor_nonfatal_fatal)
        0: message_code = 8'h30;
        1: message_code = 8'h31;
        2: message_code = 8'h33; 
    endcase

end

// 8 + 2 + 1 + 1 + 3 + 3 + 16 + 8
// 42

// What do i need?
FIFO_D #(.DEPTH(32), .DATA_WIDTH(96)) RX_BRIDGE_DATA_BUFF
(
/* input  logic                     */ .clk(clk), 
/* input  logic                     */ .rst(rst),
/* input  logic                     */ .WrEn(RX_B_Wr_En), 
/* input  logic                     */ .RdEn(RX_BRIDGE_BUFF_RD_EN),
/* input  logic [DATA_WIDTH-1:0]    */ .DataIn(RX_BRIDGE_DATA_BUSES),
/* output logic [DATA_WIDTH-1:0]    */ .DataOut(),
/* output logic [DATA_WIDTH-1:0]    */ .comb_DataOut(RX_BRIDGE_DATA_BUFF_OUT),
/* output logic                     */ .Full(), 
/* output logic                     */ .Empty(RX_BRIDGE_DATA_BUFF_EMPTY),
/* output logic                     */ .AlmostEmpty(),
/* output logic                     */ .AlmostFull()
);






 
endmodule