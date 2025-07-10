module  rep_buffer  #(
    parameter seq_num_width = 12,
              tlp_mux_in_width = 128 ,  
              lcrc_width =  32,
              entry_width = 310,
              buff_depth =256
)

(
    input wire clk ,rst ,
    //inputs from the mem
    input wire          mem_full,  
    input  wire         mem_empty,
   
    input wire  time_out,
    input wire  [seq_num_width-1:0] ack_nak_seq_num,//

   //inputs from the tlp_mux

   input wire   [tlp_mux_in_width-1:0] tlp_mux_out, 
   input wire                          tlp_mux_valid ,  
   input wire  [15:0]                  current_seq_num ,  //to store the current sequence number  
   input wire  [5:0]                   TLP_MUX_LEN, //from tlp_mux

    // input wire [tlp_mux_in_width-1:0] tlp_in,
    // input wire [seq_num_width-1:0]    seq_num_in,
    // input wire [lcrc_width-1:0]       lcrc_in,
   
   //--input from transaction ----
   input wire      tlp_coming , // to start control the tlp_mux 
   input wire      tlp_end , 

   input wire       ack_forward_progress,  //ack_received is embedded in this signal
   input wire       nak_forward_progress,  //ack_received is embedded in this signal
   input wire       lcrc_valid, //to indicate that the lcrc is valid and ready to be sent to the mem
//outputs to the mem
    output reg  wr_en, //to the mem 
    output reg  rd_en, 
    output reg purge_tlps,
    output reg  [7:0] wr_ptr, rd_ptr,
    output reg [8:0] unack_tlp_count,  
    output reg  [entry_width-1:0]  data_out, //to mem
    output reg [2:0] segment_count ,

    //output reg tlp_complete;     //flag to mem to start store the tlp

//outputs to the tlp_mux  

   output reg [1:0]       mux_sel ,  //needed to be a combinational signal ?? to minimize the clk cycles
   output reg             tlp_mux_start,
    
//otuputs to lcrc generator 
   output reg      lcrc_start,
   output reg  [1:0] lcrc_ctrl ,    

   output reg          NTS_icr , 
   output reg          skip_256 , 
   output reg          busy //to indicate that the replay buffer is busy and not ready to receive new tlp 
   //output reg          tlp_is_handled //to indicate that the tlp is handled and ready to be stored in the replay buffer                                     

);

reg          retransmitting_on; //to make fsm is not writing till rd_ptr = wr_ptr  
reg [7:0] wr_ptr_c ; //reason for it that the wr_ptr was incrememnting at stor_tlp and in idle also so i had to use the comb verison
reg [7:0]  rd_ptr_c ;
reg [8:0] count ;
reg [8:0] count_nxt ;
reg [seq_num_width-1:0] last_rcvd_seq_num ;
reg [2:0] frame_count;  //to keep track of the frame count
reg [2:0] frame_cnt_reg; 
reg [entry_width-1:0] data_collected;
reg [entry_width-1:0] data_collected_reg;

reg  [entry_width-1:0]  data_to_mem ; 


reg [1:0] mux_sel_c; 
reg [1:0] mux_sel_reg; 
reg [1:0] lcrc_ctrl_c; 
reg [1:0] lcrc_ctrl_reg; 
reg       capture_tlp ; 

reg    skip_256_c ;

logic  [7:0] ptrs_diff;  
logic dummy_bit;  

reg [2:0] seg_cnt;

//replay buffer doesn't have a state that transmitt all the time it only stores and retransmiit 
typedef enum  {
    idle,
  
    //----------------
    nsn_receiving,
    payload_receiving_128  ,
    payload_receiving_256  ,
    lcrc_receiving,
    end_tlp_receiving,
    store_tlp

} state_t;

state_t current_state, next_state; 

