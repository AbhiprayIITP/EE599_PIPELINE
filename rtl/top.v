module top
(
 input clk, 
 input rst_n
 );

reg [31:0] PC_counter;
reg PC_out;
wire [31:0] DATA_IC;
wire IF_flush_IF;

// IF declarations
wire [31:0] IF_PC;
wire [6:0] opcode_ID;
wire [4:0] rs1_ID,rs2_ID,rd_ID;
wire IF_flush_out;
wire [2:0] funct3;
wire [6:0] funct7;
wire [31:0] EA;
wire IF_flush;
wire branch;
wire jump;

//EX declarations
wire stage_ID_EX__EX_regwrite;
wire stage_ID_EX__EX_memtoreg;
wire stage_ID_EX__EX_memread;
wire stage_ID_EX__EX_memwrite;
wire stage_ID_EX__EX_alusrc;
wire [1:0] stage_ID_EX__EX_aluop;
wire stage_ID_EX__EX_regdst;
wire stage_ID_EX__EX_sys_en;
wire [31:0]stage_ID_EX__EX_rs_data;
wire [31:0]stage_ID_EX__EX_rt_data;
wire [4:0]stage_ID_EX__EX_rs_id;
wire [4:0]stage_ID_EX__EX_rt_id;
wire [4:0]stage_ID_EX__EX_rd_id;
wire [31:0]stage_ID_EX__EX_sign_ext;
wire [2:0]stage_ID_EX__EX_funct3;
wire sys__EX_done;
wire stage_EX_MEM__MEM_regwrite;
wire stage_EX_MEM__MEM_memtoreg;
wire stage_EX_MEM__MEM_memread;
wire stage_EX_MEM__MEM_memwrite;
wire [31:0] stage_EX_MEM__MEM_alures;
wire [31:0] stage_EX_MEM__MEM_store_data;
wire [4:0]  stage_EX_MEM__MEM_rd_id;    
wire EX__HDUbr_regwrite;
wire EX__HDU_memread;
wire [4:0] EX__HDU_HDUbr_rd_id;
wire  EX_stall_for_sys;
wire  FU__EX_rs_wb;
wire  FU__EX_rs_mem;
wire  FU__EX_rt_wb;
wire  FU__EX_rt_mem;
wire [31:0]  WB__EX_for_help;
wire [31:0]  MEM__EX_for_help;


