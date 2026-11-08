`timescale 1ns/1ps
module spi_master_byte #(parameter integer HALF_CYCLES=32)(
 input wire clk, input wire rst, input wire start, input wire [7:0] tx_data,
 output reg sck, output reg mosi, output reg cs_n,
 output wire busy, output reg done);
 localparam IDLE=0, XFER=1, HOLD=2;
 reg [1:0] state;
 integer divider;
 reg [7:0] shift;
 reg [2:0] bit_index;
 assign busy=(state!=IDLE);
 always @(posedge clk) begin
   if (rst) begin
     state<=IDLE; divider<=0; shift<=0; bit_index<=7;
     sck<=0; mosi<=0; cs_n<=1; done<=0;
   end else begin
     done<=0;
     case (state)
       IDLE: begin
         sck<=0; cs_n<=1; divider<=0;
         if (start) begin
           shift<=tx_data; mosi<=tx_data[7]; cs_n<=0;
           bit_index<=7; state<=XFER;
         end
       end
       XFER: begin
         if (divider==HALF_CYCLES-1) begin
           divider<=0;
           if (!sck) sck<=1;
           else begin
             sck<=0;
             if (bit_index==0) state<=HOLD;
             else begin
               bit_index<=bit_index-1'b1;
               shift<={shift[6:0],1'b0}; mosi<=shift[6];
             end
           end
         end else divider<=divider+1;
       end
       HOLD: begin
         if (divider==HALF_CYCLES-1) begin
           cs_n<=1; done<=1; divider<=0; state<=IDLE;
         end else divider<=divider+1;
       end
       default: begin state<=IDLE; sck<=0; cs_n<=1; end
     endcase
   end
 end
endmodule
