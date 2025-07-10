module dllp_creator (
  input wire clk,
  input wire rst,  
  input wire [11:0] seq_num,  //for both ack and nak depending on which dllp generating req is it
  input wire gen_ack,
  input wire gen_nak,
  input wire gen_pm,
  //input wire gen_fc,
  
  input wire pm_enter_l1,
  input wire pm_enter_l23,
  input wire pm_active_state_req,
  input wire pm_request_ack,
  
  input wire [9:0] PH_credits,  
  input wire [9:0] NPH_credits,
  input wire [9:0] CH_credits,

  input wire [9:0] PD_credits,
  input wire [9:0] NPD_credits,
  input wire [9:0] CD_credits,
  
  input wire       start_fc_init1_pkts,
  input wire       start_fc_init2_pkts, 
  input wire       transmit_update_dllp,
  
  input wire       RUN_TIME_ON, 
   
  //input wire link_active,
  
  output reg [31:0] dllp_out,           // DLLP output to CRC and to arbiter at the same clk cycle
  output reg dllp_valid_out             // DLLP valid signal
   );
   
  integer i ;

 typedef enum {
  IDLE ,
  CREATE_DLLP ,
  SEND_DLLP
  
 } state_t ;
 
 state_t current_state , next_state ;
 
 typedef enum {
	   posted_trans,
	   non_posted_trans,
	   cmp_trans
	} state_in_fc ; 
	state_in_fc curr_s , nxt_state;
 
  
  //DLLP type constants
  localparam [7:0]
    ACK_TYPE           = 8'h00,
    NAK_TYPE           = 8'h10,
    PM_ENTER_L1_TYPE   = 8'h20,
    PM_ENTER_L23_TYPE  = 8'h21,
    PM_ACTIVE_REQ_TYPE = 8'h23,
    PM_REQUEST_ACK_TYPE= 8'h24;
    
  localparam [3:0]
    FC_INIT_P_TYPE     = 4'b0100,
    FC_INIT_NP_TYPE    = 4'b0101,
    FC_INIT_CPL_TYPE   = 4'b0110,
    FC_INIT2_P_TYPE    = 4'b1100,
    FC_INIT2_NP_TYPE   = 4'b1101,
    FC_INIT2_CPL_TYPE  = 4'b1110, 
	  UpdateFC_P_TYPE    = 4'b1000, 
	  UpdateFC_NP_TYPE   = 4'b1001, 
	  UpdateFC_Cpl_TYPE  = 4'b1010; 

	
   localparam fc_vc_id = 0 ;
  
  
   //internal registers
    reg dllp_transmit_complete ;  //usful indicator for Transmission complete
  //reg [2:0] next_state, current_state;
  reg [31:0] dllp_packet;
  reg [31:0] dllp_packet_reg;
  reg [7:0] dllp_type;
  reg [7:0] dllp_type_reg;
  reg [2:0] selected_priority;  //ack-nack=00 ,pm=01 ,fc= 10
  reg [2:0] selected_priority_reg;
  //reg [1:0] fc_packet_cycle;  // like a counter for FC packets (0=Posted, 1=NonPosted, 2=Completion)
  //reg [1:0] next_fc_packet_cycle;
  reg [31:0] dllp_posted, dllp_Nposted, dllp_CPL; 
  reg [31:0] dllp_posted_reg, dllp_Nposted_reg, dllp_CPL_reg; 
  
  //pending flags for dllp types
  //to track if we will need to send ack-nak or other dlllp types
  reg [3:0] FC_init_dllp_count ;  
  reg [3:0] FC_init_dllp_count_reg ;  
  logic fc_gen ;
  assign fc_gen = (start_fc_init1_pkts || start_fc_init2_pkts || (RUN_TIME_ON && transmit_update_dllp));

  logic  [3:0]  request_vctr ;
assign request_vctr = {gen_ack,gen_nak,gen_pm,fc_gen};
  // arbiter priority encoding 

  //reg [1:0] cnt ;
  
  reg  start_fc_init1_pkts_reg ;
  reg  start_fc_init2_pkts_reg ; 
  reg  transmit_update_dllp_reg ;
  reg trans_consec;
  reg trans_consec_reg;
  reg done_creating_fc1; 
  reg done_creating_fc2; 
  reg done_creating_update; 
  
