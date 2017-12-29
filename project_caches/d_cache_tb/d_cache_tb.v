
`timescale 1ns / 1ps

module d_cache_test;
  reg clk;

  wire [63:0] data_in;
  wire [63:0] data_out;
  wire [31:0] rd_addr;
  wire        rd_en;
  wire [31:0] wr_addr;
  wire        wr_en;

  reg  [31:0] d_cache_addr = 0;
  reg  [31:0] d_cache_din = 0;
  reg         d_cache_rden = 0;
  reg         d_cache_wren = 0;
  wire        d_cache_hit_miss;
  wire [31:0] d_cache_q;

  d_cache DUT_CACHE (
    .clock(clk),
    .address(d_cache_addr),
    .din(d_cache_din),
    .rden(d_cache_rden),
    .wren(d_cache_wren),
    .hit_miss(d_cache_hit_miss),
    .q(d_cache_q),
    .mdout(data_in),
    .mrdaddress(rd_addr),
    .mrden(rd_en),
    .mwraddress(wr_addr),
    .mwren(wr_en),
    .mq(data_out)
  );

  defparam DUT_CACHE.SIZE = 32*1024*8;
  defparam DUT_CACHE.NWAYS = 4;
  defparam DUT_CACHE.NSETS = 1024;
  defparam DUT_CACHE.BLOCK_SIZE = 64;
  defparam DUT_CACHE.WIDTH = 32;
  defparam DUT_CACHE.MWIDTH = 64;

  mem DUT_MEM (
    .clock(clk),
    .data(data_in),
    .rdaddress(rd_addr),
    .rden(rd_en),
    .wraddress(wr_addr),
    .wren(wr_en),
    .q(data_out)
  );

  defparam DUT_MEM.WIDTH = 64;
  defparam DUT_MEM.DEPTH = 128;
  defparam DUT_MEM.FILE = "d_mem_data.txt";

  integer i;

  always
    begin

      // basic writeback /////////////////////////////////////////////////////////////////////////////////////////////////////////

      /*# 100; // This should be a miss

      d_cache_addr <= 32'h00000008;
      d_cache_din <= 0;
      d_cache_rden <= 1;
      d_cache_wren <= 0;

      # 100; // This should be a hit

      d_cache_addr <= 32'h00000008;
      d_cache_din <= 32'hBADDBEEF;
      d_cache_rden <= 0;
      d_cache_wren <= 1;

      # 100; // This should be a miss

      d_cache_addr <= 32'h10000008;
      d_cache_din <= 0;
      d_cache_rden <= 1;
      d_cache_wren <= 0;

      # 100; // This should be a miss

      d_cache_addr <= 32'h20000008;
      d_cache_din <= 0;
      d_cache_rden <= 1;
      d_cache_wren <= 0;

      # 100; // This should be a miss

      d_cache_addr <= 32'h30000008;
      d_cache_din <= 0;
      d_cache_rden <= 1;
      d_cache_wren <= 0;

      # 100; // This should be a miss and eviction

      d_cache_addr <= 32'h40000008;
      d_cache_din <= 0;
      d_cache_rden <= 1;
      d_cache_wren <= 0;

      # 100; // This should be a miss (evicted)

      d_cache_addr <= 32'h00000008;
      d_cache_din <= 0;
      d_cache_rden <= 1;
      d_cache_wren <= 0;

      # 100; // This should be a hit

      d_cache_addr <= 32'h30000008;
      d_cache_din <= 0;
      d_cache_rden <= 1;
      d_cache_wren <= 0;*/

      // repeated writes (w/ offset) /////////////////////////////////////////////////////////////////////////////////////////////////////////

      # 100; // This should be a miss

      d_cache_addr <= 32'h00000008;
      d_cache_din <= 0;
      d_cache_rden <= 1;
      d_cache_wren <= 0;

      # 100; // This should be a hit

      d_cache_addr <= 32'h00000008;
      d_cache_din <= 32'hBADDBEEF;
      d_cache_rden <= 0;
      d_cache_wren <= 1;

      # 100; // This should be a hit

      d_cache_addr <= 32'h0000000B;
      d_cache_din <= 32'h00000000;
      d_cache_rden <= 0;
      d_cache_wren <= 1;

      # 100; // This should be a hit

      d_cache_addr <= 32'h0000000C;
      d_cache_din <= 32'hAAAAAAAA;
      d_cache_rden <= 0;
      d_cache_wren <= 1;

      # 100; // This should be a miss

      d_cache_addr <= 32'h10000008;
      d_cache_din <= 0;
      d_cache_rden <= 1;
      d_cache_wren <= 0;

      # 100; // This should be a miss

      d_cache_addr <= 32'h20000008;
      d_cache_din <= 0;
      d_cache_rden <= 1;
      d_cache_wren <= 0;

      # 100; // This should be a miss

      d_cache_addr <= 32'h30000008;
      d_cache_din <= 0;
      d_cache_rden <= 1;
      d_cache_wren <= 0;

      # 100; // This should be a miss and eviction

      d_cache_addr <= 32'h40000008;
      d_cache_din <= 0;
      d_cache_rden <= 1;
      d_cache_wren <= 0;

      # 100; // This should be a miss (evicted)

      d_cache_addr <= 32'h00000008;
      d_cache_din <= 0;
      d_cache_rden <= 1;
      d_cache_wren <= 0;

      # 100; // This should be a miss

      d_cache_addr <= 32'h10000008;
      d_cache_din <= 32'hBADDBEEF;
      d_cache_rden <= 0;
      d_cache_wren <= 1;

      // repeated reads (w/ offset) /////////////////////////////////////////////////////////////////////////////////////////////////////////

      /*# 100; // This should be a miss

      d_cache_addr <= 32'h00000008;
      d_cache_din <= 0;
      d_cache_rden <= 1;
      d_cache_wren <= 0;

      # 100; // This should be a hit

      d_cache_addr <= 32'h0000000B;
      d_cache_din <= 32'hBADDBEEF;
      d_cache_rden <= 1;
      d_cache_wren <= 0;

      # 100; // This should be a hit

      d_cache_addr <= 32'h0000000C;
      d_cache_din <= 32'h00000000;
      d_cache_rden <= 1;
      d_cache_wren <= 0;

      # 100; // This should be a hit

      d_cache_addr <= 32'h0000000F;
      d_cache_din <= 32'hAAAAAAAA;
      d_cache_rden <= 1;
      d_cache_wren <= 0; */

      #50;

      /*for (i = 0; i < DUT_MEM.DEPTH; i = i + 1)
      begin
        $display("%b", DUT_MEM.mem[i]);
      end*/

      $finish;
    end

  initial
  begin
    //$monitor("time=%3d, addr=%1b, din=%1b, rden=%1b, wren=%1b, q=%1b, hit_miss=%1b", $time,d_cache_addr,d_cache_din,d_cache_rden,d_cache_wren,d_cache_q,d_cache_hit_miss);
    $monitor("time=%4d | addr=%10d | hm=%b | q=%08x | way1=%08h | way2=%08h | way3=%08h | way4=%08h | mem[1]=%08h | lru1=%d | lru2=%d | lru3=%d | lru4=%d" ,$time,d_cache_addr,d_cache_hit_miss,DUT_CACHE.q,DUT_CACHE.mem1[1],DUT_CACHE.mem2[1],DUT_CACHE.mem3[1],DUT_CACHE.mem4[1],DUT_MEM.mem[1],DUT_CACHE.lru1[1],DUT_CACHE.lru2[1],DUT_CACHE.lru3[1],DUT_CACHE.lru4[1]);
  end
 
  always
    begin
      clk = 1'b1;
      #5;
      clk = 1'b0;
      #5;
    end
   
endmodule
