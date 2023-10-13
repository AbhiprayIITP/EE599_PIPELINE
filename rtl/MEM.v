`define DATA_WIDTH 32
`define ADDR_WIDTH 32

module MEM (
    input clk,
    input rst_n,
    input en,
    input stage_EX_MEM__MEM_regwrite,
    input stage_EX_MEM__MEM_memtoreg,
    input stage_EX_MEM__MEM_memread,
    input stage_EX_MEM__MEM_memwrite,
    input [31:0] stage_EX_MEM__MEM_alures,  
    input [31:0] stage_EX_MEM__MEM_store_data,
    input [4:0]  stage_EX_MEM__MEM_rd_id,
    output          MEM__HDUbr_memread,
    output [31:0]   MEM__EX_ID_for_help,
    output [4:0]    MEM__FUbr_rd_id,
    output          MEM__FU_FUbr_regwrite,
    output reg      stage_MEM_WB__WB_memtoreg,
    output reg      stage_MEM_WB__WB_regwrite,
    output reg [`DATA_WIDTH-1:0] stage_MEM_WB__WB_memdata,
    output reg [31:0] stage_MEM_WB__WB_regdata,
    output reg [4:0]  stage_MEM_WB__WB_rd_id 

);

wire [`DATA_WIDTH-1:0] rdata;

ram_sync_1r1w
#(
  .DATA_WIDTH (`DATA_WIDTH),
  .ADDR_WIDTH (`ADDR_WIDTH),
  .DEPTH( 2**`ADDR_WIDTH)
) memory (
  .clk(clk),
  .wen(stage_EX_MEM__MEM_memwrite),
  .wadr(stage_EX_MEM__MEM_alures[`ADDR_WIDTH-1:0]),
  .wdata(stage_EX_MEM__MEM_store_data[`DATA_WIDTH-1:0]),
  .ren(stage_EX_MEM__MEM_memread),
  .radr(stage_EX_MEM__MEM_alures[`ADDR_WIDTH-1:0]),
  .rdata(rdata)
);


//Forwarding and stall logic
assign MEM__HDUbr_memread = stage_EX_MEM__MEM_memread;
assign MEM__EX_for_help   = stage_EX_MEM__MEM_alures;
assign MEM__FUbr_rd_id    = stage_EX_MEM__MEM_rd_id;
assign MEM__FU_FUbr_regwrite = stage_EX_MEM__MEM_regwrite;


always@(posedge clk) begin
    if(!rst_n) begin
        stage_MEM_WB__WB_memtoreg <= 0;
        stage_MEM_WB__WB_regwrite <= 0;
        stage_MEM_WB__WB_memdata <= 0;
        stage_MEM_WB__WB_regdata <= 0;
        stage_MEM_WB__WB_rd_id <= 0;
    end
    else begin
        if(en) begin
            stage_MEM_WB__WB_regwrite <= stage_EX_MEM__MEM_regwrite;
            stage_MEM_WB__WB_memtoreg <= stage_EX_MEM__MEM_memtoreg;
            stage_MEM_WB__WB_memdata  <= rdata;
            stage_MEM_WB__WB_regdata  <= stage_EX_MEM__MEM_alures;
            stage_MEM_WB__WB_rd_id    <=  stage_EX_MEM__MEM_rd_id; 
        end
    end
end


endmodule
