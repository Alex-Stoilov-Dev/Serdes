module serializer(
	input sClk,
	input pClk,
	input rst,
	input [7:0] pDataIn,
	output reg sDataOut
);

	reg [7:0] pData_8bit_reg;
	reg [3:0] pData_8_to_4_reg;
	reg [1:0] pData_4_to_2_reg;
  
	wire MUX_SEL_1;
	wire MUX_SEL_2;
	wire MUX_SEL_3;

	wire sClk_div_2;
	wire sClk_div_4;

	wire [3:0] pData_8_to_4_wire;
	wire [1:0] pData_4_to_2_wire;

	wire sData_delay;

	clk_divider MUX_CNTRL_1(
		.clk(sClk),
		.rst(rst),
		.output_q(MUX_SEL_1)
	);

	clk_divider sClk_FIRST_DIVIDER(
		.clk(sClk),
		.rst(rst),
		.output_q(sClk_div_2)
	);

	clk_divider MUX_CNTRL_2(
		.clk(rst ? sClk : sClk_div_2),
		.rst(rst),
		.output_q(MUX_SEL_2)
	);

	clk_divider sClk_SECOND_DIVIDER(
		.clk(rst ? sClk : sClk_div_2),
		.rst(rst),
		.output_q(sClk_div_4)
	);

	clk_divider MUX_CNTRL_3(
		.clk(rst ? sClk : sClk_div_4),
		.rst(rst),
		.output_q(MUX_SEL_3)
	);


	always@(posedge pClk or posedge rst) begin
		if(rst) begin
			pData_8bit_reg <= 0;
		end
		else 
			pData_8bit_reg <= pDataIn;
	end

	assign #1ps pData_8_to_4_wire = MUX_SEL_3 ? pData_8bit_reg[7:4] : pData_8bit_reg[3:0];

	always@(posedge sClk_div_4 or posedge rst) begin
		if(rst) begin
			pData_8_to_4_reg <= 0;
		end
		else begin	
			pData_8_to_4_reg <= pData_8_to_4_wire;
		end
	end

	assign #1ps pData_4_to_2_wire = ~MUX_SEL_2 ? pData_8_to_4_reg[3:2] : pData_8_to_4_reg [1:0];

	always@(posedge sClk_div_2 or posedge rst) begin
		if(rst) 
			pData_4_to_2_reg <= 0;
		else begin	
			pData_4_to_2_reg <= pData_4_to_2_wire;
		end
	end

	assign #1ps pData_2_to_1_wire = ~MUX_SEL_1 ? pData_4_to_2_reg[1] : pData_4_to_2_reg[0];

	assign #1ps sData_delay = pData_2_to_1_wire;

	always@(posedge sClk or posedge rst) begin
		if(rst) 
			sDataOut <= 0;
		else begin	
			sDataOut <= sData_delay;
		end
	end
	

endmodule
