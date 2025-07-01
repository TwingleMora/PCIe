module DOUBLE_IN_CPL_ARB_TB ;


bit clk;
logic rst;
 
//-------------------------------------------------------------------------- (4)
              /* input */   logic    [2:0]            ERR_CPL_TC;                      //.TC(TC);
              /* input */   logic    [2:0]            ERR_CPL_ATTR;                    //.ATTR(ATTR);
//---------------------------------------------------------------------------(6)
              /* input */   logic    [15:0]           ERR_CPL_requester_id;            //[[X]]  -- //COMPLETER ID 
              /* input */   logic    [7:0]            ERR_CPL_tag;                     //[[X]].
              /* input */   logic    [11:0]           ERR_CPL_byte_count;              //

//---------------------------------------------------------------------------(36)           
              /* input */   logic    [6:0]            ERR_CPL_lower_addr;              //[[X]]
                            logic    [2:0]            ERR_CPL_completion_status;
//---------------------------------------------------------------------------(7)  
//---------------------------------------------------------------------------(96)
             /* input */    logic                     ERR_CPL_Wr_En;                 //.valid(valid);
//---------------------------------------------------------------------------(1)




    //      .    .    .    .                        
    //    //.\\//.\\//.\\//.\\ CPLD FROM RX BRIDGE  
              /* input */   logic                     RX_B_tlp_read_write;          //
              /* input */   logic    [2:0]            RX_B_TC;               //
              /* input */   logic    [2:0]            RX_B_ATTR;             //
              /* input */   logic    [15:0]           RX_B_requester_id;        //
              /* input */   logic    [7:0]            RX_B_tag;              //
              /* input */   logic    [11:0]           RX_B_byte_count;       //

//--------------------------------------------------------------------------------------
              /* input */   logic    [6:0]            RX_B_lower_addr;       //
                            logic    [2:0]            RX_B_completion_status;
//----------------------------------------------------------------------------------------- 
//-----------------------------------------------------------------------------------------          
              /* input */   logic    [31:0]           RX_B_data1;                 //
              /* input */   logic    [31:0]           RX_B_data2;                 //
              /* input */   logic    [31:0]           RX_B_data3;                 //
//-----------------------------------------------------------------------------------------                   
              /* input */   logic                     RX_B_Wr_En;                  //
//-----------------------------------------------------------------------------------------


              /* output */   logic    [1:0]            X_tlp_mem_io_msg_cpl; //type // .tlp_mem_io_msg_cpl_conf(tlp_mem_io_msg_cpl_conf);
              /* output */   logic                     X_tlp_address_32_64;       //fmt[0]      //.tlp_address_32_64(tlp_address_32_64);
              /* output */   logic                     X_tlp_read_write;          //fmt[1]      // .tlp_read_write(tlp_read_write);
//-------------------------------------------------------------------------- (4)
              /* output */   logic    [2:0]            X_TC;                      //.TC(TC); 
              /* output */   logic    [2:0]            X_ATTR;                    //.ATTR(ATTR); 
//---------------------------------------------------------------------------(6)
              /* output */   logic    [15:0]           X_requester_id;            //[[X]]  -- //COMPLETER ID //.device_id(device_id);
              /* output */   logic    [7:0]            X_tag;                     //[[X]].tag(tag);
              /* output */   logic    [11:0]           X_byte_count;              //.byte_count(byte_count);
//---------------------------------------------------------------------------(36)           
              /* output */   logic    [6:0]            X_lower_addr;              //[[X]]       //.lower_addr(lower_addr);
                             logic    [2:0]            X_completion_status;
//---------------------------------------------------------------------------(7)
              /* output */   logic    [31:0]           X_data1;                 //.data1(data1);
              /* output */   logic    [31:0]           X_data2;                 //.data2(data2);
              /* output */   logic    [31:0]           X_data3;                 //.data3(data3) ;  

    //////////////////////////////////////////////////////////////////////////////////////////////
   /* input */   logic                             ACK;      ////////////////////////////////////
   /* output */  logic                             VALID;   ////////////////////////////////////
    //////////////////////////////////////////////////////////////////////////////////////////

