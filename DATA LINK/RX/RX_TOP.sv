module DLL_RX_TOP (
    // Global signals
    input wire clk,
    input wire rst,
    input wire DL_Down,
    
    // Input interface
    input wire [127:0] I_DLL,
    input wire In_vld,
    input wire [5:0] In_len,
    input wire In_end,
    input wire In_type, 

    input wire  initiate_ack ,
    input wire  initiate_nak , 

    
    output wire [127:0] Data_o,
    output wire Data_vld,
    output wire Data_end,
    output wire [5:0] Data_len,
    
    output wire [11:0] req_seq_num,
    output wire schedule_ack,
    output wire NAK_SCHEDULED,
    
    output wire CRC_CHK_vld_dllp ,
    output wire ack_nak_time_out 
);

    // Demux outputs
    wire [127:0] TLP_Dmux_o;
    wire [63:0] DLLP_Dmux_o;
    wire Dmux_vld_dllp;
    wire Dmux_vld_tlp;
    wire Dmux_o_end;
    wire [5:0] Dmux_o_len;
    
    // Next Receive Sequence Counter
    wire [11:0] NRS ;
    
    // LCRC Checker outputs
    wire LCRC_chk_vld_tlp; 

    
    // Ack/Nak Timer outputs

    wire NRS_INC ; 
    wire lat_timer_start;

    // Instantiate Demux
    Demux demux_inst (
        .I_DLL(I_DLL),
        .In_vld(In_vld),
        .In_len(In_len),
        .In_end(In_end),
        .In_type(In_type),
        .TLP_Dmux_o(TLP_Dmux_o),
        .DLLP_Dmux_o(DLLP_Dmux_o),
        .Dmux_vld_dllp(Dmux_vld_dllp),
        .Dmux_vld_tlp(Dmux_vld_tlp),
        .Dmux_o_end(Dmux_o_end),
        .Dmux_o_len(Dmux_o_len)
    );
    
    // Instantiate LCRC Checker
    lcrc_chk lcrc_checker (
        .clk(clk),
        .rst(rst),
        .Dmux_vld_tlp(Dmux_vld_tlp),
        .TLP_Dmux_o(TLP_Dmux_o),
        .Dmux_o_len(Dmux_o_len),
        .Dmux_o_end(Dmux_o_end),
        .LCRC_chk_vld_tlp(LCRC_chk_vld_tlp)
    );
    
    // Instantiate Sequence Checker
    SEQ_CHKR seq_checker (
        .clk(clk),
        .rst(rst),
        .LCRC_chk_vld_tlp(LCRC_chk_vld_tlp),
        .Dmux_vld_tlp(Dmux_vld_tlp),
        .TLP_Dmux_o(TLP_Dmux_o),
        .Dmux_o_len(Dmux_o_len),
        .Dmux_o_end(Dmux_o_end),
        .NRS(NRS),
        .NRS_INC(NRS_INC),
        .schedule_ack(schedule_ack),
        .NAK_SCHEDULED(NAK_SCHEDULED),
        .req_seq_num(req_seq_num),
        .Data_o(Data_o),
        .Data_vld(Data_vld),
        .Data_end(Data_end),
        .Data_len(Data_len),
        .lat_timer_start(lat_timer_start)
    );
    
    // Instantiate Next Receive Sequence Counter
    next_rcv_seq_counter nrs_counter (
        .clk(clk),
        .rst(rst),
        .DL_Down(DL_Down),
        .NRS_INC(NRS_INC),
        .next_rcv_seq(NRS)
    );
    
    // Instantiate CRC Checker
    CRC_CHK crc_checker (
        .Dmux_vld_dllp(Dmux_vld_dllp),
        .DLLP_Dmux_o(DLLP_Dmux_o),
        .CRC_CHK_vld_dllp(CRC_CHK_vld_dllp)
    );
    
    // Instantiate Ack/Nak Latency Timer
    ack_nak_lat_timer latency_timer (
        .clk(clk),
        .rst(rst),
        .lat_timer_start(lat_timer_start),
        .ack_scheduled(initiate_ack),
        .nak_scheduled(initiate_nak),
        .ack_nak_time_out(ack_nak_time_out)
    );

endmodule