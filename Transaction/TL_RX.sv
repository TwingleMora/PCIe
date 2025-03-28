module TL_RX #(parameter DATA_WIDTH = 32)
(
input   logic                       clk, 
input   logic                       rst,

input   logic                       VALID_FROM_DL,
input   logic    [31:0]             IN_TLP_DW,    




// <<<<<<<<<<<<<<<<<<<<<<<<<<<>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>

// output   logic    [9:0]             port_write_en,
// output   logic    [2:0]             tlp_mem_io_msg_cpl_conf,
// output   logic                      tlp_address_32_64,
// output   logic                      tlp_read_write,


// output   logic    [2:0]             TC,
// output   logic    [2:0]             ATTR,
// //output   logic    [15:0]          device_id, Enable It Later, But For NoW Conf Space Remains inside the TL_TX
// output   logic    [7:0]             tag,
// output   logic    [11:0]            byte_count,
// output   logic    [31:0]            lower_addr,
// output   logic    [31:0]            upper_addr,
// output   logic    [15:0]            dest_bdf_id,
// output   logic    [31:0]            data,
// output   logic    [9:0]             config_dw_number,

// output   logic                      RD_EN,

// output   logic                      valid_from_tl_rx,

// output   wire                       ALL_BUFFS_EMPTY

// <<<<<<<<<<<<<<<<<<<<<<<<<<<>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>

input   logic [31:0]        M_PRDATA1,
input   logic [31:0]        M_PRDATA2,

output  logic               M_PSEL1,
output  logic               M_PSEL2,
output  logic [31:0]        M_PADDR,
output  logic               M_PENABLE,
output  logic               M_PWRITE,
output  logic [3:0]         M_PSTRB,
output  logic [31:0]        M_PWDATA

);


//---------------------------------------------
//ERROR CHECK
// /* output */  logic                     HEADER_DATA; // 0: Header; 1: Data
// /* output */  logic [1:0]               P_NP_CPL; // Posted: 00; Non-Posted: 01; Completion: 11
// /* output */  logic [DATA_WIDTH-1:0]    IN_TLP_DW;
// /* output */  logic                     WR_EN;

// /* output */  logic                     commit;
// /* output */  logic                     flush;

//---------------------------------------------
//RX_PNPC_BUFF
// /* input */  logic                     HEADER_DATA; // 0: Header; 1: Data
// /* input */  logic [1:0]               P_NP_CPL; // Posted: 00; Non-Posted: 01; Completion: 11
// /* input */  logic [DATA_WIDTH-1:0]    IN_TLP_DW;
// /* input */  logic                     WR_EN;
// /* input */  logic                     RD_EN;

// /* input */  logic                     commit;
// /* input */  logic                     flush;



// /* output */ wire                      EMPTY;
// /* output */ logic                     OUT_EMPTY;
// /* output */ logic [DATA_WIDTH-1:0]    OUT_TLP_DW;      
// /* output */ logic [DATA_WIDTH-1:0]    OUT_TLP_DW_COMB;  
//---------------------------------------------
//TL_RX_DECODER
/*output*/  logic            DATA_BUFFER_WR_EN;
/*output*/  logic [2:0]      rx_tlp_mem_io_msg_cpl_conf;
/*output*/  logic            rx_tlp_address_32_64;
/*output*/  logic            rx_tlp_read_write;

/*output*/  logic [11:0]     rx_cpl_byte_count;
/*output*/  logic [6:0]      rx_cpl_lower_address;
/*output*/  logic [3:0]      rx_first_dw_be;
/*output*/  logic [3:0]      rx_last_dw_be;
/*output*/  logic [31:0]     rx_lower_addr;
/*output*/  logic [31:0]     rx_upper_addr;
/*output*/  logic [31:0]     rx_data;
/*output*/  logic [11:0]     rx_config_dw_number;

/*input*/   logic [31:0]     TLP;
/*input*/   logic            M_READY;
/*output*/  logic            M_ENABLE;

//---------------------------------------------------------
//FIFO
// /*input*/  logic        DATA_BUFF_WR_EN;
// /*input*/  logic        DATA_BUFF_RD_EN;
// /*input*/  logic [DATA_WIDTH-1:0] DATA_BUFF_DATA_IN;
// /*output*/ logic [DATA_WIDTH-1:0] DATA_BUFF_DATA_OUT;
/*output*/  logic [DATA_WIDTH-1:0] DATA_BUFF_COMB_DATA_OUT;
// /*output*/ logic        DATA_BUFF_Full;
// /*output*/ logic        DATA_BUFF_Empty;

//--------------------------------------------------------------
//MASTER_BRIDGE

// /*input*/   logic               PENABLE;
// /*output*/  logic               PREADY;
// /*input*/   logic  [2:0]        tlp_mem_io_msg_cpl_conf;
// /*input*/   logic               tlp_address_32_64;
// /*input*/   logic               tlp_read_write;
// /*input*/   logic  [3:0]        first_dw_be;
// /*input*/   logic  [3:0]        last_dw_be;
// /*input*/   logic  [31:0]       lower_addr;
// /*input*/   logic  [31:0]       data;
/*input*/   logic               last_dw;
/*input*/   logic               DATA_BUFF_EMPTY;
/*output*/  logic               DATA_BUFF_RD_EN;
// /*input*/   logic  [9:0]        config_dw_number;
//                 <<APB INTF>>



/*
Error Check

*/
// TL_RX_ERROR_CHECK tl_rx_error_check();


