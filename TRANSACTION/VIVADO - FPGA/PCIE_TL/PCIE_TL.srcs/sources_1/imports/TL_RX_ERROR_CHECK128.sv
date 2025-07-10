
module TL_RX_ERROR_CHECK128 #(parameter DATA_WIDTH = 32)
(
    input   logic clk,                              
    input   logic rst,

///////////FROM DL///////////////////////
    input  logic   [127:0]      TLP,
    input  logic                new_tlp_ready, 
    input  logic                valid,

///////////P_NP_CPL BUFFER////////////////////

//Write (H||D), Read (H)

    input   logic                       FULL_POSTED_H,
    input   logic                       FULL_POSTED_D,

    input   logic                       FULL_NONPOSTED_H,
    input   logic                       FULL_NONPOSTED_D,

    input   logic                       FULL_CMPL_H,
    input   logic                       FULL_CMPL_D,

    input   logic                       TLP_BUFFER_EMPTY,

    output  logic                       HEADER_DATA, // 0: Header; 1: Data
    output  logic [1:0]                 P_NP_CPL, // Posted: 00; Non-Posted: 01; Completion: 11
    // output  logic [DATA_WIDTH-1:0]      IN_TLP_DW,

    output  logic                       WR_EN,

    output  logic                       flush,
    output  logic                       commit,
    // output  logic                       TLP_BUFFER_RD_EN, //Not Busy
    
    ////////////////////////////////////
    
    // output  logic                       DATA_BUFFER_WR_EN,          
    
    ////////////////////////////////////

    output  logic                       TX_NP_REQ_BUFF_RD_EN,
    output  logic                       TX_NP_REQ_BUFF_TAG,  //(CPL TAG)
    input   logic                       EXIST, //<THERE IS REQUEST WITH THE SAME TAG?>


    output  logic                       RX_NP_REG_BUFF_RD_EN,
    output  logic                       RX_NP_REQ_BUFF_TAG, //(REQ TAG) 
    input   logic                       RX_NP_REQ_BUFF_STATUS, //(REQ TAG) 

// ---------------------------------------------------------------------------
// -----------------------------CPL TIMEOUT----------------------------------
// ---------------------------------------------------------------------------


    output    logic                     NP_RDEN,     
    output    logic  [7:0]              NP_TAG_IDX,  
    output    logic  [15:0]             NP_DEST_IDX, 
    input     logic                     NP_REQ_EXIST     



);
// ====================================================


    /* output */  logic  [2:0]     tlp_mem_io_msg_cpl_conf;
    /* output */  logic            tlp_address_32_64;
    /* output */  logic            tlp_read_write;
    //output  logic                tlp_conf_type;

    /* output */  logic  [11:0]    cpl_byte_count;
    /* output */  logic  [6:0]     cpl_lower_address;
                  logic  [7:0]     cpl_tag;
                  logic  [15:0]    cpl_requester_id;

    /* output */  logic  [3:0]     first_dw_be;
    /* output */  logic  [3:0]     last_dw_be;

    /* output */  logic  [31:0]    lower_addr;
    /* output */  logic  [31:0]    upper_addr;

    /* output */  logic  [31:0]    data;
    /* output */  logic  [11:0]    config_dw_number;

                  logic            cpl_exist;




// ====================================================
// typedef enum reg [3:0] {IDLE=0, START, H0, H1_REQ, H_ADDR32, H_ADDR64, H_ID,  H1_CPL, H2_CPL, H1_MSG, DATA, FINISH} State;
typedef enum reg [3:0] {IDLE=0, HEADER, DATA, FINISH} State;

State current;

reg [9:0] length;


//H0
wire  [2:0] fmt_;
wire  [4:0] type_;

wire  [2:0] TC_;
wire  [2:0] attr_;
wire        TH_;
wire        TD_;
wire        EP_;
wire        AT_;
wire  [9:0] length_;



//H1_REQ
wire  [15:0]    requester_id_;
wire  [7:0]     tag_;
wire  [3:0]     last_dw_be_;
wire  [3:0]     first_dw_be_;

//MEM, IO
wire  [31:0]    lower_addr_;
wire  [31:0]    upper_addr_;

//CONF
wire  [15:0]    BDF_;
wire  [11:0]    config_dw_number_;


