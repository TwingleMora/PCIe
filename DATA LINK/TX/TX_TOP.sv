module TX_TOP  #(
    parameter ENTRY_WIDTH = 310,
              BUFF_DEPTH = 256,
              SEQ_NUM_WIDTH = 12,
              TLP_MUX_IN_WIDTH = 128,
              LCRC_WIDTH = 32,
              MAX_ADDR_SIZE = 12
)
(

  input wire      clk , rst ,
  input wire      link_training ,
  //input will come form other blocks in future integration ..but let's make them global for now
  input wire [SEQ_NUM_WIDTH-1:0]   ack_nak_seq_num,
  //input wire [SEQ_NUM_WIDTH-1:0]   nak_seq_num,

  input wire                       tlp_coming ,
  input wire                       tlp_end ,

  input wire                       ack_forward_progress ,
  input wire                       nak_forward_progress ,

  input wire [TLP_MUX_IN_WIDTH-1:0] incoming_tlp_data,

  input  wire  [5:0]                TLP_LEN,
  input  wire                       DL_Down , 

  
 //-----------------------ins coming from the DLCMSM-----------------------------------------------
 input    wire          gen_ack,
 input    wire          gen_nak,
 input    wire          gen_pm, 
 input    wire          RUN_TIME_ON,
 input    wire          pm_enter_l1,
 input    wire          pm_enter_l23,
 input    wire          pm_active_state_req,
 input    wire          pm_request_ack,
 input    wire          start_fc_init1_pkts,
 input    wire          start_fc_init2_pkts , 
 input    wire          transmit_update_dllp , 


 //------------------------ins coming from the transaction layer
input wire [9:0] PH_credits,  
input wire [9:0] NPH_credits,
input wire [9:0] CH_credits,
input wire [9:0] PD_credits,
input wire [9:0] NPD_credits,
input wire [9:0] CD_credits, 

//output signals will go to other blocks in future integration within TX ...but let's make them global for now
output wire replay_buffer_full,
output wire replay_buffer_empty,
output wire replay_buffer_purge,
output wire mem_almost_full_status,
output wire mem_almost_empty_status,
output wire mem_overflow_status,
output wire mem_underflow_status,

output wire  [127:0]      tx_out ,
output wire             tx_out_valid, 
output wire             tx_type, // 1 --->  if tlp and 0 ---> if dllp 
output wire             tx_out_end,
output  wire    [5:0]   tx_out_len, 

output  wire   [1:0]    replay_num , //to CtrlFsm
output  wire            retrain_link, //to CtrlFsm,
output  wire            busy     //to transaction 

  
);

//------------------signals between the rep_buffer and tlp_mux------------------
//from tlp_mux to rep_buffer 
wire  [TLP_MUX_IN_WIDTH-1:0] TLP_MUX_O ;
wire                         tlp_mux_valid ;   // a valid signal from tlp_mux for lcrc and rep_buffer and arbiter  
wire                         tlp_mux_end ; // tlp_mux --> arbiter
wire  [5:0]                  TLP_MUX_LEN ; 


wire                      CAPTURE_TLP ;

//from rep_buffer to tlp_mux

wire [1:0] MUX_SEL ;
wire      TLP_MUX_START ;

//-------------------------------------------------------------------------------

//------------------signals between rep_buffer and lcrc generator and tlp_mux -----------------
//from lcrc to rep_buffer
wire                     LCRC_VALID;
wire    [LCRC_WIDTH-1:0]       LCRC_O;

//from  rep_buffer to lcrc generator 
wire      LCRC_START ;  
wire  [1:0] LCRC_CTRL ;

wire          skip_256; 
wire   [5:0] RB_BUFF_LEN ;
// signals to arbiter 
wire [127:0]          mem_output_data;  // rb --> arbiter
wire                   rb_tlp_valid ; // rb --> arbiter 
wire                   TLP_END_RB ; // rb --> arbiter          
//------------------------------------

wire [SEQ_NUM_WIDTH-1:0] NTS ; //next sequence number 

wire       NTS_INC ;





wire [8:0] unacknowledged_tlp_count;  //from rb_buffer --> rep_timer
wire        TIME_OUT;                  //rep_timer --> rb_buffer & RP_NUM


