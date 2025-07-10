module lcrc32_bit (
    input wire            clk,
    input wire            rst,
    
    input wire [127:0]    data_in,  // 176-bit input
    input wire [1:0]      ctrl ,    // comning from retry_buffer
    input wire             start , //this input from rep-buffer indicats that there is a seq_num and tlp to be sent this signal comes from the 
    input wire            tlp_end,
    input wire            skip_256,
    output reg [31:0] lcrc_out,
    output reg        lcrc_valid
);


 typedef enum 
{ 
    idle ,
    store_seq_num,
    store_tlp_128 ,
    store_tlp_256, 
    calc_lcrc
}state_t ; 

parameter POLY = 32'h04C11DB7;
reg [31:0] crc;
integer i;
bit din ;

state_t current_state , next_state ;

reg [271:0] data_collected ; // 256 tlp + 12 seq_num .
reg [271:0] data_collected_reg ; // 256 tlp + 12 seq_num .


 always @(posedge clk or negedge rst) begin
    if (!rst) begin
        current_state<=idle;
        lcrc_out <= 32'hFFFFFFFF;  // Initialize to all 1's
        crc <= 32'hFFFFFFFF;
      //  data_collected <= 0;
        lcrc_valid <= 1'b0;
        data_collected_reg <= 0;
    end  
    else begin 
    //crc <= lcrc_out;
    current_state <= next_state;
    data_collected_reg<= data_collected;
    end
end 


 always @(*) begin
    //crc = lcrc_out;  
    data_collected= data_collected_reg  ;
     lcrc_valid = 1'b0;
    lcrc_out = 32'hFFFFFFFF;
    
   case(ctrl)   //we need to make the case on control siganl
      2'b00 : begin 
        if(start)  begin
            data_collected[271:256] = {4'b0,data_in[11:0]}; // seq_num is 12 bits
            next_state = store_tlp_128; // go to next state to store the first TLP
        end 
        else  begin
            data_collected = data_collected_reg; 
            next_state = idle; // if not start, stay in idle state 
        end
        
       end 

      2'b01 : begin 
             data_collected[255:128] = data_in; // first_tlp is 128 bits
             data_collected[271:256] = data_collected_reg[271:256] ;
            if(tlp_end)  
            next_state = calc_lcrc ;  
             else  
             next_state = store_tlp_256 ;  
       
      end

        2'b10 : begin 
                data_collected[127:0] = data_in; // last_tlp is 128 bits 
                data_collected[255:128] = data_collected_reg[255:128] ;
                data_collected[271:256] = data_collected_reg[271:256] ; // seq_num is 12 bits
             next_state = calc_lcrc ; 
        end 

        2'b11 : begin  
                next_state = idle; 
                lcrc_valid = 1'b1;  
                if (skip_256)begin //When skip_256 is set, and you only want to calculate CRC on 140 bits:
                    for (i = 0; i < 144; i = i + 1) begin  
                     din = data_collected[271 - i] ^ lcrc_out[31];    //This is correct if and only if the first valid data bit is at data_collected[267] and you want to process MSB-first.  not 140 ---> u can see that on TX>LCRC>ttt
                     lcrc_out = (lcrc_out << 1);
                    if (din) lcrc_out = lcrc_out ^ POLY;
                end
                end
                else begin 
                    for (i = 0; i < 272; i = i + 1) begin  
                     din = data_collected[271 - i] ^ lcrc_out[31];  // MSB-first processing
                     lcrc_out = (lcrc_out << 1);
                    if (din) lcrc_out = lcrc_out ^ POLY;
                end
                end    
        end 

        default : begin 
            lcrc_valid = 1'b0;  
            lcrc_out = 32'hFFFFFFFF;
        end
   endcase
end 

/*
always @(*) begin 
    lcrc_valid = 1'b0;  
    llcrc_out = 32'hFFFFFFFF;

case (ctrl) 
  2'b00 : begin  
           if(start) begin 
            data_collected[267:256] = data_in[11:0];  

           end 
          end

   2'b01 : begin  
            data_collected[255:128] = data_in; 
   end

    2'b10 : begin  
            data_collected[127:0] = data_in; 
    end 

    2'b11 : begin  
            lcrc_valid = 1'b1;  
            for (i = 0; i < 268; i = i + 1) begin  // Unrolls into 176 parallel ops
                 din = data_collected[267 - i] ^ lcrc_out[31];  // MSB-first processing
                 lcrc_out = (lcrc_out << 1);
                if (din) lcrc_out = lcrc_out ^ POLY;
            end
    end
   
   default : begin 
            lcrc_valid = 1'b0;  
            lcrc_out = 32'hFFFFFFFF;
   end

endcase 

end
*/

endmodule