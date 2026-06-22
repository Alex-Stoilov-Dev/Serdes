module deserializer(
	input sDataIn,
	input sClk,
	input pClk,
	input rst,
	output reg [7:0] pDataOut
);

	wire sClk_div_2;
	wire sClk_div_4;

	reg first_reg;
	reg second_reg_posedge;
	reg second_reg_negedge;
	reg [1:0] third_reg_posedge;
	reg [1:0] third_reg_negedge;
	reg [3:0] fourth_reg_posedge;
	reg [3:0] fourth_reg_negedge;
	
	wire first_reg_delay;
	wire second_reg_posedge_delay;
	wire second_reg_negedge_delay;
	wire [1:0] second_to_third_reg;
	wire [1:0] third_reg_posedge_delay;
	wire [1:0] third_reg_negedge_delay;
	wire [3:0] fourth_reg_posedge_delay;
	wire [3:0] fourth_reg_negedge_delay;

	clk_divider sClk_over_2 (
		.clk(sClk),
		.rst(rst),
		.output_q(sClk_div_2)
	);

	clk_divider sClk_over_4(
		.clk(rst ? sClk : sClk_div_2),
		.rst(rst),
		.output_q(sClk_div_4)
	);

	always@(posedge sClk) begin
		if(rst)
			first_reg <= 0;
		else
			first_reg <= sDataIn;
	end

	assign #1ps first_reg_delay = first_reg;

	always@(posedge sClk_div_2 or posedge rst) begin
		if(rst)
			second_reg_posedge <= 0;
		else
			second_reg_posedge <= first_reg_delay;
	end

	always@(negedge sClk_div_2 or posedge rst) begin
		if(rst)
			second_reg_negedge <= 0;
		else
			second_reg_negedge <= first_reg_delay;
	end
	
	assign #1ps second_reg_posedge_delay = second_reg_posedge;
	assign #1ps second_reg_negedge_delay = second_reg_negedge;
	assign #1ps second_to_third_reg = {second_reg_negedge_delay, second_reg_posedge_delay};

	always@(posedge sClk_div_4 or posedge rst) begin
		if(rst)		
			third_reg_posedge <= 0;
		else
			third_reg_posedge <= second_to_third_reg;
	end

	always@(negedge sClk_div_4 or posedge rst) begin
		if(rst)
			third_reg_negedge <= 0;
		else
			third_reg_negedge <= second_to_third_reg;
	end
	
	assign #1ps third_reg_posedge_delay = third_reg_posedge;
	assign #1ps third_reg_negedge_delay = third_reg_negedge;

	always@(posedge pClk) begin
		if(rst)
			fourth_reg_posedge <= 0;
		else
			fourth_reg_posedge <= {third_reg_negedge_delay, third_reg_posedge_delay};
	end

	always@(negedge pClk) begin
		if(rst)
			fourth_reg_negedge <= 0;
		else
			fourth_reg_negedge <= {third_reg_negedge_delay, third_reg_posedge_delay};	
	end

	assign #1ps fourth_reg_posedge_delay = fourth_reg_posedge;
	assign #1ps fourth_reg_negedge_delay = fourth_reg_negedge;

	always@(posedge pClk) begin
		if(rst)
			pDataOut <= 0;
		else
			pDataOut <= {fourth_reg_negedge_delay, fourth_reg_posedge_delay};

	end

endmodule