//---------------signals out from the dllp creator  and crc -----
wire   [31:0]       dllp_creator_out;
wire                dllp_creator_vld;   
wire   [15:0]       CRC_O ;



    
    REP_BUFFER_TOP #(
        .entry_width(ENTRY_WIDTH),
        .buff_depth(BUFF_DEPTH),
        .seq_num_width(SEQ_NUM_WIDTH),
        .tlp_mux_in_width(TLP_MUX_IN_WIDTH),
        .lcrc_width(LCRC_WIDTH),
        .max_addr_size(MAX_ADDR_SIZE)
    ) u_replay_buffer (
        // Clock and reset
        .clk(clk),
        .rst(rst),
        // Input signals
        .time_out(TIME_OUT),
        .ack_nak_seq_num(ack_nak_seq_num),
        //.nak_seq_num(nak_seq_num),
        .tlp_mux_out(TLP_MUX_O),
        .tlp_mux_valid(tlp_mux_valid),
        .ack_forward_progress(ack_forward_progress),
        .nak_forward_progress(nak_forward_progress),
        .tlp_coming(tlp_coming),
        .tlp_end(tlp_end),
        .lcrc_valid(LCRC_VALID), 
        .TLP_MUX_LEN(TLP_MUX_LEN) ,
        
        // Memory status outputs
        .mem_full(replay_buffer_full),
        .mem_empty(replay_buffer_empty),
        .purge_tlps(replay_buffer_purge),
        .unack_tlp_count(unacknowledged_tlp_count),
        .mem_almost_full(mem_almost_full_status),
        .mem_almost_empty(mem_almost_empty_status),
        .mem_overflow(mem_overflow_status),
        .mem_underflow(mem_underflow_status),
        .mem_data_out(mem_output_data),

        // Control outputs
        .mux_sel(MUX_SEL),
        .tlp_mux_start(TLP_MUX_START),
        .lcrc_start(LCRC_START),
        .lcrc_ctrl(LCRC_CTRL),
        .NTS_icr(NTS_INC),
        .skip_256(skip_256),
        .rb_tlp_valid(rb_tlp_valid),
        .busy(busy) ,
        .O_LEN(RB_BUFF_LEN),
        .TLP_END_RB(TLP_END_RB)  

    );



 TLP_MUX u_tlp_mux (
        // Clock and reset
        .clk(clk),
        .rst(rst),
        
        // Input data
        .TLP_IN(incoming_tlp_data), 
        .TLP_LEN(TLP_LEN),
        // Control signals
        .mux_start(TLP_MUX_START),
        .seq_num_in(NTS),
        .lcrc(LCRC_O),
        .mux_sel(MUX_SEL),
        .tlp_mux_valid(tlp_mux_valid),
        .tlp_mux_end(tlp_mux_end),
        .mux_out(TLP_MUX_O),
        .TLP_MUX_LEN(TLP_MUX_LEN)
    );


    lcrc32_bit u_lcrc_generator (
        // Clock and reset
        .clk(clk),
        .rst(rst),
        
        // Control signals
        .tlp_end(tlp_end),
        .ctrl(LCRC_CTRL),
        .start(LCRC_START),
        .skip_256(skip_256),
        
        // Data input
        .data_in(TLP_MUX_O),  // 128-bit input
        
        // Outputs
        .lcrc_out(LCRC_O),
        .lcrc_valid(LCRC_VALID)
    );

       next_sequence_number #(.seq_num_size(SEQ_NUM_WIDTH)) u_next_seq_num (
        .clk(clk),
        .rst(rst),
        .NTS_inc(NTS_INC),       
        .DL_Down(DL_Down),              
        .next_seq_num(NTS)             
      
    );

TX_ARBITER u_arbiter (
    .clk (clk), 
    .rst (rst), 

    //.request        (), 

    .rb_buff_o    (mem_output_data), 
    .rb_tlp_valid (rb_tlp_valid), 
    .TLP_END_RB   (TLP_END_RB),
    .RB_BUFF_LEN (RB_BUFF_LEN) ,

    .tlp_mux_out  (TLP_MUX_O), 
    .tlp_mux_valid(tlp_mux_valid), 
    .tlp_mux_end  (tlp_mux_end), 
    .TLP_MUX_LEN  (RB_BUFF_LEN), 

    .dllp_crtr_o   (dllp_creator_out), 
    .crc_o   (CRC_O), 
    .dllp_valid  (dllp_creator_vld), 
    .tx_out (tx_out),  
    //.arbit_busy(1'b0),
    .tx_out_valid(tx_out_valid), 
    .tx_type     (tx_type),
    .tx_out_len(tx_out_len) ,
    .tx_out_end(tx_out_end)
);

rep_timer u_rep_timer 
(
.clk(clk),
.rst(rst),
.DL_Down(DL_Down),
.ack_forward_progress(ack_forward_progress),
.unack_tlp_count(unacknowledged_tlp_count),
.nak_forward_progress(nak_forward_progress),
.link_train(link_training),
//.tlp_transmitted(),
.time_out(TIME_OUT)

);

REP_NUM u_rep_num 
(
.clk(clk),
.rst(rst),
.DL_Down(DL_Down),
.nak_forward_progress(nak_forward_progress),
.replay_timeout(TIME_OUT),
.ack_forward_progress(ack_forward_progress),
.replay_num(replay_num),
.retrain_link(retrain_link)
); 



dllp_creator  u_dllp_creator
(
.clk(clk),
.rst(rst),
.seq_num(ack_nak_seq_num),
.gen_ack(gen_ack),
.gen_nak(gen_nak),
.gen_pm(gen_pm),
.transmit_update_dllp(transmit_update_dllp),
.pm_enter_l1(pm_enter_l1),
.pm_enter_l23(pm_enter_l23),
.pm_active_state_req(pm_active_state_req),
.pm_request_ack(pm_request_ack),
.PH_credits(PH_credits),
.NPH_credits(NPH_credits),
.CH_credits(CH_credits),
.PD_credits(PD_credits),
.NPD_credits(NPD_credits),
.CD_credits(CD_credits),
.start_fc_init1_pkts(start_fc_init1_pkts),
.start_fc_init2_pkts(start_fc_init2_pkts),
.RUN_TIME_ON(RUN_TIME_ON),

//--outputs-----
.dllp_out(dllp_creator_out),    
.dllp_valid_out(dllp_creator_vld)         
    
);
 

 crc16_32bit  u_crc 
 (
.crc_en(dllp_creator_vld),
.data_in(dllp_creator_out),
.crc_out(CRC_O)

 );

endmodule 