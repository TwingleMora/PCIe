module  ack_nak_lat_timer (
    input wire          clk,
    input wire          rst, 
    input wire          lat_timer_start , // flag from sequence checker to start the timer  
    input wire          ack_scheduled ,
    input wire          nak_scheduled,

    
    //input wire  [15:0]  RX_BUFF_CNT, //it is not a good idea to OR on the buff_cnt as the timer reset and it only starts counting again once the next TLP is successfully received
    // so we will use a flag from the 

    output reg             ack_nak_time_out             
);



reg [8:0]   timer ; 
reg [8:0]   timer_nxt ; 

reg  ack_nak_time_out_reg ;

parameter timer_limit =  300 ;


typedef enum  
{

    idle ,
    timer_run ,
    reset_halt ,
    reset_run  
}state_t;
state_t current_state, next_state ;


always @(posedge clk or negedge rst) begin 
   if(!rst)  
   begin  
        current_state <= idle ;
        timer <= 9'b0 ; 
        ack_nak_time_out_reg<= 0 ;
     end
     else begin 
        current_state <= next_state ;
        timer <= timer_nxt ; 
        ack_nak_time_out_reg <= ack_nak_time_out;
     end

end

always @(*) begin 
timer_nxt =timer ; 
ack_nak_time_out = ack_nak_time_out_reg; //default value
   case(current_state) 
    idle : begin   
        timer_nxt = 0 ;
        if(lat_timer_start)  //&& !nak_scheduled ??? 
         begin 
            next_state = timer_run ;
            timer_nxt ++ ;
         end
         else  
            begin 
                next_state = idle ;
                timer_nxt = 9'b0 ; // reset the timer
            end

    end 

    timer_run : begin 
        timer_nxt ++ ; // increment the timer   
        if(timer == timer_limit) begin  
            next_state = reset_halt ;
            ack_nak_time_out = 1 ;    
            timer_nxt = timer  ;
        end  
        else if (nak_scheduled) begin 
             next_state  =reset_halt ; 

        end
        else   begin 
            next_state = timer_run ;
            ack_nak_time_out = 0 ;  
        end
    end

    reset_halt : begin  //???????????check this state again 
        /* if(ack_scheduled) 
        begin 
        timer_nxt = 0 ;
        end 
        else  
         timer_nxt = timer ;  */  
         //timer == time_limit 
         timer_nxt = 0 ;
        if(lat_timer_start) 
        begin  
            next_state = timer_run ;  
        end
        else  
            next_state = idle ;



    end 

    default : begin 
                 next_state = idle ;
                 ack_nak_time_out = 0;
    end

   endcase 
end

endmodule 

/*
 50  --start lat_timer 
 [time_out]  --->ack 
 reset_halt 
 if(lat_timer_start) 


*/