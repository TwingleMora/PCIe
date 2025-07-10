module REP_BUFFER_MEM #(
    parameter entry_width = 310,   //assume 32 bytes for tlp (pl+hdr) + 2bytes for seq_num + 4 byte crc = 38 bytes + length 9 bit 
              buff_depth = 256, // 2^8 ; 8 bit pointer
              max_addr_size = 8 // 8 bit pointer
)

( 
    input wire clk,
    input wire rst,
    input wire [entry_width-1:0] data_in,
    input wire      rd_en, wr_en,
    input wire  [max_addr_size-1:0]     wr_ptr, rd_ptr,
    input wire [max_addr_size:0] count,  //it has the same bits as the depth so we can equl them "extra bit to distinguish between full & empty flags"
    input wire  [2:0] segment_count,

    output reg [127:0]   data_out,
    output reg                   data_o_vlid,
    output reg [15:0] current_seq_num,
    output reg   full, empty,
    output reg almost_full, almost_empty,
    output reg overflow, underflow ,
    output reg   [5:0] O_LEN ,
    output reg          TLP_END_RB
);
 //to store the current sequence number
reg [entry_width-1:0] buff_mem [buff_depth-1:0] ;
//reg [max_addr_size-1:0] i ; //that cost me one night to figure out that i should use integer instead of reg
integer i ;
reg [entry_width-1:0] data_o_;
//always block to handle the write process 

always @(*) begin 
    current_seq_num = buff_mem[rd_ptr][303 -: 16]; 
end

always @(posedge clk or negedge rst) begin 

    if (!rst)
    begin 
        for(i=0; i<buff_depth; i=i+1)
        buff_mem[i] <= {entry_width{1'b0}};
       // wr_ptr <= 0; //first write operation will be at the first address
        overflow <= 0;
    end
    else if (wr_en) begin  
            buff_mem[wr_ptr] <= data_in;
            //wr_ptr <= wr_ptr + 1;
    end
    
    else  begin 
        if (wr_en && full)
            overflow <= 1;             
        else
            overflow <= 0;
    end

end

//always block to handle the write process
always @(posedge clk or negedge rst) begin 
    
        if (!rst)
        begin 
            //rd_ptr <= 0; //first read operation will be at the first address
            underflow <= 0;
            data_out<= 0 ;
            data_o_vlid <= 0;  
            O_LEN <= 0 ; 
            TLP_END_RB<=0;
           // current_seq_num <= 0;
        end
        else if (rd_en)  begin  //&&!empty ??? the rd_en wont be if the buffer is empty as  wont enter retransmitting state due to "|count" condition  
           O_LEN <= buff_mem[rd_ptr][309:304];
           
            case(segment_count) 

            2'b01 : begin   
                data_out <= buff_mem[rd_ptr][303:176]; 
                TLP_END_RB<=0;
                data_o_vlid <=1;
            end
            2'b10:  begin 
                data_o_vlid <=1; 
                TLP_END_RB<=0;
                data_out <= buff_mem[rd_ptr][175:48];
            end
            2'b11:  begin 
                data_o_vlid <=1;
                TLP_END_RB<=1 ;
                data_out <= {buff_mem[rd_ptr][47:0],80'b0};
            end
            endcase
               // data_out <= buff_mem[rd_ptr]; 
                 //assuming the first 16 bits are the length of the data
                //rd_ptr <= rd_ptr + 1;
                
                 //current_seq_num <= buff_mem[rd_ptr][303 -: 16];
        end

        else  begin  
            data_o_vlid <= 0;
            TLP_END_RB<=0;
            if (rd_en && empty)
                underflow <= 1;             
            else
                underflow <= 0;
        end

end
/*always @(posedge clk or negedge rst) begin 
    if (!rst)
        current_seq_num <= 0;
    else 
        current_seq_num <= buff_mem[rd_ptr][303 -: 16]; //assuming the first 16 bits are the sequence number
end

//alwys block to handle the count
always @(posedge clk or negedge rst)
begin  
    if (!rst)
    begin 
        count <= 0;
    end
    else  
    begin
         //first two conditions are normal that increment  decrement the count when one of the enablers is high  
    if ({wr_en, rd_en} == 2'b10 && !full) //write operation
        count <= count + 1;
    else if ({wr_en, rd_en} == 2'b01 && !empty) //read operation
        count <= count - 1;

        //these other two conditions to handle the count when both enablers are high
    else if ({wr_en, rd_en} == 2'b11 && empty)  //write operation
        count <= count + 1;
    else if ({wr_en, rd_en} == 2'b11 && full)  //read operation
        count <= count - 1;
    
    end
end
*/

//assign full = (wr_ptr[max_addr_size] ! = rd_ptr[max_addr_size] && (wr_ptr[max_addr_size-1:0] == rd_ptr[max_addr_size-1:0]));
//assign empty = !full&& (wr_ptr == rd_ptr);

assign full = (count == buff_depth)? 1'b1 : 1'b0;
assign empty = (count == 0) ? 1'b1 : 1'b0;
//assign almost_full =( !full && (count[12:11]==2'b11 )) ? 1'b1 : 1'b0;  // 3/4 full 3072 'this according to the paper' 
//assign almost_empty = ( !empty && (count [12:11]==2'b01  ) )? 1'b1 : 1'b0; // 1/4 full 1024 'this due according the paper' 
    
endmodule