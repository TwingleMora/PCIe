module rep_timer (
    input wire clk,
    input wire rst,
    input wire DL_Down,   //DL_Down  // Indicates if link layer is active
    input wire ack_forward_progress,
    input wire [8:0] unack_tlp_count,  // Replay buffer is 12-bit buffer (in TX paper)
    input wire nak_forward_progress,
    input wire link_train,   // A flag set when the training process of the link is currently ongoing
    //input wire tlp_transmitted, // Last symbol is transmitted
    output reg time_out
);

// PCIe 5.0 supports 32 Gigabits/sec/lane/direction of raw bandwidth
// Using simplified limits of the replay timer covered in specs
// Assuming the extended bit is clear and worst-case timeout of 31000 cycles

//reg time_out_c;
reg [14:0] timer;
reg [14:0] next_timer_value;

typedef enum logic [2:0] {
    idle,
    counting,
    reset_restart,
    reset_hold,
    hold
} state_t;

state_t current_state, next_state;

// State transition logic
always @(posedge clk or negedge rst) begin
    if (!rst) begin
        current_state <= idle;
                timer <= 15'd0;
    end
    else begin 
        current_state <= next_state;
                timer <= next_timer_value;
    end
end

// Next state logic
always @(*) begin
    next_state = current_state;
    case (current_state)
        idle: begin
            if (|unack_tlp_count)
                next_state = counting;
            else
                next_state = idle;
        end
        
        counting: begin
            if (ack_forward_progress && (|unack_tlp_count))
                next_state = reset_restart;
            else if (ack_forward_progress && !(|unack_tlp_count))
                next_state = reset_hold;
            else if (nak_forward_progress || time_out || DL_Down)
                next_state = reset_hold;
            else if (link_train)
                next_state = hold;
            else
                next_state = counting;
        end
        
        reset_restart: begin
            next_state = counting;
        end
        
        reset_hold: begin
            if (!DL_Down && !time_out && !nak_forward_progress)
                next_state = idle;
            else
                next_state = hold;
        end
        
        hold: begin
            if (!link_train && !DL_Down)
                next_state = idle;
            else
                next_state = hold;
        end
        
        default: next_state = idle;
    endcase
end

// Output logic
always @(*) begin
    time_out = 1'b0;
    next_timer_value = timer;

    case (current_state)
        idle: begin
            time_out = 1'b0;
            next_timer_value = 15'd0;
        end
        
        counting: begin
            next_timer_value = timer + 1;
            if (next_timer_value == 15'b111_1001_0001_1000)
                time_out = 1'b1;
        end
        
        reset_restart: begin
            next_timer_value = 15'd0;
        end
        reset_hold: begin
            next_timer_value = 15'd0;
        end
        
        hold: begin
            next_timer_value = timer;
        end
    endcase
end
/*
// Timer and timeout update
always @(posedge clk or negedge rst) begin
    if (!rst) begin
        time_out <= 1'b0;
        timer <= 15'd0;
    end else begin
        time_out <= time_out_c;
        timer <= next_timer_value;
    end
end
*/
endmodule
