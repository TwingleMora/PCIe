module dllp_creator (
  input wire clk,
  input wire rst,
  
  input wire [11:0] next_rcv_seq,  // expected packet num
  input wire [11:0] incoming_seq,  // actual packet num
  input wire tlp_error,
  input wire gen_ack,
  input wire gen_nak,
  // Power managementt inputs
  input wire pm_enter_l1,
  input wire pm_enter_l23,
  input wire pm_active_state_req,
  input wire pm_request_ack,
  // Flow Control Inputs
  input wire [2:0] fc_vc_id,         
  input wire [7:0] fc_header_credits, // free spae for header 
  input wire [11:0] fc_data_credits, // free space for data
  input wire [3:0] fc_dllp_type,     
  input wire fc_gen,            // Generate Flow Control DLLP
  
  // Vendor-Specific Inputs
  input wire [23:0] vendor_specific_data,
  input wire generate_vendor_specific,
  
  input wire [15:0] crc_in,
  input wire crc_valid,
  output reg crc_request, // request for crc calculation
  output reg [31:0] crc_data,
  
  output reg [63:0] dllp_packet,
  output reg dllp_valid,   // flag
  output reg [2:0] current_state,
  output reg [2:0] next_state,
  output reg [7:0] dllp_type,
  output reg [11:0] ack_nak_seq,
  output reg [7:0] saved_dllp_type
);
    
  // We have 4 groups (ack/nak-power management-flow control-vendor specific)
  
  localparam [2:0]
    IDLE = 3'b000,
    ACK_CALC_SEQ = 3'b001,
    NAK_CALC_SEQ = 3'b010,
    PM = 3'b011,
    FC = 3'b100,
    VENDOR = 3'b101,
    CALC_CRC = 3'b110,
    ASSEMBLE_DLLP = 3'b111;
    
  //reg [2:0] current_state;
 // reg [2:0] next_state;
  
  //i made a registers for groups specifications
  //reg [7:0] dllp_type;
  reg [31:0] dllp_core;
  //reg [11:0] ack_nak_seq;
  
  // Saved values to ensure consistency between state transitions (tb)
  reg [31:0] saved_dllp_data;
  
  // Control symbols (page 219 in specs)
  localparam [9:0] SDP_SYMBOL = 10'b0101_111100;
  localparam [9:0] END_SYMBOL = 10'b0101_011100;
  
  // DLLP type
  localparam [7:0]
    ACK_TYPE           = 8'h00,
    NAK_TYPE           = 8'h10,
    PM_ENTER_L1_TYPE   = 8'h20,
    PM_ENTER_L23_TYPE  = 8'h21,
    PM_ACTIVE_REQ_TYPE = 8'h23,
    PM_REQUEST_ACK_TYPE= 8'h24,
    VENDOR_TYPE        = 8'h30;
    
  // Flow control type
  localparam [7:0]
    FC_INIT_P_TYPE     = 8'h40,
    FC_INIT_NP_TYPE    = 8'h50,
    FC_INIT_CPL_TYPE   = 8'h60,
    FC_INIT2_P_TYPE    = 8'hC0,
    FC_INIT2_NP_TYPE   = 8'hD0,
    FC_INIT2_CPL_TYPE  = 8'hE0,
    FC_UPDATE_P_TYPE   = 8'h80,
    FC_UPDATE_NP_TYPE  = 8'h90,
    FC_UPDATE_CPL_TYPE = 8'hA0;
  
  always @(posedge clk or negedge rst) 
    begin
      if (!rst) 
       begin
         current_state <= IDLE;
         dllp_valid <= 0;
         crc_request <= 0;
         saved_dllp_type <= 0;
         saved_dllp_data <= 0;
        end 
      else 
       begin
        current_state <= next_state;
      
       // Save DLLP type and data so when wee transmitee to CALC_CRC
        if (current_state != next_state && next_state == CALC_CRC) begin
            saved_dllp_type <= dllp_type;
            saved_dllp_data <= dllp_core;
        end
    end
