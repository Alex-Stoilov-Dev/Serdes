module clk_divider(
	input clk,
	input rst,
	output reg output_q
);


	always@(posedge clk) begin
		if (rst) begin
			output_q <= 1'b0;
		end else begin
			output_q <= ~output_q;
		end
	end

endmodule
