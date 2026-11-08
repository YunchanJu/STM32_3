`timescale 1ns/1ps
module spi_tx_top #(parameter integer PERIOD_CYCLES=50000000,
 parameter integer HALF_CYCLES=32)(
 input wire clk_50mhz,input wire rst_p,
 output wire spi_sck,output wire spi_mosi,output wire spi_cs_n);
 (* ASYNC_REG="TRUE" *) reg [1:0] reset_sync=2'b11;
 always @(posedge clk_50mhz) reset_sync<={reset_sync[0],rst_p};
 wire rst=reset_sync[1];
 integer timer;
 reg [1:0] pattern_index;
 reg start;
 reg [7:0] data;
 wire busy,done;
 function [7:0] pattern(input [1:0] index);
  begin case(index) 0:pattern=8'h55;1:pattern=8'ha5;2:pattern=8'h00;default:pattern=8'hff;endcase end
 endfunction
 always @(posedge clk_50mhz) begin
   if(rst) begin timer<=0;pattern_index<=0;start<=0;data<=8'h55;end
   else begin
     start<=0;
     if(timer==PERIOD_CYCLES-1) begin
       timer<=0;
       if(!busy) begin data<=pattern(pattern_index);start<=1;pattern_index<=pattern_index+1'b1;end
     end else timer<=timer+1;
   end
 end
 spi_master_byte #(.HALF_CYCLES(HALF_CYCLES)) u_master(
 .clk(clk_50mhz),.rst(rst),.start(start),.tx_data(data),
 .sck(spi_sck),.mosi(spi_mosi),.cs_n(spi_cs_n),.busy(busy),.done(done));
endmodule
