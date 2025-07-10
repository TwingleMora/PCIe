module REP_BUFFER_TOP #(
 parameter  entry_width = 310,   
              buff_depth = 256, 
              seq_num_width = 12,
              tlp_mux_in_width = 128,
              lcrc_width = 32 ,
              max_addr_size = 8    

)

(

    input wire                          clk ,rst ,
    input wire                          time_out,
    input wire  [seq_num_width-1:0]     ack_nak_seq_num,
   input wire    [tlp_mux_in_width-1:0]  tlp_mux_out ,
    input wire                          ack_forward_progress, 
    input wire                          nak_forward_progress, 

    input wire                           tlp_coming, 
    input wire                           lcrc_valid,
    input  wire                         tlp_mux_valid, 

    input wire                           tlp_end , //from transaction layer with the last valid 128 bits of tlp
    input wire    [5:0]                  TLP_MUX_LEN ,
    output reg  mem_full,mem_empty,
    output reg purge_tlps,
    output reg [8:0] unack_tlp_count, 
    output wire mem_almost_full,                
    output wire mem_almost_empty,               
    output wire mem_overflow,                   
    output wire mem_underflow,   
    output wire [127:0] mem_data_out   ,

    output wire    [1:0]   mux_sel ,
    output wire            tlp_mux_start ,
    output wire            lcrc_start ,
    output wire    [1:0]   lcrc_ctrl ,
    output wire            rb_tlp_valid,

    output wire        NTS_icr ,
    output wire        skip_256 ,
    output wire        busy ,
    output wire   [5:0] O_LEN,
    output wire      TLP_END_RB   //for the arbiter

);

wire [entry_width-1:0] mem_data_in;
wire mem_rd_en, mem_wr_en;
wire [max_addr_size-1:0] mem_wr_ptr, mem_rd_ptr; 

wire    [15:0]  current_seq_num; // sequence number of the old rd_ptr "before the ack/nak"

wire [2:0] segment_count; 
 REP_BUFFER_MEM #(.entry_width(entry_width), .buff_depth(buff_depth),.max_addr_size(max_addr_size)) U0_rep_buff_mem (
.clk(clk),
.rst(rst),
.data_in(mem_data_in),
.rd_en(mem_rd_en),
.wr_en(mem_wr_en),
.wr_ptr(mem_wr_ptr),
.rd_ptr(mem_rd_ptr),
.segment_count(segment_count),
.count(unack_tlp_count),
.data_out(mem_data_out),
.full(mem_full),
.empty(mem_empty),
.almost_full(mem_almost_full),
.almost_empty(mem_almost_empty),
.overflow(mem_overflow),
.underflow(mem_underflow),
.data_o_vlid(rb_tlp_valid),
. O_LEN(O_LEN),
.current_seq_num(current_seq_num),
.TLP_END_RB(TLP_END_RB)
 );

rep_buffer #(.seq_num_width(seq_num_width),.tlp_mux_in_width(tlp_mux_in_width),.lcrc_width(lcrc_width), .buff_depth(buff_depth),.entry_width(entry_width)) rep_buffer_inst (
.clk(clk),
.rst(rst),
.mem_full(mem_full),
.mem_empty(mem_empty),
.time_out(time_out),
.ack_nak_seq_num(ack_nak_seq_num),

.tlp_mux_out(tlp_mux_out),
.tlp_coming(tlp_coming),
.lcrc_valid(lcrc_valid),
.tlp_end(tlp_end),
.tlp_mux_valid(tlp_mux_valid),
.ack_forward_progress(ack_forward_progress),
.nak_forward_progress(nak_forward_progress),
.current_seq_num(current_seq_num),
.TLP_MUX_LEN(TLP_MUX_LEN),
.wr_en(mem_wr_en),
.rd_en(mem_rd_en),
.purge_tlps(purge_tlps),
.wr_ptr(mem_wr_ptr),
.rd_ptr(mem_rd_ptr),
.segment_count(segment_count),
.unack_tlp_count(unack_tlp_count),
.data_out(mem_data_in),
//.tlp_complete(tlp_complete)
.mux_sel(mux_sel),
.tlp_mux_start(tlp_mux_start),
.lcrc_start(lcrc_start),
.lcrc_ctrl(lcrc_ctrl),
.NTS_icr(NTS_icr),
.skip_256(skip_256),
.busy(busy)
);


endmodule

