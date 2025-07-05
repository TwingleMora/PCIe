//B => Bridge
//COMPLETION is 3DW
module DOUBLE_IN_CPL_ARB#(parameter DATA_WIDTH = 128, parameter DATA_WIDTH2 = 32 )
(
    input clk,
    input rst,

    //    I'll use this block to generate CPL/ CPLD 
    //      .    .    .    .                        
    //    //.\\//.\\//.\\//.\\ CPL FROM ERROR BLOCK     
    
   /*         input   logic    [2:0]          ERR_CPL_tlp_mem_io_msg_cpl, */ //type // .tlp_mem_io_msg_cpl_conf(tlp_mem_io_msg_cpl_conf),
 /*           input   logic                   ERR_CPL_tlp_address_32_64,       //fmt[0]      //.tlp_address_32_64(tlp_address_32_64), */
/*            input   logic                   ERR_CPL_tlp_read_write,          //fmt[1]      // .tlp_read_write(tlp_read_write), */
//-------------------------------------------------------------------------- (4)

           input   logic    [2:0]          ERR_CPL_TC,                      //.TC(TC),
           input   logic    [2:0]          ERR_CPL_ATTR,                    //.ATTR(ATTR),
//---------------------------------------------------------------------------(6)

           input   logic    [15:0]         ERR_CPL_requester_id,            //[[X]]  -- //COMPLETER ID //.device_id(device_id),
           input   logic    [7:0]          ERR_CPL_tag,                     //[[X]].tag(tag),
           input   logic    [11:0]         ERR_CPL_byte_count,              //.byte_count(byte_count),
//---------------------------------------------------------------------------(36)           
           input   logic    [2:0]          ERR_CPL_completion_status,
           input   logic    [6:0]          ERR_CPL_lower_addr,              //[[X]]       //.lower_addr(lower_addr),
//---------------------------------------------------------------------------(7)
           // Do I need Address Here?? No 
           
         
    //    input   logic    [31:0]         ERR_CPL_data1,                 //.data1(data1),
    //    input   logic    [31:0]         ERR_CPL_data2,                 //.data2(data2),
    //    input   logic    [31:0]         ERR_CPL_data3,                 //.data3(data3),
//---------------------------------------------------------------------------(96)
           
    //     input   logic                   ERR_CPL_valid,                 //.valid(valid),
           input   logic                   ERR_CPL_Wr_En,                 //.valid(valid),
//---------------------------------------------------------------------------(1)




    //      .    .    .    .                        
    //    //.\\//.\\//.\\//.\\ CPLD FROM RX BRIDGE  
           /* input   logic    [2:0]          RX_B_tlp_mem_io_msg_cpl,  */// .tlp_mem_io_msg_cpl_conf(tlp_mem_io_msg_cpl_conf),
        /* input   logic                   RX_B_tlp_address_32_64,       //.tlp_address_32_64(tlp_address_32_64), */
           input   logic                        RX_B_tlp_read_write,          // .tlp_read_write(tlp_read_write),


           input   logic    [2:0]               RX_B_TC,               //.TC(TC),
           input   logic    [2:0]               RX_B_ATTR,             //.ATTR(ATTR),
           
           input   logic    [15:0]              RX_B_requester_id,     //.device_id(device_id),
           input   logic    [7:0]               RX_B_tag,              //.tag(tag),
           input   logic    [11:0]              RX_B_byte_count,       //.byte_count(byte_count),

//--------------------------------------------------------------------------------------
           
           // Do I need Address Here?? No 
           input   logic    [2:0]               RX_B_completion_status,
           input   logic    [6:0]               RX_B_lower_addr,       //.lower_addr(lower_addr),     

//-----------------------------------------------------------------------------------------           
//-----------------------------------------------------------------------------------------           
           input   logic    [DATA_WIDTH-1:0]    RX_B_data,
  
     //////////////////////////////////////////////////////////////
    //////////////////////////TX_FIFO/////////////////////////////
           input   logic    [DATA_WIDTH2-1:0]    RX_B_TX_DATA_FIFO_data,
           input   logic                         RX_B_TX_DATA_FIFO_WR_EN,
  //////////////////////////////////////////////////////////////
   
           input   logic                        RX_B_Wr_En,                  //.valid(valid),
//-----------------------------------------------------------------------------------------           
//-----------------------------------------------------------------------------------------           
           
       //  input   logic                   RX_B_valid                   //.valid(valid),
//-----------------------------------------------------------------------------------------



    /// FROM BRIDGE

 
    //


    /////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////
    ///////////////////////////////////////////////////////////////////
    output  logic                           VALID,   /////////////////
                                                    /////////////////
                                                   //////////////////
    /////////////////////////////////////////////////////////////////
    /////////////////////////////////////////////////////////////////
    /////////////////////////////////////////////////////////////////

           output   logic    [2:0]              X_tlp_mem_io_msg_cpl, //type // .tlp_mem_io_msg_cpl_conf(tlp_mem_io_msg_cpl_conf),
           output   logic                       X_tlp_address_32_64,       //fmt[0]      //.tlp_address_32_64(tlp_address_32_64),
           output   logic                       X_tlp_read_write,          //fmt[1]      // .tlp_read_write(tlp_read_write),
//---------------------------------------------------------------------------(4)
           output   logic    [2:0]              X_TC,                      //.TC(TC), 
           output   logic    [2:0]              X_ATTR,                    //.ATTR(ATTR), 
//---------------------------------------------------------------------------(6)

           output   logic    [15:0]             X_requester_id,            //[[X]]  -- //COMPLETER ID //.device_id(device_id),
           output   logic    [7:0]              X_tag,                     //[[X]].tag(tag),
           output   logic    [11:0]             X_byte_count,              //.byte_count(byte_count),
//-----------------------------------------------------------------------------(36)           
           output   logic    [2:0]              X_completion_status,
           output   logic    [6:0]              X_lower_addr,              //[[X]]       //.lower_addr(lower_addr),
//-----------------------------------------------------------------------------(10) 
           output   logic    [DATA_WIDTH-1:0]   X_data,                   //.data1(data1),

      //////////////////////////////////////////////////////////////
     //////////////////////////////////////////////////////////////
    //////////////////////////TX_FIFO/////////////////////////////
   //////////////////////////////////////////////////////////////
  //////////////////////////////////////////////////////////////
           input   logic                        X_TX_FIFO_RD_EN,
           input   logic                        X_ACK,
           output  logic    [DATA_WIDTH2-1:0]   X_data2                   //.data1(data1),

);
// Address: 32bit,
// Data: 96 ~ 128 bit
// [2 + 1 + 1]  [3 + 3]  [16 + 8]  [12] =>



