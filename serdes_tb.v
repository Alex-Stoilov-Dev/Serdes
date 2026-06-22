// TODO: Ask Stenly and Ivan about the Deserializer second_reg_negedge
// shifting
// At the moment, the data is not delayed by 1 clock cycle, as it should be.
// Removed all the #1ps delays, as that seems to be triggering race conditions
// in the deserializer
module serdes_tb();

	parameter TRUE = 1;
	parameter FALSE = 0;

	reg sClk;
	reg pClk;
	reg rst;
	reg [7:0] pDataInput;
	reg sData;
	reg [7:0] pDataOutput;

	reg [7:0] pDataInput_delay1;
	reg [7:0] pDataInput_delay2;
	reg [7:0] pDataInput_delay3;
	reg [7:0] pDataInput_delay4;
	reg [7:0] pDataInput_delay5;
	reg [7:0] pDataInput_delay6;

	reg [15:0] comparison_data;
	reg [7:0] comparison_data_delay;

	reg [15:0] des_sData_In_holder;

	reg [2:0] pClk_counter;
	reg has_valid_data;

	wire sData_ser_to_des;

	serializer my_ser(
		.sClk(sClk),
		.pClk(pClk),
		.rst(rst),
		.pDataIn(pDataInput),
		.sDataOut(sData)
	);

	assign #1ps sData_ser_to_des = sData;

	deserializer my_des(
		.sDataIn(sData_ser_to_des),
		.pDataOut(pDataOutput),
		.sClk(sClk),
		.pClk(pClk),
		.rst(rst)
	);
	
	shift_reg #(
		.OUTPUT_DATA_WIDTH(16),
		.INPUT_DATA_WIDTH(8),
		.SHIFT_MSB_TO_LSB(TRUE)
	) 	deserializer_out_hold(
			.data_in(pDataOutput),
			.clk(pClk),
			.rst(rst),
			.data_out(comparison_data)
	);

	always@(posedge pClk) begin
		if(rst) begin
			pClk_counter <= '0;
		end
		else begin
			if(pClk_counter == 3'b100) begin
				pClk_counter <= 3'b100;
			end 
			else begin
				pClk_counter <= pClk_counter + 1'b1;
			end
		end
	end

	always@(posedge pClk) begin
		if(rst) begin
			has_valid_data <= 0;
		end
		else begin
			if(pClk_counter == 3'b100) begin
				has_valid_data <= 1;
			end
			else 
				has_valid_data <= 0;
		end
	end

	always@(posedge pClk) begin
		if(rst) begin
			pDataInput_delay1 <= '0;	
			pDataInput_delay2 <= '0;	
			pDataInput_delay3 <= '0;	
			pDataInput_delay4 <= '0;	
			pDataInput_delay5 <= '0;
			pDataInput_delay6 <= '0;
		end
		else begin
			pDataInput_delay1 <= pDataInput;	
			pDataInput_delay2 <= pDataInput_delay1;	
			pDataInput_delay3 <= pDataInput_delay2;	
			pDataInput_delay4 <= pDataInput_delay3;	
			pDataInput_delay5 <= pDataInput_delay4;	
			pDataInput_delay6 <= pDataInput_delay5;
		end
	end

	always@(posedge pClk) begin
		if(rst)
			comparison_data_delay <= '0;
		else 
			comparison_data_delay <= comparison_data[10:3];
	end

	always@(posedge pClk) begin
		if(has_valid_data) begin
			if(pDataInput_delay6 == comparison_data_delay)
				$display("[SUCCESS] timestamp %0t, pDataOut = %b comparison_data = %b", $realtime, pDataInput_delay6, comparison_data_delay);
			else
				$display("[FAIL] timestamp %0t, pDataInput_delayed = %b comparison_data = %b", $realtime, pDataInput_delay6, comparison_data_delay);
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

	// always @ (posedge pClk) begin
	// 	if(rst) begin
	// 		pDataInput <= '0;
	// 	end else begin
	// 		pDataInput <= $random;
	// 	end
	// end

	shift_reg #(
		.OUTPUT_DATA_WIDTH(16),
		.INPUT_DATA_WIDTH(1),
		.SHIFT_MSB_TO_LSB(TRUE)
	) 	deserializer_checker(
			.data_in(sData),
			.clk(sClk),
			.rst(rst),
			.data_out(des_sData_In_holder)
	);

	initial begin
		forever begin
			@(posedge pClk);
				pDataInput <= 8'hab;
			@(posedge pClk);
				pDataInput <= 8'hcd;
			@(posedge pClk);
				pDataInput <= 8'hef;
			@(posedge pClk);
				pDataInput <= 8'hde;
			@(posedge pClk);
				pDataInput <= 8'had;
		end
	end

	initial begin
		#150 $finish;
	end
endmodule
