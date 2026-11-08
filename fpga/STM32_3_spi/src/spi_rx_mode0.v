`timescale 1ns/1ps
module spi_rx_mode0(input wire clk, input wire rst,
 input wire sck, input wire mosi, input wire cs_n,
 output reg [7:0] rx_data, output reg rx_valid);
 (* ASYNC_REG = "TRUE" *) reg [2:0] sck_sync, cs_sync, mosi_sync;
 reg sck_prev;
 reg [7:0] shift;
 reg [2:0] bit_count;
 always @(posedge clk) begin
   if (rst) begin
     sck_sync<=0; cs_sync<=7; mosi_sync<=0; sck_prev<=0;
     shift<=0; bit_count<=0; rx_data<=0; rx_valid<=0;
   end else begin
     sck_sync<={sck_sync[1:0],sck};
     cs_sync<={cs_sync[1:0],cs_n};
     mosi_sync<={mosi_sync[1:0],mosi};
     sck_prev<=sck_sync[2]; rx_valid<=0;
     if (cs_sync[2]) begin
       bit_count<=0; shift<=0;
     end else if (sck_sync[2] && !sck_prev) begin
       shift<={shift[6:0],mosi_sync[2]};
       if (bit_count==7) begin
         rx_data<={shift[6:0],mosi_sync[2]};
         rx_valid<=1; bit_count<=0;
       end else bit_count<=bit_count+1'b1;
     end
   end
 end
endmodule
