module Demux (
    input wire [127:0]       I_DLL,
    input wire               In_vld,
    input wire [5:0]        In_len,
    input wire               In_end,
    input wire               In_type,

    output reg [127:0]      TLP_Dmux_o,
    output reg [63:0]       DLLP_Dmux_o,
    output reg              Dmux_vld_dllp, 
    output reg              Dmux_vld_tlp,  
    output reg              Dmux_o_end,
    output reg [5:0]        Dmux_o_len
);

always @(*) begin 

    TLP_Dmux_o = 128'b0;
    DLLP_Dmux_o = 64'b0;
    Dmux_vld_dllp = 1'b0;
    Dmux_vld_tlp = 1'b0;
    Dmux_o_len = 6'b0;
    Dmux_o_end = 1'b0;

    if (In_vld) begin
        if (!In_type) begin
            Dmux_o_len = 6'd6; //6bytes 16 bit crc + 32 bit dllp  
            Dmux_vld_dllp = 1'b1;
            DLLP_Dmux_o = I_DLL[127:64];  
            Dmux_o_end = 1'b1;          
        end
        else begin 
            Dmux_o_len = In_len - 6;  
            Dmux_vld_tlp = 1'b1;
            TLP_Dmux_o = I_DLL;
            Dmux_o_end = In_end;         
        end
    end  
  else  begin 
    TLP_Dmux_o = 128'b0;
    DLLP_Dmux_o = 64'b0;
    Dmux_vld_dllp = 1'b0;
    Dmux_vld_tlp = 1'b0;
    Dmux_o_len = 6'b0;
    Dmux_o_end = 1'b0;
  end
end

endmodule