//CPL1
wire  [15:0]    cpl_completer_id_;
wire  [2:0]     cpl_status_;
wire            cpl_bcm_;
wire  [11:0]    cpl_byte_count_;

//CPL2
wire  [15:0]    cpl_requester_id_;
wire  [7:0]     cpl_tag_;
wire  [6:0]     cpl_lower_address_;


//MSG
wire  [15:0]    message_request_id_;
wire  [7:0]     message_tag_;
wire  [7:0]     message_code_;      


//DATA
wire [31:0]     data_;
//-----------------
assign fmt_         = TLP[127:125] /* [31:29] */;//
assign type_        = TLP[124: 120] /* [28:24] */;//
//R[23]
assign TC_          = TLP[118:116];// /* [22:20] */
//R[19]
assign attr_[2]     = TLP[114];//[18];//[114]
//R[17]
assign TH_          = TLP[112];//[16]; //[112]
assign TD_          = TLP[111];//[15];//[111]
assign EP_          = TLP[110];//[14];//[110]
assign attr_[1:0]   = TLP[109:108];//[13:12];//[109::108]
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
assign BDF_ = TLP[63:48];//[31:16];//[63:48]
// R[15:12]
assign config_dw_number_ = TLP[43:32];//{TLP[11:0]};//[43:32] //Check last 2 bits are 00

//CPL1
assign cpl_completer_id_    = TLP[95:80];//[31:16]; //[63:48]
assign cpl_status_          = TLP[79:77];//[15:13]; //[47:45]
assign cpl_bcm_             = TLP[76];//[12];//[44]
assign cpl_byte_count_      = TLP[75:64];//[11:0];//[43:32]

//CPL2
assign cpl_requester_id_    = TLP[63:48];//[31:16];//[31:16]
assign cpl_tag_             = TLP[47:40];//[15:8]; //[15:8]
assign cpl_lower_address_   = TLP[38:32];// [6:0]
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

//Completion For What??


//Counter the TLP and check it has the same length as it should
// If Write (fmt[1]=1) we must check data count also if Read(fmt[1]=0) we must not check data 

// Link Flow Control Related Errors
/*
    Prior to forwarding the packet to the Data Link Layer for transmission, the
    Transaction Layer must check Flow Control (FC) credits to ensure that the
    receive buffers of the Link neighbor have sufficient room to hold it. Flow Con
    trol violations may occur, and they are considered uncorrectable. Protocol viola
    tions related to Flow Control can detected by and associated with the port
    receiving the Flow Control information. Some examples are given here:
        
        • Link partner fails to advertise at least the minimum number of FC credits
        defined by the spec during FC initialization for any Virtual Channel.
        
        • Link partner advertises more than the allowed maximum number of FC
        credits (up to 2047 unused credits for data payload and 127 unused credits
        for headers).
        
        • Receipt of FC updates containing non‐zero values in credit fields that were
        initially advertised as infinite.
        
        • A receive buffer overflow, resulting in lost data. This check is optional but a
        detected violation is considered to be a Fatal error.
*/

// 7-  Traffic Class field contains a value not assigned to an enabled Virtual Channel (this is also known as TC Filtering).
// 10- Undefined Type field values. [...]

// MALFORMED
/*
15- Data Payload exceeds Max Payload Size [X]
14- Data Length doesn't match length specified [X]
13- Memory Start Address and Length Combine to cause a transaction to cross a naturally-aligned 4 KB boundary []
12- TLP Digest (TD field) indication doesn’t correspond with packet size (ECRC is unexpectedly missing or present).  []
11- Byte Enable violation. [...]
10- Undefined Type field values. [...]
9-  Completion that violates the Read Completion Boundary (RCB) value. [...]
8-  Completion with status of Configuration Request Retry Status in response to a Request other than a configuration Request. [..]

7-  Traffic Class field contains a value not assigned to an enabled Virtual Channel (this is also known as TC Filtering).

6- I/O and Configuration Request violations (checking optional) ‐ examples:
TC field, Attr[1:0], and the AT field must all be zero, while the Length field
 must have a value of one.

5- Interrupt emulation messages sent downstream (checking optional).

4- TLP received with a TLP Prefix error:
 — TLP Prefix but no TLP Header
 — End‐to‐End TLP Prefixes preceding Local Prefixes
 — Local TLP Prefix type not supported
 —More than 4 End‐to‐End TLP Prefixes
 —More End‐to‐End TLP Prefixes than are supported

3-  Transaction type requiring use of TC0 has a different TC value:
 — I/O Read or Write Requests and corresponding Completions
 — Configuration Read or Write Requests and corresponding Completions
 — Error Messages
 — INTx messages
 — Power Management messages
 — Unlock messages
 — Slot Power messages
 — LTR messages
 — OBFF messages

2- AtomicOp operand doesn’t match an architected value
1- AtomicOp address isn’t naturally aligned with operand size.
0- Routing is incorrect for transaction type (e.g., transactions requiring routing
    to Root Complex detected moving away from Root Complex).

*/  