DOUBLE_IN_CPL_ARB double_in_cpl_arb
(
    .clk(clk),
    .rst(rst),

    //    I'll use this block to generate CPL/ CPLD 
    //      .    .    .    .                        
    //    //.\\//.\\//.\\//.\\ CPL FROM ERROR BLOCK     
    
//-------------------------------------------------------------------------- (4)
           /* input   logic    [2:0]           */.ERR_CPL_TC(ERR_CPL_TC),                      //.TC(TC)(),
           /* input   logic    [2:0]           */.ERR_CPL_ATTR(ERR_CPL_ATTR),                    //.ATTR(ATTR)(),
//---------------------------------------------------------------------------(6)
           /* input   logic    [15:0]          */.ERR_CPL_requester_id(ERR_CPL_requester_id),            //[[X]]  -- //COMPLETER ID 
           /* input   logic    [7:0]           */.ERR_CPL_tag(ERR_CPL_tag),                     //[[X]].
           /* input   logic    [11:0]          */.ERR_CPL_byte_count(ERR_CPL_byte_count),              //
//---------------------------------------------------------------------------(36)           
           /* input   logic    [6:0]           */.ERR_CPL_lower_addr(ERR_CPL_lower_addr),              //[[X]]
//---------------------------------------------------------------------------(7)    
                                                 .ERR_CPL_completion_status(ERR_CPL_completion_status),
//---------------------------------------------------------------------------(96)
          /* input   logic                     */.ERR_CPL_Wr_En(ERR_CPL_Wr_En),                 //.valid(valid)(),
//---------------------------------------------------------------------------(1)




    //      .    .    .    .                        
    //    //.\\//.\\//.\\//.\\ CPLD FROM RX BRIDGE  
           /* input   logic                    */.RX_B_tlp_read_write(RX_B_tlp_read_write),          //
           /* input   logic    [2:0]           */.RX_B_TC(RX_B_TC),               //
           /* input   logic    [2:0]           */.RX_B_ATTR(RX_B_ATTR),             //
           /* input   logic    [15:0]          */.RX_B_requester_id(RX_B_requester_id),        //
           /* input   logic    [7:0]           */.RX_B_tag(RX_B_tag),              //
           /* input   logic    [11:0]          */.RX_B_byte_count(RX_B_byte_count),       //
//--------------------------------------------------------------------------------------
           /* input   logic    [6:0]           */.RX_B_lower_addr(RX_B_lower_addr),       //
                                                 .RX_B_completion_status(RX_B_completion_status),
//-----------------------------------------------------------------------------------------           
           /* input   logic    [31:0]          */.RX_B_data1(RX_B_data1),                 //
           /* input   logic    [31:0]          */.RX_B_data2(RX_B_data2),                 //
           /* input   logic    [31:0]          */.RX_B_data3(RX_B_data3),                 //
//-----------------------------------------------------------------------------------------                   
           /* input   logic                    */.RX_B_Wr_En(RX_B_Wr_En),                  //
//-----------------------------------------------------------------------------------------


           /* output   logic    [1:0]           */.X_tlp_mem_io_msg_cpl(X_tlp_mem_io_msg_cpl), //type // .tlp_mem_io_msg_cpl_conf(tlp_mem_io_msg_cpl_conf)(),
           /* output   logic                    */.X_tlp_address_32_64(X_tlp_address_32_64),       //fmt[0]      //.tlp_address_32_64(tlp_address_32_64)(),
           /* output   logic                    */.X_tlp_read_write(X_tlp_read_write),          //fmt[1]      // .tlp_read_write(tlp_read_write)(),
//-------------------------------------------------------------------------- (4)
           /* output   logic    [2:0]           */.X_TC(X_TC),                      //.TC(TC)(), 
           /* output   logic    [2:0]           */.X_ATTR(X_ATTR),                    //.ATTR(ATTR)(), 
//---------------------------------------------------------------------------(6)
           /* output   logic    [15:0]          */.X_requester_id(X_requester_id),            //[[X]]  -- //COMPLETER ID //.device_id(device_id)(),
           /* output   logic    [7:0]           */.X_tag(X_tag),                     //[[X]].tag(tag)(),
           /* output   logic    [11:0]          */.X_byte_count(X_byte_count),              //.byte_count(byte_count)(),
//---------------------------------------------------------------------------(36)           
           /* output   logic    [6:0]           */.X_lower_addr(X_lower_addr),              //[[X]]       //.lower_addr(lower_addr)(),
                                                  .X_completion_status(X_completion_status),
//---------------------------------------------------------------------------(7)
           /* output   logic    [31:0]          */.X_data1(X_data1),                 //.data1(data1)(),
           /* output   logic    [31:0]          */.X_data2(X_data2),                 //.data2(data2)(),
           /* output   logic    [31:0]          */.X_data3(X_data3),                 //.data3(data3),  

    /////////////////////////////////////////////////////////////////////////////////////////////
/* input   logic                            */.ACK(ACK),    ///////////////////////////////////////
/* output  logic                            */.VALID(VALID)   //////////////////////////////////////
    //////////////////////////////////////////////////////////////////////////////////////////
);


