module ser_test_bench();

	parameter DATA_WIDTH= 8;
	parameter TRUE = 1;
	parameter FALSE = 0;

	reg sClk;
	reg pClk;
	reg rst;
	reg [DATA_WIDTH-1:0] pData;
	reg sData;

	reg [DATA_WIDTH-1:0] shifted_data;
	reg [DATA_WIDTH-1:0] shifted_data_delay_1;
	reg [DATA_WIDTH-1:0] shifted_data_delay_2;

	reg [DATA_WIDTH-1:0] comparison_data;
	reg sData_delay1;
	reg sData_delay2;
	reg sData_delay3;
	reg sData_delay4;

	reg [1:0] pClk_counter;
	reg has_valid_data;

	serializer my_ser(
		.sClk(sClk),
		.pClk(pClk),
		.rst(rst),
		.pDataIn(pData),
		.sDataOut(sData)
	);

	always@(posedge sClk) begin
		if(rst) begin
			sData_delay1 <= '0;
			sData_delay2 <= '0;
			sData_delay3 <= '0;
			sData_delay4 <= '0;
		end
		else begin
			sData_delay1 <= sData;
			sData_delay2 <= sData_delay1;
			sData_delay3 <= sData_delay2;
			sData_delay4 <= sData_delay3;
		end
	end

	always@(posedge pClk) begin
		if(rst) begin
			pClk_counter <= '0;
		end
		else begin
			if(pClk_counter == 2'b10) begin
				pClk_counter <= 2'b10;
			end 
			else begin
				pClk_counter <= pClk_counter + 1'b1;
			end
		end
	end

	always@(posedge sClk) begin
		if(rst) begin
			has_valid_data <= 0;
		end
		else begin
			if(pClk_counter == 2'b10) begin
				has_valid_data <= 1;
			end
			else 
				has_valid_data <= 0;
		end
	end

	always@(posedge pClk) begin
		#1ps;
		if(rst) begin
			shifted_data <= '0;
		end
		else begin
			shifted_data <= pData;
		end
	end

	always@(posedge pClk) begin
		if(rst) begin
			shifted_data_delay_1 <= '0;
			shifted_data_delay_2 <= '0;
		end
		else begin
			shifted_data_delay_1 <= shifted_data;
			shifted_data_delay_2 <= shifted_data_delay_1;
		end
	end
	
	shift_reg #(
		.OUTPUT_DATA_WIDTH(DATA_WIDTH),
		.INPUT_DATA_WIDTH(1),
		.SHIFT_MSB_TO_LSB(TRUE)
	) 	serializer_checker(
			.data_in(sData_delay3),
			.clk(sClk),
			.rst(rst),
			.data_out(comparison_data)
	);

	always@(posedge pClk) begin
		if(!rst) begin
			if(has_valid_data) begin
				if(shifted_data_delay_2 == comparison_data)
					$display("[OK]");
				else				
					$display("[FAIL] time=%0t pData=%b, comparison_data=%b", $realtime, shifted_data_delay_2, comparison_data);
			end
		end
	end

	initial begin
		sClk = 1;
		pClk = 1;
	end

	always begin
		#60ps sClk = ~sClk;
	end

	always begin
		#480ps pClk = ~pClk;
	end

	initial begin
		rst <= 0;
		repeat(2)@(posedge pClk);
		rst <= 1;
		repeat(2)@(posedge pClk);
		rst <= 0;
	end

	always @ (posedge pClk) begin
		if(rst) begin
			pData <= 0;
		end else begin
			pData <= $random;
		end
	end

	initial begin
		#15000ps $finish;
	end
endmodule
