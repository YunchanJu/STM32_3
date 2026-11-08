`timescale 1ns/1ps
module tb_spi_system;
 reg clk=0;always #10 clk=~clk;
 reg rst=1,start=0;reg [7:0] tx=0;
 wire sck,mosi,cs_n,busy,done,valid;
 wire [7:0] rx;
 spi_master_byte #(.HALF_CYCLES(32)) master(clk,rst,start,tx,sck,mosi,cs_n,busy,done);
 spi_rx_mode0 receiver(clk,rst,sck,mosi,cs_n,rx,valid);
 integer edges=0,received=0;reg [7:0] expected;
 time last_edge;
 always @(negedge cs_n) begin edges=0;last_edge=$time;end
 always @(posedge sck) if(!rst) begin
   if(cs_n) $fatal(1,"SCK outside CS");
   if($time-last_edge!=640) $fatal(1,"Half period is not 640 ns");
   last_edge=$time;edges=edges+1;
   if(mosi!==expected[8-edges]) $fatal(1,"MSB order error at bit %0d",edges);
 end
 always @(negedge sck) if(!rst && !cs_n) begin
   if($time-last_edge!=640) $fatal(1,"Falling edge spacing");last_edge=$time;
 end
 always @(posedge cs_n) if(!rst && $time>100) begin
   if(edges!=8) $fatal(1,"Expected eight rising edges");
   if(sck!==0) $fatal(1,"Idle SCK must be low");
 end
 always @(posedge clk) if(valid) begin
   if(rx!==expected) $fatal(1,"RX %02x expected %02x",rx,expected);
   received=received+1;
 end
 task send(input [7:0] b);
   begin
     expected=b;@(negedge clk);tx=b;start=1;
     @(negedge clk);start=0;tx=~b;
     repeat(10) @(negedge clk);
     // Busy start requests must not restart the current byte.
     start=1;@(negedge clk);start=0;
     wait(done);repeat(8) @(negedge clk);
   end
 endtask
 initial begin
   repeat(6) @(negedge clk);rst=0;
   send(8'h55);send(8'ha5);send(8'h00);send(8'hff);
   if(received!=4) $fatal(1,"RX count %0d",received);
   $display("PASS SPI mode0: 4 patterns, 8 edges, 781250Hz, latch, busy start");$finish;
 end
 initial begin #1000000;$fatal(1,"Timeout");end
endmodule
