module shift_reg #(
        parameter OUTPUT_DATA_WIDTH=8,
        parameter INPUT_DATA_WIDTH=1,
        parameter SHIFT_MSB_TO_LSB=1
    )(
    input [INPUT_DATA_WIDTH-1:0] data_in,                     
    input clk,                   
    input rst,                  
    output reg [OUTPUT_DATA_WIDTH-1:0] data_out
    ); 

   always @ (posedge clk) begin
        if (rst) begin
            data_out <= 0;
        end
        else begin
            if(SHIFT_MSB_TO_LSB)
                data_out <= {data_in, data_out[OUTPUT_DATA_WIDTH-1:INPUT_DATA_WIDTH]}; // Shift left -> right
            else
            	data_out <= {data_out[OUTPUT_DATA_WIDTH-INPUT_DATA_WIDTH-1:0], data_in}; // Shift right -> left
        end
    end
endmodule