//-------------------------------------------------------------------------- 
           logic    [2:0]          ERR_CPL_tlp_mem_io_msg_cpl_out; //type // .tlp_mem_io_msg_cpl_conf(tlp_mem_io_msg_cpl_conf),                 //input   logic    [1:0]           tlp_mem_io_msg_cpl_conf,
           logic                   ERR_CPL_tlp_address_32_64_out;       //fmt[0]      //.tlp_address_32_64(tlp_address_32_64),                       //input   logic                    tlp_address_32_64,
           logic                   ERR_CPL_tlp_read_write_out;          //fmt[1]      // .tlp_read_write(tlp_read_write),                            //input   logic                    tlp_read_write,
//-------------------------------------------------------------------------- (4)

           logic    [2:0]          ERR_CPL_TC_out;                      //.TC(TC),                                                      //input   logic    [2:0]          TC,
           logic    [2:0]          ERR_CPL_ATTR_out;                    //.ATTR(ATTR),                                                  //input   logic    [2:0]          ATTR,
//---------------------------------------------------------------------------(6)

           logic    [15:0]         ERR_CPL_requester_id_out;            //[[X]]  -- //COMPLETER ID //.device_id(device_id),             //input   logic    [15:0]         device_id,
           logic    [7:0]          ERR_CPL_tag_out;                     //[[X]].tag(tag),                                               //input   logic    [7:0]          tag,
           logic    [11:0]         ERR_CPL_byte_count_out;              //.byte_count(byte_count),                                      //input   logic    [11:0]         byte_count;
//---------------------------------------------------------------------------(36)           

           logic    [6:0]          ERR_CPL_lower_addr_out;              //[[X]]       //.lower_addr(lower_addr),                                      //input   logic    [31:0]         lower_addr,
           logic    [2:0]          ERR_CPL_completion_status_out;
