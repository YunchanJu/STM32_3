`timescale 1ns/1ps
module spi_rx_top #(parameter integer CLKS_PER_BIT=5208)(
 input wire clk_50mhz,input wire rst_p,
 input wire spi_sck,input wire spi_mosi,input wire spi_cs_n,
 output wire uart_tx_o);
 (* ASYNC_REG="TRUE" *) reg [1:0] reset_sync=2'b11;
 always @(posedge clk_50mhz) reset_sync<={reset_sync[0],rst_p};
 wire rst=reset_sync[1];
 wire [7:0] data;
 wire valid,overrun;
 spi_rx_mode0 u_rx(.clk(clk_50mhz),.rst(rst),.sck(spi_sck),
 .mosi(spi_mosi),.cs_n(spi_cs_n),.rx_data(data),.rx_valid(valid));
 spi_uart_reporter #(.CLKS_PER_BIT(CLKS_PER_BIT)) u_report(
 .clk(clk_50mhz),.rst(rst),.rx_data(data),.rx_valid(valid),.uart_tx_o(uart_tx_o),.overrun(overrun));
endmodule
