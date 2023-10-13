`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11.10.2023 23:42:29
// Design Name: 
// Module Name: tb
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

`timescale 1ns/1ns

module tb();

reg clk, rst_n;

initial begin
    clk = 0;
    forever begin
        #1 clk = ~clk;
    end
end


top TOP_BLOCK(clk,rst_n);

initial begin
    rst_n = 0;
    #10 rst_n = 1;    
end


initial begin
    $display("Loading ROM");
    $readmemb("test.mem",TOP_BLOCK.INSTRUCTION_CACHE.mem);
end

endmodule