//---------------------------------------------------------------------------(7)
//---------------------------------------------------------------------------(96)
           


//--------------------------------------------------------------------------// 
//--------------------------------------------------------------------------//
//--------------------------------------------------------------------------//
//--------------------------------------------------------------------------// 



           logic    [2:0]               RX_B_tlp_mem_io_msg_cpl_out;      //type // .tlp_mem_io_msg_cpl_conf(tlp_mem_io_msg_cpl_conf),                 //input   logic    [1:0]           tlp_mem_io_msg_cpl_conf,
           logic                        RX_B_tlp_address_32_64_out;       //fmt[0]      //.tlp_address_32_64(tlp_address_32_64),                       //input   logic                    tlp_address_32_64,
           logic                        RX_B_tlp_read_write_out;          //fmt[1]      // .tlp_read_write(tlp_read_write),                            //input   logic                    tlp_read_write,
//-------------------------------------------------------------------------- (4)

           logic    [2:0]               RX_B_TC_out;                      //.TC(TC),                                                      //input   logic    [2:0]          TC,
           logic    [2:0]               RX_B_ATTR_out;                    //.ATTR(ATTR),                                                  //input   logic    [2:0]          ATTR,
//---------------------------------------------------------------------------(6)

           logic    [15:0]              RX_B_requester_id_out;            //[[X]]  -- //COMPLETER ID //.device_id(device_id),             //input   logic    [15:0]         device_id,
           logic    [7:0]               RX_B_tag_out;                     //[[X]].tag(tag),                                               //input   logic    [7:0]          tag,
           logic    [11:0]              RX_B_byte_count_out;              //.byte_count(byte_count),                                      //input   logic    [11:0]         byte_count;
//---------------------------------------------------------------------------(36)           

           logic    [6:0]               RX_B_lower_addr_out;              //[[X]]       //.lower_addr(lower_addr),                                      //input   logic    [31:0]         lower_addr,
           logic    [2:0]               RX_B_completion_status_out;
//---------------------------------------------------------------------------(7)
        // Do I need Address Here?? No 
           logic    [DATA_WIDTH-1:0]    RX_B_data_out;                 //.data1(data1),                                 //input   logic    [31:0]         data1,
           
        //////////////////////////////////////////////////////////////
        /////////////////////////////FIFO TX/////////////////////////
        //////////////////////////////////////////////////////////////
           logic    [DATA_WIDTH2-1:0]    RX_B_data_out2;                 //.data1(data1),                                 //input   logic    [31:0]         data1,
        //////////////////////////////////////////////////////////////
        //////////////////////////////////////////////////////////////
                
//---------------------------------------------------------------------------(96)


//TODO
/*
1- add signal in port signals
2- add signal in out signals
3- add signal to x_CONTROL_SIGNALS
4- add signal to x_CONTROL_BUFF_OUT

// WIDTH = 55-0 + 1 = 56
*/
      //////////////////////////////////////////////////////////////
     //////////////////////////////////////////////////////////////
    //////////////////////////TX_FIFO/////////////////////////////
   //////////////////////////////////////////////////////////////
  //////////////////////////////////////////////////////////////
           logic                     ERR_ACK;

      //////////////////////////////////////////////////////////////
     //////////////////////////////////////////////////////////////
    //////////////////////////TX_FIFO/////////////////////////////
   //////////////////////////////////////////////////////////////
  //////////////////////////////////////////////////////////////
           logic                     RX_TX_FIFO_RD_EN;

           logic                     RX_ACK;





wire ERROR_BUFF_RD_EN;

wire [56:0] ERROR_CONTROL_SIGNALS = {3'b011, /* ERR_CPL_tlp_address_32_64 */ 1'b0,
 /* ERR_CPL_tlp_read_write */ 1'b0, ERR_CPL_TC, ERR_CPL_ATTR, ERR_CPL_requester_id, ERR_CPL_tag, ERR_CPL_byte_count, 
 ERR_CPL_completion_status, ERR_CPL_lower_addr};

