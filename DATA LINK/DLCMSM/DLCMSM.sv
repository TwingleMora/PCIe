 module DLCMSM 
(


  input logic              clk ,rst ,
 // input      // Sequence number that is carried on the ack or nak  ;

  input logic              PHY_UP ,    //  

//----- inputs from the RX---------------------- 
  input logic             CRC_CHK_vld_dllp ,
  input logic   [63:0]    DLLP_Dmux_o,
  input logic             Dmux_vld_dllp, 
  input logic             ack_nak_time_out ,  
  input logic             NAK_SCHEDULED ,
  input logic   [11:0]    req_seq_num ,  //to start an ack or a nak
//-----------------------------------------------
  input logic             exit_fc_init1,//from  FC in Transaction 
  input logic              credits_vld,

  output logic             DL_Down ,  
  output logic             init_flag ,
  output logic             start_fc_init2_pkts ,
  output logic             start_fc_init1_pkts ,
  output logic             RUN_TIME_ON ,
   
   
//-------------------outputs to FC --------------------------------
  output   logic  [7:0]   PH_credits_limit ,
  output   logic  [7:0]   NPH_credit_limit ,
  output   logic  [7:0]   CH_credits_limit ,
  output   logic  [11:0]  PD_credits_limit ,
  output   logic  [11:0]  NPD_credit_limit ,
  output   logic  [11:0]  CD_credits_limit ,
//-------------------outputs to dllp_creator --------------------------------
  output   logic  [11:0] pending_seq_num  , //to start an ack or a nak 
  output   logic         initiate_ack , 
  output   logic         initiate_nak,  
  output   logic         transmit_update_dllp, 
//-------------------  outputs to replay buffer and other TX blocks  --------------------------------
  output   logic         ack_forward_progress ,
  output   logic         nak_forward_progress , 
  output   logic [11:0]  ack_nak_seq_num 
);


typedef enum {
 DL_Inactive ,
 Init_FC1 ,
 Init_FC2,
 DL_Active  , 
 power_management ,
 error_state 
}state_L ;

state_L  dl_curr_state , dl_next_state ;

logic  [5:0] update_timer;
logic  [5:0] update_timer_nxt;

logic  [11:0] ack_nak_seq_num_reg ; 
logic  [11:0] notify_seq_num;
logic  [11:0] notify_seq_num_reg;
logic  [11:0] last_notify_seq_num ;// Last acknowledged sequence number  
logic  [11:0] ack_seq_num;
logic  [11:0] nak_seq_num;

logic [3:0] FC_INIT2_Received_TYPE ;
logic Fl2 ;//exit_fc_init2 //coming from the RX "after decoding the incoming dllps first 4 bits page224" 

logic   ack_received ;
logic   nak_received ; 

logic    exit_fc_init2 ;



always @(posedge clk or negedge rst) begin
    if (!rst) begin
        dl_curr_state <= DL_Inactive;
        last_notify_seq_num <= 12'd0; // Initialize last acknowledged sequence number 
        update_timer <= 0 ; 
        notify_seq_num_reg<=0;
        ack_nak_seq_num_reg<=0;
    end else begin
        dl_curr_state <= dl_next_state;  
        update_timer <= update_timer_nxt ;
        notify_seq_num_reg<= notify_seq_num;
        ack_nak_seq_num_reg<= ack_nak_seq_num ;  

        if(ack_forward_progress)  
        last_notify_seq_num <= notify_seq_num ;
        else if(nak_forward_progress)  
        last_notify_seq_num <= notify_seq_num ;

    end 

end 



always @(*) begin 
DL_Down = 0 ;
init_flag = 0 ; 
start_fc_init1_pkts = 0;
start_fc_init2_pkts = 0;
RUN_TIME_ON = 0;   
ack_nak_seq_num = ack_nak_seq_num_reg ;   
//dl_curr_state = DL_Inactive ; 
transmit_update_dllp = 0 ; 
update_timer_nxt = update_timer ;
case(dl_curr_state) 
 DL_Inactive : begin 
        DL_Down = 1'b1; // Indicate that the link is down;  
        if(PHY_UP)  
        dl_next_state = Init_FC1; 
        else  
        dl_next_state = DL_Inactive; 
 end

