//ARB: ARBITER
module TX_TRIPLE_IN_ARB #(parameter DATA_WIDTH = 128, parameter DATA_WIDTH2 = 32)

(
input   logic    [2:0]              cpl_tlp_mem_io_msg_cpl_conf,
input   logic                       cpl_tlp_address_32_64,
input   logic                       cpl_tlp_read_write,
input   logic    [2:0]              cpl_TC,
input   logic    [2:0]              cpl_ATTR,
input   logic    [15:0]             cpl_requester_id,
input   logic    [7:0]              cpl_tag,
input   logic    [11:0]             cpl_byte_count,
input   logic    [31:0]             cpl_lower_addr,
input   logic    [31:0]             cpl_upper_addr,
input   logic    [15:0]             cpl_dest_bdf_id,

// input   logic    [31:0]         cpl_data1,
// input   logic    [31:0]         cpl_data2,
// input   logic    [31:0]         cpl_data3,

input   logic   [DATA_WIDTH-1:0]    cpl_data,

  /////////////////////////////////////////////////////
 ////////////////////FIFO TX//////////////////////////
/////////////////////////////////////////////////////
input   logic   [DATA_WIDTH2-1:0]   cpl_data2,
input   logic                       cpl_wr_en,
output  logic                       cpl_rd_en,
/////////////////////////////////////////////////////
/////////////////////////////////////////////////////

input   logic    [9:0]              cpl_config_dw_number,

input   logic    [2:0]              cpl_completion_status,
input   logic    [7:0]              cpl_message_code,
input   logic                       cpl_valid,
output  logic                       CPL_ARB_ACK,
//-------------------------------------------------------------


//MSG_INTF
input   logic    [2:0]              msg_tlp_mem_io_msg_cpl_conf,
input   logic                       msg_tlp_address_32_64,
input   logic                       msg_tlp_read_write,
input   logic    [2:0]              msg_TC,
input   logic    [2:0]              msg_ATTR,
input   logic    [15:0]             msg_requester_id,
input   logic    [7:0]              msg_tag,
input   logic    [11:0]             msg_byte_count,
input   logic    [31:0]             msg_lower_addr,
input   logic    [31:0]             msg_upper_addr,
input   logic    [15:0]             msg_dest_bdf_id,

// input   logic    [31:0]          msg_data1,
// input   logic    [31:0]          msg_data2,
// input   logic    [31:0]          msg_data3,

input   logic   [DATA_WIDTH-1:0]    msg_data,

input   logic    [9:0]              msg_config_dw_number,

input   logic    [2:0]              msg_completion_status,
input   logic    [7:0]              msg_message_code,
input   logic                       msg_valid,
output  logic                       MSG_ARB_ACK,
//-------------------------------------------------------------


//REQ_INTF
// input   logic    [31:0]          req_data1,
// input   logic    [31:0]          req_data2,
// input   logic    [31:0]          req_data3,
input   logic    [2:0]              req_tlp_mem_io_msg_cpl_conf,
input   logic                       req_tlp_address_32_64,
input   logic                       req_tlp_read_write,
input   logic    [2:0]              req_TC,
input   logic    [2:0]              req_ATTR,
input   logic    [15:0]             req_requester_id,
input   logic    [7:0]              req_tag,
input   logic    [11:0]             req_byte_count,
input   logic    [31:0]             req_lower_addr,
input   logic    [31:0]             req_upper_addr,
input   logic    [15:0]             req_dest_bdf_id,
input   logic    [DATA_WIDTH-1:0]   req_data,

  /////////////////////////////////////////////////////
 ////////////////////FIFO TX/////////////////////////
/////////////////////////////////////////////////////
input    logic    [DATA_WIDTH2-1:0]   req_data2,
input    logic                        req_wr_en,
output   logic                        req_rd_en,
/////////////////////////////////////////////////////
/////////////////////////////////////////////////////

input   logic    [9:0]               req_config_dw_number,
input   logic    [2:0]               req_completion_status,
input   logic    [7:0]               req_message_code,
input   logic                        req_valid,
output  logic                        REQ_ARB_ACK,
//-------------------------------------------------------------
//-------------------------------------------------------------

output   logic    [2:0]             x_tlp_mem_io_msg_cpl_conf,
output   logic                      x_tlp_address_32_64      ,
output   logic                      x_tlp_read_write         ,
output   logic    [2:0]             x_TC                     ,
output   logic    [2:0]             x_ATTR                   ,
output   logic    [15:0]            x_requester_id           ,
output   logic    [7:0]             x_tag                    ,
output   logic    [11:0]            x_byte_count             ,
output   logic    [31:0]            x_lower_addr             ,
output   logic    [31:0]            x_upper_addr             ,
output   logic    [15:0]            x_dest_bdf_id            ,

// output   logic    [31:0]           x_data1,
// output   logic    [31:0]           x_data2,
// output   logic    [31:0]           x_data3,
output   logic   [DATA_WIDTH-1 :0]    x_data                 ,

  /////////////////////////////////////////////////////
 ////////////////////FIFO TX/////////////////////////
/////////////////////////////////////////////////////
output   logic   [DATA_WIDTH2-1:0]    x_data2,
output   logic                        x_wr_en,
input    logic                        x_rd_en,
/////////////////////////////////////////////////////
/////////////////////////////////////////////////////

output   logic    [9:0]               x_config_dw_number,
output   logic    [2:0]               x_completion_status,
output   logic    [7:0]               x_message_code,
output   logic                        x_valid,
input    logic                        X_ARB_ACK


);