wire [56:0] ERROR_CONTROL_BUFF_OUT;
assign {ERR_CPL_tlp_mem_io_msg_cpl_out, ERR_CPL_tlp_address_32_64_out,
 ERR_CPL_tlp_read_write_out, ERR_CPL_TC_out, ERR_CPL_ATTR_out, ERR_CPL_requester_id_out, ERR_CPL_tag_out, ERR_CPL_byte_count_out, 
 ERR_CPL_completion_status_out, ERR_CPL_lower_addr_out} = ERROR_CONTROL_BUFF_OUT;
wire ERROR_CONTROL_BUFF_EMPTY;
wire ERROR_CONTROL_BUFF_VALID = ~ERROR_CONTROL_BUFF_EMPTY;
FIFO_D #(.DEPTH(32), .DATA_WIDTH(57)) ERROR_CONTROL_BUFF
(
/* input  logic                     */ .clk(clk), 
/* input  logic                     */ .rst(rst),
/* input  logic                     */ .WrEn(ERR_CPL_Wr_En), 
/* input  logic                     */ .RdEn(ERR_ACK),
/* input  logic [DATA_WIDTH-1:0]    */ .DataIn(ERROR_CONTROL_SIGNALS),
/* output logic [DATA_WIDTH-1:0]    */ .DataOut(),
/* output logic [DATA_WIDTH-1:0]    */ .comb_DataOut(ERROR_CONTROL_BUFF_OUT),
/* output logic                     */ .Full(), 
/* output logic                     */ .Empty(ERROR_CONTROL_BUFF_EMPTY),
/* output logic                     */ .AlmostEmpty(),
/* output logic                     */ .AlmostFull()
);

// wire [95:0] ERROR_DATA_BUSES = {ERR_CPL_data3, ERR_CPL_data2, ERR_CPL_data1}; 
// wire [95:0] ERROR_DATA_BUFF_OUT;
// wire ERROR_DATA_BUFF_EMPTY;
// wire ERROR_DATA_BUFF_VALID = ~ERROR_DATA_BUFF_EMPTY;
// FIFO_D #(.DEPTH(32), .DATA_WIDTH(96)) ERROR_DATA_BUFF
// (
// /* input  logic                     */ .clk(clk), 
// /* input  logic                     */ .rst(rst),
// /* input  logic                     */ .WrEn(ERR_CPL_Wr_En), 
// /* input  logic                     */ .RdEn(),
// /* input  logic [DATA_WIDTH-1:0]    */ .DataIn(ERROR_DATA_BUSES),
// /* output logic [DATA_WIDTH-1:0]    */ .DataOut(),
// /* output logic [DATA_WIDTH-1:0]    */ .comb_DataOut(ERROR_DATA_BUFF_OUT),
// /* output logic                     */ .Full(), 
// /* output logic                     */ .Empty(ERROR_DATA_BUFF_EMPTY),
// /* output logic                     */ .AlmostEmpty(),
// /* output logic                     */ .AlmostFull()
// ); 


 //////-------------------------------------------------------------/////
 /////=============================================================/////
 ////=============================================================/////
 ///=============================================================/////
 //-------------------------------------------------------------/////
 /*-----------------------------------------------------------*/////

wire RX_BRIDGE_BUFF_RD_EN;


wire [56:0] RX_BRIDGE_CONTROL_SIGNALS = {3'b011, /* RX_B_tlp_address_32_64 3DW */ 1'b0,
RX_B_tlp_read_write /* CPL /CPLD */, RX_B_TC, RX_B_ATTR, RX_B_requester_id,
RX_B_tag, RX_B_byte_count, RX_B_completion_status, RX_B_lower_addr};
wire [56:0] RX_BRIDGE_CONTROL_SIGNALS_OUT;


assign {RX_B_tlp_mem_io_msg_cpl_out, RX_B_tlp_address_32_64_out,
RX_B_tlp_read_write_out /* CPL /CPLD */, RX_B_TC_out, RX_B_ATTR_out, 
RX_B_requester_id_out, RX_B_tag_out, RX_B_byte_count_out, RX_B_completion_status_out, RX_B_lower_addr_out} = RX_BRIDGE_CONTROL_SIGNALS_OUT;

wire RX_BRIDGE_CONTROL_BUFF_EMPTY;
wire RX_BRIDGE_CONTROL_BUFF_VALID = ~RX_BRIDGE_CONTROL_BUFF_EMPTY;