Init_FC1 : begin 
     DL_Down = 1'b1;
     init_flag = 1'b1;   // we enter the init_fc1 state before the FC and with this flag we make it give us the credit allocation   
          //!!!!!!!!!!!!!!!!!!!!!!!!we could check the credits "in dllp creator"...> if they are not zero we creat the dllps.. give up the vlaid signals!!!!!!!!!!!!!!!!!!!!!!!!!!! 
     if(credits_vld)
        start_fc_init1_pkts = 1; // start creating FC init1 packets ---->dllp creator  
      else  
        start_fc_init1_pkts = 0;
      //---------next state logic ---- 
     if (exit_fc_init1) begin 
         dl_next_state = Init_FC2; // Proceed to the next state after FC initialization
     end else begin
         dl_next_state = Init_FC1; // Stay in the same state until FC initialization is complete
     end 
      
end

Init_FC2 : begin 
         start_fc_init2_pkts  =1 ;  //dllp creator starts creating the FC init2 packets 
         DL_Down = 0 ;
         if(exit_fc_init2)   // == exit_init_fc2
         dl_next_state = DL_Active ;
         else   
         dl_next_state = Init_FC2 ;
end


DL_Active : begin   // == L0 
    //the flow of the TLPs is initiated 
     DL_Down = 0 ;  
     RUN_TIME_ON = 1;   //for the FC and  for the dllp creator "so it only transmit the update dllps"  
     if(update_timer == 60 )  begin // this 60 could be changed   
      transmit_update_dllp =1;  
      update_timer_nxt = 0 ; 
      dl_next_state = DL_Active ;
     end 
     else begin 
      transmit_update_dllp = 0;  
      update_timer_nxt++ ; 
      dl_next_state = DL_Active ;
     end 

     if(ack_forward_progress) begin   
      ack_nak_seq_num =  notify_seq_num ; 
       dl_next_state = DL_Active ;
     end 
     else if (nak_forward_progress) begin  
      ack_nak_seq_num = notify_seq_num ;  
        dl_next_state = DL_Active ;
     end 
     else   begin 
      ack_nak_seq_num = ack_nak_seq_num_reg ;   
         dl_next_state = DL_Active ;
     end

     if (!PHY_UP) 
     dl_next_state = DL_Inactive ;
     else  
     dl_next_state = DL_Active ;

end
//power_management : begin 
      
//end

default : begin 
    dl_next_state = DL_Inactive; // Reset to inactive state on error
    DL_Down = 0 ;  
    init_flag = 0 ;
    start_fc_init1_pkts = 0 ; 
    start_fc_init2_pkts = 0 ; 
    transmit_update_dllp= 0 ;
   
end

endcase

end



//---------------------------------decode the incoming initialization dllps ------------------------------------------ 
 //decoding the init_fc1 packets and forward it to FC 
 // decode the  init_fc2 packets and doesn't forward them to fc and rise flag of exit init_fc2 state and enter the run_time state 


typedef enum {

  RX_IDLE , 
  NP_DEC , 
  C_DEC ,
  RUN_TIME_HANDLING 

} state_rx ;
 
state_rx  current_rx , next_rx ;

always @(posedge clk or negedge rst) begin
    if (!rst) begin
     current_rx <= RX_IDLE;
    end else begin
     current_rx <= next_rx ; 
    end 

end  




//logic forward_progress_calc;
/*
logic  [12:0] seq_diff_a  ;

assign seq_diff_a = {1'b0, ack_seq_num} - {1'b0, last_notify_seq_num};  
logic [12:0] seq_diff_b  ;
assign seq_diff_b = {1'b0, last_notify_seq_num} - {1'b0, ack_seq_num};   

logic  case_a = ~seq_diff_a[12] & (~seq_diff_a[11] & (seq_diff_a[11:0] != 12'd0));
logic  case_b = ~seq_diff_b[12] & seq_diff_b[11];

always @(*)  
begin 
   ack_forward_progress = ack_received && (case_a || case_b); 
end
*/

  always @(*)  