wire[2:0] REQUESTS = {cpl_valid, 1'b0, req_valid};
wire[2:0] GRANTS;

Arbiter #(.WIDTH(3)) arbiter (.IN(REQUESTS), .OUT(GRANTS));
localparam COMPLETION = 4, MESSAGE = 2, REQUEST = 1;
always@(*) begin
        x_tlp_mem_io_msg_cpl_conf =  0;
        x_tlp_address_32_64 = 0;
        x_tlp_read_write = 0;
        x_TC   = 0;
        x_ATTR = 0;
        x_requester_id  = 0;
        x_tag  = 0;
        x_byte_count    =     0 ;
        x_lower_addr    =     0 ;
        x_upper_addr    =     0 ;
        x_dest_bdf_id    =    0 ;

        x_data          =     0 ;

  /////////////////////////////////////////////////////
 ////////////////////FIFO TX/////////////////////////
/////////////////////////////////////////////////////
        x_data2         =       0;
        x_wr_en         =       0;
        cpl_rd_en       =       0;
        req_rd_en       =       0;
/////////////////////////////////////////////////////
/////////////////////////////////////////////////////
        x_config_dw_number    =    0 ;

        x_completion_status    =    0 ;
        x_message_code    =     0;
        x_valid = 0;

        CPL_ARB_ACK = X_ARB_ACK;
    case (GRANTS)
    COMPLETION:
    begin
        x_tlp_mem_io_msg_cpl_conf    =  cpl_tlp_mem_io_msg_cpl_conf   ;
        x_tlp_address_32_64    =   cpl_tlp_address_32_64  ;
        x_tlp_read_write    =   cpl_tlp_read_write  ;
        x_TC    =   cpl_TC  ;
        x_ATTR    = cpl_ATTR    ;
        x_requester_id    = cpl_requester_id    ;
        x_tag    =   cpl_tag  ;
        x_byte_count    = cpl_byte_count    ;
        x_lower_addr    =   cpl_lower_addr  ;
        x_upper_addr    =    cpl_upper_addr ;
        x_dest_bdf_id    =    cpl_dest_bdf_id ;

        x_data          =     cpl_data;
        
  /////////////////////////////////////////////////////
 ////////////////////FIFO TX/////////////////////////
/////////////////////////////////////////////////////
        x_data2         =       cpl_data2;
        x_wr_en         =       cpl_wr_en;
        cpl_rd_en       =       x_rd_en; 
/////////////////////////////////////////////////////
/////////////////////////////////////////////////////

        x_config_dw_number    =    cpl_config_dw_number ;

        x_completion_status    =    cpl_completion_status ;
        x_message_code    =     cpl_message_code;
        x_valid = cpl_valid;

        CPL_ARB_ACK = X_ARB_ACK;
    end
    MESSAGE: 
    begin
        x_tlp_mem_io_msg_cpl_conf    =  msg_tlp_mem_io_msg_cpl_conf   ;
        x_tlp_address_32_64    =   msg_tlp_address_32_64  ;
        x_tlp_read_write    =   msg_tlp_read_write  ;
        x_TC    =   msg_TC  ;
        x_ATTR    = msg_ATTR    ;
        x_requester_id    = msg_requester_id    ;
        x_tag    =   msg_tag  ;
        x_byte_count    = msg_byte_count    ;
        x_lower_addr    =   msg_lower_addr  ;
        x_upper_addr    =    msg_upper_addr ;
        x_dest_bdf_id    =    msg_dest_bdf_id ;

        x_data          =     msg_data;
        

        x_config_dw_number    =    msg_config_dw_number ;

        x_completion_status    =    msg_completion_status ;
        x_message_code    =     msg_message_code;
        x_valid = msg_valid;

        MSG_ARB_ACK = X_ARB_ACK;
    end
    REQUEST: begin
        x_tlp_mem_io_msg_cpl_conf    =    req_tlp_mem_io_msg_cpl_conf;
        x_tlp_address_32_64          =    req_tlp_address_32_64  ;
        x_tlp_read_write             =    req_tlp_read_write  ;
        x_TC                         =    req_TC  ;
        x_ATTR                       =    req_ATTR    ;
        x_requester_id               =    req_requester_id    ;
        x_tag                        =    req_tag  ;
        x_byte_count                 =    req_byte_count    ;
        x_lower_addr                 =    req_lower_addr  ;
        x_upper_addr                 =    req_upper_addr ;
        x_dest_bdf_id                =    req_dest_bdf_id ;

        x_data                       =    req_data;

  /////////////////////////////////////////////////////
 ////////////////////FIFO TX/////////////////////////
/////////////////////////////////////////////////////
        x_data2                     =       req_data2;
        x_wr_en                     =       req_wr_en;
        req_rd_en                   =       x_rd_en;
/////////////////////////////////////////////////////
/////////////////////////////////////////////////////

        x_config_dw_number           =    req_config_dw_number ;

        x_completion_status          =    req_completion_status ;
        x_message_code               =    req_message_code;
        x_valid                      =    req_valid;

        REQ_ARB_ACK                  =    X_ARB_ACK;
    end
    
    endcase
end

endmodule