FIFO_D #(.DEPTH(32), .DATA_WIDTH(57)) RX_BRIDGE_CONTROL_BUFF
(
/* input  logic                     */ .clk(clk), 
/* input  logic                     */ .rst(rst),
/* input  logic                     */ .WrEn(RX_B_Wr_En), 
/* input  logic                     */ .RdEn(RX_ACK),
/* input  logic [DATA_WIDTH-1:0]    */ .DataIn(RX_BRIDGE_CONTROL_SIGNALS),
/* output logic [DATA_WIDTH-1:0]    */ .DataOut(),
/* output logic [DATA_WIDTH-1:0]    */ .comb_DataOut(RX_BRIDGE_CONTROL_SIGNALS_OUT),
/* output logic                     */ .Full(), 
/* output logic                     */ .Empty(RX_BRIDGE_CONTROL_BUFF_EMPTY),
/* output logic                     */ .AlmostEmpty(),
/* output logic                     */ .AlmostFull()
);

wire [DATA_WIDTH-1:0] RX_BRIDGE_DATA_BUSES = {RX_B_data};
wire [DATA_WIDTH-1:0] RX_BRIDGE_DATA_BUFF_OUT;
wire [DATA_WIDTH2-1:0] RX_BRIDGE_DATA_BUFF_OUT2;

assign {RX_B_data_out} = RX_BRIDGE_DATA_BUFF_OUT;
assign RX_B_data_out2 = RX_BRIDGE_DATA_BUFF_OUT2;

wire RX_BRIDGE_DATA_BUFF_EMPTY;
wire RX_BRIDGE_DATA_BUFF_VALID = ~ RX_BRIDGE_DATA_BUFF_EMPTY;


// FIFO_D #(.DEPTH(32), .DATA_WIDTH(DATA_WIDTH)) RX_BRIDGE_DATA_BUFF
// (
// /* input  logic                     */ .clk(clk), 
// /* input  logic                     */ .rst(rst),
// /* input  logic                     */ .WrEn(RX_B_Wr_En), 
// /* input  logic                     */ .RdEn(RX_TX_FIFO_RD_EN),
// /* input  logic [DATA_WIDTH-1:0]    */ .DataIn(RX_BRIDGE_DATA_BUSES),
// /* output logic [DATA_WIDTH-1:0]    */ .DataOut(),
// /* output logic [DATA_WIDTH-1:0]    */ .comb_DataOut(RX_BRIDGE_DATA_BUFF_OUT),
// /* output logic                     */ .Full(), 
// /* output logic                     */ .Empty(RX_BRIDGE_DATA_BUFF_EMPTY),
// /* output logic                     */ .AlmostEmpty(),
// /* output logic                     */ .AlmostFull()
// );

FIFO_D #(.DEPTH(32), .DATA_WIDTH(DATA_WIDTH2)) RX_BRIDGE_DATA_BUFF2
(
/* input  logic                     */ .clk(clk), 
/* input  logic                     */ .rst(rst),
/* input  logic                     */ .WrEn(RX_B_TX_DATA_FIFO_WR_EN), 
/* input  logic [DATA_WIDTH-1:0]    */ .DataIn(RX_B_TX_DATA_FIFO_data),
/* output logic [DATA_WIDTH-1:0]    */ .DataOut(),
/* input  logic                     */ .RdEn(RX_TX_FIFO_RD_EN),
/* output logic [DATA_WIDTH-1:0]    */ .comb_DataOut(RX_BRIDGE_DATA_BUFF_OUT2),
/* output logic                     */ .Full(), 
/* output logic                     */ .Empty(RX_BRIDGE_DATA_BUFF_EMPTY),
/* output logic                     */ .AlmostEmpty(),
/* output logic                     */ .AlmostFull()
);


wire RX_BRIDGE_BUFF_REQ = (RX_BRIDGE_DATA_BUFF_VALID && RX_BRIDGE_CONTROL_BUFF_VALID); //I think data must exist
wire ERROR_BUFF_REQ     = (/* ERROR_DATA_BUFF_VALID &&  */ERROR_CONTROL_BUFF_VALID);
 
