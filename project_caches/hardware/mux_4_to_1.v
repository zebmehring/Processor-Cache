module mux_4_to_1 
(
  output  wire	[63:0]  Y,
  input   wire 	[63:0]  A, B, C, D,
  input   wire  [1:0]	sel
);

reg [63:0] _Y;
assign Y = _Y;

always @(*) begin
	case (sel)
		2'b00:   _Y = A;
		2'b01:   _Y = B;
		2'b10:   _Y = C;
		2'b11:   _Y = D;
	endcase
end

endmodule