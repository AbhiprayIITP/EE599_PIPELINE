module IF(
    input [31:0] IM, 
    input [31:0] PC, 
    input IF_flush_in,
    input en,
    input clk,
    input rst_n,
    output reg [6:0] opcode_ID, 
    output reg [4:0] rs1_ID, 
    output reg [4:0] rs2_ID, 
    output reg [4:0] rd_ID,
    output reg IF_flush_out,
    output reg [2:0] funct3,
    output reg [6:0] funct7,
    output reg [31:0] IF_PC );

    reg [31:0] IF_inst; // from IM
    reg IF_flush; // set 1 normally

    always@(posedge clk)
    begin
      if(!rst_n)
        begin
    		  opcode_ID<=0; 
    		  rs1_ID<=0; 
    		  rs2_ID<=0; 
    		  rd_ID<=0;
          IF_flush_out<=0;
    		  funct3<=0;
    		  funct7<=0;
    		  IF_PC<=0;
        end
        else 
          begin
            if(en)
              begin
              	opcode_ID<=IM[6:0]; 
    			      rs1_ID<=IM[19:15]; 
    			      rs2_ID<=IM[24:20]; 
    			      rd_ID<=IM[11:7];
                IF_flush_out<=IF_flush_in;
    			      funct3<=IM[14:12];
    			      funct7<=IM[31:25];
    			      IF_PC<=PC;
              end
          end
    end

endmodule
