`define DATA_WIDTH 32
`define ADDR_WIDTH 32

module WB (
    input                   stage_MEM_WB__WB_memtoreg,
    input                   stage_MEM_WB__WB_regwrite,
    input [`DATA_WIDTH-1:0] stage_MEM_WB__WB_memdata,
    input [31:0]            stage_MEM_WB__WB_regdata,
    input [4:0]             stage_MEM_WB__WB_rd_id,
    output                  WB__FU_RF_regwrite,
    output[4:0]             WB__FU_RF_rd_id,
    output [31:0]           WB__RF_data
);

assign WB__RF_data = stage_MEM_WB__WB_memtoreg?stage_MEM_WB__WB_memdata:stage_MEM_WB__WB_regdata;
assign WB__FU_RF_regwrite = stage_MEM_WB__WB_regwrite;
assign WB__FU_RF_rd_id    = stage_MEM_WB__WB_rd_id;

endmodule