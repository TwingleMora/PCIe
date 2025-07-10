module next_rcv_seq_counter (
    input wire clk,                    
    input wire rst,                  
    input wire DL_Down,       // Data Link Layer active signal
    input wire NRS_INC,      // Good TLP received from RX buffer
    output reg [11:0] next_rcv_seq     // 12-bit Next Receive Sequence number
);

    
    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            next_rcv_seq <= 12'h000;
        end
        else if (DL_Down) begin
            next_rcv_seq <= 12'h000;
        end
        else if (NRS_INC) begin
            next_rcv_seq <= next_rcv_seq + 1'b1;
        end
    end

endmodule

