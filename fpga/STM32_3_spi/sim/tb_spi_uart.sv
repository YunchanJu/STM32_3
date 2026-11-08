`timescale 1ns/1ps
module tb_spi_uart;
 reg clk=0;always #10 clk=~clk;
 reg rst=1,sck=0,mosi=0,cs_n=1;
 wire uart;
 localparam CPB=16;
 spi_rx_top #(.CLKS_PER_BIT(CPB)) dut(clk,rst,sck,mosi,cs_n,uart);
 reg [7:0] expected[0:27];reg [7:0] byte_rx;
 integer chars=0,i;
 always begin
   @(negedge uart);#(CPB*20/2);
   if(uart!==0) $fatal(1,"UART start");
   for(integer k=0;k<8;k=k+1) begin #(CPB*20);byte_rx[k]=uart;end
   #(CPB*20);if(uart!==1) $fatal(1,"UART stop");
   if(chars>=28 || byte_rx!==expected[chars]) $fatal(1,"UART char %0d=%02x expected %02x",chars,byte_rx,expected[chars]);
   chars=chars+1;
 end
 task send(input [7:0] b);
   begin cs_n=0;#137;
    for(integer bitn=7;bitn>=0;bitn=bitn-1) begin
      mosi=b[bitn];#640;sck=1;#640;sck=0;
    end
    #137;cs_n=1;#300;
   end
 endtask
 initial begin
   for(i=0;i<4;i=i+1) begin
    expected[7*i]=8'h52;expected[7*i+1]=8'h58;expected[7*i+2]=8'h3d;
    expected[7*i+5]=8'h0d;expected[7*i+6]=8'h0a;
   end
   expected[3]="5";expected[4]="5";expected[10]="A";expected[11]="5";
   expected[17]="0";expected[18]="0";expected[24]="F";expected[25]="F";
   #223;rst=0;#300;
   send(8'h55);send(8'ha5);send(8'h00);send(8'hff);
   wait(chars==28);#1000;
   if(dut.overrun) $fatal(1,"Unexpected FIFO overrun");
   $display("PASS SPI to UART: RX=55/A5/00/FF CR LF, queue and 8N1");$finish;
 end
 initial begin #300000;$fatal(1,"Timeout chars=%0d",chars);end
endmodule
