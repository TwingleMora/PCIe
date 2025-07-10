module SEQ_CHKR 

(

input wire          clk , rst , 
input wire          LCRC_chk_vld_tlp ,
input wire          Dmux_vld_tlp ,
input wire  [127:0] TLP_Dmux_o ,
input wire  [5:0]   Dmux_o_len , //max length is 38 bytes (6 bits needed ----> 64 ) 
input wire          Dmux_o_end ,    
input wire  [11:0]  NRS , 


output reg          NRS_INC ,
output reg          schedule_ack ,   //this would be the 
output reg          NAK_SCHEDULED,
output reg   [11:0] req_seq_num, // the seq number to be given to the DLCSM to start an ack/nak
//-------------------outs for the transaction layer --------------------------------------------------------
output reg   [127:0] Data_o   ,
output reg           Data_vld , 
output reg           Data_end ,
output reg   [5:0]   Data_len  ,
output reg           lat_timer_start                


);


// functions of the sequence checker 
/*
1- check for the incoming tlp's sequence number  --first must wait for the lcrc validation 
2-  forward the tlp to transaction layer
3-  increment the NRS "increments the NEXT_RCV_SEQ counter, and schedules an Ack. "
*/ 
//---------latching signals-----------------------
logic [15:0] received_tlp_seq ; 
reg   [15:0] received_tlp_seq_reg; 
logic [255:0] tlp_payload ; 
reg   [261:0] tlp_payload_buff [1:0] ;  //256 bit max tlp + 
logic   start_transmitting ;  
logic  [127:0] TLP_Dmux_o_reg; 

logic   [11:0]  req_seq_num_reg;
//----------------buff control signals -------------------
logic w_ptr,w_ptr_c; 
logic r_ptr,r_ptr_c; 
logic wr_en; 
logic rd_en;

logic short_tlp ;
//-----------------
logic [2:0] trans_segs ; //counter to track the segements transmitted  
logic [2:0] receive_segs ; //counter to track the segements received 

logic [5:0] expected_len ;
assign expected_len = Dmux_o_len - 6; 

logic tlp_end; 
logic NAK_SCHEDULED_reg ;
typedef enum {

idle ,
receive_1, 
receive_2 ,
compare_chk 
}state_w; 

state_w current_state , next_state ;

typedef enum {
trans_1,
trans_2

}state_t; 

state_t curr_s,nxt_s ;


always@(posedge clk or negedge rst) 
begin 
  if(!rst)  begin 
       current_state<=idle ; 
       received_tlp_seq_reg<=0; 
       curr_s <= trans_1 ; 
       NAK_SCHEDULED_reg<=0;
       req_seq_num_reg<=0;
  end 

  else  
  begin 
    current_state <= next_state ; 
    received_tlp_seq_reg<= received_tlp_seq; 
    curr_s <= nxt_s; 
    NAK_SCHEDULED_reg<=NAK_SCHEDULED;
    req_seq_num_reg<=req_seq_num;
  
  end

end
///**/
always@(*) 
begin  
    received_tlp_seq= received_tlp_seq_reg ;
    start_transmitting = 0;
    wr_en = 0 ; 
    NRS_INC =0;
    schedule_ack =0 ;
    NAK_SCHEDULED = NAK_SCHEDULED_reg ;
    req_seq_num = req_seq_num_reg; 
    receive_segs =0 ; 
    tlp_end=0; 
    lat_timer_start =0 ;