/* You're correctly identifying a common issue in FSM-driven modules where a pulse signal (1 clk cycle) needs 
  to be latched or remembered for more than one cycle.
  In your case, start_fc_init1_pkts or start_fc_init2_pkts might be high for only 1 cycle, and if the FSM is not
  in the right state to see it at that moment, the signal will be missed.*/
  
  
always @(posedge clk or  negedge rst)
   begin
     if(!rst)
       begin
        current_state <= IDLE; 
		    curr_s <= posted_trans; 
		    start_fc_init1_pkts_reg <=0;
        start_fc_init2_pkts_reg <= 0;
        FC_init_dllp_count <= 0;	
        dllp_packet_reg<=0;
        dllp_type_reg<=0;
        dllp_out <= 0;
        dllp_transmit_complete <= 0;  
        selected_priority_reg<=3'b111; 
        dllp_posted_reg <=0;
        dllp_Nposted_reg<=0;
        dllp_CPL_reg<=0; 
        trans_consec_reg<=0; 
        FC_init_dllp_count_reg<=0;
        transmit_update_dllp_reg<=0;

       end
     else
       begin
        current_state <= next_state; 
		    curr_s <= nxt_state ;    
        dllp_packet_reg<=dllp_packet;
        dllp_type_reg<=dllp_type;
        dllp_posted_reg <=dllp_posted;
        dllp_Nposted_reg<=dllp_Nposted;
        dllp_CPL_reg<=dllp_CPL;
        trans_consec_reg<=trans_consec;
        FC_init_dllp_count_reg<=FC_init_dllp_count;
        selected_priority_reg <= selected_priority ;
		     if(start_fc_init1_pkts) start_fc_init1_pkts_reg<=1;
		     else if(done_creating_fc1) start_fc_init1_pkts_reg <=0;

         if(start_fc_init2_pkts) start_fc_init2_pkts_reg<=1; 
         else if(done_creating_fc2) start_fc_init2_pkts_reg <= 0; 

         if(transmit_update_dllp)transmit_update_dllp_reg<=1;
         else if(done_creating_update) transmit_update_dllp_reg<=0; 


    end	
end	 

    