// Unsupported Request (UR) Status
/*
9- Request type not supported (example: IO Request to native Endpoint or
 MRdLk to native Endpoint)

8- Message with unsupported or undefined message code

7- Request does not reference address space mapped to the device

6- Request address isn’t mapped within a Switch Port’s address range

5-  Poisoned write Request (EP=1) targets an I/O or Memory‐mapped control
    space in the Completer. Such Requests must not be allowed to modify the
    location and are instead discarded by the Completer and reported with a
    Completion having a UR status.

4-  A downstream Root or Switch Port receives a configuration Request targeting
    a device on its Secondary Bus that doesn’t exist (e.g. a device with a
    non‐zero device number, unless ARI is enabled). The Port must terminate
    the Request and return a Completion with UR status because the down
    stream Device number is required to be zero (unless ARI, Alternative Routing‐ID
    Interpretation, is enabled).


3-  Type 1 configuration Request is received at an Endpoint.

2-  Completion using a reserved Completion Status field encoding must be interpreted as UR.   

1-  A function in the D1, D2, or D3hot power management state receives a Request other than a configuration Request or Message.

0-  A TLP without the No Snoop bit set in its header is routed to a port that has the Reject Snoop
    Transactions bit set in its VC Resource Capability register.
*/


//  Completer Abort (CA) Status
/*

3- Completer receives a Request that it cannot complete without violating its
    programming rules. For example, some Functions may be designed to only
    allow accesses to some registers in a complete and aligned manner (e.g. a 4
    byte register may require a 4‐byte aligned access). Any attempt to access
    one of these registers in a partial or misaligned fashion (e.g. reading only
    two bytes of a 4‐byte register) would fail. Such restrictions are not violations
    of the spec, but rather legal constraints associated with the programming
    interface for this Function. Access to such a Function is based on the expec
    tation that the device driver understands how to access its Function.

2-  Completer receives a Request that it cannot process because of some permanent
    error condition in the device. For example, a wireless LAN card that
    won’t accept new packets because it can’t transmit or receive over its radio
    until an approved antenna is attached.

1-  Completer receives a Request for which it detects an ACS (Access Control
    Services) error. An example of this would be a Root Port that implements
    the ACS registers and has ACS Translation Blocking enabled. If a memory
    Request is seen on that Port with anything other than the default value in
    the AT field, it will be an ACS violation.

0-  PCIe‐to‐PCI Bridge may receive a Request that targets the PCI bus. PCI
    allows the target device to signal a target abort if it can’t complete the
    Request due to some permanent condition or violation of the Function’s
    programming rules. In response, the bridge would return a Completion
    with CA status.

// A Completer that aborts a Request may report the error to the Root with a Non fatal Error Message and,
    if the Request requires a Completion, the status would be CA.
*/


// Unexpected Completion
/*

    When a Requester receives a Completion, it uses the transaction descriptor
    (Requester ID and Tag) to match it with an earlier Request. In rare circumstances,
    the transaction descriptor may not match any previous Request. This
    might happen because the Completion was mis‐routed on its journey back to
    the intended Requester. An Advisory Non‐fatal Error Message can be sent by
    the device that receives the unexpected Completion, but it’s expected that the
    correct Requester will eventually timeout and take the appropriate action, so
    that error Message would be a low priority. 

    ** <Completion>? @H2_CPL I check whether this tag exists or no**
    case(current)
    .
    .
    .
    current <= H2_CPL
    tag<= TLP...
    tag is connected to the buffer 
    
    now current == H2_CPL
    current <= DATA, FINISH


*/

