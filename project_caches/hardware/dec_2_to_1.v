module dec_2_to_1
(
	output wire 	  out,
	input  wire [1:0] in
);

reg _out;
assign out = _out;

always @(*) begin
	case (in)
		2'b01: _out = 1'b0;
		2'b10: _out = 1'b1;
		default: _out = 1'bz;
	endcase
end

endmodule