typedef enum  
 {   
    idle_l,
    TMUX_SEQNUM_TRANS, 
    TMUX_tlp128_TRANS, 
    TMUX_tlp256_TRANS,
    Tmux_lcrc_transmit

 } state_l;

 state_l present_state , nxt_state ;

 typedef enum {
     idle_t2,
    ack_purging,  // state to purge the tlps from the mem
    ack_prg_cont,
    //-----------------------
    nak_purging, 
    retransmitting_loading , 
    retransmitting_segments

} state_t2;

state_t2 curr_s , next_s;


//state transition logic
always @(posedge clk or negedge rst) begin
    if (!rst) begin
        current_state <= idle;
        present_state <= idle_l; 
        curr_s <= idle_t2;
            wr_ptr <= 0;
            rd_ptr <= 0;
            data_collected <= 0;
            data_collected_reg<= 0;
            data_out <= 0;
            unack_tlp_count <= 0;
            count <= 0;
            frame_cnt_reg<=0 ;
            // frame_count <= 0;
            last_rcvd_seq_num <= 0;
            wr_ptr_c<=0;
            rd_ptr_c <= 0;
            data_to_mem<=0;
           
           mux_sel <= 0;  
           mux_sel_reg<= 0 ;
           skip_256<= 0;
           lcrc_ctrl <= 0; 
           segment_count <=0;

    end
    else begin 
        current_state <= next_state;
        present_state <= nxt_state; 
        curr_s <= next_s;
        unack_tlp_count <= count_nxt ;   //or make it count_nxt i think count_nxt is right as like this unack_tlp will be 2 cycles away from count_nxt
        count <= count_nxt;
        wr_ptr <= wr_ptr_c ;
        rd_ptr <= rd_ptr_c ;
        data_collected_reg <= data_collected ;
        frame_cnt_reg <= frame_count;
        //data_out <= data_to_mem;
       // mux_sel <= mux_sel_c; 
       lcrc_ctrl_reg <= lcrc_ctrl;
       // lcrc_ctrl <= lcrc_ctrl_c;
        mux_sel_reg <= mux_sel ;
        skip_256 <= skip_256_c ; 
        segment_count <= seg_cnt;
    end
end



always @ (*) 
begin 
    //-------------------------tlp_mux controlling states -------------------------
    //tlp_rd_en  = 0 ;
    NTS_icr =0 ;
    lcrc_start = 0;
    tlp_mux_start = 0;  
    capture_tlp = 0;
    mux_sel = 0;   
    skip_256_c =0 ; 
    //mux_sel_c =  mux_sel ; 
    // lcrc_ctrl_c = lcrc_ctrl ;
    lcrc_ctrl =lcrc_ctrl_reg;
    mux_sel =mux_sel_reg; 
    busy = 0;

//here the DLL needs one clk cycle  to  let the sequenece number flow throught the tlp_mux to the lcrc and the retry_buffer after the tlp_coming signal is high  
//so we could make the TMUX_SEQ_TRANS state to transmit the seq_num and give the idle_l state up ....> this affected the second fsm as the rep_buffer will sample the tlp128 in the 
//nsn_receiving state .
 case (present_state)
     idle_l :begin 
        mux_sel = 2'b11 ;
        lcrc_start = 0; 
        lcrc_ctrl = 2'b00; 
        if (retransmitting_on)begin   // this busy signal must be checked at flow control only at the beginning of transmission
         busy = 1'b1;
        end
         else
         begin
         busy = 1'b0; //the replay buffer is busy when it is retransmitting
         end
        if (tlp_coming) begin
        nxt_state = TMUX_SEQNUM_TRANS;
        // tlp_mux_start =1 ;
        capture_tlp = 1 ;
        end 
        else  
        nxt_state = idle_l ;
     end