// Completion Timeout
/*

    For the case of a pending Request that never receives the Completion it’s expect
    ing, the spec defines a Completion timeout mechanism. The spec clearly intends
    this to detect when a Completion has no reasonable chance of returning; it
    should be longer than any normal expected latencies.
    The Completion timeout timer must be implemented by all devices that initiate
    Requests that expect Completions, except for devices that only initiate configu
    ration transactions. Note also that every Request waiting for Completions is
    timed independently, and so there must be a way to track time for each out
    standing transaction. The 1.x and 2.0 versions of the spec defined the permissi
    ble range of the timeout value as follows:
        • It is strongly recommended that a device not timeout earlier than 10ms after
        sending a Request; however, if the device requires greater granularity a timeout
        can occur as early as 50μs.

        • Devices must time‐out no later than 50ms.
        
        
        Beginning with the 2.1 spec revision, the Device Control Register 2 was added
        to the PCI Express Capability Block to allow software visibility and control of
        the timeout values, as shown in Figure 15‐8 on page 665.

*/

// 
//reg [2:0] counter;

//reg                   ECRC_FAILURE;
//reg                   ATOMIC_EGRESS_BLOCKED;
//reg                   TLP_PREFIX_BLOCKED;
//reg                   ACS_VIOLATION; //(Access Control Services)
//reg                   MC_BLOCKED; //(Mutli-cast)

  ////////  x   ////////
 /// BUFFER SIGNALS ///
////////   x   ///////

reg [1:0] P_NP_CPL_REG;
reg  HEADER_DATA_REG;

  ///////////////////////////////////////////////////////////////////////////////
 ///////////////////////// ERROR FLAGS ////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////
reg [15:0]      MALFORMED_TLP;
reg [9:0]       UNSUPPORTED_REQUEST; reg [3:0]   COMPLETER_ABORT;


reg             RX_BUFF_OV;
reg             FC_ERROR;
reg             UNEXPECTED_COMPLETION;
reg             POISONED_TLP;
//reg           COMPLETION_TIMEOUT;

reg             ERROR;

  ////////////////////////////////////////////////////////////////////////
 //////////////////////// ERROR DETECTION ///////////////////////////////
////////////////////////////////////////////////////////////////////////

reg [9:0]   dw_counter; //<<<<<<<<<<<<<<<<<<
reg [9:0]   data_counter; //<<<<<<<<<<<<<<<


reg [9:0]   number_of_dws_;
reg         tlp_end;
reg         data_phase;

reg [9:0]   calc_tlp_dw_count; //
reg [10:0]  exp;



  ////////////////////////////////////////////////////////////////////////
 //////////////////////// ERROR REPORT //////////////////////////////////
////////////////////////////////////////////////////////////////////////



always@(*) begin
    case(fmt_[0])//Addr64 / 32
    0: number_of_dws_ = 3;
    1: number_of_dws_ = 4;
    endcase
end


