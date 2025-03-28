module CONF_SPACE 
    #(
    parameter            DW_COUNT          = 16,
    parameter reg [15:0] DEV_ID            = 16'b0000_0001_00000_000,
    parameter reg [15:0] VENDOR_ID         = 16'b0000_0001_00000_000,
    parameter reg [7:0]  HEADER_TYPE       = 8'b0000,
    
    parameter reg        BAR0EN            = 1,
    parameter reg        BAR0MM_IO         = 0,
    parameter reg        BAR0_32_64        = 2'b00,
    parameter reg        BAR0_NONPRE_PRE   = 1'b0,
    parameter            BAR0_BYTES_COUNT  = 4096,

    parameter reg        BAR1EN            = 0,
    parameter reg        BAR1MM_IO         = 0,
    parameter reg        BAR1_32_64        = 2'b00,
    parameter reg        BAR1_NONPRE_PRE   = 1'b0,
    parameter            BAR1_BYTES_COUNT  = 4096, //  

    parameter reg        BAR2EN            = 0,
    parameter reg        BAR2MM_IO         = 0,
    parameter reg        BAR2_32_64        = 2'b00,
    parameter reg        BAR2_NONPRE_PRE   = 1'b0,
    parameter            BAR2_BYTES_COUNT  = 4096 // 
    )
    (
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
    
    localparam BAR1_HardWired_MSB = $clog2(BAR1_BYTES_COUNT) - 1; 
    localparam BAR1_WRITTABLE_LSB = $clog2(BAR1_BYTES_COUNT);


    wire [31:0] default_values [DW_COUNT];

    assign default_values[0] = {DEV_ID, VENDOR_ID};
    assign default_values[1] = 0;
    assign default_values[2] = 0;
    assign default_values[3] = {HEADER_TYPE};
    //assign default_values[4] = 0;
    generate
        if(BAR0EN) begin : gen_bar0
            assign default_values[4] ={{28{1'b0}},BAR0_NONPRE_PRE, BAR0_32_64, BAR0MM_IO}; 
        end
        else begin: gen_bar0_disabled
            assign default_values[4] = 0;
	end

        if(BAR1EN) begin : gen_bar1
            assign default_values[5] ={{28{1'b0}},BAR1_NONPRE_PRE, BAR1_32_64, BAR1MM_IO}; 
        end
        else begin: gen_bar1_disabled
            assign default_values[5] = 0;
	end
        if(BAR2EN) begin : gen_bar2
            assign default_values[6] ={{28{1'b0}},BAR2_NONPRE_PRE, BAR2_32_64, BAR2MM_IO}; 
        end
        else begin: gen_bar2_disabled
            assign default_values[6] = 0;
	end
    endgenerate


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


    always@(posedge clk or negedge rst)
    begin
        if(!rst)
        begin
            for(int i = 0; i < DW_COUNT; i++)
            begin
                
                if(i<=4)
                    conf_space[i] <= default_values[i];
                else
                    conf_space[i] <= 0;
            end
        end
        else
        begin
            if(wr_en)
            begin
                    //read-only protection.
                    case(addr)
                    0: 
                    begin
                    //...
                    end
                    1:
                    begin
                        conf_space[1] <= data_in;
                    end
                    2:
                        conf_space[2] <= data_in;
                    3:
		     begin
                        conf_space[3][31:24] <= data_in[31:24];
      	                conf_space[3][15:0] <= data_in[15:0];
   		     end
                     4:
                        conf_space[4][31:BAR0_WRITTABLE_LSB] <= data_in[31:BAR0_WRITTABLE_LSB];
                    default:
                        conf_space[addr] <= data_in;
                endcase

            end
        end
    end

    always@(*)
    begin

    end



endmodule