begin   
  ack_forward_progress = 0 ;
  nak_forward_progress = 0;
  
  ack_forward_progress = ack_received && (
    ((ack_seq_num > last_notify_seq_num) && ((ack_seq_num - last_notify_seq_num) < 12'd2048)) || 
    ((ack_seq_num < last_notify_seq_num) && ((last_notify_seq_num - ack_seq_num) >= 12'd2048))
  );  

  nak_forward_progress = nak_received && (
    ((nak_seq_num > last_notify_seq_num) && ((nak_seq_num - last_notify_seq_num) < 12'd2048)) || 
    ((nak_seq_num < last_notify_seq_num) && ((last_notify_seq_num - nak_seq_num) >= 12'd2048))
  );

end

always @(*)  
begin 
  Fl2 = 0;
  FC_INIT2_Received_TYPE =0 ; 
  PH_credits_limit = 0 ;
  NPH_credit_limit = 0 ;
  CH_credits_limit = 0 ;
  PD_credits_limit = 0 ;
  NPD_credit_limit = 0 ;
  CD_credits_limit = 0 ; 
  initiate_ack = 0 ;
  initiate_nak = 0 ; 
  ack_received = 0 ;
  nak_received = 0 ;  
  ack_seq_num = 0 ;
  nak_seq_num = 0 ;
  notify_seq_num  = notify_seq_num_reg ;
  //ack_forward_progress =0 ; 
  pending_seq_num =  0 ;
  exit_fc_init2 = 0;
 case (current_rx)
  RX_IDLE :begin  
    if (init_flag ) begin //  if (dl_curr_state == Init_FC1 ) 'dl_curr_state' might be read before written in always_comb or always @* block.
        if(CRC_CHK_vld_dllp && Dmux_vld_dllp) 
          begin 
               // dllp_received = DLLP_Dmux_o[63:32];
                PH_credits_limit = DLLP_Dmux_o[53:46];
                PD_credits_limit = DLLP_Dmux_o[43:32];
                next_rx = NP_DEC ;
          end 

        else   begin 
             next_rx =RX_IDLE ;
        end 
    end
    else if (start_fc_init2_pkts) begin //dl_curr_state == Init_FC2
            if(CRC_CHK_vld_dllp && Dmux_vld_dllp) 
              begin                                             
               if( DLLP_Dmux_o[63:60] == 4'b1100 )begin // get the type of the received dllp)
                 Fl2 = 1'b1;  
                 next_rx =  NP_DEC  ;
                 exit_fc_init2 = 0;
/*|| 
                 FC_INIT2_Received_TYPE == 4'b1101 ||
                 FC_INIT2_Received_TYPE == 4'b1110 ) begin*/
              end 

            else   begin 
                Fl2 =1'b0; 
                next_rx = RX_IDLE ;
            end 
        end
        else begin 
            next_rx = RX_IDLE ; // no dllps to decode in the other states 
        end
    end   

  else if(RUN_TIME_ON ) begin  //dl_active state   
        next_rx  =  RUN_TIME_HANDLING ;
    end 
  else   begin  
    next_rx = RX_IDLE ;
  end 
  end
   
NP_DEC: begin  
  if(init_flag) begin 
      if(CRC_CHK_vld_dllp && Dmux_vld_dllp) 
          begin 
                NPH_credit_limit = DLLP_Dmux_o[53:46];
                NPD_credit_limit = DLLP_Dmux_o[43:32];
                next_rx = C_DEC ; 
                Fl2 = 0 ;
          end 

        else   begin 
             next_rx = NP_DEC ; 
              Fl2 = 0 ;
        end 
    end
  else if (start_fc_init2_pkts) 
    begin 
     if(CRC_CHK_vld_dllp && Dmux_vld_dllp) 
          begin 
             if(DLLP_Dmux_o[63:60] ==  4'b1101 ) begin 
                Fl2 =1 ;
                next_rx = C_DEC ; 
                exit_fc_init2 = 0;
             end 
             else  begin 
                Fl2 =1'b0; 
                next_rx = RX_IDLE ;
             end
          end 
      else   begin 
        next_rx = NP_DEC ; 
        Fl2 =1 ;
      end
    end

  else  begin 
    next_rx = RX_IDLE ; 
    Fl2 = 0 ;
  end
end

C_DEC: begin 
   if(init_flag) begin 
      if(CRC_CHK_vld_dllp && Dmux_vld_dllp) 
          begin 
                CH_credits_limit = DLLP_Dmux_o[53:46];
                CD_credits_limit = DLLP_Dmux_o[43:32];
                next_rx = RX_IDLE ; 
                 Fl2 = 0 ;
          end 
        else   begin 
             next_rx = C_DEC ;
              Fl2 = 0 ;
        end 
   end  

  else if (start_fc_init2_pkts) 
    begin 
     if(CRC_CHK_vld_dllp && Dmux_vld_dllp) 
          begin 
             if(DLLP_Dmux_o[63:60] ==  4'b1110 ) begin 
                Fl2 =1 ; 
                exit_fc_init2 = 1 ; 
                next_rx = RX_IDLE ;
             end 
             else  begin 
                Fl2 =1'b0; 
                next_rx = RX_IDLE ;
             end
          end 
      else   begin 
        next_rx = C_DEC ; 
        Fl2 =1 ;
      end
    end
  else begin  
    next_rx = RX_IDLE ; 
    Fl2 = 0;
  end

end  

RUN_TIME_HANDLING: begin   
  if(RUN_TIME_ON) begin 
    if(CRC_CHK_vld_dllp && Dmux_vld_dllp) begin   //decode ack_nak
      if(DLLP_Dmux_o[63:56] ==8'b0000_0000 )begin 
         ack_received = 1 ;  
         notify_seq_num =  DLLP_Dmux_o[43:32] ;
         ack_seq_num = notify_seq_num ; 
         next_rx = RUN_TIME_HANDLING ;
      end  

      else if (DLLP_Dmux_o[63:56] ==8'b0001_0000) begin 
         nak_received = 1 ;  
         notify_seq_num =  DLLP_Dmux_o[43:32] ;
         nak_seq_num = notify_seq_num ;
         next_rx = RUN_TIME_HANDLING ;

      end 
  
      else if(DLLP_Dmux_o[63:60] == 4'b1000 ) begin   //does FC need a valid signal to capture the data
              PH_credits_limit = DLLP_Dmux_o[53:46];
              PD_credits_limit = DLLP_Dmux_o[43:32];
              next_rx = RUN_TIME_HANDLING ;
      end 
      else if (DLLP_Dmux_o[63:60] == 4'b1001) begin 
                NPH_credit_limit = DLLP_Dmux_o[53:46];
                NPD_credit_limit = DLLP_Dmux_o[43:32];
                next_rx = RUN_TIME_HANDLING ;

      end 
      else if (DLLP_Dmux_o[63:60] == 4'b1010) begin 
                CH_credits_limit = DLLP_Dmux_o[53:46];
                CD_credits_limit = DLLP_Dmux_o[43:32];
                next_rx = RUN_TIME_HANDLING ;
      end  

      else begin 

        next_rx = RUN_TIME_HANDLING ;
  
      end
      end

      else begin   //must go to tx(rx-->tx) of the same device
        if (NAK_SCHEDULED) 
          begin 
            initiate_nak  = 1 ;
            pending_seq_num = req_seq_num  ;
            next_rx = RUN_TIME_HANDLING ;
          end 
        else if(ack_nak_time_out) 
          begin 
            initiate_ack = 1 ; 
            pending_seq_num = req_seq_num ;  
            next_rx = RUN_TIME_HANDLING ;
          end
        else  begin  
            initiate_ack = 0 ;
            initiate_nak = 0 ;  
            next_rx = RUN_TIME_HANDLING ;
        end
      end
end  

else  begin 
  next_rx = RX_IDLE ;
end
end

default: begin 
        ack_received = 0 ;
        nak_received = 0 ; 
        PH_credits_limit = 0 ;
        NPH_credit_limit = 0 ;
        CH_credits_limit = 0 ;
        PD_credits_limit = 0 ;
        NPD_credit_limit = 0 ;
        CD_credits_limit = 0 ;           
        pending_seq_num =  0 ;
        exit_fc_init2 = 0;
        ack_seq_num = 0 ;
        nak_seq_num = 0 ;
        notify_seq_num  = notify_seq_num_reg ;



end


 endcase
end

 endmodule 