always@(*) begin

        P_NP_CPL = 0;
        HEADER_DATA = 0;
        WR_EN = 0;

        flush = 0;
        commit = 0; 

        NP_DEST_IDX = 0;
        NP_TAG_IDX = 0;
        NP_RDEN = 0;

        if((new_tlp_ready&&valid)) begin // ITS H0 (IT can be from IDLE or from previous packet)
            case({fmt_[1],type_[4:3],type_[1]})//fmt[1] write
                4'b1_00_0, 4'b1_10_0, 4'b1_10_1: //Posted
                begin
                    P_NP_CPL = 2'b00;
                end
                4'b0_00_1, 4'b1_00_1, 4'b0_00_0: //Non Posted
                begin
                    P_NP_CPL = 2'b01;    
                end
                4'b0_01_1, 4'b1_01_1: //Completion
                begin
                    P_NP_CPL = 2'b11;
                end
            endcase


            case(type_[4:3])
                REQ: begin
                    
                end
                CPL: begin
                    NP_DEST_IDX = cpl_requester_id_;
                    NP_TAG_IDX =  cpl_tag_;
                end
                MSG: begin
                    
                end
            endcase
            HEADER_DATA = 0;
            WR_EN = 1;

            if(current!=IDLE) 
            begin
                if(dw_counter == calc_tlp_dw_count) 
                begin //
                    commit = 1;
                    flush  = 0;
                end
                else 
                begin
                    commit = 0;
                    flush  = 1;
                end
            end
        end
        else if(((current!=IDLE)&&(!valid))/* ||tlp_end */) begin 
            WR_EN = 0;
            HEADER_DATA =0;
            if(dw_counter == calc_tlp_dw_count) begin
                commit = 1;
                flush  = 0;
            end
            else begin
                commit = 0;
                flush  = 1;
            end
        end
        else begin //if(((current!=IDLE)&&(valid))

        P_NP_CPL = P_NP_CPL_REG;
        
        
        
        // HEADER_DATA = data_phase;
        case(current)
            HEADER: begin
                case(tlp_mem_io_msg_cpl_conf)
                3: begin
                    NP_DEST_IDX = cpl_requester_id;
                    NP_TAG_IDX  = cpl_tag;
                    NP_RDEN = 1;
                end
                endcase
                WR_EN = 1;
                if(tlp_read_write)
                    begin
                        HEADER_DATA = 1;
                    end
                    else
                    begin 
                        HEADER_DATA = 0;
                        WR_EN = 0;
                    end
            end
            DATA: begin
                HEADER_DATA = 1;
                if(data_counter==length)
                begin 
                    HEADER_DATA = 0;
                    WR_EN = 0;
                end
                else begin
                    WR_EN = 1;
                end
            end
            default: begin
                // WR_EN = 1;
            end
        endcase
        // case(current)

        // endcase
        end  
end

// always@(*) begin
//     UNEXPECTED_COMPLETION = !cpl_exist;
//     ERROR = |MALFORMED_TLP || |FC_ERROR || |POISONED_TLP || |UNSUPPORTED_REQUEST || |COMPLETER_ABORT;
// end

// 7-  Traffic Class field contains a value not assigned to an enabled Virtual Channel (this is also known as TC Filtering).
// 10- Undefined Type field values. [...]
// always@(posedge clk or negedge rst) begin
//     if(!rst) begin
//          MALFORMED_TLP<=0;
//     end
//     else begin
//         if(new_tlp_ready&&valid) 
//         begin // GO TO H0
//                 case(type_[4:3])
//                 REQ: 
//                 begin
//                 case(type_[2:1])
//                     MEM:begin
//              
//                     end 
//                     IO:
//                     begin
//                      MALFORMED[7] <= (TC_ != 0) 
//                     end 
//                     CONF:
//                     begin
//                      MALFORMED[7] <= (TC_ != 0)
//                     end
//    
//                 endcase 
//                 end
//                 CPL: begin
//                  
//                 end
//                 MSG: begin
//                  
//                 end
//            default: begin
//              MALFORMED_TLP[10] <= 1;
//            end
//
//             endcase
//         end
//         else if((current != IDLE && !valid) /*||tlp_end*/) 
//         begin //FROM END <TO IDLE . >        
        //    MALFORMED_TLP<=0;
//         end
//         else
//         begin
           
//         end
//     end

// end

