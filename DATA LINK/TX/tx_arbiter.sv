module TX_ARBITER 


(


 input wire        clk ,rst ,

 //input wire    [1:0]     request , 

 input wire    [127:0]     rb_buff_o , 
 input wire                 rb_tlp_valid,
 input wire                 TLP_END_RB , // end of TLP transmission from replay buffer
 input wire    [5:0]             RB_BUFF_LEN , // end of TLP transmission from replay buffer

 input wire    [127:0]      tlp_mux_out ,
 input wire                 tlp_mux_valid , 
input wire                 tlp_mux_end , // end of TLP transmission from mux
input wire      [5:0]      TLP_MUX_LEN , // end of TLP transmission from mux


 //input wire      [63:0]      dll_mux_o ,  
 input wire      [31:0]      dllp_crtr_o ,  
 input wire      [15:0]      crc_o ,  
 input wire                 dllp_valid , 
 //input wire                 dllp_end , // end of DLLP transmission from mux (it is all done in one clk cyle )
 

 //--------request signals coming to arbiter-------------------------
//output    reg              arbit_busy ,

 output    reg   [127:0]    tx_out ,  
 output    reg              tx_out_valid  , 
 output    reg              tx_out_end ,
 output    reg              tx_type , // 1 --->  if tlp and 0 ---> if dllp 
 output    reg    [5:0]     tx_out_len 


)  ;


reg      [1:0]   grant ; 
wire     [2:0]   request_vctr ;

 reg      [127:0] tx_out_c;
reg              tx_out_valid_c;
reg              tx_type_c;  
reg [47:0]  latched_dllp;
reg          arbit_busy_c;
assign request_vctr = {dllp_valid,rb_tlp_valid,tlp_mux_valid};


typedef enum {
    Idle_dllp_trans, 
    rb_tlp_retrans,
    tlp_mux_trans
}state_t;  
state_t current_state , next_state ; 

// Priority: DLLP ---> RB_TLP ----> TLP_MUX
always @(*) begin
    //next_state = current_state;
     grant = 2'b00;
    // arbit_busy_c = arbit_busy;
    case (current_state)
        Idle_dllp_trans: begin
             grant = 2'b00;
            casex (request_vctr)
                3'b1xx: next_state = Idle_dllp_trans;
                3'b01x: next_state = rb_tlp_retrans;
                3'b001: next_state = tlp_mux_trans;
                default: next_state = Idle_dllp_trans;
            endcase
        end
        
        rb_tlp_retrans: begin
            //arbit_busy_c = 1'b1;
            grant = 2'b10;
            if (TLP_END_RB) 
                next_state = Idle_dllp_trans;
            else
                next_state = rb_tlp_retrans;
        end
        
        tlp_mux_trans: begin
            //arbit_busy_c = 1'b1;
             grant = 2'b11;
            if (tlp_mux_end) 
                next_state = Idle_dllp_trans;
            else
                next_state = tlp_mux_trans;
        end
        
        default: begin 
             next_state = Idle_dllp_trans;
             grant = 2'b00;

        end
    endcase
end

always @(posedge clk or negedge rst) begin
    if (!rst) begin
        current_state <= Idle_dllp_trans;  
       // arbit_busy <= 1'b0;
    end
    else begin
        current_state <= next_state;
        //arbit_busy <= arbit_busy_c;
    end
end



/*
always @(*) begin
    case (current_state)        //must be on the current state not the request vector ...so the o/p only changes when the state changes
        Idle_dllp_trans:       grant = 2'b00;
        dllp_trans:    grant = 2'b01;
        rb_tlp_retrans:  grant = 2'b10;
        tlp_mux_trans: grant = 2'b11;
        default:    grant = 2'b00;
    endcase
end
*/

always @(posedge clk or negedge rst) begin 

    if (!rst) begin 
        tx_out <= 128'b0; 
        tx_out_valid <= 1'b0;
        tx_type <= 1'b0; 
        //arbit_busy <= 1'b0; 
        latched_dllp<=0;
        tx_out_len<=0;
        tx_out_len<=0;
    end

    else begin   
        // arbit_busy <= arbit_busy_c; 
         latched_dllp<={dllp_crtr_o,crc_o};

        case (current_state)   //when casing on grant there the o/p changes output was  const at 0 ...why ?? ----> we'll see later  

            Idle_dllp_trans :begin 
            casex (request_vctr)
                3'b1xx: begin 
                    tx_out <= {80'b0,dllp_crtr_o,crc_o};
                    tx_out_valid <= 1;
                    tx_type <= 1'b0; // DLLP
                    tx_out_len<= 6; //6 bytes
                end
                3'b01x:begin
                      tx_out <= rb_buff_o;
                    tx_out_valid <= 1;
                    tx_type <= 1'b1; // TLP 
                    tx_out_len <= RB_BUFF_LEN ;
                end
                3'b001: begin 
                    tx_out <= tlp_mux_out;
                    tx_out_valid <= 1;
                    tx_type <= 1'b1; // TLP 
                    tx_out_len <= TLP_MUX_LEN ;
                end
                default: begin 
                 tx_out <= 128'b0; // no request 
                    tx_out_valid <= 1'b0;
                    tx_type <= 1'b0; 

                end
            endcase
            end

            rb_tlp_retrans: begin  
                tx_out <= rb_buff_o;
                tx_out_valid <= 1;
                tx_type <= 1'b1; // TLP
                tx_out_len <= RB_BUFF_LEN ;

            end

            tlp_mux_trans: begin  
                tx_out <= tlp_mux_out;
                tx_out_valid <= 1;
                tx_type <= 1'b1; // TLP
                tx_out_len <= TLP_MUX_LEN ;

            end

            default: begin 
                tx_out <= 128'b0; 
                tx_out_valid <= 1'b0;
                tx_type <= 1'b0;
            end
        endcase
    end


end 




endmodule 