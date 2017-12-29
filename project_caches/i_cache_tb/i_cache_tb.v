
`timescale 1ns / 1ps

module i_cache_test;
  reg clk;

  wire [31:0] data_in;
  wire [31:0] data_out;
  wire [31:0] rd_addr;
  wire        rd_en;
  wire [31:0] wr_addr;
  wire        wr_en;

  reg  [31:0] i_cache_addr = 0;
  reg  [31:0] i_cache_din = 0;
  reg         i_cache_rden = 0;
  reg         i_cache_wren = 0;
  wire        i_cache_hit_miss;
  wire [31:0] i_cache_q;

  i_cache DUT_CACHE (
    .clock(clk),
    .address(i_cache_addr),
    .din(i_cache_din),
    .rden(i_cache_rden),
    .wren(i_cache_wren),
    .hit_miss(i_cache_hit_miss),
    .q(i_cache_q),
    .mdout(data_in),
    .mrdaddress(rd_addr),
    .mrden(rd_en),
    .mwraddress(wr_addr),
    .mwren(wr_en),
    .mq(data_out)
  );

  defparam DUT_CACHE.SIZE = 16*1024*8;
  defparam DUT_CACHE.NWAYS = 2;
  defparam DUT_CACHE.NSETS = 2048;
  defparam DUT_CACHE.BLOCK_SIZE = 32;
  defparam DUT_CACHE.WIDTH = 32;
  defparam DUT_CACHE.MWIDTH = 32;

  mem DUT_MEM (
    .clock(clk),
    .data(data_in),
    .rdaddress(rd_addr),
    .rden(rd_en),
    .wraddress(wr_addr),
    .wren(wr_en),
    .q(data_out)
  );

  defparam DUT_MEM.WIDTH = 32;
  defparam DUT_MEM.DEPTH = 128;
  defparam DUT_MEM.FILE = "i_mem_data.txt";

  integer i;

  always
    begin

      // basic writeback /////////////////////////////////////////////////////////////////////////////////////////////////////////

      /*# 100; // This should be a miss

      i_cache_addr <= 32'h00000004;
      i_cache_din <= 0;
      i_cache_rden <= 1;
      i_cache_wren <= 0;

      # 100; // This should be a hit

      i_cache_addr <= 32'h00000004;
      i_cache_din <= 32'hBADDBEEF;
      i_cache_rden <= 0;
      i_cache_wren <= 1;

      # 100; // This should be a miss

      i_cache_addr <= 32'h10000004;
      i_cache_din <= 0;
      i_cache_rden <= 1;
      i_cache_wren <= 0;

      # 100; // This should be a miss

      i_cache_addr <= 32'h20000004;
      i_cache_din <= 0;
      i_cache_rden <= 1;
      i_cache_wren <= 0;

      # 100; // This should be a miss (evicted)

      i_cache_addr <= 32'h00000004;
      i_cache_din <= 0;
      i_cache_rden <= 1;
      i_cache_wren <= 0;

      # 100; // This should be a hit

      i_cache_addr <= 32'h20000004;
      i_cache_din <= 0;
      i_cache_rden <= 1;
      i_cache_wren <= 0;*/

      // repeated writes (w/ offset) /////////////////////////////////////////////////////////////////////////////////////////////////////////

      /*# 100; // This should be a miss

      i_cache_addr <= 32'h00000004;
      i_cache_din <= 0;
      i_cache_rden <= 1;
      i_cache_wren <= 0;

      # 100; // This should be a hit

      i_cache_addr <= 32'h00000004;
      i_cache_din <= 32'hBADDBEEF;
      i_cache_rden <= 0;
      i_cache_wren <= 1;

      # 100; // This should be a hit

      i_cache_addr <= 32'h00000006;
      i_cache_din <= 32'h00000000;
      i_cache_rden <= 0;
      i_cache_wren <= 1;

      # 100; // This should be a miss

      i_cache_addr <= 32'h10000004;
      i_cache_din <= 0;
      i_cache_rden <= 1;
      i_cache_wren <= 0;

      # 100; // This should be a miss

      i_cache_addr <= 32'h20000004;
      i_cache_din <= 0;
      i_cache_rden <= 1;
      i_cache_wren <= 0;

      # 100; // This should be a miss (evicted)

      i_cache_addr <= 32'h00000004;
      i_cache_din <= 0;
      i_cache_rden <= 1;
      i_cache_wren <= 0;

      # 100; // This should be a hit

      i_cache_addr <= 32'h20000004;
      i_cache_din <= 0;
      i_cache_rden <= 1;
      i_cache_wren <= 0;*/

      // repeated reads (w/ offset) /////////////////////////////////////////////////////////////////////////////////////////////////////////

      # 100; // This should be a miss

      i_cache_addr <= 32'h00000004;
      i_cache_din <= 0;
      i_cache_rden <= 1;
      i_cache_wren <= 0;

      # 100; // This should be a miss

      i_cache_addr <= 32'h10000004;
      i_cache_din <= 0;
      i_cache_rden <= 1;
      i_cache_wren <= 0;

      # 100; // This should be a hit

      i_cache_addr <= 32'h00000005;
      i_cache_din <= 32'hBADDBEEF;
      i_cache_rden <= 1;
      i_cache_wren <= 0;

      # 100; // This should be a hit

      i_cache_addr <= 32'h10000006;
      i_cache_din <= 32'h00000000;
      i_cache_rden <= 1;
      i_cache_wren <= 0;

      # 100; // This should be a hit

      i_cache_addr <= 32'h00000007;
      i_cache_din <= 32'hAAAAAAAA;
      i_cache_rden <= 1;
      i_cache_wren <= 0;

      #50;

      /*for (i = 0; i < DUT_MEM.DEPTH; i = i + 1)
      begin
        $display("%b", DUT_MEM.mem[i]);
      end*/

      $finish;
    end

  initial
  begin
    //$monitor("time=%3d, addr=%1b, din=%1b, rden=%1b, wren=%1b, q=%1b, hit_miss=%1b", $time,i_cache_addr,i_cache_din,i_cache_rden,i_cache_wren,i_cache_q,i_cache_hit_miss);
    $monitor("time=%4d | addr=%10d | hm=%b | q=%08x | way1=%08h | way2=%08h | mem1=%08h | lru1=%d | lru2=%d" ,$time,i_cache_addr,i_cache_hit_miss,DUT_CACHE.q,DUT_CACHE.mem1[1],DUT_CACHE.mem2[1],DUT_MEM.mem[1],DUT_CACHE.lru1[1],DUT_CACHE.lru2[1]);
  end
 
  always
    begin
      clk = 1'b1;
      #5;
      clk = 1'b0;
      #5;
    end
   
endmodule