always@(posedge clk or negedge rst)
begin
    if(!rst)
    begin
        current <= IDLE;
        ///////////////////////////////////////////////////////


        RX_BUFF_OV<=0;
        FC_ERROR<=0;
       
        UNSUPPORTED_REQUEST<=0;
        COMPLETER_ABORT<=0;
        
        POISONED_TLP<=0;


        /////////////////////////////////////////////////////
        //****************************************************
        dw_counter <= 0;
        calc_tlp_dw_count <= 0;

        P_NP_CPL_REG <= 0;
        // HEADER_DATA_REG <= 0;

        //****************************************************
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
        cpl_tag <= 0;
        cpl_requester_id <= 0;

        //DATA
        data_counter <= 0;
        data <= 0;
        cpl_exist<=0;

    end
    else
    begin
        
        if(new_tlp_ready&&valid) 
        begin // GO TO H0
            cpl_exist<=0;

            case(fmt_[0])
                0: tlp_address_32_64 <= 0;
                1: tlp_address_32_64 <= 1;
            endcase
            case(fmt_[1])
                0: tlp_read_write <= 0;
                1: tlp_read_write <= 1;
            endcase
            case(type_[4:3])
                REQ: 
                begin
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
                    cpl_tag <= cpl_tag_;
                    cpl_requester_id <= cpl_requester_id_;
                end
                MSG: begin
                    tlp_mem_io_msg_cpl_conf<= 2;
                end
            endcase

            case({fmt_[1],type_[4:3],type_[1]})//fmt[1] write
                4'b1_00_0, 4'b1_10_0, 4'b1_10_1: //Posted
                begin
                    P_NP_CPL_REG <= 2'b00;
                end
                4'b0_00_1, 4'b1_00_1, 4'b0_00_0: //Non Posted
                begin
                    P_NP_CPL_REG <= 2'b01;    
                end
                4'b0_01_1, 4'b1_01_1: //Completion
                begin
                    P_NP_CPL_REG <= 2'b11;
                end
            endcase
            

            length <= length_;
            
            case(fmt_[1])
                0: //READ
                begin
                    //Header (3-4DW I'll call it a row) Data (1 .. 1024DWs)
                    calc_tlp_dw_count <= 1; ///* length_ +  */((number_of_dws_ - 1)>>2)+1;
                end
                1:
                begin
                    // calc_tlp_dw_count <= ((length_ + number_of_dws_ - 1)>>2)+1;
                    calc_tlp_dw_count <= 1 + ((length_ - 1)>>2)+1;
                    // current <= H1_REQ;
                end
            endcase

            case(type_[4:3])
                REQ: begin
                    first_dw_be <= first_dw_be_;
                    last_dw_be  <= last_dw_be_;
                    // current<=H1_REQ;
                    case(tlp_mem_io_msg_cpl_conf)
                        0,1: begin
                            case(tlp_address_32_64)
                            0: 
                            begin
                                lower_addr <= upper_addr_;
                            end
                            1: 
                            begin
                                upper_addr <= upper_addr_;
                                lower_addr<=lower_addr_;         
                            end
                            endcase
                        end
                        4: 
                        begin
                            config_dw_number <= config_dw_number_;                         
                        end
                    endcase
                end
                CPL: 
                begin
                    cpl_byte_count <= cpl_byte_count_ ;
                    cpl_lower_address <= cpl_lower_address_;
                end
            endcase

            dw_counter <= 1;
            data_counter <= 0; //Is that inmportant? yes ,what about in IDLE status

            current <= HEADER;
        end
        else if((current != IDLE && !valid) /*||tlp_end*/) 
        begin //FROM END <TO IDLE . >        
            // flush <= 0;
            // commit <= 0;
            cpl_exist         <= 0;
            dw_counter        <= 0;
            data_counter      <= 0;
            calc_tlp_dw_count <= 0;
            //It's either @ tlp end or @!valid in non idle state
            current <= IDLE; //only gate to IDLE
        end
        else
        begin
            dw_counter <= dw_counter + 1;
            case(current)
                IDLE: begin
                    dw_counter <= 0;
                end
                HEADER: begin

                    cpl_exist <= NP_REQ_EXIST || (tlp_mem_io_msg_cpl_conf!=3);

                    if(tlp_read_write)
                    begin
                        current      <= DATA;
                        data_counter <= 1;
                    end
                    else
                    begin 
                        // cpl_exist <= 0;
                    end
                end
                DATA: begin
                    if(data_counter==length)
                    begin 
                        // cpl_exist <= 0;
                        // ******************************** ******************** ************************ *************************    
                    end
                    else
                    begin
                        // dw_counter <= dw_counter + 1;
                        // data <= data_;
                        data_counter <= data_counter + 1;
                    end
                end
            endcase
        end
    end
end
  
always@(*) begin
    tlp_end = 0;
    data_phase = 0;
    case(current)
     HEADER: begin
            //XXX
            if(tlp_read_write)
            begin
                data_phase = 1;
            end
            else
            begin
                 // ******************************** ******************** ************************ *************************
                tlp_end = 1;
            end

        end
        
        DATA: begin
            if(data_counter == length)
            begin 
                // ******************************** ******************** ************************ *************************
                tlp_end =1;
                data_phase = 0;
            end
            else
            begin
                data_phase = 1;
            end
        end
    endcase
end
endmodule
