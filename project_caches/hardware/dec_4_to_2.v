module dec_4_to_2
(
	output wire [1:0] out,
	input  wire [3:0] in
);

reg [1:0] _out;
assign out = _out;

always @(*) begin
	case (in)
		4'b0001: _out = 2'b00;
		4'b0010: _out = 2'b01;
		4'b0100: _out = 2'b10;
		4'b1000: _out = 2'b11;
		default: _out = 2'bzz;
	endcase
end

endmodule