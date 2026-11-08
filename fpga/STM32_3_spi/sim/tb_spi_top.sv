`timescale 1ns/1ps
module tb_spi_top;
 reg clk=0;always #10 clk=~clk;
 reg rst=1;wire sck,mosi,cs_n;
 spi_tx_top #(.PERIOD_CYCLES(2000),.HALF_CYCLES(32)) dut(clk,rst,sck,mosi,cs_n);
 reg [7:0] expected[0:3];reg [7:0] value;
 integer n=0,edges=0;time previous_start=0;
 always @(negedge cs_n) begin
   if(previous_start && $time-previous_start!=40000) $fatal(1,"Start interval");
   previous_start=$time;edges=0;value=0;
 end
 always @(posedge sck) begin value={value[6:0],mosi};edges=edges+1;end
 always @(posedge cs_n) if($time>1000 && !rst) begin
   if(edges!=8 || value!==expected[n%4]) $fatal(1,"Top pattern %0d %02x",n,value);
   n=n+1;
 end
 initial begin
   expected[0]=8'h55;expected[1]=8'ha5;expected[2]=0;expected[3]=8'hff;
   #200;rst=0;wait(n==5);
   // Synchronous reset must restore idle lines and sequence index.
   #100;rst=1;#200;rst=0;previous_start=0;n=0;
   wait(n==1);#100;
   $display("PASS TX top: periodic starts, 55/A5/00/FF repeat, reset restart");$finish;
 end
 initial begin #400000;$fatal(1,"Timeout");end
endmodule
