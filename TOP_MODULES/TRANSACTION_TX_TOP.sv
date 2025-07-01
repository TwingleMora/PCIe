module TRANSACTION_TX_TOP (
input  logic                       clk,
input  logic                       rst,
                               
//DATA LINK INTERFACE          
input  logic                       RD_EN,
output logic                       VALID_FOR_DL,
output logic                       ALL_BUFFS_EMPTY,
output logic   [31:0]              OUT_TLP_DW,
output logic                       fsm_finished,
output logic                       TL_TX_ACK,
output logic                       fsm_started,
output logic                       TLP_START_BIT_OUT_COMB,
output logic                       TLP_END_BIT_OUT_COMB,


//FROM RX ERROR DETECTION TO TX MASTER

//\\\\\\\\\\\\\\\\\\\\\\\\\\\-----------------//////////////////////////////\\
 //\\\\\\\\\\\\\\\\\\\\\\\\\\\     |= =|     //////////////////////////////\\
  //\\\\\\\\\\\\\\\\\\\\\\\\\\\    |= =|    //////////////////////////////\\
   //\\\\\\\\\\\\\\\\\\\\\\\\\\\     |     //////////////////////////////\\
    //\\\\\\\\\\\\\\\\\\\\\\\\\\\    |    //////////////////////////////\\
     //\\\\\\\\\\\\\\\\\\\\\\\\\\\   |   //////////////////////////////\\
      //\\\\\\\\\\\\\\\\\\\\\\\\\\\  |  //////////////////////////////\\
       //\\\\\\\\\\\\\\\\\\\\\\\\\\\ | //////////////////////////////\\
        //\\\\\\\\\\\\\\\\\\\\\\\\\\\|//////////////////////////////\\

//FROM RX MASTER to TX MASTER
input    logic    [2:0]            CPL_tlp_mem_io_msg_cpl,   //tlp_mem_io_msg_cpl_conf(tlp_mem_io_msg_cpl_conf),
input    logic                     CPL_tlp_address_32_64,    //fmt[0]      //tlp_address_32_64(tlp_address_32_64),
input    logic                     CPL_tlp_read_write,       //fmt[1]      // tlp_read_write(tlp_read_write),
//-------------------------------------------------------------------------- (4)
input    logic    [2:0]            CPL_TC,                      //TC(TC), 
input    logic    [2:0]            CPL_ATTR,                    //ATTR(ATTR), 
//---------------------------------------------------------------------------(6)
input    logic    [15:0]           CPL_requester_id,            //[[CPL]]  -- //COMPLETER ID //device_id(device_id),
input    logic    [7:0]            CPL_tag,                     //[[CPL]]tag(tag),
input    logic    [11:0]           CPL_byte_count,              //byte_count(byte_count),
//---------------------------------------------------------------------------(36)           
input    logic    [6:0]            CPL_lower_addr,              //[[CPL]]       //lower_addr(lower_addr),
input    logic    [2:0]            CPL_completion_status,
//---------------------------------------------------------------------------(7)
input    logic    [31:0]           CPL_data1,                 //data1(data1),
input    logic    [31:0]           CPL_data2,                 //data2(data2),
input    logic    [31:0]           CPL_data3,                 //data3(data3) ,  

////////////////////////////////////////////////////////////////////////////////////////////////
input    logic                     CPL_ARB_VALID,                    //////////////////////////
output   logic                     CPL_ARB_ACK,                     //////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////




input    logic    [2:0]            MSG_tlp_mem_io_msg_cpl, //type // tlp_mem_io_msg_cpl_conf(tlp_mem_io_msg_cpl_conf),
input    logic                     MSG_tlp_address_32_64,       //fmt[0]      //tlp_address_32_64(tlp_address_32_64),
input    logic                     MSG_tlp_read_write,          //fmt[1]      // tlp_read_write(tlp_read_write),
//-------------------------------------------------------------------------- (4)
input    logic    [2:0]            MSG_TC,                      //TC(TC), 
input    logic    [2:0]            MSG_ATTR,                    //ATTR(ATTR), 
//---------------------------------------------------------------------------(6)
input    logic    [15:0]           MSG_requester_id,            //[[MSG]]  -- //COMPLETER ID //device_id(device_id),
input    logic    [7:0]            MSG_tag,                     //[[MSG]]tag(tag),
input    logic    [11:0]           MSG_byte_count,              //byte_count(byte_count),
//---------------------------------------------------------------------------(36)           
input    logic    [6:0]            MSG_lower_addr,              //[[MSG]]       //lower_addr(lower_addr),
input    logic    [2:0]            MSG_completion_status,
//---------------------------------------------------------------------------(7)
input    logic    [31:0]           MSG_data1,                 //data1(data1),
input    logic    [31:0]           MSG_data2,                 //data2(data2),
input    logic    [31:0]           MSG_data3,                 //data3(data3) ,  
/////////////////////////////////////////////////////////////////////////////////////////////
input    logic                     MSG_ARB_VALID,           ////////////////////////////////
output   logic                     MSG_ARB_ACK,             ////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////



// ---------------------------------------------------------------------------
// AXI
// ---------------------------------------------------------------------------
input    logic    [2:0]                        REQ_tlp_mem_io_msg_cpl_conf,
input    logic                                 REQ_tlp_address_32_64,
input    logic                                 REQ_tlp_read_write,
input    logic    [2:0]                        REQ_TC,
input    logic    [2:0]                        REQ_ATTR,
input    logic    [15:0]                       REQ_requester_id,
input    logic    [7:0]                        REQ_tag,
input    logic    [11:0]                       REQ_byte_count,
input    logic    [31:0]                       REQ_lower_addr,
input    logic    [31:0]                       REQ_upper_addr,
input    logic    [15:0]                       REQ_dest_bdf_id,
// /* input */   logic    [UPGRADED_DATA_WIDTH-1:0]    REQ_data,
input    logic    [31:0]                       REQ_data1,
input    logic    [31:0]                       REQ_data2,
input    logic    [31:0]                       REQ_data3,

input    logic    [9:0]                        REQ_config_dw_number,
input    logic    [2:0]                        REQ_completion_status,
input    logic    [7:0]                        REQ_message_code,
input    logic                                 REQ_valid
// ---------------------------------------------------------------------------
// ---------------------------------------------------------------------------




);
/*
input    logic           .clk(),
logic    logic           .rst(),

logic                   .RD_EN(),
wire                    .VALID_FOR_DL(),
wire                    .ALL_BUFFS_EMPTY(),
logic   [31:0]          .OUT_TLP_DW(),
logic                   .fsm_finished(),
logic                   .TL_TX_ACK(),


//FROM RX ERROR DETECTION TO TX MASTER


//FROM RX MASTER to TX MASTER
input    logic    [2:0]            .CPL_tlp_mem_io_msg_cpl(), //type // .tlp_mem_io_msg_cpl_conf(tlp_mem_io_msg_cpl_conf)(),
input    logic                     .CPL_tlp_address_32_64(),       //fmt[0]      //.tlp_address_32_64(tlp_address_32_64)(),
input    logic                     .CPL_tlp_read_write(),          //fmt[1]      // .tlp_read_write(tlp_read_write)(),
//-------------------------------------------------------------------------- (4)
input    logic    [2:0]            .CPL_TC(),                      //.TC(TC)(), 
input    logic    [2:0]            .CPL_ATTR(),                    //.ATTR(ATTR)(), 
//---------------------------------------------------------------------------(6)
input    logic    [15:0]           .CPL_requester_id(),            //[[CPL]]  -- //COMPLETER ID //.device_id(device_id)(),
input    logic    [7:0]            .CPL_tag(),                     //[[CPL]].tag(tag)(),
input    logic    [11:0]           .CPL_byte_count(),              //.byte_count(byte_count)(),
//---------------------------------------------------------------------------(36)           
input    logic    [6:0]            .CPL_lower_addr(),              //[[CPL]]       //.lower_addr(lower_addr)(),
input    logic    [2:0]            .CPL_completion_status(),
//---------------------------------------------------------------------------(7)
input    logic    [31:0]           .CPL_data1(),                 //.data1(data1)(),
input    logic    [31:0]           .CPL_data2(),                 //.data2(data2)(),
input    logic    [31:0]           .CPL_data3(),                 //.data3(data3) (),  

    //////////////////////////////////////////////////////////////////////////////////////////////
output   logic                             .CPL_ARB_ACK(),      ////////////////////////////
input    logic                             .CPL_ARB_VALID()   ////////////////////////////
    ///////////////////////////////////////////////////////////////////////////////////////////

*/