end
     
  always @(*)
   begin
    next_state = current_state;
    crc_request = 0;
    dllp_valid = 0;
    dllp_core = 0;
    dllp_type = 0;
      
    case (current_state)
      // In IDLE we select which group
      IDLE:
       begin
          if (pm_enter_l1 || pm_enter_l23 || pm_active_state_req || pm_request_ack)
               next_state = PM;
          else if (gen_ack)
              next_state = ACK_CALC_SEQ;
          else if (gen_nak)
              next_state = NAK_CALC_SEQ;
          else if (fc_gen)
              next_state = FC;
          else if (generate_vendor_specific)
              next_state = VENDOR;
          else
             next_state = IDLE;
       end
        
      // group 1: ack/nak 
      ACK_CALC_SEQ: 
       begin
        dllp_type = ACK_TYPE;
        // For aCK: if incoming_seq matches expected, use incoming_seq, else use next_rcv_seq-1
        if (incoming_seq == next_rcv_seq)
          ack_nak_seq = incoming_seq;
        else 
          ack_nak_seq = next_rcv_seq - 1;
       
            
        dllp_core = {20'h0, ack_nak_seq};
        next_state = CALC_CRC;
      end
        
      NAK_CALC_SEQ: begin
        dllp_type = NAK_TYPE;
        // For NAK, use next_rcv_seq - 1
        ack_nak_seq = next_rcv_seq - 1;
        dllp_core = {20'h0, ack_nak_seq};
        next_state = CALC_CRC;
      end
        
      // Group 2: power management
      PM: 
      begin
         dllp_type = PM_REQUEST_ACK_TYPE;
         dllp_core = 32'h0;
      if (pm_enter_l1)
       begin
        dllp_type = PM_ENTER_L1_TYPE;
       end 
      else if (pm_enter_l23)
       begin
        dllp_type = PM_ENTER_L23_TYPE;
       end 
      else if (pm_active_state_req)
       begin
        dllp_type = PM_ACTIVE_REQ_TYPE;
       end
             
        next_state = CALC_CRC;
    end
    
      // group 3: flow control
      FC: 
       begin
        case (fc_dllp_type)
          4'b0000: dllp_type = FC_INIT_P_TYPE;    // InitFC1-P
          4'b0001: dllp_type = FC_INIT_NP_TYPE;   // InitFC1-NP
          4'b0010: dllp_type = FC_INIT_CPL_TYPE;  // InitFC1-Cpl
          4'b0011: dllp_type = FC_INIT2_P_TYPE;   // InitFC2-P
          4'b0100: dllp_type = FC_INIT2_NP_TYPE;  // InitFC2-NP
          4'b0101: dllp_type = FC_INIT2_CPL_TYPE; // InitFC2-Cpl
          4'b0110: dllp_type = FC_UPDATE_P_TYPE;  // UpdateFC-P
          4'b0111: dllp_type = FC_UPDATE_NP_TYPE; // UpdateFC-NP
          default: dllp_type = FC_UPDATE_CPL_TYPE; // UpdateFC-Cpl 
        endcase
        
        dllp_core = {1'b0, fc_vc_id, fc_header_credits, 4'b0, fc_data_credits};
        next_state = CALC_CRC;
      end 
    
      // group 4: vendor specific
      VENDOR:
       begin
        dllp_type = VENDOR_TYPE;
        dllp_core = {vendor_specific_data, 8'h0};
        next_state = CALC_CRC;  
      end
    
      CALC_CRC: 
       begin
          case (current_state)
                ACK_CALC_SEQ, NAK_CALC_SEQ: 
                  begin
                    // Sequence number logic per spec
                    if (current_state == ACK_CALC_SEQ)
                     begin
                        if (incoming_seq == next_rcv_seq)
                            ack_nak_seq = incoming_seq;
                        else 
                            ack_nak_seq = next_rcv_seq - 1;
                    end
                    else 
                      begin // NAK_CALC_SEQ
                        if (tlp_error || (incoming_seq > next_rcv_seq) || (current_state == NAK_CALC_SEQ))
                            ack_nak_seq = next_rcv_seq - 1;
                      end
                    dllp_core = {8'h0, 4'b0, ack_nak_seq};
                end 
              endcase
                crc_data = {saved_dllp_type, saved_dllp_data[31:8]};
                crc_request = 1;
                 next_state = ASSEMBLE_DLLP;
         end
                
      ASSEMBLE_DLLP:
       begin
        if (crc_valid)
         begin
          dllp_valid = 1;
          if ((saved_dllp_type == ACK_TYPE) || (saved_dllp_type == NAK_TYPE)) 
           begin
            dllp_packet = {
            SDP_SYMBOL,           
            saved_dllp_type,      
            12'b0,                //reserved
            saved_dllp_data[11:0], 
            crc_in,               
            END_SYMBOL       
            };
          end 
       else 
        begin
         dllp_packet = {SDP_SYMBOL,saved_dllp_type,saved_dllp_data[31:8],crc_in,END_SYMBOL[5:0]};
        end
       next_state = IDLE;
      end
      end
    endcase
  end

endmodule