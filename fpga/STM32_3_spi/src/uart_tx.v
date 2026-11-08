`timescale 1ns/1ps
module uart_tx #(parameter integer CLKS_PER_BIT=5208)(
 input wire clk,input wire rst,input wire start,input wire [7:0] data,
 output reg tx,output reg busy);
 reg [9:0] frame;
 integer tick;
 reg [3:0] bit_index;
 always @(posedge clk) begin
   if(rst) begin tx<=1; busy<=0; frame<=10'h3ff; tick<=0; bit_index<=0; end
   else if(!busy) begin
     tx<=1;
     if(start) begin
       frame<={1'b1,data,1'b0};tx<=0;busy<=1;tick<=0;bit_index<=0;
     end
   end else if(tick==CLKS_PER_BIT-1) begin
     tick<=0;
     if(bit_index==9) begin busy<=0;tx<=1;end
     else begin
       bit_index<=bit_index+1'b1;frame<={1'b1,frame[9:1]};tx<=frame[1];
     end
   end else tick<=tick+1;
 end
endmodule