case (current_state)  

 idle: begin  
       if(Dmux_vld_tlp)  
        begin   
            received_tlp_seq = TLP_Dmux_o[127 :112] ;  //first 16 bits of seq_num 
            wr_en =1 ;  

           receive_segs =1; //++
           // tlp_payload_buff[w_ptr][255:144] = TLP_Dmux_o[111:0] ; // first 112 bits of the first128 tlp 
          // tlp_payload[255:144] = TLP_Dmux_o[111:0] ;
            next_state = receive_1 ;
        end  
        else  begin 
         next_state = idle ; 
         wr_en = 0 ;
        end
 end 

   receive_1 : begin 
            if(Dmux_vld_tlp)  
            begin   
                wr_en =1;
                if(Dmux_o_end)  begin  
                  next_state = compare_chk ;
                 // tlp_payload_buff[w_ptr][143:128] = TLP_Dmux_o[127:112]  ;
                 // tlp_payload[143:128] = TLP_Dmux_o[127:112]  ;
                  tlp_end =1; 
                 // tlp_payload_buff[w_ptr][127:0] = 128'b0;  
                  //tlp_payload[127:0] = 128'b0;   
                  receive_segs = 2 ;
                end
                else  begin 
                    next_state =receive_2 ;
                    //tlp_payload_buff[143:16] = TLP_Dmux_o ; 
                   // tlp_payload[143:16] = TLP_Dmux_o ; 
                    receive_segs = 3 ;
                end
            end   
            else  begin 
            next_state = idle ;
             wr_en =0;
            end
   end

   receive_2 : begin  
            if(Dmux_vld_tlp) begin  
                wr_en =1; 
                next_state =compare_chk ; 
               // tlp_payload[15:0] = TLP_Dmux_o[127:112] ;  
                receive_segs = 4;
            end 

            else  begin 
            next_state = idle ;  
            wr_en = 0;
            end
   end

 // we could compare the 2 seqs at the first state but this has no meaning as the lcrc checker must validate the packet first
    compare_chk : begin   
        next_state = idle ;
        wr_en =0;
         if(LCRC_chk_vld_tlp)  
         begin  
            if(received_tlp_seq == {4'b0,NRS} )  begin  
              schedule_ack =1 ;  
              lat_timer_start =1;
              start_transmitting =1 ;  
              NRS_INC=1;  
              req_seq_num = received_tlp_seq ; 
              NAK_SCHEDULED = 0; 
            end
            else if (received_tlp_seq < {4'h0,NRS})  begin //duplacated packets   
              schedule_ack = 1;  
              req_seq_num = NRS - 1 ;
              start_transmitting = 0 ;  //packet will be ignored  
              NAK_SCHEDULED = 0;
            end
            else  begin   
             NAK_SCHEDULED =1 ; 
             req_seq_num  =  NRS - 1  ;  //missing tlp ---> initiate a nak  [handle first packet "sequenc 0" error page]
             start_transmitting = 0 ;    //packet will be discarded 
            end  

         end 
        else   begin  
         NAK_SCHEDULED =1; 
         req_seq_num = received_tlp_seq;
        end

    end   

    default : begin  
        wr_en = 0 ;
        next_state = idle ;
        NRS_INC =0 ; 
        schedule_ack = 0 ; 
        NAK_SCHEDULED = NAK_SCHEDULED_reg;
        req_seq_num = req_seq_num_reg ; 
        tlp_end=0; 
        lat_timer_start= 0;
        
    end 
endcase 
end 


always @(*)  
begin 
    rd_en = 0 ; 
    short_tlp =0; 
    trans_segs =0 ;
   case(curr_s)
    trans_1: begin   
        if(start_transmitting)  
        begin    
              trans_segs = 1 ;  
              rd_en = 1; 
              if(tlp_payload_buff[r_ptr][261:256] == 16) begin
              nxt_s  = trans_1 ;  
              short_tlp = 1 ;
              end
              else  
              nxt_s = trans_2 ; //len =32
        end 
        else          
        begin  
            nxt_s = trans_1 ;
            rd_en = 0 ;
        end 
    end 
     trans_2 :  begin  
        trans_segs = 3'd2 ; 
        rd_en =1 ;   
        nxt_s =trans_1 ;  
    end
    default : begin  
      rd_en = 0 ;
      short_tlp = 0 ; 
      trans_segs = 0 ;

    end
   endcase 
end
 

 always@(posedge clk)  begin  

    if (!rst)  begin 
         for(integer i=0; i<2; i=i+1)
        tlp_payload_buff[i] <= {256{1'b0}}; 
        w_ptr <= 0 ; 
        r_ptr <= 0 ; 
        Data_vld <= 0;
        Data_o<=128'b0 ;  
        Data_len<=0;
        Data_end<=0;
        TLP_Dmux_o_reg<=0;

    end  

    else   
      begin 

        TLP_Dmux_o_reg<=TLP_Dmux_o;
        case(receive_segs)   
        
        3'd1:   begin 
        if(wr_en) begin 
           tlp_payload_buff[w_ptr][255:144] <= TLP_Dmux_o[111:0] ;  
           tlp_payload_buff[w_ptr][261:256] <= Dmux_o_len ;
        end
        end
        3'd2: begin 
        if(wr_en) begin 
           tlp_payload_buff[w_ptr][143:128] <= TLP_Dmux_o[127:112]  ; 
           tlp_payload_buff[w_ptr][127:0] <= 128'b0;   
           if(tlp_end) begin 
                  w_ptr++ ;
            end   
        end
        end
        3'd3:  begin  
          if(wr_en) begin 
            tlp_payload_buff[w_ptr][143:16] <= TLP_Dmux_o ;
          end
        end 
        3'd4 : begin  
          if(wr_en) begin 
            tlp_payload_buff[w_ptr][15:0] <= TLP_Dmux_o[127:112] ;   
            w_ptr++ ;
          end
        end
        endcase 
      end
     
      case(trans_segs)  
        3'd0: begin 
             Data_vld <=0;  
             Data_o<=0; 
             Data_end<=0;  
             Data_len<=0;
        end
        3'd1 : begin  
          if (rd_en) begin 
            Data_o  <= tlp_payload_buff[r_ptr][255:128] ;   
            Data_len <= tlp_payload_buff[r_ptr][261:256] ;
            Data_vld  <=1; 
            if(short_tlp)  begin 
              r_ptr++;
              Data_end <=1;
            end
            else    begin 
             Data_end <=0; 
            end 
          end
        end
        3'd2 :  begin  
          if (rd_en) begin  
            Data_o  <= tlp_payload_buff[r_ptr][127:0] ;   
            Data_vld <=1;  
            r_ptr++; 
            Data_end<=1;
          end
        end
        endcase
 end


endmodule 