wire RX_BRIDGE_BUFF_GRANT;
wire ERROR_BUFF_GRANT;
wire [1:0] requests;
wire [1:0] grants;
assign requests = {RX_BRIDGE_BUFF_REQ, ERROR_BUFF_REQ}; 
assign {RX_BRIDGE_BUFF_GRANT, ERROR_BUFF_GRANT}  = grants;
Arbiter #(.WIDTH(2), .DESC(1)) CPL_ARBITER
(
 /* input   logic [WIDTH-1:0]  */ .IN(requests),
 /* output  logic [WIDTH-1:0] */  .OUT(grants)
);

// assign ERROR_BUFF_RD_EN = ERROR_BUFF_GRANT && ACK;
// assign RX_BRIDGE_BUFF_RD_EN = RX_BRIDGE_BUFF_GRANT && ACK;

assign VALID = ERROR_BUFF_GRANT || RX_BRIDGE_BUFF_GRANT;

localparam ERROR_BUFF=1, RX_BRIDGE_BUFF=2; 
always@(*)
begin

        /* output   logic    [1:0] */          X_tlp_mem_io_msg_cpl = 0/* RX_B_tlp_mem_io_msg_cpl_out */; //type // .tlp_mem_io_msg_cpl_conf(tlp_mem_io_msg_cpl_conf),                 //output   logic    [1:0]           tlp_mem_io_msg_cpl_conf,
        /* output   logic */                   X_tlp_address_32_64 = 0 /* RX_B_tlp_address_32_64_out */;       //fmt[0]      //.tlp_address_32_64(tlp_address_32_64),                       //output   logic                    tlp_address_32_64,
        /* output   logic */                   X_tlp_read_write = 0/* RX_B_tlp_read_write_out */;          //fmt[1]      // .tlp_read_write(tlp_read_write),                            //output   logic                    tlp_read_write,
//-------------------------------------------------------------------------- (4)

        /* output   logic    [2:0] */          X_TC = 0/* RX_B_TC_out */;                       //.TC(TC),                                                      //output   logic    [2:0]          TC,
        /* output   logic    [2:0] */          X_ATTR = 0/* RX_B_ATTR_out */;                   //.ATTR(ATTR),                                                  //output   logic    [2:0]          ATTR,
//---------------------------------------------------------------------------(6)

        /* output   logic    [15:0] */         X_requester_id      = 0/* RX_B_requester_id_out */;          //[[X]]  -- //COMPLETER ID //.device_id(device_id),             //output   logic    [15:0]         device_id,
        /* output   logic    [1:0]  */         X_completion_status = 0; 
        /* output   logic    [7:0] */          X_tag               = 0/* RX_B_tag_out */;                            //[[X]].tag(tag),                                               //output   logic    [7:0]          tag,
        /* output   logic    [11:0] */         X_byte_count        = 0/* RX_B_byte_count_out */;              //.byte_count(byte_count),                                      //output   logic    [11:0]         byte_count,
//---------------------------------------------------------------------------(36)           

        /* output   logic    [6:0] */          X_lower_addr = 0/* RX_B_lower_addr_out */;              //[[X]]       //.lower_addr(lower_addr),  
        
        // /* output   logic    [31:0] */         X_data1 = 0/* RX_B_data1 */;                 //.data1(data1),
        // /* output   logic    [31:0] */         X_data2 = 0/* RX_B_data2 */;                 //.data2(data2),
        // /* output   logic    [31:0] */         X_data3 = 0/* RX_B_data3 */;                 //.data3(data3), 
                                               

              ////////////////////////////////////////////////////////////
                                               X_data = 0;
              ////////////////////////////////////////////////////////////
             /////////////////////////FIFO TX//////////////////////////
            //////////////////////////////////////////////////////////
                                                RX_ACK = 0;
                                                RX_TX_FIFO_RD_EN = 0;
            //////////////////////////////////////////////////////////

              ////////////////////////////////////////////////////////////
             /////////////////////////FIFO TX//////////////////////////
            //////////////////////////////////////////////////////////
                                                ERR_ACK = 0;
            //////////////////////////////////////////////////////////
            

              ////////////////////////////////////////////////////////////
             /////////////////////////FIFO TX//////////////////////////
            //////////////////////////////////////////////////////////    
                                                X_data2 = 0; 
            //////////////////////////////////////////////////////////    
    case(grants)
    ERROR_BUFF:
    begin
        /* output   logic    [1:0] */          X_tlp_mem_io_msg_cpl = ERR_CPL_tlp_mem_io_msg_cpl_out; //type // .tlp_mem_io_msg_cpl_conf(tlp_mem_io_msg_cpl_conf),                 //output   logic    [1:0]           tlp_mem_io_msg_cpl_conf,
        /* output   logic */                   X_tlp_address_32_64 = ERR_CPL_tlp_address_32_64_out;       //fmt[0]      //.tlp_address_32_64(tlp_address_32_64),                       //output   logic                    tlp_address_32_64,
        /* output   logic */                   X_tlp_read_write = ERR_CPL_tlp_read_write_out;          //fmt[1]      // .tlp_read_write(tlp_read_write),                            //output   logic                    tlp_read_write,
