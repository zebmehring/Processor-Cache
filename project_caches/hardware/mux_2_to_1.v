module mux_2_to_1
(
  output  wire	[31:0]  Y,
  input   wire 	[31:0]  A, B,
  input   wire  		sel
);

reg [31:0] _Y;
assign Y = _Y;

always @(*) begin
	case (sel)
		1'b0:   _Y = A;
		1'b1:   _Y = B;
	endcase
end

endmodule