RX_PNPC_BUFF #(.DATA_WIDTH(32)) PNPC_BUFF0
(
    .clk(clk),                            //input  logic                     clk,
    .rst(rst),                            //input  logic                     rst,
    .HEADER_DATA(HEADER_DATA),            //input  logic                     HEADER_DATA, // 0: Header, 1: Data
    .P_NP_CPL(P_NP_CPL),                  //input  logic [1:0]               P_NP_CPL, // Posted: 00, Non-Posted: 01, Completion: 11
    .IN_TLP_DW(IN_TLP_DW),                //input  logic [DATA_WIDTH-1:0]    IN_TLP_DW
    .WR_EN(PNPC_BUFF_WR_EN),              //input  logic                     WrEn,
    .RD_EN(RD_EN),                        //input  logic                     RdEn,
    .commit(),
    .flush(),
    .EMPTY(ALL_BUFFS_EMPTY),
    
    .OUT_TLP_DW(OUT_TLP_DW)               //output logic [DATA_WIDTH-1:0]    OUT_TLP_DW           
);


// PENDING_REQUESTS BUFFER.

// NON_POSTED_REQUESTS BUFFER.


TL_RX_DECODER tl_rx_decoder
(
    .clk(clk),
    .rst(rst),
    .TLP(OUT_TLP_DW),// input  logic   [31:0]   TLP,
    .TLP_BUFFER_EMPTY(ALL_BUFFS_EMPTY),// input  logic            TLP_BUFFER_EMPTY,
    .TLP_BUFFER_RD_EN(RD_EN),// output logic            TLP_BUFFER_RD_EN,
    
    
    .DATA_BUFFER_WR_EN(DATA_BUFFER_WR_EN),// output logic            DATA_BUFFER_WR_EN,          
    


    .tlp_mem_io_msg_cpl_conf(rx_tlp_mem_io_msg_cpl_conf),// output  logic  [2:0]     tlp_mem_io_msg_cpl_conf,
    .tlp_address_32_64(rx_tlp_address_32_64),// output  logic            tlp_address_32_64,
    .tlp_read_write(rx_tlp_read_write),// output  logic            tlp_read_write,
    // //output  logic            tlp_conf_type,

    .cpl_byte_count(rx_cpl_byte_count),// output  logic  [11:0]    cpl_byte_count,
    .cpl_lower_address(rx_cpl_lower_address),// output  logic  [6:0]     cpl_lower_address,

    .first_dw_be(rx_first_dw_be),  // output  logic  [3:0]     first_dw_be,
    .last_dw_be(rx_last_dw_be),    // output  logic  [3:0]     last_dw_be,

    .lower_addr(rx_lower_addr),            // output  logic  [31:0]    lower_addr,
    .upper_addr(rx_upper_addr),            // output  logic  [31:0]    upper_addr,
    
    .config_dw_number(rx_config_dw_number),// output  logic  [11:0]    config_dw_number,

    .data(rx_data),                        // output  logic  [31:0]    data,





    // Interface With Master
    .M_READY(M_READY), // input  logic            M_READY
    .M_ENABLE(M_ENABLE)// output logic            M_ENABLE,

);



FIFO DATA_BUFFER
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







MASTER_BRIDGE master_bridge
(
    .PCLK(clk),     //     input logic         PCLK,
    .PRESETn(rst),  //     input logic         PRESETn,



    
    // //SLAVE Interface (APB-Like Interface FROM Transaction )

    .PENABLE(M_ENABLE), //     input   logic           PENABLE,
    .PREADY(M_READY),   //     output  logic           PREADY,

        

        
    .tlp_mem_io_msg_cpl_conf(rx_tlp_mem_io_msg_cpl_conf),   //     input  logic  [2:0]     tlp_mem_io_msg_cpl_conf,
    .tlp_address_32_64(rx_tlp_address_32_64),               //     input  logic            tlp_address_32_64,
    .tlp_read_write(rx_tlp_read_write),                     //     input  logic            tlp_read_write,

        
    .first_dw_be(rx_first_dw_be),   //     input  logic  [3:0]     first_dw_be,
    .last_dw_be(rx_last_dw_be),     //     input  logic  [3:0]     last_dw_be,
    .lower_addr(rx_lower_addr),     //     input  logic  [31:0]    lower_addr,

    // //calculate OFFSET and M_PSTRB

    .data(DATA_BUFF_COMB_DATA_OUT), //     input  logic  [31:0]    data,
    .last_dw(last_dw),              //     input  logic            last_dw,

    .DATA_BUFF_EMPTY(DATA_BUFF_EMPTY),  //     output logic            DATA_BUFF_EMPTY,
    .DATA_BUFF_RD_EN(DATA_BUFF_RD_EN),                 //     output logic            DATA_BUFF_RD_EN,

    .config_dw_number(rx_config_dw_number),//     input  logic  [9:0]     config_dw_number,


    // // Master Interface (TO APPLICATION & CONF MEMORY)

    .M_PRDATA1(M_PRDATA1),  //     input  logic [31:0] M_PRDATA1,
    .M_PRDATA2(),           //     input  logic [31:0] M_PRDATA2,

    .M_PREADY1(M_PREADY1),  //     input  logic        M_PREADY1,
    .M_PREADY2(),           //     input  logic        M_PREADY2,
    

    .M_PSEL1(M_PSEL1),      //     output logic        M_PSEL1,
    .M_PSEL2(),             //     output logic        M_PSEL2,

    .M_PADDR(M_PADDR),      //     output logic [31:0] M_PADDR,
    .M_PENABLE(M_PENABLE),  //     output logic        M_PENABLE,
    .M_PWRITE(M_PWRITE),    //     output logic        M_PWRITE,
    .M_PSTRB(M_PSTRB),      //     output logic [3:0]  M_PSTRB,
    .M_PWDATA(M_PWDATA)     //     output logic [31:0] M_PWDATA 


    //////////////TRANSMITER///////////// FOR COMPLETION //////////////
);







endmodule