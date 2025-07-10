module crc16_32bit (
    input         crc_en,
    input  [31:0] data_in,   // 64-bit input
    output reg [15:0] crc_out // 16-bit CRC
);

// Polynomial: X^16 + X^12 + X^3 + X + 1 (0x100B)
parameter POLY = 16'h100B;  // Note: 0x100B = 0x1021 >> 1 (adjust for implementation)

reg [15:0] crc;
integer i;
bit din;


always @(*) begin 
    crc_out = 16'hFFFF;
    if (crc_en) begin 
           for (i = 0; i < 32; i = i + 1) begin  // Unrolls into 64 parallel steps
            din  = data_in[32 - i] ^ crc_out[15];  // MSB-first processing
            crc_out = (crc_out << 1);
            if (din) crc_out = crc_out ^ POLY;
        end
    end 
    else   begin 
        crc_out = 16'hFFFF; 
    end
end
/*

always @(posedge clk or negedge rst) begin
    if (!rst) begin
        crc_out <= 16'hFFFF;  // Initialize to all 1's
        crc <= 16'hFFFF;      // Initialize CRC register
    end 
        else  
        crc_out <= crc; 
end

*/

endmodule