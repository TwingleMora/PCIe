module TLP_MUX(
//------------inputs-------------------//
input wire           clk ,rst,
input wire  [127:0]  TLP_IN,
input wire           mux_start,  //this signal is coming from the rep_buffer to indicate that there is a tlp to be sent...and rep buffer gets it from the DLCMSM " dll fsm "
input wire  [11:0]   seq_num_in ,
input wire  [31:0]   lcrc ,
input wire  [5:0]    TLP_LEN ,
input wire  [1:0]    mux_sel , // 00 ==> nsn_transmit , 01 ==> first_tlp128 , 10 ===> last_tlp128 , 11 ==> lcrc_transmit 

//------------outputs-------------------//
output  reg [127:0]   mux_out, 
output  reg           tlp_mux_valid ,
output  reg           tlp_mux_end , 
output  reg   [5:0]   TLP_MUX_LEN

) ;
reg [5:0]   TLP_MUX_LEN_reg ;
reg [127:0] mux_o_comp ; 
reg [50:0] packets_count;
reg [50:0] packets_count_reg;
always @(posedge clk or negedge rst ) 
begin 
if (!rst) 
  begin 
     packets_count_reg <= 0 ; 
     TLP_MUX_LEN_reg<=0;

  end
  else begin 
    packets_count_reg <= packets_count ; // update the packet count 
    TLP_MUX_LEN_reg<=TLP_MUX_LEN ;
  end

end

always @(*) begin
    // Default values
    //mux_out = 128'b0;   //need to have a default value for the mux_out to avoid latches
    tlp_mux_valid = 1'b0;
    packets_count = packets_count_reg; // Reset the packet count  
    tlp_mux_end = 1'b0; 
    TLP_MUX_LEN = TLP_MUX_LEN_reg ;

    case (mux_sel) 
        
        2'b00: begin 
            mux_out = {116'b0, seq_num_in}; 
            TLP_MUX_LEN = TLP_LEN; 
            tlp_mux_valid = 1'b1;
        end

        2'b01: begin // first_tlp128
            mux_out = TLP_IN;
            tlp_mux_valid = 1'b1;
        end

        2'b10: begin // lcrc_transmit
            mux_out = {96'b0, lcrc};
            tlp_mux_valid = 1'b1;
            tlp_mux_end = 1'b1; // Indicate the end of the TLP transmission
            packets_count++ ;


        end
        default : begin 
               tlp_mux_valid = 0 ;
        end
    endcase
end
endmodule 
