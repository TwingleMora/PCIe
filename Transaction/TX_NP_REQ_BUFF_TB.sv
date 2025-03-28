//Everything in nanosecond
// SIZE is problem.



module TX_NP_REQ_BUFF_TB;

/* input */   bit            clk;
/* input */   logic          rst;

/* input */   logic          WR_EN;
/* input */   logic          RD_EN;

//SEL
/* input */   logic  [7:0]   TAG;

/* input */   logic  [7:0]   DEST;
// input   logic  [14:0]  START_TIME,
// input   logic          EXIST

/* output */  logic          EXIST;



/* output */  logic          EMPTY;

/* output */  logic          FULL;
              
              logic   [31:0] OUT;

TX_NP_REQ_BUFF #(.TIMEOUT(50_000), .PERIOD(10), .DATA_WIDTH(32), .MEMORY_DEPTH(16)) tx_np_req_buff
(
/* input   logic */          .clk(clk),
/* input   logic */          .rst(rst),

/* input   logic */          .WR_EN(WR_EN),
/* input   logic */          .RD_EN(RD_EN),

//SEL
/* input   logic  [7:0] */   .TAG(TAG),

/* input   logic  [7:0] */   .DEST(DEST),
// input   logic  [14:0]  START_TIME,
// input   logic          EXIST

/* output  logic */          .EXIST(EXIST),

// /* output  logic [MEMORY_DEPTH-1:0] */ .FREE_X(),

// /* output  logic [MEMORY_DEPTH-1:0] */ .SAME_TAG(),

// /* output  logic [MEMORY_DEPTH-1:0] */ .TIME_OUT(),

/* output  logic */                    .EMPTY(EMPTY),

/* output  logic */                    .FULL(FULL),

// /* output  logic  [14:0] */  .UPPER_TIME(UPPER_TIME),

// /* output logic [TIMER_WIDTH-1:0] */ .now_time(now_time),


// /* output logic [14:0] */   .NEXT_TIME()

/* output  logic   [31:0] */ .OUT(OUT)
);

always #100 clk = ~clk;

    task reset();
        rst<=0;
        RD_EN <= 0;
        WR_EN <= 0;
        @(posedge clk)
        rst<=1;
    endtask

    task save_tag();
        WR_EN <= 1;
        TAG <= 1;
        DEST <= 5;
        @(posedge clk)
        TAG <= 3;
        DEST <= 6;
        
        @(posedge clk)
        TAG <= 7;
        DEST <= 8;

        @(posedge clk)
        @(posedge clk)
        WR_EN <= 0;
        
    endtask

    task read_tag();
        RD_EN <= 1;
        TAG <= 1;
        @(posedge clk)
        TAG <= 3;
        @(posedge clk)
        RD_EN<=0;
    endtask



    initial begin
        reset();
        save_tag();
        read_tag();

        repeat(10000)
            @(posedge clk)

        $stop;

    end


endmodule