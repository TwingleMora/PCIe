class Transaction;

rand logic        WrEn; 
rand logic        RdEn;
rand logic [31:0] DataIn;


logic [31:0] DataOut;
logic        Full; 
logic        Empty;




endclass

module FIFOV3_TB;
int passed=0, failed =0;


localparam PTR_WIDTH = 4;

bit        clk; 
logic        rst;
logic        WrEn; 
logic        RdEn;
logic [31:0] DataIn;
logic [31:0] DataOut;
logic        Full; 
logic        Empty;

always #5 clk = ~clk;
localparam DEPTH = 6;

FIFOV3 #(.DEPTH(DEPTH)) DUT (.clk(clk), .rst(rst), .WrEn(WrEn), .RdEn(RdEn), .DataIn(DataIn), .DataOut(DataOut), .Full(Full), .Empty(Empty));


task Drive;
    Transaction t;
    t = new();
    rst = 0;
    #1
    rst = 1;

    forever begin
        @(posedge clk)
        t.randomize();
        WrEn <= t.WrEn;
        RdEn <= t.RdEn;
        DataIn <= t.DataIn;
    end

endtask


task Monitor;
Transaction t;
t = new();
forever
begin
@(posedge clk);
t.DataIn = DataIn;
t.WrEn = WrEn;
t.RdEn = RdEn;
@(negedge clk);
t.DataOut = DataOut;
t.Full = Full;
t.Empty = Empty;
Scoreboard(t);
end

endtask

reg [31:0] mem [$];
bit ExpFull, ExpEmpty;
//reg [31:0] ExpDataOut = 0;
//or
reg [31:0] ExpDataOut;
task Scoreboard(Transaction t);
    //ExpDataOut = 0;
    if(t.WrEn)
    begin
        if(mem.size()<DEPTH)
            mem.push_back(t.DataIn);
    end
    if(t.RdEn)
    begin
        if(mem.size()>0)
            ExpDataOut = mem.pop_front();
    end

    ExpFull = (mem.size() == DEPTH);
    ExpEmpty = (mem.size() == 0);

    $display("\n\n==========START============");
    $display("DUT: ");
    DisplayDUT();
    $display("\nTB:");
    DisplayMEM();
    
    assert(t.DataOut === ExpDataOut)
    begin
        $display("Passed.");
        passed++;
    end
    else
    begin
        $error("Failed.");
        failed++;
    end    

    $display("\n==========END============");
endtask

task DisplayMEM;
    foreach(mem[i])
        begin
            $display("%h", DUT.mem[i]);
        end
    $display("ExpectedOutput: %h", ExpDataOut);
endtask

task DisplayDUT;

    foreach(DUT.mem[i])
    begin
        if(DUT.WrAddr == i && DUT.RdAddr == i)
            $display("%h <- (WrPtr) (RdPtr) [DataIn: %h | DataOut: %h]",DUT.mem[i], DataIn, DataOut);
        else if(DUT.WrAddr == i)
            $display("%h <- (WrPtr) [DataIn: %h]",DUT.mem[i], DataIn);
        else if(DUT.RdAddr == i)
            $display("%h <- (RdPtr) [DataOut: %h]",DUT.mem[i], DataOut);
        else 
            $display("%h", DUT.mem[i]);
    end

endtask

initial
begin
    fork
        Drive();
        Monitor();
    join_none
    #1000;
    $display("Passed: %d, Failed: %d", passed, failed);
    $stop;
end

endmodule
