//Everything in nanosecond
// SIZE is problem.
// module Arbiter #(parameter WIDTH = 16, parameter DESC = 0) 
// (
//  input   logic [WIDTH-1:0] IN,
//  output  logic [WIDTH-1:0] OUT
// );

   
//    logic [WIDTH-1:0] OUT1;
//    logic [WIDTH-1:0] OUT2;

//    logic option;

// generate
    
// if(DESC==1) begin:descending_priority
//     always@(*)
//     begin
//         OUT[WIDTH-1] = IN[WIDTH-1];
//         OUT[WIDTH-2] = !IN[WIDTH-1] & IN[WIDTH-2];

//         for(int x = WIDTH-3; x>=0 ; x--)
//         begin
//             OUT[x] = ~|IN[WIDTH-1:x+1] & IN[x];
//         end

//     end
// end
// else
// begin: ascending_priority

//     always@(*)
//     begin
//         OUT[0] = IN[0];
//         OUT[1] = !IN[0] & IN[1];

//         for(int x = 2; x<WIDTH ; x++)
//         begin
//             OUT[x] = ~|IN[x-1:0] & IN[x];
//         end

//     end
// end
// endgenerate


// endmodule


// module Timer #(parameter WIDTH = 44)
// (
//     input  logic clk,
//     input  logic rst,

//     input  logic             sync_rst,
//     output logic [WIDTH-1:0] timer
    
// );


//     always@(posedge clk or negedge rst)
//     begin
//         if(!rst)
//         begin
//             timer[WIDTH-1] <= 1;
//             timer[WIDTH-2:0] <= 0;
//         end
//         else
//         begin
//             if(!sync_rst)
//             begin
//                 timer <= 0;
//             end
//             else
//             begin
//                 timer <= timer + 1;
//             end
//         end

//     end

// endmodule

module TX_NP_REQ_BUFF #(parameter TIMEOUT = 50_000,parameter PERIOD = 10, parameter DATA_WIDTH = 32, parameter MEMORY_DEPTH = 16)
(
input   logic               clk,
input   logic               rst,
input   logic               WR_EN,
input   logic               RD_EN,
//SEL                         
input   logic  [7:0]        TAG_IN,
input   logic  [7:0]        TAG_IDX,
input   logic  [15:0]       DEST_IN,
input   logic  [15:0]       DEST_IDX,
// input   logic  [14:0]    START_TIME,
// input   logic            EXIST
output  logic               EXIST,
output  logic               EMPTY,
output  logic               FULL,
output  logic   [31:0]      OUT

);




localparam TIMER_WIDTH = ($clog2(TIMEOUT/PERIOD) < 15) ? 15 : $clog2(TIMEOUT/PERIOD);
localparam real_size = ($clog2(TIMEOUT/PERIOD) <= 15) ? ($clog2(TIMEOUT/PERIOD))-11 : 15; 
// parameter TIMER_WIDTH = $clog2(TIMEOUT/PERIOD);


// logic  [14:0]  UPPER_TIME;
// | TAG_IN[7:0] | Destination[7:0]  | Start-Time[14:0]  | Free [1]  |
// |  8 bits  |     8 bits        |      15 bits      |   1 bit   |
// |---------- ------------------- ------------------- -----------
// | [31:25]  |     [24:16]       |      [15:1]       |    [0]    |


logic [DATA_WIDTH-1:0] mem [MEMORY_DEPTH];

// logic [MEMORY_DEPTH-1:0] FREE_X;

// logic [MEMORY_DEPTH-1:0] SAME_TAG_X;

logic [14:0]                START_TIME_X [MEMORY_DEPTH];
logic [14:0]                END_TIME_X [MEMORY_DEPTH];

logic [7:0]                 DESTINATION_X [MEMORY_DEPTH];

logic [7:0]                 TAG_X [MEMORY_DEPTH];

logic [31:0]                OUT_X [MEMORY_DEPTH];

logic [31:0]                OR_X [MEMORY_DEPTH];

logic [MEMORY_DEPTH-1:0]    ARB_FREE_X;



