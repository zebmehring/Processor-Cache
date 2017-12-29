
/*
 * Single-ported memory module.
 *
 * Public domain.
 *
 */

module mem
#(
  parameter WIDTH = 8,
  parameter DEPTH = 64,
  parameter FILE = "",
  parameter INIT = 0
)
(
  input  wire                 clock,
  input  wire [WIDTH-1:0]     data,
  input  wire [`CLOG2(DEPTH)-1:0] rdaddress,
  input  wire                 rden,
  input  wire [`CLOG2(DEPTH)-1:0] wraddress,
  input  wire                 wren,
  output reg  [WIDTH-1:0]     q
);

  reg [WIDTH-1:0] mem [0:DEPTH-1] /* synthesis ramstyle = "M20K" */;

  integer file;
  integer scan;
  integer i;

  initial
    begin
      // read file contents if FILE is given
      if (FILE != "")
        // If you get error here, check path to FILE
        $readmemh(FILE, mem);

      // set all data to 0 if INIT is true
      if (INIT)
        for (i = 0; i < DEPTH; i = i + 1)
          mem[i] = {WIDTH{1'b0}};
   end

  always @ (posedge clock)
  begin
    if (wren)
      mem[wraddress] <= data;
  end

  always @ (posedge clock)
  begin
    if (rden)
      q <= mem[rdaddress];
  end

endmodule