logic  [2:0]        tlp_mem_io_msg_cpl_conf;
logic               tlp_address_32_64;
logic               tlp_read_write;


logic  [2:0]        TC;
logic  [2:0]        ATTR;
logic  [15:0]       device_id;
logic  [15:0]       requester_id;
logic  [7:0]        tag;
logic  [11:0]       byte_count;
logic  [31:0]       lower_addr;
logic  [31:0]       upper_addr;
logic  [15:0]       dest_bdf_id;

logic  [31:0]       data1;
logic  [31:0]       data2;
logic  [31:0]       data3;


logic  [9:0]        config_dw_number;

logic  [2:0]        completion_status;
logic  [7:0]        message_code;

logic               valid;



TX_TRIPLE_IN_ARB #(.DATA_WIDTH(128)) tx_triple_in_arb
(
/* input   logic    [2:0]               */.cpl_tlp_mem_io_msg_cpl_conf(CPL_tlp_mem_io_msg_cpl),
/* input   logic                        */.cpl_tlp_address_32_64(CPL_tlp_address_32_64),
/* input   logic                        */.cpl_tlp_read_write(CPL_tlp_read_write),
/* input   logic    [2:0]               */.cpl_TC(CPL_TC),
/* input   logic    [2:0]               */.cpl_ATTR(CPL_ATTR),
/* input   logic    [15:0]              */.cpl_requester_id(CPL_requester_id),
/* input   logic    [7:0]               */.cpl_tag(CPL_tag),
/* input   logic    [11:0]              */.cpl_byte_count(CPL_byte_count),
/* input   logic    [31:0]              */.cpl_lower_addr(CPL_lower_addr),
// /* input   logic    [31:0]              */.cpl_upper_addr(cpl_upper_addr),
/* input   logic    [15:0]              */.cpl_dest_bdf_id(cpl_dest_bdf_id),

// input   logic    [31:0]         cpl_data1(),
// input   logic    [31:0]         cpl_data2(),
// input   logic    [31:0]         cpl_data3(),

/* input   logic   [DATA_WIDTH-1:0]     */.cpl_data({32'h0, CPL_data3, CPL_data2, CPL_data1}),

/* input   logic    [9:0]               */.cpl_config_dw_number(cpl_config_dw_number),

/* input   logic    [2:0]               */.cpl_completion_status(CPL_completion_status),
/* input   logic    [7:0]               */.cpl_message_code(),
/* input   logic                        */.cpl_valid(CPL_ARB_VALID),
/* output  logic                        */.CPL_ARB_ACK(CPL_ARB_ACK),
//-------------------------------------------------------------


//MSG_INTF
/* input   logic    [2:0]               */.msg_tlp_mem_io_msg_cpl_conf(MSG_tlp_mem_io_msg_cpl),
/* input   logic                        */.msg_tlp_address_32_64(MSG_tlp_address_32_64),
/* input   logic                        */.msg_tlp_read_write(msg_tlp_read_write),
/* input   logic    [2:0]               */.msg_TC(msg_TC),
/* input   logic    [2:0]               */.msg_ATTR(msg_ATTR),
/* input   logic    [15:0]              */.msg_requester_id(msg_requester_id),
/* input   logic    [7:0]               */.msg_tag(msg_tag),
/* input   logic    [11:0]              */.msg_byte_count(msg_byte_count),
/* input   logic    [31:0]              */.msg_lower_addr(msg_lower_addr),
/* input   logic    [31:0]              */.msg_upper_addr(msg_upper_addr),
/* input   logic    [15:0]              */.msg_dest_bdf_id(msg_dest_bdf_id),

// input   logic    [31:0]          msg_data1(),
// input   logic    [31:0]          msg_data2(),
// input   logic    [31:0]          msg_data3(),

/* input   logic   [DATA_WIDTH-1:0]     */.msg_data({msg_data3, msg_data2, msg_data1}),

/* input   logic    [9:0]               */.msg_config_dw_number(),

/* input   logic    [2:0]               */.msg_completion_status(),
/* input   logic    [7:0]               */.msg_message_code(msg_message_code),
/* input   logic                        */.msg_valid(MSG_ARB_VALID),
/* output  logic                        */.MSG_ARB_ACK(MSG_ARB_ACK),
//-------------------------------------------------------------


//REQ_INTF
/* input   logic    [2:0]               */.req_tlp_mem_io_msg_cpl_conf(REQ_tlp_mem_io_msg_cpl_conf),
/* input   logic                        */.req_tlp_address_32_64(REQ_tlp_address_32_64),
/* input   logic                        */.req_tlp_read_write(REQ_tlp_read_write),
/* input   logic    [2:0]               */.req_TC(REQ_TC),
/* input   logic    [2:0]               */.req_ATTR(REQ_ATTR),
/* input   logic    [15:0]              */.req_requester_id(REQ_requester_id),
/* input   logic    [7:0]               */.req_tag(REQ_tag),
/* input   logic    [11:0]              */.req_byte_count(REQ_byte_count),
/* input   logic    [31:0]              */.req_lower_addr(REQ_lower_addr),
/* input   logic    [31:0]              */.req_upper_addr(REQ_upper_addr),
/* input   logic    [15:0]              */.req_dest_bdf_id(REQ_dest_bdf_id),

// input   logic    [31:0]             req_data1(),
// input   logic    [31:0]             req_data2(),
// input   logic    [31:0]             req_data3(),
/* input   logic   [DATA_WIDTH-1:0]     */.req_data({32'h0, REQ_data3, REQ_data2, REQ_data1}),

/* input   logic    [9:0]               */.req_config_dw_number(config_dw_number),

// /* input   logic    [2:0]               */.req_completion_status(),
// /* input   logic    [7:0]               */.req_message_code(),
/* input   logic                        */.req_valid(REQ_valid),
/* output  logic                        */.REQ_ARB_ACK(),
//-------------------------------------------------------------
//-------------------------------------------------------------

/* output   logic    [2:0]              */.x_tlp_mem_io_msg_cpl_conf(tlp_mem_io_msg_cpl_conf),
/* output   logic                       */.x_tlp_address_32_64(tlp_address_32_64),
/* output   logic                       */.x_tlp_read_write(tlp_read_write),
/* output   logic    [2:0]              */.x_TC(TC),
/* output   logic    [2:0]              */.x_ATTR(ATTR),
/* output   logic    [15:0]             */.x_requester_id(requester_id),
/* output   logic    [7:0]              */.x_tag(tag),
/* output   logic    [11:0]             */.x_byte_count(byte_count),
/* output   logic    [31:0]             */.x_lower_addr(lower_addr),
/* output   logic    [31:0]             */.x_upper_addr(upper_addr),
/* output   logic    [15:0]             */.x_dest_bdf_id(dest_bdf_id),

// output   logic    [31:0]         x_data1(),
// output   logic    [31:0]         x_data2(),
// output   logic    [31:0]         x_data3(),
/* output   logic   [DATA_WIDTH-1:0]    */.x_data({dumb_signal2 ,data3, data2, data1}),

/* output   logic    [9:0]              */.x_config_dw_number(config_dw_number),

/* output   logic    [2:0]              */.x_completion_status(completion_status),
/* output   logic    [7:0]              */.x_message_code(message_code),
/* output   logic                       */.x_valid(valid),
/* input    logic                       */.X_ARB_ACK(TL_TX_ACK)


);


wire TLP_START_BIT_OUT;
assign TLP_START_BIT_OUT_COMB = TLP_START_BIT_OUT && !ALL_BUFFS_EMPTY;
TL_TX_MAL TL_TX0 
(           .clk(clk),                                  //input   logic                    clk, 
            .rst(rst),                                  //input   logic                    rst,
            .DPI_MM(DPI_MM),                            //input   logic                    DPI_MM,

            .port_write_en(port_write_en),                        //input   logic    [9:0]           port_write_en,
            .tlp_mem_io_msg_cpl_conf(tlp_mem_io_msg_cpl_conf),    //input   logic    [1:0]           tlp_mem_io_msg_cpl_conf,
            .tlp_address_32_64(tlp_address_32_64),                //input   logic                    tlp_address_32_64,
            .tlp_read_write(tlp_read_write),                      //input   logic                    tlp_read_write,


            .TC(TC),                                    //input   logic    [2:0]          TC,
            .ATTR(ATTR),                                //input   logic    [2:0]          ATTR,
            .requester_id(requester_id),                    //input   logic    [15:0]         device_id,
            .tag(tag),                                  //input   logic    [7:0]          tag,
            .byte_count(byte_count),                    //input   logic    [11:0]         byte_count,
            .lower_addr(lower_addr),                    //input   logic    [31:0]         lower_addr,
            .upper_addr(upper_addr),                                               //input   logic    [31:0]         upper_addr,
            .config_dw_number(config_dw_number),        //input   logic    [9:0]          config_dw_number,


            .data1(data1),                                //input   logic    [31:0]         data1,
            .data2(data2),                                //input   logic    [31:0]         data2,
            .data3(data3),                                //input   logic    [31:0]         data3,

            .dest_bdf_id(dest_bdf_id),                  //input   logic    [15:0]         dest_bdf_id,
            
            .completion_status(completion_status),
            .message_code(message_code),
            
            .valid(valid),                              //input   logic                   valid,


            .RD_EN(RD_EN),                              //input   logic                   RD_EN,
            .ALL_BUFFS_EMPTY(ALL_BUFFS_EMPTY),          //output  logic                   EMPTY,
            .VALID_FOR_DL(VALID_FOR_DL),                //output  logic                   VALID,
            .OUT_TLP_DW(OUT_TLP_DW),                     //output  logic    [31:0]         OUT_TLP_DW    );

            .TLP_START_BIT_OUT_COMB(TLP_START_BIT_OUT),
            .TLP_END_BIT_OUT_COMB(TLP_END_BIT_OUT_COMB),

            // .CPL_ARB_ACK(CPL_ARB_ACK),

            .fsm_finished(fsm_finished),
            .fsm_started(fsm_started),
            .ACK(TL_TX_ACK)
);
endmodule