//MEM declarations
wire          MEM__HDUbr_memread;
wire [31:0]   MEM__EX_ID_for_help;
wire [4:0]    MEM__FUbr_rd_id;
wire          MEM__FU_FUbr_regwrite;
wire      stage_MEM_WB__WB_memtoreg;
wire      stage_MEM_WB__WB_regwrite;
wire [`DATA_WIDTH-1:0] stage_MEM_WB__WB_memdata;
wire [31:0] stage_MEM_WB__WB_regdata;
wire [4:0]  stage_MEM_WB__WB_rd_id;


//WB declarations
wire                    WB__FU_RF_regwrite;
wire[4:0]               WB__FU_RF_rd_id;
wire [31:0]             WB__RF_data;

assign IF_flush_IF = ~IF_flush;


always@(posedge clk)
    begin
        if(!rst_n)
            begin
                PC_counter <=0;
            end
        else
            PC_counter <= PC_out;
    end
always@(*)
    begin
        if(branch || jump)
            PC_out = EA;
        else
            PC_out = PC_counter+4;
    end

ram_sync_1r1w #( .DATA_WIDTH(32), .ADDR_WIDTH(32), .DEPTH(256)) INSTRUCTION_CACHE 
 (.clk(clk),
 .wen(0),
 .wadr(0),
 .wdata(0),
 .ren(1),
 .radr(PC_counter),
 .rdata(DATA_IC)
);


IF IF_STAGE(
    .clk(clk),
    .rst_n(rst_n),
    .en(1'b1),
    .IM(DATA_IC), 
    .PC(PC_counter), 
    .IF_flush_in(IF_flush_IF),
    .opcode_ID(opcode_ID), 
    .rs1_ID(rs1_ID), 
    .rs2_ID(rs2_ID), 
    .rd_ID(rd_ID),
    .IF_flush_out(IF_flush_out),
    .funct3(funct3),
    .funct7(funct7),
    .IF_PC(IF_PC) 
    );


// HELP FROM MEM MISSING
ID ID_STAGE(
    .clk(clk),
    .rst_n(rst_n),
    .en(1'b1),
    .IF_PC(IF_PC),
    .Reg_write_Mem(MEM__FU_FUbr_regwrite),
    .opcode_ID(opcode_ID), 
    .rs1_ID(rs1_ID), 
    .rs2_ID(rs2_ID), 
    .rd_ID(rd_ID),
    .rs1_add_EX(stage_ID_EX__EX_rs_id), 
    .rs2_add_EX(stage_ID_EX__EX_rt_id), 
    .rd_add_EX(stage_ID_EX__EX_rd_id),
    .rs1_data_EX(stage_ID_EX__EX_rs_data), 
    .rs2_data_EX(stage_ID_EX__EX_rt_data),
    .IF_flush_out(~IF_flush_out), 
    .WB__FU_RF_regwrite(WB__FU_RF_regwrite), // Abhipray
    .WB__FU_RF_rd_id(WB__FU_RF_rd_id), //Abhi
    .WB__RF_data(WB__RF_data) , //Abhi
    .stall(1'b0), //from HBU 
    .MEM__EX_ID_for_help(MEM__EX_ID_for_help), //Abhi
    .stage_EX_MEM__MEM_rd_id(stage_EX_MEM__MEM_rd_id), //Abhi
    .ALUSrc(stage_ID_EX__EX_alusrc),//A
    .ALUOp(stage_ID_EX__EX_aluop) ,//A
    .MemRead_ID(stage_ID_EX__EX_memread), //A
    .MemWrite_ID(stage_ID_EX__EX_memwrite),//A
    .RegWrite_ID(stage_ID_EX__EX_regwrite),//A
    .RegDst_ID(stage_ID_EX__EX_regdst),//A
    .IF_flush(IF_flush),
    .EA(EA), 
    .funct3(funct3), 
    .funct7(funct7),
    .jump(jump),
    .branch(branch), 
    .sys(stage_ID_EX__EX_sys_en), 
    .funct3_EX(stage_ID_EX__EX_funct3),
    .s_ext(stage_ID_EX__EX_sign_ext),
    .memtoreg(stage_ID_EX__EX_memtoreg)
    );

EX EX_STAGE (
    .clk(clk),
    .rst_n(rst_n),
    .en(1'b1),
    .stage_ID_EX__EX_regwrite(stage_ID_EX__EX_regwrite),
    .stage_ID_EX__EX_memtoreg(stage_ID_EX__EX_memtoreg),
    .stage_ID_EX__EX_memread(stage_ID_EX__EX_memread),
    .stage_ID_EX__EX_memwrite(stage_ID_EX__EX_memwrite),
    .stage_ID_EX__EX_alusrc(stage_ID_EX__EX_alusrc),
    .stage_ID_EX__EX_aluop(stage_ID_EX__EX_aluop),
    .stage_ID_EX__EX_regdst(stage_ID_EX__EX_regdst),
    .stage_ID_EX__EX_sys_en(stage_ID_EX__EX_sys_en),
    .stage_ID_EX__EX_rs_data(stage_ID_EX__EX_rs_data),
    .stage_ID_EX__EX_rt_data(stage_ID_EX__EX_rt_data),
    .stage_ID_EX__EX_rs_id(stage_ID_EX__EX_rs_id),
    .stage_ID_EX__EX_rt_id(stage_ID_EX__EX_rt_id),
    .stage_ID_EX__EX_rd_id(stage_ID_EX__EX_rd_id),
    .stage_ID_EX__EX_sign_ext(stage_ID_EX__EX_sign_ext),
    .stage_ID_EX__EX_funct3(stage_ID_EX__EX_funct3),
    .sys__EX_done(sys__EX_done),
    .stage_EX_MEM__MEM_regwrite(stage_EX_MEM__MEM_regwrite),
    .stage_EX_MEM__MEM_memtoreg(stage_EX_MEM__MEM_memtoreg),
    .stage_EX_MEM__MEM_memread(stage_EX_MEM__MEM_memread),
    .stage_EX_MEM__MEM_memwrite(stage_EX_MEM__MEM_memwrite),
    .stage_EX_MEM__MEM_alures(stage_EX_MEM__MEM_alures),
    .stage_EX_MEM__MEM_store_data(stage_EX_MEM__MEM_store_data),
    .stage_EX_MEM__MEM_rd_id(stage_EX_MEM__MEM_rd_id),
    .EX__HDUbr_regwrite(EX__HDUbr_regwrite),
    .EX__HDU_memread(EX__HDU_memread),
    .EX__HDU_HDUbr_rd_id(EX__HDU_HDUbr_rd_id),
    .EX_stall_for_sys(EX_stall_for_sys),
    .FU__EX_rs_wb(1'b0),
    .FU__EX_rs_mem(1'b0),
    .FU__EX_rt_wb(1'b0),
    .FU__EX_rt_mem(1'b0),
    .WB__EX_for_help(WB__RF_data),
    .MEM__EX_for_help(MEM__EX_ID_for_help)

);

MEM MEM_STAGE(
    .clk(clk),
    .rst_n(rst_n),
    .en(1'b1),
    .stage_EX_MEM__MEM_regwrite(stage_EX_MEM__MEM_regwrite),
    .stage_EX_MEM__MEM_memtoreg(stage_EX_MEM__MEM_memtoreg),
    .stage_EX_MEM__MEM_memread(stage_EX_MEM__MEM_memread),
    .stage_EX_MEM__MEM_memwrite(stage_EX_MEM__MEM_memwrite),
    .stage_EX_MEM__MEM_alures(stage_EX_MEM__MEM_alures),  
    .stage_EX_MEM__MEM_store_data(stage_EX_MEM__MEM_store_data),
    .stage_EX_MEM__MEM_rd_id(stage_EX_MEM__MEM_rd_id),
    .MEM__HDUbr_memread(MEM__HDUbr_memread),
    .MEM__EX_ID_for_help(MEM__EX_ID_for_help),
    .MEM__FUbr_rd_id(MEM__FUbr_rd_id),
    .MEM__FU_FUbr_regwrite(MEM__FU_FUbr_regwrite),
    .stage_MEM_WB__WB_memtoreg(stage_MEM_WB__WB_memtoreg),
    .stage_MEM_WB__WB_regwrite(stage_MEM_WB__WB_regwrite),
    .stage_MEM_WB__WB_memdata(stage_MEM_WB__WB_memdata),
    .stage_MEM_WB__WB_regdata(stage_MEM_WB__WB_regdata),
    .stage_MEM_WB__WB_rd_id(stage_MEM_WB__WB_rd_id) 

);

WB WB_STAGE(
    .stage_MEM_WB__WB_memtoreg(stage_MEM_WB__WB_memtoreg),
    .stage_MEM_WB__WB_regwrite(stage_MEM_WB__WB_regwrite),
    .stage_MEM_WB__WB_memdata(stage_MEM_WB__WB_memdata),
    .stage_MEM_WB__WB_regdata(stage_MEM_WB__WB_regdata),
    .stage_MEM_WB__WB_rd_id(stage_MEM_WB__WB_rd_id),
    .WB__FU_RF_regwrite(WB__FU_RF_regwrite),
    .WB__FU_RF_rd_id(WB__FU_RF_rd_id),
    .WB__RF_data(WB__RF_data)
);


endmodule