//-------------------------------------------------------------------------- (4)

        /* output   logic    [2:0] */          X_TC = ERR_CPL_TC_out;                      //.TC(TC),                                                      //output   logic    [2:0]          TC,
        /* output   logic    [2:0] */          X_ATTR = ERR_CPL_ATTR_out;                   //.ATTR(ATTR),                                                  //output   logic    [2:0]          ATTR,
//---------------------------------------------------------------------------(6)

        /* output   logic    [15:0] */         X_requester_id = ERR_CPL_requester_id_out;           //[[X]]  -- //COMPLETER ID //.device_id(device_id),             //output   logic    [15:0]         device_id,
        /* output   logic    [1:0]  */         X_completion_status = ERR_CPL_completion_status_out; 
        /* output   logic    [7:0] */          X_tag = ERR_CPL_tag_out;                             //[[X]].tag(tag),                                               //output   logic    [7:0]          tag,
        /* output   logic    [11:0] */         X_byte_count = ERR_CPL_byte_count_out;              //.byte_count(byte_count),                                      //output   logic    [11:0]         byte_count,
//---------------------------------------------------------------------------(36)           

        /* output   logic    [6:0] */          X_lower_addr = ERR_CPL_lower_addr_out;              //[[X]]       //.lower_addr(lower_addr),  
                                               
             ////////////////////////////////////////////////////////////
            /////////////////////////FIFO TX//////////////////////////
            //////////////////////////////////////////////////////////
                                               ERR_ACK      = X_ACK;
            //////////////////////////////////////////////////////////
            //////////////////////////////////////////////////////////
    end
    
    RX_BRIDGE_BUFF:
    begin
        /* output   logic    [1:0] */          X_tlp_mem_io_msg_cpl = RX_B_tlp_mem_io_msg_cpl_out; //type // .tlp_mem_io_msg_cpl_conf(tlp_mem_io_msg_cpl_conf),                 //output   logic    [1:0]           tlp_mem_io_msg_cpl_conf,
        /* output   logic */                   X_tlp_address_32_64  = RX_B_tlp_address_32_64_out;       //fmt[0]      //.tlp_address_32_64(tlp_address_32_64),                       //output   logic                    tlp_address_32_64,
        /* output   logic */                   X_tlp_read_write     = RX_B_tlp_read_write_out;          //fmt[1]      // .tlp_read_write(tlp_read_write),                            //output   logic                    tlp_read_write,
//-------------------------------------------------------------------------- (4)

        /* output   logic    [2:0] */          X_TC = RX_B_TC_out;                       //.TC(TC),                                                      //output   logic    [2:0]          TC,
        /* output   logic    [2:0] */          X_ATTR = RX_B_ATTR_out;                   //.ATTR(ATTR),                                                  //output   logic    [2:0]          ATTR,
//---------------------------------------------------------------------------(6)

        /* output   logic    [15:0] */         X_requester_id = RX_B_requester_id_out;          //[[X]]  -- //COMPLETER ID //.device_id(device_id),             //output   logic    [15:0]         device_id,
        /* output   logic    [1:0]  */         X_completion_status = RX_B_completion_status_out;
        /* output   logic    [7:0] */          X_tag = RX_B_tag_out;                            //[[X]].tag(tag),                                               //output   logic    [7:0]          tag,
        /* output   logic    [11:0] */         X_byte_count = RX_B_byte_count_out;              //.byte_count(byte_count),                                      //output   logic    [11:0]         byte_count,
