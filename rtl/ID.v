// Code your design here
module ID (
  	
    input clk,
    input rst_n,
    input en, //for PC and IF
    input [31:0] IF_PC,
    input [6:0] opcode_ID, 
    input [4:0] rs1_ID, 
    input [4:0] rs2_ID, 
    input [4:0] rd_ID,
    input IF_flush_out, //going to control logic
    input         WB__FU_RF_regwrite, // regwrite from WB
    input [4:0]   WB__FU_RF_rd_id, //WB regdata
    input [31:0]  WB__RF_data , //WB rd_id
    input stall, //from HDU
    input [31:0] MEM__EX_ID_for_help, //ALU result
    input stage_EX_MEM__MEM_rd_id, //Rd from EX
    output reg [4:0] rs1_add_EX, rs2_add_EX, rd_add_EX,
    output reg [31:0] rs1_data_EX, rs2_data_EX,
    output reg ALUSrc,
    output reg [1:0] ALUOp ,  
    output reg MemRead_ID,
    output reg MemWrite_ID,
    output reg RegWrite_ID,
    output reg RegDst_ID,
    output IF_flush ,//going to IF and can be used to select address also for pc
    output reg [31:0] EA, //Effective address 
    input [2:0] funct3,
    input [6:0] funct7,
    output reg sys,
    output reg [2:0] funct3_EX,
    output reg [31:0]s_ext,
    output reg jump,
    output reg branch,
    output reg memtoreg,
    input Reg_write_Mem
    ); //sign extended value for lw/sw

    //control logic
    reg ALUSrc_temp, MemWrite_ID_temp, RegDst_ID_temp, RegWrite_ID_temp,MemRead_ID_temp,sys_temp;
    reg [1:0]ALUOp_temp;
    reg load, store;
    reg memtoreg_temp;
    always@(*)
    begin
      ALUOp_temp=0;
      ALUSrc_temp=0;
      MemRead_ID_temp=0;
      MemWrite_ID_temp=0;
      RegWrite_ID_temp=1;
      RegDst_ID_temp=1;
      branch=0;
      jump=0;
      load=0;
      store=0;
      sys_temp=0;
      memtoreg_temp=0;
      case(opcode_ID)
        7'b0110011: //R-type
          begin
          ALUSrc_temp=0;
            if(funct3==000)
              begin
                if(funct7===0000000)
                  ALUOp_temp=01;
                else if (funct7==0100000)
                  ALUOp_temp=10;
              end
            else if(funct3==101)
              begin
                if(funct7==0000000)
                  ALUOp_temp = 01;
                else if(funct7==0100000)
                  ALUOp_temp=01;
              end
            else if(funct3==110 && funct7==0000000)
              ALUOp_temp=01;
            else if(funct3==111 && funct7==0000000)
              ALUOp_temp=01;
          end
        7'b0010011: //ADDI
          begin
            ALUSrc_temp=1;
            ALUOp_temp=00;
          end
        7'b0100011: //STORE
          begin
            MemWrite_ID_temp=0;
            RegWrite_ID_temp=0;
            ALUSrc_temp=1;
            store=1;
          end
        7'b0000011: //LOAD
          begin
            RegDst_ID_temp=0;
            MemRead_ID_temp=1;
            ALUSrc_temp=1;
            load=1;
            memtoreg_temp=1;
          end
        7'b0110111: //LUI
          begin
            RegDst_ID_temp=0;
            MemRead_ID_temp=1;
            ALUSrc_temp=1;
            load=1;
          end
        7'b1100011: //beq
          begin
            branch=1;
          end
        7'b1100111: //jal
          begin
            jump=1;
          end
        7'b0001011: //sys
          begin
            sys_temp=1;
          end
        endcase

    end
