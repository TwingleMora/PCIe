module CONF_SPACE #(DW_COUNT = 32, DEV_ID = 0, VENDOR_ID = 0, HEADER_TYPE = 0, BAR0_BYTES_COUNT = 1024)    (
        input       logic                           clk,
        input       logic                           rst,
        input       logic                           wr_en,
        input       logic [31:0]                    data_in,
        input       logic [$clog2(DW_COUNT)-1:0]    addr,

        output      logic [31:0]                    data_out,  
        output wire logic [15:0]                    device_id,
        output wire logic [15:0]                    vendor_id,
        output wire logic [7:0]                     header_type,

        output wire logic [31:0]                    BAR0,
        output      logic [31:0]                    BAR0_END,
        output wire logic [31:0]                    BAR1,
        output wire logic [31:0]                    BAR2,
        output wire logic [7:0]                     BridgeSubBusNum,
        output wire logic [7:0]                     BridgeSecBusNum,
        output wire logic [7:0]                     BridgePriBusNum,

        output wire logic [7:0]                     BridgeIOLimit,
        output wire logic [7:0]                     BridgeIOBase,

        output wire logic [7:0]                     BridgeMemLimit,
        output wire logic [7:0]                     BridgeMemBase,

        output wire logic [7:0]                     BridgePrefMemLimit,
        output wire logic [7:0]                     BridgePrefMemBase,

        output wire logic [31:0]                    BridgePrefMemBaseUpper,
        output wire logic [31:0]                    BridgePrefMemLimitUpper,

        output wire logic [15:0]                     BridgeIOLimitUpper,
        output wire logic [15:0]                     BridgeIOBaseUpper

    );
    localparam BAR0_HardWired_MSB = $clog2(BAR0_BYTES_COUNT) - 1; 
    localparam BAR0_WRITTABLE_LSB = $clog2(BAR0_BYTES_COUNT);
    



    wire [31:0] default_values [DW_COUNT];

    assign default_values[0] = {DEV_ID, VENDOR_ID};
    assign default_values[1] = 0;
    assign default_values[2] = 0;
    assign default_values[3] = {HEADER_TYPE};
    assign default_values[4] = 32'h00_00_00_00;
    assign BAR0_END          = 32'h00_00_00_ff;

    //assign default_values[4] = 0;
    


    reg [31:0] conf_space [DW_COUNT];

    //logic [$clog2(BYTES_COUNT)-1:0]
    assign device_id                = conf_space[0][31:16];
    assign vendor_id                = conf_space[0][15:00];
    assign header_type              = conf_space[3][23:16];

    assign BAR0                     = conf_space[4];
    assign BAR1                     = conf_space[5];
    assign BAR2                     = conf_space[6];

    //Bridge
    assign BridgeSubBusNum          = conf_space[6][23:16];
    assign BridgeSecBusNum          = conf_space[6][15:8];
    assign BridgePriBusNum          = conf_space[6][7:0];


    assign BridgeIOLimit            = conf_space[7][15:8];
    assign BridgeIOBase             = conf_space[7][7:0];

    assign BridgeMemLimit           = conf_space[8][31:16];
    assign BridgeMemBase            = conf_space[8][15:0];

    assign BridgePrefMemLimit       = conf_space[9][31:16];
    assign BridgePrefMemBase        = conf_space[9][15:0];
    assign BridgePrefMemBaseUpper   = conf_space[10][31:0];
    assign BridgePrefMemLimitUpper  = conf_space[11][31:0]; 

    assign BridgeIOLimitUpper       = conf_space[12][31:16];
    assign BridgeIOBaseUpper        = conf_space[12][15:0];




endmodule