always #5 clk = ~clk;
assign ERR_CPL_tlp_mem_io_msg_cpl =2'b11;
assign ERR_CPL_TC = 0;
assign ERR_CPL_ATTR = 0;

assign RX_B_tlp_mem_io_msg_cpl =2'b11;
assign RX_B_TC = 0;
assign RX_B_ATTR = 0;
assign RX_B_tlp_read_write = 1;

task reset();
    rst <=0;
    ACK <=0;
    @(posedge clk)
    rst<= 1;
endtask

task add_rx_bridge_completion(int requester_id_, int tag_, int byte_count_, int lower_addr_, int completion_status_, int data1_, int data2_, int data3_, int Wr_En_);

    RX_B_requester_id <= requester_id_;
    RX_B_tag <= tag_;
    RX_B_byte_count <= byte_count_;
    RX_B_lower_addr <= lower_addr_;
    RX_B_completion_status <= completion_status_;

    RX_B_data1 <= data1_;
    RX_B_data2 <= data2_;
    RX_B_data3 <= data3_;

    RX_B_Wr_En <= Wr_En_;
    @(posedge clk);
    RX_B_Wr_En <= 0;
endtask

task add_err_completion(int requester_id_, int tag_, int byte_count_, int lower_addr_, int completion_status_, int data1_ = 0, int data2_ = 0, int data3_ = 0, int Wr_En_);
    ERR_CPL_requester_id <= requester_id_;
    ERR_CPL_tag <= tag_;
    ERR_CPL_byte_count <= byte_count_;
    ERR_CPL_lower_addr <= lower_addr_;
    ERR_CPL_completion_status <= completion_status_;

    ERR_CPL_completion_status <= completion_status_;

    ERR_CPL_Wr_En <= Wr_En_;  
    @(posedge clk);
    ERR_CPL_Wr_En <= 0;
endtask

task ACKNOWLEDGE;
ACK<=1;
@(posedge clk)
ACK<=0;
endtask
initial begin
reset();

add_rx_bridge_completion(.requester_id_(0), .tag_(1), .byte_count_(4), .lower_addr_(2),
 .completion_status_(0),
  .data1_(32'hDEAD_BEEF), .data2_(0), .data3_(0), .Wr_En_(1));

add_rx_bridge_completion(.requester_id_(0), .tag_(2), .byte_count_(4), .lower_addr_(2),
 .completion_status_(0),
  .data1_(32'hCAFE_CAFE), .data2_(0), .data3_(0), .Wr_En_(1));

add_err_completion(.requester_id_(2), .tag_(3), .byte_count_(4), .lower_addr_(2),
.completion_status_(0), .data1_(32'hCAFE_CAFE), .data2_(0), .data3_(0), .Wr_En_(1));
ACKNOWLEDGE;

add_err_completion(.requester_id_(2), .tag_(3), .byte_count_(4), .lower_addr_(2),
.completion_status_(0), .data1_(32'hCAFE_CAFE), .data2_(0), .data3_(0), .Wr_En_(1));
ACKNOWLEDGE;
ACKNOWLEDGE;

$stop;

end


endmodule