//stall logic (control signals)
always@(posedge clk)
    if(!rst_n)
      begin
        ALUSrc <=0;
        ALUOp <=0;
        MemRead_ID <=0;
        MemWrite_ID <=0;
        RegWrite_ID <=0;
        RegDst_ID <=0;
      end
    else 
      begin
        if(stall || IF_flush_out )
          begin
            ALUSrc <=0;
            ALUOp <=0;
            MemRead_ID <=0;
            MemWrite_ID <=0;
            RegWrite_ID <=0;
            RegDst_ID <=0;
            memtoreg <=0;
          end
        else
          begin
            if(en) begin
              ALUSrc <=ALUSrc_temp;
              ALUOp <=ALUOp_temp;
              MemRead_ID <=MemRead_ID_temp;
              MemWrite_ID <=MemWrite_ID_temp;
              RegWrite_ID <=RegWrite_ID_temp;
              RegDst_ID <=RegDst_ID_temp;
              memtoreg <= memtoreg_temp;
            end
          end
      end
    
    //RF
    reg [31:0] rs1_RF; //from RF
    reg [31:0] rs2_RF;  // from RF
    reg [31:0] RF [31:0];

    always@(posedge clk)
      begin
        if(!rst_n)
          RF[0] <= 0;
        else begin
          if(WB__FU_RF_regwrite & WB__FU_RF_rd_id!=0)
              RF[WB__FU_RF_rd_id] <= WB__RF_data;
        end
      end
    //IFRF
    always@(*)
      begin
        if(rs1_ID == WB__FU_RF_rd_id && rs1_ID !=0)
          rs1_RF = WB__RF_data;
        else
          rs1_RF = RF[rs1_ID];
        if(rs2_ID == WB__FU_RF_rd_id && rs2_ID !=0)
          rs2_RF = WB__RF_data;
        else
          rs2_RF = RF[rs2_ID];
      end

    //FU_Br
    wire FW_rs1, FW_rs2;
    wire [31:0] rs1_out; //to reg 
    wire [31:0] rs2_out;  // to reg
    assign FW_rs1 = (rs1_ID==stage_EX_MEM__MEM_rd_id && Reg_write_Mem && rs1_ID !=0)?1:0;
    assign FW_rs2 = (rs2_ID==stage_EX_MEM__MEM_rd_id && Reg_write_Mem && rs2_ID !=0)?1:0;

    assign rs1_out = FW_rs1?MEM__EX_ID_for_help:rs1_RF;
    assign rs2_out = FW_rs2?MEM__EX_ID_for_help:rs2_RF;
    //Beq
    assign IF_flush = ((rs1_out==rs2_out)&&branch)?1:0;
    //Address Calc
    always@(*)
      begin
        if(branch)
          EA = (funct7[6])?({20'b1,funct7,rd_ID} + IF_PC):({20'b0,funct7,rd_ID} + IF_PC);
        else if(jump)
          EA = (funct7[6])?({15'b1,funct7,rs2_ID,rs1_ID} + IF_PC):({15'b0,funct7,rs2_ID,rs1_ID} + IF_PC);
        else
          EA=0;
      end
//sign extension
reg [31:0]s_ext_temp;
always@(*)
  begin
    if(load||(opcode_ID == 7'b0010011))
      s_ext_temp = (funct7[6])?({20'b1,funct7,rs2_ID}):({20'b0,funct7,rs2_ID});
    else if(store)
      s_ext_temp = (funct7[6])?({20'b1,funct7,rd_ID}):({20'b0,funct7,rd_ID});
    else 
      s_ext_temp = 0;
  end

always@(posedge clk)
  begin
    if(!rst_n)
      begin
        rs1_add_EX <= 0;
        rs2_add_EX <= 0;
        rd_add_EX <= 0;
        rs1_data_EX <= 0;
        rs2_data_EX <=0;
        funct3_EX <=0;
        s_ext <=0;
        sys <=0;
      end
    else
      begin
        rs1_add_EX <= rs1_ID ;
        rs2_add_EX <=rs2_ID ;
        rd_add_EX <= rd_ID;
        rs1_data_EX <= rs1_out;
        rs2_data_EX <=rs2_out;
        funct3_EX <=funct3;
        s_ext <=s_ext_temp;
        sys <= sys_temp;
      end
  end
endmodule

