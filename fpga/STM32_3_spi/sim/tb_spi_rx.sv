`timescale 1ns/1ps
module tb_spi_rx;
 reg clk=0;always #10 clk=~clk;
 reg rst=1,sck=0,mosi=0,cs_n=1;
 wire [7:0] data;wire valid;
 integer n=0;reg [7:0] expected[0:3];
 spi_rx_mode0 dut(clk,rst,sck,mosi,cs_n,data,valid);
 always @(posedge clk) if(valid) begin
   if(n>3 || data!==expected[n]) $fatal(1,"Byte %0d = %02x",n,data);
   n=n+1;
 end
 task bits(input [7:0] b,input integer total);
  integer i;
  begin for(i=7;i>7-total;i=i-1) begin
    mosi=b[i];#617;sck=1;#643;sck=0;
  end #211;end
 endtask
 initial begin
  expected[0]=8'ha5;expected[1]=8'h00;expected[2]=8'hff;expected[3]=8'h55;
  #123;rst=0;#203;
  bits(8'hff,8); // deselected clocks must not produce data
  cs_n=0;#127;bits(8'hd0,3);cs_n=1;#211; // partial byte aborted
  cs_n=0;#127;bits(8'ha5,8);bits(8'h00,8);cs_n=1;#211;
  cs_n=0;#127;bits(8'hff,8);cs_n=1;#211;
  cs_n=0;#127;bits(8'h55,8);cs_n=1;#300;
  if(n!=4) $fatal(1,"Count %0d",n);
  $display("PASS RX: asynchronous phase, CS abort, ignored deselect, consecutive bytes, restart");$finish;
 end
 initial begin #200000;$fatal(1,"Timeout");end
endmodule
