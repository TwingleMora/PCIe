module RX_PNPC_BUFF_TB;

localparam DATA_WIDTH = 32;

bit clk;
logic rst;

/* input */  logic                     HEADER_DATA; // 0: Header; 1: Data
/* input */  logic [1:0]               P_NP_CPL; // Posted: 00; Non-Posted: 01; Completion: 11
/* input */  logic [DATA_WIDTH-1:0]    IN_TLP_DW;
/* input */  logic                     WR_EN;
/* input */  logic                     RD_EN;

/* input */  logic                     commit;
/* input */  logic                     flush;



/* output */ wire                      EMPTY;
/* output */ logic                     OUT_EMPTY;
/* output */ logic [DATA_WIDTH-1:0]    OUT_TLP_DW;      
/* output */ logic [DATA_WIDTH-1:0]    OUT_TLP_DW_COMB;  


RX_PNPC_BUFF rx_pnpc_buff (.*);

always #5 clk = ~clk;

task reset();
    WR_EN <= 0;
    RD_EN <= 0;
    P_NP_CPL <= 0;
    HEADER_DATA <= 0;
    commit <= 0;
    flush <= 0;
    rst <= 0;
    @(posedge clk)
    rst <= 1;
endtask

task write(int data, bit [1:0] p_np_cpl, bit header_data);
    @(posedge clk)
    IN_TLP_DW <= data;
    WR_EN <= 1;
    P_NP_CPL <= p_np_cpl;
    HEADER_DATA <= header_data;
    flush <= 0;
    commit <= 0;


endtask

task commit_buffer();
    @(posedge clk)
    WR_EN <= 0;
    flush <= 0;
    commit <= 1;
endtask

task flush_buffer();
    @(posedge clk)
    WR_EN <= 0;
    flush <= 1;
    commit <= 0;

endtask

task read();
    @(posedge clk)
    RD_EN <= 1;
endtask


task drive();

reset();

write('h11_11_11_11,0,0);
write('h22_22_22_22,0,1);
write('h33_33_33_33,1,1);
//flush_buffer();
commit_buffer();

write('h44_44_44_44,0,0);
write('h55_55_55_55,0,1);
write('h66_66_66_66,1,1);
flush_buffer();
@(negedge clk);

endtask




initial begin
drive();

repeat(10)begin
    read();

end
@(negedge clk);

$stop;

end

endmodule