TMUX_SEQNUM_TRANS : begin    //sequence number transmission from mux_out signal ... as it is registered in the tlp_mux
       // tlp_mux_start =1 ;
        mux_sel = 2'b00 ;
        lcrc_start = 1; 
        lcrc_ctrl = 2'b00; 
        nxt_state = TMUX_tlp128_TRANS; 
       //tlp_rd_en = 1;           //tlp_rd_en is a signal to give the transaction a permission to start transmit the tlp so do we want it here equal one as the output of the
       // transaction layer is registered so it needs the signal rd to be enabeled one clock cycle before it    

end

   TMUX_tlp128_TRANS : begin 
        //tlp_rd_en = 1 ;
        mux_sel = 2'b01;
        lcrc_ctrl = 2'b01 ; 
        if ( tlp_end ) begin 
        nxt_state = Tmux_lcrc_transmit ;  
        skip_256_c =1;          //when the skip signal was controlled in the tmux_lcrc_transmit state the skip signal was risen 
        end             
        else 
        nxt_state = TMUX_tlp256_TRANS; 
   end

   TMUX_tlp256_TRANS : begin  
        //tlp_rd_en = 1 ;
        mux_sel = 2'b01;
        lcrc_ctrl = 2'b10;    
        nxt_state = Tmux_lcrc_transmit; 
   end
   
   Tmux_lcrc_transmit : begin 
    lcrc_ctrl = 2'b11; 
    NTS_icr = 1 ;  
  //  tlp_rd_en  = 0 ;
          if(lcrc_valid) begin 
          mux_sel = 2'b10; //to select the lcrc_in from the tlp_mux
          nxt_state = idle_l;  
          end
          else
          nxt_state =Tmux_lcrc_transmit;
   end 
   default : begin 
        nxt_state = idle_l ;
        //tlp_rd_en = 0 ;
        mux_sel = 0;    
        NTS_icr =0 ;
        lcrc_start = 0;
        tlp_mux_start = 0; 
        capture_tlp = 0;
        skip_256 =0 ; 
        busy = 0 ;

   end

endcase

end

always @(*) begin
    wr_en = 0;
    frame_count = frame_cnt_reg;
    data_collected = data_collected_reg;
    //tlp_complete = 0;
    count_nxt = unack_tlp_count;  //looks like this next_state = current_state;   
    //count_nxt = 0 ;
    wr_ptr_c = wr_ptr ;
    busy = 1'b0;


case (current_state)

    idle: begin  
        
        if(capture_tlp&&!retransmitting_on)
        next_state = nsn_receiving ;
        else begin
        next_state =idle;
        end
    end