//---------------------------------------------------------------------------(36)           

        /* output   logic    [6:0] */          X_lower_addr = RX_B_lower_addr_out;              //[[X]]       //.lower_addr(lower_addr),  
        
        // /* output   logic    [31:0] */         X_data1 = RX_B_data1_out;                 //.data1(data1),
        // /* output   logic    [31:0] */         X_data2 = RX_B_data2_out;                 //.data2(data2),
        // /* output   logic    [31:0] */         X_data3 = RX_B_data3_out;                 //.data3(data3),  
                                                X_data      = RX_B_data_out;

            ////////////////////////////////////////////////////////////
            /////////////////////////FIFO TX//////////////////////////
            //////////////////////////////////////////////////////////
                                                RX_ACK             = X_ACK;
                                               
                                                X_data2            = RX_B_data_out2;
                                                RX_TX_FIFO_RD_EN   = X_TX_FIFO_RD_EN;
            //////////////////////////////////////////////////////////
            //////////////////////////////////////////////////////////

    end
    default:
    begin
        /* output   logic    [1:0] */          X_tlp_mem_io_msg_cpl = 0/* RX_B_tlp_mem_io_msg_cpl_out */; //type // .tlp_mem_io_msg_cpl_conf(tlp_mem_io_msg_cpl_conf),                 //output   logic    [1:0]           tlp_mem_io_msg_cpl_conf,
        /* output   logic */                   X_tlp_address_32_64 = 0 /* RX_B_tlp_address_32_64_out */;       //fmt[0]      //.tlp_address_32_64(tlp_address_32_64),                       //output   logic                    tlp_address_32_64,
        /* output   logic */                   X_tlp_read_write = 0/* RX_B_tlp_read_write_out */;          //fmt[1]      // .tlp_read_write(tlp_read_write),                            //output   logic                    tlp_read_write,
//-------------------------------------------------------------------------- (4)

        /* output   logic    [2:0] */          X_TC = 0/* RX_B_TC_out */;                       //.TC(TC),                                                      //output   logic    [2:0]          TC,
        /* output   logic    [2:0] */          X_ATTR = 0/* RX_B_ATTR_out */;                   //.ATTR(ATTR),                                                  //output   logic    [2:0]          ATTR,
//---------------------------------------------------------------------------(6)

        /* output   logic    [15:0] */         X_requester_id = 0/*RX_B_requester_id_out */;         //[[X]]  -- //COMPLETER ID //.device_id(device_id),             //output   logic    [15:0]         device_id,
        /* output   logic    [1:0]  */         X_completion_status = 0;
        /* output   logic    [7:0] */          X_tag = 0/*RX_B_tag_out*/;                            //[[X]].tag(tag),                                               //output   logic    [7:0]          tag,
        /* output   logic    [11:0] */         X_byte_count = 0/* RX_B_byte_count_out */;            //.byte_count(byte_count),                                      //output   logic    [11:0]         byte_count,
//---------------------------------------------------------------------------(36)           

        /* output   logic    [6:0] */          X_lower_addr = 0/* RX_B_lower_addr_out */;              //[[X]]       //.lower_addr(lower_addr),  
        
        // /* output   logic    [31:0] */         X_data1 = 0/* RX_B_data1 */;                 //.data1(data1),
        // /* output   logic    [31:0] */         X_data2 = 0/* RX_B_data2 */;                 //.data2(data2),
        // /* output   logic    [31:0] */         X_data3 = 0/* RX_B_data3 */;                 //.data3(data3), 
                                                X_data = 0;

            ////////////////////////////////////////////////////////////
            /////////////////////////FIFO TX//////////////////////////
            //////////////////////////////////////////////////////////
                                                RX_ACK = 0;
                                                RX_TX_FIFO_RD_EN = 0;
            //////////////////////////////////////////////////////////

            ////////////////////////////////////////////////////////////
            /////////////////////////FIFO TX//////////////////////////
            //////////////////////////////////////////////////////////
                                                ERR_ACK = 0;
            //////////////////////////////////////////////////////////
    end
    endcase

end





endmodule