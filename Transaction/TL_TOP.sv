module TL_TOP
(
//2 Interfaces: Data Link & Application Layer

);


FIFO NON_POSTED_BUFFER // [TAG]: {Requester ID, Status, Valid}
(
    .clk            (clk),//input  logic        clk, 
    .rst            (rst),//input  logic        rst,
    .WrEn           (DATA_BUFFER_WR_EN),//input  logic        DATA_BUFF_WR_EN, 
    .RdEn           (DATA_BUFF_RD_EN),//input  logic        DATA_BUFF_RD_EN,
    .DataIn         (rx_data),//input  logic [DATA_WIDTH-1:0] DATA_BUFF_DATA_IN,
    // .DataOut        (),//output logic [DATA_WIDTH-1:0] DATA_BUFF_DATA_OUT,
    .comb_DataOut   (DATA_BUFF_COMB_DATA_OUT), //output logic [DATA_WIDTH-1:0] DATA_BUFF_COMB_DATA_OUT
    .Full           (),//output logic        DATA_BUFF_Full, 
    .Empty          (DATA_BUFF_EMPTY),//output logic        DATA_BUFF_Empty 
    .AlmostEmpty    (last_dw)
); 


TX_NP_REQ_BUFF tx_np_req_buff // [TAG]: {Destination, Start Time, Valid}
(
    .clk            (clk),//input  logic        clk, 
    .rst            (rst),//input  logic        rst,
    .WrEn           (DATA_BUFFER_WR_EN),//input  logic        DATA_BUFF_WR_EN, 
    .RdEn           (DATA_BUFF_RD_EN),//input  logic        DATA_BUFF_RD_EN,
    .DataIn         (rx_data),//input  logic [DATA_WIDTH-1:0] DATA_BUFF_DATA_IN,
    // .DataOut        (),//output logic [DATA_WIDTH-1:0] DATA_BUFF_DATA_OUT,
    .comb_DataOut   (DATA_BUFF_COMB_DATA_OUT), //output logic [DATA_WIDTH-1:0] DATA_BUFF_COMB_DATA_OUT
    .Full           (),//output logic        DATA_BUFF_Full, 
    .Empty          (DATA_BUFF_EMPTY),//output logic        DATA_BUFF_Empty 
    .AlmostEmpty    (last_dw)
); 

endmodule