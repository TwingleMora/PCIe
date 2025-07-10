module CRC_CHK (

    input wire          Dmux_vld_dllp,
    input wire  [63:0] DLLP_Dmux_o,
    output reg          CRC_CHK_vld_dllp
);  


parameter POLY = 16'h100B ;
integer i ;
bit din; 
wire [15:0] crc_received ;
reg [15:0] generated_crc ;
assign crc_received = DLLP_Dmux_o[31:16]; //last 16 bits are zeros"negelected"

always @(*) begin 
CRC_CHK_vld_dllp = 1'b0;
generated_crc = 16'hFFFF;  
  if(Dmux_vld_dllp) begin 
      for(i = 0 ; i < 32 ; i= i+1) begin 
            din  = DLLP_Dmux_o[63 - i] ^ generated_crc[15];  // MSB-first processing
            generated_crc = (generated_crc << 1);
            if (din) generated_crc = generated_crc ^ POLY;
      end

       if(generated_crc == crc_received) begin 
        CRC_CHK_vld_dllp = 1'b1; // valid crc
        //generated_crc = 16'hFFFF; // reset the crc output 
       end
       else 
        CRC_CHK_vld_dllp = 1'b0; // invalid crc 
  end
    else 
        generated_crc = 16'hFFFF;  

end





endmodule 

/*parameter POLY = 16'h100B;

integer i;
bit din;
reg [15:0] crc_reg;
reg [15:0] crc_received;

always @(*) begin
    CRC_CHK_vld_dllp = 1'b0;
    generated_crc        = 16'hFFFF;  // default CRC
    crc_reg          = 16'hFFFF;
    crc_received     = DLLP_Dmux_o[31:16];  // get the received CRC

    if (Dmux_vld_dllp) begin
        for (i = 0; i < 32; i = i + 1) begin
            din     = DLLP_Dmux_o[63 - i] ^ crc_reg[15];
            crc_reg = crc_reg << 1;
            if (din)
                crc_reg = crc_reg ^ POLY;
        end

        // Output and comparison
        if (crc_reg == crc_received) begin
            CRC_CHK_vld_dllp = 1'b1;
        end

        generated_crc = crc_reg;  // output the computed CRC (useful for debugging)
    end
end

endmodule*/