/* output */ logic [MEMORY_DEPTH-1:0]   FREE_X;
/* output */ logic [MEMORY_DEPTH-1:0]   SAME_TAG_X;
/* output */ logic [MEMORY_DEPTH-1:0]   TIME_OUT;

/* output */ logic [TIMER_WIDTH-1:0]    now_time;
/* output */ logic [14:0]               UPPER_TIME;
/* output */ logic [14:0]               NEXT_TIME;

//logic [14:0]             upper_now_time;


Arbiter #(.WIDTH(16), .DESC(0)) arbiter 
(
 /*input   logic [WIDTH-1:0]*/ .IN(FREE_X),
 /*output  logic [WIDTH-1:0]*/ .OUT(ARB_FREE_X)
);

Timer#(.WIDTH(TIMER_WIDTH)) timer 
(.clk(clk), .rst(rst), .sync_rst(1'b0), .timer(now_time));



always@(*)
begin
    FULL = (|FREE_X == 0)?1'b1:1'b0;
    EMPTY = (&FREE_X == 1)?1'b1:1'b0;
end

always@(*) begin
    for(int x = 0; x < 16 ; x++)
    begin
        if((TIMER_WIDTH-1-x) >= 0)
            UPPER_TIME[14-x]  = now_time[(TIMER_WIDTH-1)-x];
        else
            UPPER_TIME[14-x] = 0;
    end



end

always@(*)
begin
    // OR_X[0] = OUT_X[0];
    for(int x = 0 ; x < MEMORY_DEPTH; x++ ) begin
        
        TAG_X[x]            =   mem[x][31:24];
        DESTINATION_X[x]    =   mem[x][23:16];
        
        START_TIME_X[x]     =   mem[x][15:1];
        END_TIME_X[x]       =   START_TIME_X[x] + {(real_size){1'b1}};

        FREE_X[x]           =   mem[x][0];

        // OUT_X[x]            =   ((mem[x][31:24] == TAG_IN)&&(mem[x][0] == 0))? {TAG_X[x], DESTINATION_X[x], START_TIME_X[x], FREE_X[x]} : 0;

        SAME_TAG_X[x]       =   ((mem[x][23:16] == DEST_IDX)&&(mem[x][31:24] == TAG_IDX)&&(mem[x][0] == 0))? 1 : 0;
        
        TIME_OUT[x]         =   (({(mem[x][15:1] + {(real_size ){1'b1}})} == UPPER_TIME)&&(mem[x][0] == 0))? 1 : 0;

    end

    // for (int y = 1; y < MEMORY_DEPTH; y++) begin
    //     OR_X[y] = OR_X[y-1] | OUT_X[y];         
    // end


    // OUT = OR_X[MEMORY_DEPTH-1];    


end   


// always@(posedge clk or negedge rst) begin
//     if(!rst) begin
//         for(int xx = 0; xx < MEMORY_DEPTH; xx=xx+1) begin
//             mem[xx] <= 1'b1;    //b00000...01
//         end
//     end
//     else begin
//         // for(int xx = 0; xx < MEMORY_DEPTH; xx=xx+1) begin
//         //     mem[xx] <= 1'b1;    //b00000...01
//         // end
//     end
// end

always@(posedge clk or negedge rst) begin
    if(!rst) begin
        for(int x = 0; x < MEMORY_DEPTH; x++) begin
            mem[x] <= 1'b1;//b00000...01
        end
        NEXT_TIME<=0;
    end
    else begin
        for(int x = 0; x < MEMORY_DEPTH; x++) begin
            if(ARB_FREE_X[x]) begin
                if(WR_EN) begin
                    if(~EXIST) begin
                        mem[x] <= {TAG_IN, DEST_IN, UPPER_TIME, 1'b0};
                        NEXT_TIME<= UPPER_TIME + {real_size{1'b1}};
                    end
                end
            end
            else begin
                if(RD_EN&&SAME_TAG_X[x] || TIME_OUT[x]) begin
                    mem[x][0] <= 1'b1; 
                    // if(TIME_OUT[x]) begin

                    // end
                end


            end
        end
    end

end

always@(*)
begin

    EXIST = |SAME_TAG_X;

end


endmodule