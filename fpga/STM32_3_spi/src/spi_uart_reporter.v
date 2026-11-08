`timescale 1ns/1ps
module spi_uart_reporter #(parameter integer CLKS_PER_BIT=5208)(
 input wire clk,input wire rst,input wire [7:0] rx_data,input wire rx_valid,
 output wire uart_tx_o,output reg overrun);
 reg [7:0] fifo[0:3];
 reg [1:0] wr_ptr,rd_ptr;
 reg [2:0] count;
 reg active;
 reg [2:0] pos;
 reg [7:0] value;
 reg uart_start;
 reg [7:0] uart_data;
 wire uart_busy;
 wire pop=(!active && count!=0);
 wire push=(rx_valid && (count<4 || pop));
 function [7:0] hex_ascii(input [3:0] nibble);
   begin hex_ascii=(nibble<10)?(8'h30+nibble):(8'h41+nibble-10);end
 endfunction
 uart_tx #(.CLKS_PER_BIT(CLKS_PER_BIT)) u_uart(
 .clk(clk),.rst(rst),.start(uart_start),.data(uart_data),.tx(uart_tx_o),.busy(uart_busy));
 always @(posedge clk) begin
   if(rst) begin
     wr_ptr<=0;rd_ptr<=0;count<=0;active<=0;pos<=0;
     value<=0;uart_start<=0;uart_data<=0;overrun<=0;
   end else begin
     uart_start<=0;
     if(rx_valid && !push) overrun<=1;
     if(push) begin fifo[wr_ptr]<=rx_data;wr_ptr<=wr_ptr+1'b1;end
     if(pop) begin value<=fifo[rd_ptr];rd_ptr<=rd_ptr+1'b1;active<=1;pos<=0;end
     case({push,pop})
       2'b10:count<=count+1'b1;
       2'b01:count<=count-1'b1;
       default:count<=count;
     endcase
     if(active && !uart_busy && !uart_start) begin
       case(pos)
         0:uart_data<=8'h52; 1:uart_data<=8'h58; 2:uart_data<=8'h3d;
         3:uart_data<=hex_ascii(value[7:4]); 4:uart_data<=hex_ascii(value[3:0]);
         5:uart_data<=8'h0d; default:uart_data<=8'h0a;
       endcase
       uart_start<=1;
       if(pos==6) active<=0;else pos<=pos+1'b1;
     end
   end
 end
endmodule