//////////////////DLLP CREATOR BLOCK////////////////
always @(*)
 begin
   next_state = current_state;
    //next_fc_packet_cycle = fc_packet_cycle;
   dllp_packet=dllp_packet_reg;
   dllp_type=dllp_type_reg;
   dllp_valid_out = 0;
   dllp_transmit_complete = 0;
   selected_priority = selected_priority_reg;  
   FC_init_dllp_count = 0 ; 
   nxt_state =curr_s; 
   trans_consec=0;
   done_creating_fc1=0; 
   done_creating_fc2=0; 
   done_creating_update=0; 
   dllp_posted =dllp_posted_reg;
   dllp_Nposted=dllp_Nposted_reg;
   dllp_CPL=dllp_CPL_reg; 
   trans_consec= trans_consec_reg; 
   FC_init_dllp_count=FC_init_dllp_count_reg;

   //request_vctr = {gen_ack,gen_nak,gen_pm,fc_gen};
   case(current_state)
     IDLE:
      begin 

        casex(request_vctr) 
            4'b1xxx: begin 
              next_state = CREATE_DLLP; 
              selected_priority = 3'b000;
            end
            4'b01xx: begin 
               next_state = CREATE_DLLP; 
               selected_priority = 3'b001;
            end
            4'b001x:begin 
               next_state = CREATE_DLLP; 
               selected_priority =3'b010;
            end
            4'b0001: begin 
               next_state = CREATE_DLLP; 
               selected_priority =3'b011;
            end
            default: next_state = IDLE;

        endcase
      end 
     
 CREATE_DLLP: 
  begin
    case(selected_priority)
    3'b000:
       begin 
        
        dllp_type = ACK_TYPE;         
        dllp_packet = {dllp_type, 12'b0, seq_num};  
      end 
      
    3'b001: begin 
      dllp_type = NAK_TYPE;
      dllp_packet = {dllp_type, 12'b0, seq_num};  
    end
    
   3'b010:
    begin 
        if (pm_enter_l1)
        dllp_type = PM_ENTER_L1_TYPE;
      else if (pm_enter_l23)
        dllp_type = PM_ENTER_L23_TYPE;
      else if (pm_active_state_req)
        dllp_type = PM_ACTIVE_REQ_TYPE;
      else
        dllp_type = PM_REQUEST_ACK_TYPE;  
   
      dllp_packet = {dllp_type, 24'b0};
    end

   3'b011:
    begin 
      // first we will create the 3 packets
     if(start_fc_init1_pkts_reg) 
       begin 
	    trans_consec = 1 ; //transmit consecutive packets ps-->nps--> cmp
        dllp_posted  = {FC_INIT_P_TYPE,1'b0,   fc_vc_id, 2'b0, PH_credits,  2'b0, PD_credits};
        dllp_Nposted = {FC_INIT_NP_TYPE,1'b0,  fc_vc_id, 2'b0, NPH_credits, 2'b0, NPD_credits}; 
        dllp_CPL     = {FC_INIT_CPL_TYPE,1'b0, fc_vc_id, 2'b0, CH_credits,  2'b0, CD_credits};  
		done_creating_fc1 =1;
      end
    else if(start_fc_init2_pkts_reg) 
      begin 
	     trans_consec =1 ;
        dllp_posted  = {FC_INIT2_P_TYPE,1'b0,   fc_vc_id, 2'b0, PH_credits,  2'b0, PD_credits}; 
        dllp_Nposted = {FC_INIT2_NP_TYPE,1'b0,  fc_vc_id, 2'b0, NPH_credits, 2'b0, NPD_credits}; 
        dllp_CPL     = {FC_INIT2_CPL_TYPE,1'b0, fc_vc_id, 2'b0, CH_credits,  2'b0, CD_credits}; 
		done_creating_fc2 =1;
      end 
	  else if (transmit_update_dllp) begin    //handle the update dllps 
	    trans_consec =0 ; 
	    dllp_posted  = {UpdateFC_P_TYPE,1'b0,   fc_vc_id, 2'b0, PH_credits,  2'b0, PD_credits}; 
        dllp_Nposted = {UpdateFC_NP_TYPE,1'b0,  fc_vc_id, 2'b0, NPH_credits, 2'b0, NPD_credits}; 
        dllp_CPL     = {UpdateFC_Cpl_TYPE,1'b0, fc_vc_id, 2'b0, CH_credits,  2'b0, CD_credits};  
		done_creating_update =1;
	  end
   else begin 
       dllp_posted =dllp_posted_reg;
       dllp_Nposted=dllp_Nposted_reg;
       dllp_CPL=dllp_CPL_reg;  
       next_state = IDLE;
   end         
   end
   default : begin 
        //selected_priority  = 3'b111 ;
		done_creating_fc1 =0 ;
		done_creating_fc2 =0 ;
		done_creating_update =0 ;
   end
 endcase 
  next_state = SEND_DLLP;
end


SEND_DLLP:
 begin 
   dllp_valid_out = 1; 
   next_state = IDLE; 
   //genvar i ;
 if(trans_consec)
  begin  //(start_fc_init1_pkts || start_fc_init2_pkts)
 
    nxt_state = curr_s;
    case(curr_s)  
	   posted_trans : 
		  begin 
		   dllp_out = dllp_posted ;
		   nxt_state = non_posted_trans; 
		   FC_init_dllp_count++; 
		  end
		non_posted_trans : 
		 begin
		  dllp_out =  dllp_Nposted ; 
		  nxt_state = cmp_trans;
      FC_init_dllp_count++; 
		 end 
		cmp_trans:
   		 begin  
		    dllp_out = dllp_CPL;
        nxt_state = posted_trans;
        FC_init_dllp_count++;		
		 end
        default :
         begin
		      dllp_out = 32'h0;
     	    nxt_state = posted_trans ;  
          FC_init_dllp_count=FC_init_dllp_count_reg;

		     end
	   endcase
	  
 if (FC_init_dllp_count == 9) 
	 begin  
	  dllp_transmit_complete = 1; 
    FC_init_dllp_count = 0; //reset the counter 
	  trans_consec = 0 ;
	  next_state = IDLE;
 	 end
  else
	   begin 
	    dllp_transmit_complete =0	 ;
	    trans_consec = 1;
	    next_state = SEND_DLLP;
     end
   end
   else 
    begin 
     dllp_out = dllp_packet;  
     dllp_transmit_complete =1 ;
	   next_state = IDLE;
   end
 end
 
  default:
   begin
     next_state = IDLE; 
     trans_consec=0;
     done_creating_fc1=0;
     done_creating_fc2=0;
     done_creating_update=0;
	   dllp_transmit_complete =0 ;
   end
 endcase
 end
 
 endmodule
    
 
