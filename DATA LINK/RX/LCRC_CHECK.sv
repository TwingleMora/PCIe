module lcrc_chk 

(

   input wire          clk ,rst ,
   input wire          Dmux_vld_tlp ,
   input wire  [127:0] TLP_Dmux_o ,
   input wire  [5:0]   Dmux_o_len ,
   input wire          Dmux_o_end , 

   output reg          LCRC_chk_vld_tlp 
   //output reg  [31:0]   LCRC_chk_o

); 

parameter POLY = 32'h04C11DB7;
reg [271:0] data_collected ; 
reg [271:0] data_collected_reg ; 
reg [31:0] lcrc_received;  
reg [31:0] lcrc_received_reg;  
reg [31:0] generated_lcrc;
integer i; 
bit din ; 
reg completed_data;

logic tlp_truncated; 


typedef enum 
{
idle ,
receive_1 , 
receive_2,
compute_lcrc
} state_t;

state_t current_state, next_state ;


always@(posedge clk or negedge rst) begin 
if(!rst) begin 
      current_state = idle ;   
      data_collected_reg <= 272'b0; 
      lcrc_received_reg <= 32'hFFFFFFFF; // reset the received lcrc
end
else  
begin 
    current_state = next_state ;
      data_collected_reg <= data_collected; // store the collected data for the next state 
      lcrc_received_reg <= lcrc_received; 

end

end
 always@(*) 
 begin 
   LCRC_chk_vld_tlp = 1'b0;
   generated_lcrc = 32'hFFFFFFFF;  
  // data_collected = 272'b0;  
   tlp_truncated = 1'b0; // default value 
   data_collected = data_collected_reg; 
   lcrc_received = lcrc_received_reg; 
   completed_data = 0; // default value
   
   case(current_state) 

      idle :  begin 
      if(Dmux_vld_tlp)     
        begin 
               data_collected[271:144] = TLP_Dmux_o ; 
               next_state = receive_1 ;
        end
        else  begin 
        next_state =idle ;  
        data_collected = data_collected_reg ; 
        end
      end


    receive_1 : begin 
         if(Dmux_vld_tlp) begin 
            //data_collected = {data_collected[271:144], TLP_Dmux_o};  //16 
             if(Dmux_o_end) begin  // lcrc 
                data_collected[143:128] = TLP_Dmux_o [127:112] ;  //"16bits left from the first 128"here we assume that the transmission is only 128TLP as if there a transmission of 256 the end signal
                //won't be provided at that cycle" as the end signal didn't appear at the clock cycle this means that the transmission without the lcrc solid 128 " even if there was zeros"invalid data" within transmission 
                data_collected[271:144] =data_collected_reg[271:144]; 
                lcrc_received = TLP_Dmux_o[111-:32] ; // the last 4 bytes are the lcrc
                 next_state = compute_lcrc ; 
                 tlp_truncated = 1 ;  // this mean tha the data collected is only 176 bits long
             end
             else begin 
                   // data_collected = {data_collected[271:144], TLP_Dmux_o}; //last 16 bits of them are the MSB of lcrc  ---> that gave an error 
                    data_collected[143:16] = TLP_Dmux_o;
                    data_collected[271:144] = data_collected_reg[271:144]; 
                    next_state = receive_2 ;
             end
         end
         else 
         next_state =idle ;

    end


    receive_2 :begin 
        if(Dmux_vld_tlp) begin 
                data_collected[15:0] = TLP_Dmux_o[127:112];  
                //data_collected[271:1]
                data_collected[143:16] = data_collected_reg[143:16]; 
                  data_collected[271:144] = data_collected_reg[271:144];
                lcrc_received = TLP_Dmux_o[111:80];    
                next_state = compute_lcrc ;

        end 
        else  
        next_state = idle ;

    end

    compute_lcrc : begin  
           next_state = idle ; 
            if(tlp_truncated)begin 
                  for (i = 0; i < 144; i = i + 1) begin  
                     din = data_collected[271 - i] ^ generated_lcrc[31];    //This is correct if and only if the first valid data bit is at data_collected[267] and you want to process MSB-first.  not 140 ---> u can see that on TX>LCRC>ttt
                     generated_lcrc = (generated_lcrc << 1);
                    if (din) generated_lcrc = generated_lcrc ^ POLY;
                end  
                if(generated_lcrc == lcrc_received) begin 
                     LCRC_chk_vld_tlp = 1'b1; // valid lcrc
                     generated_lcrc = 32'hFFFFFFFF; // reset the lcrc output  
                  end
                  else begin 
                     LCRC_chk_vld_tlp = 1'b0; // invalid lcrc
                     generated_lcrc = 32'hFFFFFFFF; // reset the lcrc output  
                  end

            end 

            else begin   
               completed_data =1 ; //just indication that we reached the completed case
                for (i = 0; i < 272; i = i + 1) begin  
                     din = data_collected[271 - i] ^ generated_lcrc[31];    //This is correct if and only if the first valid data bit is at data_collected[267] and you want to process MSB-first.  not 140 ---> u can see that on TX>LCRC>ttt
                     generated_lcrc = (generated_lcrc << 1);
                    if (din) generated_lcrc = generated_lcrc ^ POLY;
                end
                  if(generated_lcrc == lcrc_received) begin 
                        LCRC_chk_vld_tlp = 1'b1; // valid lcrc
                        //generated_lcrc = 32'hFFFFFFFF; // reset the lcrc output  
                     end
                     else begin 
                        LCRC_chk_vld_tlp = 1'b0; // invalid lcrc
                        //generated_lcrc = 32'hFFFFFFFF; // reset the lcrc output 
                     end
            end
        
    end

    default : begin 
        next_state = idle ; // default state
       // generated_lcrc = 32'hFFFFFFFF; // reset the lcrc output  
        LCRC_chk_vld_tlp = 1'b0; // reset the lcrc valid signal
       // data_collected = 272'b0; // reset the data collected
        //lcrc_received = 32'hFFFFFFFF; // reset the received lcrc
        tlp_truncated = 1'b0; // reset the truncated signal
    end
   endcase

 end


endmodule