//-------------------------receiving the tlp and store it in mem -------------------------
/*     collect_tlp: begin  
        if (!mem_full)  //so that the wr_ptr won't rollover and start overwritting in the location [0] again 
            next_state = nsn_receiving;
        else
            next_state = idle; 
    end*/
    nsn_receiving : begin  
                if(!mem_full && tlp_mux_valid) begin
                next_state = payload_receiving_128;  
                data_collected[entry_width-1:entry_width-6] = TLP_MUX_LEN;  
                 data_collected[entry_width-7:entry_width-22] = {4'b0, tlp_mux_out[11:0]}; // 16-bit seq num (bits 303:288)//{4'b0,seq_num_in}; 
                frame_count++;
                 end
                else  
                next_state = idle ;
    end
    payload_receiving_128: begin   
                     if(tlp_mux_valid) begin
                    // data_collected[entry_width-26:entry_width-153] = tlp_mux_out;
                     data_collected[entry_width-23:entry_width-151] = tlp_mux_out; 

                     data_collected[entry_width-1:entry_width-22] = data_collected_reg[entry_width-1:entry_width-22];                     
                     frame_count++;
                    end
                    else 
                     next_state = idle ;

                if(tlp_end) 
                next_state = lcrc_receiving ; 
                else  
                next_state = payload_receiving_256 ;
                

    end
    payload_receiving_256: begin  
               if(tlp_mux_valid) begin
                next_state = lcrc_receiving;   
                data_collected[entry_width-154:entry_width-281] = tlp_mux_out;
                data_collected[entry_width-26:entry_width-153] = data_collected_reg[entry_width-26:entry_width-153];
                frame_count = frame_count + 1; end
                else  
                next_state = idle ;
    end
    lcrc_receiving : begin  
               if(tlp_mux_valid) begin 
                //next_state = end_tlp_receiving;
                data_collected[31:0] = tlp_mux_out[31:0];
                 // Maintain previous values
                 data_collected[entry_width-154:entry_width-281] = data_collected_reg[entry_width-154:entry_width-281];
                //data_collected[entry_width-17:entry_width-144] = data_collected_reg[entry_width-17:entry_width-144] ;
                frame_count = frame_count + 1;
               end 
               else  
                next_state = idle ; 

                if(skip_256) begin  
                    if(frame_count == 3'd3) begin 
                         next_state = store_tlp;
                         wr_en = 1 ;         //should we make the wr_en = 0 here and make it 1 in the next state or the opposite lets see in tb ==>here is the answer "always before the wr_ptr increment" with one clock cycle
                         //frame_count = 0;
                         data_out = {data_collected[entry_width-1:entry_width-16],data_collected[entry_width-17:entry_width-144],data_collected[31:0],128'b0 };
                         if (count == 13'd 256)  // why 4096 not 4095 as in wr_ptr ?as the name of signals suggest the count is the number of the tlps that not unacked while the wr_ptr for the next value to write on  
                            count_nxt = count ; 
                            //wr_ptr_c = 0 ; the fsm won't even enter this state when the count equals this for the condition of !mem_full  
                         else 
                         count_nxt = count_nxt + 1;
                    end 
                    else begin 
                    next_state = lcrc_receiving;
                    wr_en = 0; //don't write in the mem until the end of the tlp is received
                    end

                end 
                else begin 

                if(frame_count == 3'd4) begin
                    next_state = store_tlp;
                    wr_en = 1 ;         //should we make the wr_en = 0 here and make it 1 in the next state or the opposite lets see in tb ==>here is the answer "always before the wr_ptr increment" with one clock cycle
                    //frame_count = 0;
                    data_out = data_collected;
                    if (count == 13'd 256)  // why 4096 not 4095 as in wr_ptr ?as the name of signals suggest the count is the number of the tlps that not unacked while the wr_ptr for the next value to write on  
                       count_nxt = count ; 
                       //wr_ptr_c = 0 ; the fsm won't even enter this state when the count equals this for the condition of !mem_full  
                    else 
                    count_nxt = count_nxt + 1;
                end 
                else begin 
                    next_state = lcrc_receiving;
                    wr_en = 0; //don't write in the mem until the end of the tlp is received
                end
            end


    end

    /* end_tlp_receiving : begin   
        if(frame_count == 3'd4) begin
        next_state = store_tlp;
        wr_en = 1 ;         //should we make the wr_en = 0 here and make it 1 in the next state or the opposite lets see in tb ==>here is the answer "always before the wr_ptr increment" with one clock cycle
        frame_count = 0;
        data_out = data_collected;
        if (count == 13'd 4096)  // why 4096 not 4095 as in wr_ptr ?as the name of signals suggest the count is the number of the tlps that not unacked while the wr_ptr for the next value to write on  
           count_nxt = count ; 
           //wr_ptr_c = 0 ; the fsm won't even enter this state when the count equals this for the condition of !mem_full  
        else 
        count_nxt = count_nxt + 1;
        end
        else
            next_state = end_tlp_receiving;
    end */

    store_tlp : begin 
        //tlp_is_handled = 1; //to indicate that the tlp is handled and ready to be stored in the replay buffer
       // wr_en = 1; //to write the tlp in the replay buffer
        frame_count = 0;
        next_state = idle;
        wr_ptr_c = wr_ptr_c + 1; //increment the wr_ptr to store the next tlp,but after storing it in the buff_mem
        //when the count ==4096 at location '4095' the wr_ptr will be pointing to 0 but it wont write the next clk cycle as the mem_full is 1
        /*if (retransmitting_on)begin 
           busy =1'b1;
        end
        else
        begin 
           busy = 1'b0; //the replay buffer is not busy when it is not retransmitting  
        end */
    end

    default: begin 
        next_state = idle;  
        wr_en = 0;

        rd_en = 0;
        purge_tlps = 0;
        //frame_count =0;
        lcrc_start=0;
        tlp_mux_start = 0 ;
        // busy = 1'b0;
    end
    endcase
end

always @(*) begin
    rd_en = 0;
    purge_tlps = 0;
    rd_ptr_c = rd_ptr; 
    retransmitting_on =1'b0;
    {dummy_bit,ptrs_diff} = wr_ptr - rd_ptr_c;
    seg_cnt = segment_count; 
    //unack_tlp_count = ptrs_diff;
    //wr_ptr_c = wr_ptr; //make the simulation stuck if defined in above alwyas(*) 
case (curr_s) 
   idle_t2: begin 
      
            if(|count)  // this very important condition ... when the count is zero "empty" and a purging "ack,or nak received" this condition will not make the fsm enter the purging states
            begin 
                if(ack_forward_progress)
                next_s = ack_purging ;
                else if(nak_forward_progress)
                next_s = nak_purging ;
                else if(time_out)
                next_s = retransmitting_loading;
                else  
                next_s =idle_t2 ;
            end
            else  
            next_s =idle_t2;

    end
    
//------------------------------- only purging the tlp------------------------------------- 
    ack_purging: begin 
        purge_tlps = 1;  //take care purging not replaying "rd_en == 0" 
        last_rcvd_seq_num = ack_nak_seq_num;
        //rd_ptr_c = ack_seq_num + 1;
        rd_ptr_c = rd_ptr +((ack_nak_seq_num - current_seq_num)+1); 

        next_s = ack_prg_cont; 

    
    end
    ack_prg_cont:  begin 
      /*
        if (rd_ptr == wr_ptr) 
            unack_tlp_count = 0;  //with count_nxt there the simulation stucks ....>
        else if (wr_ptr > rd_ptr) begin    //could >= and remove the above condition
            //count_nxt = wr_ptr - (ack_seq_num + 1); //tmam  ===>wr_ptr-rd_ptr
            unack_tlp_count = wr_ptr_c - rd_ptr_c  ;
        end
        else  
            unack_tlp_count = buff_depth - (rd_ptr_c - wr_ptr_c);   //count_nxt = (buff_depth - rd_ptr_c) + wr_ptr_c;
*/
         if(dummy_bit) begin  //ptrs_diff[13]
            ptrs_diff= ~(ptrs_diff) +1; //2's complement to get the absolute value 
             unack_tlp_count = buff_depth - (rd_ptr_c- wr_ptr) ; 
             
          end
          else  begin 
           ptrs_diff =ptrs_diff + 0 ;
                  unack_tlp_count = ptrs_diff; 
          end   

        if (ack_forward_progress) begin    //if having two forward progress consecutively then we can purge the tlps
            next_s = ack_purging;
        end
        else 
            next_s = idle_t2;
    end  

//--------------------------------purging and retransmitting the tlps-------------------------
  nak_purging :begin 
        purge_tlps = 1 ; 
        //rd_ptr_c = ack_nak_seq_num +1 ;
        rd_ptr_c = rd_ptr +((ack_nak_seq_num - current_seq_num)+1); 
        last_rcvd_seq_num = ack_nak_seq_num;
        //count_nxt = count_nxt - rd_ptr_c ;  //this is wrong   ---> this makes the the  
        next_s = retransmitting_loading; //must do retransmitting here before checking for any other state 
        
      /*  if (rd_ptr_c == wr_ptr) begin
                unack_tlp_count = 0;
            end
            else if (wr_ptr > rd_ptr_c) begin
                unack_tlp_count = wr_ptr_c - rd_ptr_c;
            end
            else begin
                unack_tlp_count = buff_depth - (rd_ptr_c - wr_ptr_c);
            end  */   
            
    end

    retransmitting_loading :begin   // in both nak receiving or in time out condition the tx transmitt eveery thing in the replay buffer
        //rd_ptr_c = rd_ptr_c + 1;
        rd_en =1;
        retransmitting_on =1'b1;
        seg_cnt = 2'd1;    
        next_s = retransmitting_segments;
         if(dummy_bit) begin   
            ptrs_diff= ~(ptrs_diff) +1; //2's complement to get the absolute value 
             unack_tlp_count = buff_depth - (rd_ptr_c- wr_ptr) ; 
             
          end
          else  begin 
           ptrs_diff =ptrs_diff + 0 ;
                  unack_tlp_count = ptrs_diff; 
          end   
       /* 
        if(rd_ptr == wr_ptr) begin  //if the rd_ptr reach the wr_ptr then we can stop the retransmitting
            next_s = idle_t2;
            unack_tlp_count = 0 ;
            rd_ptr_c =rd_ptr;
            //count_nxt = 0 ; why???
            rd_en = 0; 
        end  
        else
            next_s = retransmitting;
       */ 
    end  
    //!!!!!!!!!!!!!!!!!!need to add a signal from the lcrc_receiving that inform our fsm when retransmitting that the packet has only128 tlp not 256 so probably we would chang this state!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

    retransmitting_segments: begin  
         if (seg_cnt == 3'd3) begin  
            seg_cnt = 0 ; //reset the segment count to 0
            if(rd_ptr_c == wr_ptr-1) begin  //if the rd_ptr reach the wr_ptr-1 "last packet i want to transmitt" then we can stop the retransmitting
                next_s = idle_t2;  
                rd_ptr_c ++;   
                unack_tlp_count--;  
                retransmitting_on = 1'b0; 
                rd_en = 1;
            end 
            else begin   
                rd_en = 1 ;
                retransmitting_on = 1'b1; 
                rd_ptr_c++; 
                unack_tlp_count--;  
                next_s = retransmitting_loading ; //???we'll see in the tb 
            end
         end
        else begin    
            retransmitting_on = 1'b1;
            rd_en = 1;  
            seg_cnt++;  
            next_s = retransmitting_segments;
        end

    end 

   default: begin 
        next_s = idle_t2 ;
        wr_en = 0;
        rd_en = 0;
        purge_tlps = 0;
        retransmitting_on =1'b0;
    end
    endcase
end
endmodule 

/*
ack_purging: begin 
    purge_tlps = 1;  // Assert purging signal
    rd_ptr = ack_seq_num + 1;  // Update read pointer to the next TLP after the acknowledged ones
    last_rcvd_seq_num = ack_seq_num;  // Update the last received sequence number

    // Calculate the difference between wr_ptr_c and rd_ptr
    reg [seq_num_width:0] diff;  // Extra bit to handle overflow
    diff = wr_ptr_c - rd_ptr;

    // Calculate the number of unacknowledged TLPs after purging
    if (diff == 0) begin
        // Case 1: All TLPs are purged
        count_nxt = 0;  
    end else begin
        // Check the MSB of diff to determine if wr_ptr_c > rd_ptr
        if (~diff[seq_num_width]) begin
            // Case 2: Normal case (no wrap-around)
            count_nxt = diff[seq_num_width-1:0];  // Use the lower bits of diff
        end else begin
            // Case 3: Wrap-around case
            count_nxt = buff_depth + diff[seq_num_width-1:0];  // Add buffer depth to handle wrap-around
        end
    end

    // Transition logic
    if (ack_forward_progress) begin
        next_state = ack_purging;  // Stay in purging state if more progress is expected
    end else begin
        next_state = idle;  // Return to idle state
    end
end
*/