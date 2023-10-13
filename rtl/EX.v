module EX (
    input clk,
    input rst_n,
    input en,
    input stage_ID_EX__EX_regwrite,
    input stage_ID_EX__EX_memtoreg,
    input stage_ID_EX__EX_memread,
    input stage_ID_EX__EX_memwrite,
    input stage_ID_EX__EX_alusrc,
    input [1:0] stage_ID_EX__EX_aluop,
    input stage_ID_EX__EX_regdst,
    input stage_ID_EX__EX_sys_en,
    input [31:0]stage_ID_EX__EX_rs_data,
    input [31:0]stage_ID_EX__EX_rt_data,
    input [4:0]stage_ID_EX__EX_rs_id,
    input [4:0]stage_ID_EX__EX_rt_id,
    input [4:0]stage_ID_EX__EX_rd_id,
    input [31:0]stage_ID_EX__EX_sign_ext,
    input [2:0]stage_ID_EX__EX_funct3,
    input sys__EX_done,
    output reg stage_EX_MEM__MEM_regwrite,
    output reg stage_EX_MEM__MEM_memtoreg,
    output reg stage_EX_MEM__MEM_memread,
    output reg stage_EX_MEM__MEM_memwrite,
    output reg [31:0] stage_EX_MEM__MEM_alures,
    output reg [31:0] stage_EX_MEM__MEM_store_data,
    output reg [4:0]  stage_EX_MEM__MEM_rd_id,
    
    output EX__HDUbr_regwrite,
    output EX__HDU_memread,
    output [4:0] EX__HDU_HDUbr_rd_id,
    output reg  EX_stall_for_sys,

    input  FU__EX_rs_wb,
    input  FU__EX_rs_mem,
    input  FU__EX_rt_wb,
    input  FU__EX_rt_mem,
    input [31:0]  WB__EX_for_help,
    input [31:0]  MEM__EX_for_help

);

localparam S0 = 0; // Going into stall if sys_en high
localparam S1 = 1; // Stall remains high in this state

wire [31:0] FMP1_out_rs;
wire [31:0] FMP1_out_rt;
wire [31:0] FMP2_out_rs;
wire [31:0] FMP2_out_rt;

wire [31:0] alu_in_rs;
wire [31:0] alu_in_rt;

reg  [31:0] alu_res;

assign FMP1_out_rs = (FU__EX_rs_wb)?WB__EX_for_help:stage_ID_EX__EX_rs_data;
assign FMP1_out_rt = (FU__EX_rt_wb)?WB__EX_for_help:stage_ID_EX__EX_rt_data;
assign FMP2_out_rs = (FU__EX_rs_mem)?MEM__EX_for_help:FMP1_out_rs;
assign FMP2_out_rt = (FU__EX_rt_mem)?MEM__EX_for_help:FMP1_out_rt;

assign alu_in_rs = FMP2_out_rs;
assign alu_in_rt = (stage_ID_EX__EX_alusrc)?stage_ID_EX__EX_sign_ext:FMP2_out_rt;


always@* begin
    case ({stage_ID_EX__EX_aluop,stage_ID_EX__EX_funct3})
        5'b00000: alu_res = alu_in_rs+alu_in_rt;
        5'b01000: alu_res = alu_in_rs+alu_in_rt;
        5'b10000: alu_res = alu_in_rs-alu_in_rt;
        5'b01001: alu_res = alu_in_rs<<alu_in_rt[4:0];
        5'b01101: alu_res = alu_in_rs>>alu_in_rt[4:0];
        5'b10101: alu_res = alu_in_rs>>>alu_in_rt[4:0];
        5'b01100: alu_res = alu_in_rs^alu_in_rt;
        5'b01110: alu_res = alu_in_rs|alu_in_rt;
        5'b01111: alu_res = alu_in_rs&alu_in_rt;
        default: alu_res = 32'b0;  //Could be X but don't wanna take risk on added bugs in silicon
    endcase
end

//Stall Logic for sys

reg curr_state , next_state;
always@(posedge clk) begin
    if (!rst_n) begin
        curr_state <= 0;
        next_state <= 0;
    end
    else begin
        curr_state <= next_state;
    end
end

always@* begin
    next_state = curr_state;
    EX_stall_for_sys = 0;
    case(curr_state) 
        S0: begin
                if (stage_ID_EX__EX_sys_en) begin
                    next_state = S1;
                    EX_stall_for_sys = 1;
                end
        end
        S1: begin
                if(!sys__EX_done)
                    EX_stall_for_sys = 1;
                else begin
                    EX_stall_for_sys = 0;
                    next_state = curr_state;
                end
        end
    endcase
end


// EX/MEM Stage Register

always@(posedge clk) begin
    if(!rst_n) begin
        stage_EX_MEM__MEM_regwrite <= 0;
        stage_EX_MEM__MEM_memtoreg <= 0;
        stage_EX_MEM__MEM_memread <= 0;
        stage_EX_MEM__MEM_memwrite <= 0;
        stage_EX_MEM__MEM_alures <= 0;
        stage_EX_MEM__MEM_store_data <= 0;
        stage_EX_MEM__MEM_rd_id <= 0;
    end
    else begin
        if(en) begin
            stage_EX_MEM__MEM_regwrite <= EX_stall_for_sys?0:stage_ID_EX__EX_regwrite;
            stage_EX_MEM__MEM_memtoreg <= EX_stall_for_sys?0:stage_ID_EX__EX_memtoreg;
            stage_EX_MEM__MEM_memread  <= EX_stall_for_sys?0:stage_ID_EX__EX_memread;
            stage_EX_MEM__MEM_memwrite <= EX_stall_for_sys?0:stage_ID_EX__EX_memwrite;
            stage_EX_MEM__MEM_alures   <= alu_res;
            stage_EX_MEM__MEM_store_data <= FMP2_out_rt;
            stage_EX_MEM__MEM_rd_id      <= stage_ID_EX__EX_regdst?stage_ID_EX__EX_rd_id:stage_ID_EX__EX_rt_id; 
        end
    end
end

// Signals to HDU and HDU_Br

assign EX__HDU_HDUbr_rd_id = stage_ID_EX__EX_regdst?stage_ID_EX__EX_rd_id:stage_ID_EX__EX_rt_id;
assign EX__HDU_memread = stage_ID_EX__EX_memread;
assign EX__HDUbr_regwrite = stage_ID_EX__EX_regwrite;

endmodule