module des_tb();
	parameter DATA_WIDTH = 8;
	parameter CHECKER_DEPTH = 21;
	parameter TRUE = 1;
	parameter FALSE = 0;

	reg sClk;
	reg pClk;
	reg rst;
	reg [DATA_WIDTH-1:0] pData;
	reg sData;
	reg sData_delay_1;
	reg sData_delay_2;
	reg sData_delay_3;
	reg sData_delay_4;
	reg sData_delay_5;

	reg [(DATA_WIDTH*2)-1:0] comparison_data;

	reg [(DATA_WIDTH*2)-1:0] shifted_data_hold;

	reg [DATA_WIDTH-1:0] comparison_data_delay;

	reg pClk_counter;
	reg has_valid_data;

	deserializer my_des(
		.sDataIn(sData),
		.pDataOut(pData),
		.sClk(sClk),
		.pClk(pClk),
		.rst(rst)
	);

	shift_reg #(
		.OUTPUT_DATA_WIDTH(DATA_WIDTH*2),
		.INPUT_DATA_WIDTH(1),
		.SHIFT_MSB_TO_LSB(TRUE)
	) 	deserializer_checker(
			.data_in(sData_delay_5),
			.clk(sClk),
			.rst(rst),
			.data_out(comparison_data)
	);

	always@(posedge sClk) begin
		if(rst) begin
			sData_delay_1 <= '0;
			sData_delay_2 <= '0;
			sData_delay_3 <= '0;
			sData_delay_4 <= '0;
			sData_delay_5 <= '0;
		end
		else begin
			sData_delay_1 <= sData;
			sData_delay_2 <= sData_delay_1;
			sData_delay_3 <= sData_delay_2;
			sData_delay_4 <= sData_delay_3;
			sData_delay_5 <= sData_delay_4;
		end
	end

	always@(posedge pClk) begin
		if(rst) 
			pClk_counter <= '0;
		else
			if(pClk_counter)
				pClk_counter <= pClk_counter;
			else
				pClk_counter <= '0;
	end

	always@(posedge pClk) begin
		if(rst)
			has_valid_data <= '0;
		else
			if(pClk_counter)
				has_valid_data <= 1;
	end

	always@(posedge pClk) begin
		if(rst) 
			comparison_data_delay <= '0;
		else
			comparison_data_delay <= comparison_data[13:6];
	end

	always@(posedge pClk) begin
		if(!rst && has_valid_data)
			if(pData == comparison_data_delay)	
				$display("[SUCCESS] timestamp %0t, pData = %b comparison_data = %b", $realtime, pData, comparison_data_delay);
			else 
				$display("[FAIL] timestamp %0t, pData = %b comparison_data = %b", $realtime, pData, comparison_data_delay);
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

	 always @ (posedge sClk) begin
	 	if(rst) begin
	 		sData <= 0;
	 	end else begin
	 		sData <= $random;
	 	end
	 end

	 initial begin
		sData <= 0;
		forever begin
			@(posedge sClk);
			sData <= 0;
			@(posedge sClk);
			sData <= 1;
			@(posedge sClk);
			sData <= 0;
			@(posedge sClk);
	  		sData <= 0;
	 		@(posedge sClk);
	  		sData <= 1;
	  		@(posedge sClk);
	  		sData <= 0;
	  		@(posedge sClk);
	  		sData <= 1;
	  		@(posedge sClk);
			sData <= 1;
		end
	end

	initial begin
		#20000ps $finish;
	end

endmodule
