(*keep_hierarchy = "yes"*) module FIFO
	#(
		parameter WORD_SIZE = 8,
		parameter BUFFER_SIZE = 256	// If this is not a power of two, the actual buffer size will be the smallest power of two greater than BUFFER_SIZE
	)(
		input wire clk,
		input wire rst,
		input wire [WORD_SIZE-1:0] data_in,
		input wire we,

		output wire [WORD_SIZE-1:0] data_out,
		input wire oe,
		
		output wire isData,
		output wire bufferFull
    );

	localparam ADDRESS_SIZE = $clog2(BUFFER_SIZE);
	localparam DEPTH = 1 << ADDRESS_SIZE;

	reg we_buffered = 1'b0;
	reg oe_buffered = 1'b0;
	reg [WORD_SIZE-1:0] data_in_buffered = 'b0;

	reg [ADDRESS_SIZE-1:0] startPointer = 'b0;
	reg [ADDRESS_SIZE-1:0] endPointer = 'b0;
	reg [WORD_SIZE-1:0] buffer [DEPTH-1:0];

	assign isData = startPointer != endPointer;

	always @(posedge clk) begin
		if (rst) begin
			we_buffered <= 1'b0;
			oe_buffered <= 1'b0;
			data_in_buffered <= 'b0;
		end else begin
			we_buffered <= we;
			oe_buffered <= oe;
			data_in_buffered <= data_in;
		end
	end

	assign bufferFull = endPointer + 1 == startPointer;

	always @(negedge clk) begin
		if (rst) begin
			startPointer = 'b0;
			endPointer = 'b0;
		end else begin
			// Update start pointer first, so that if the buffer is full and we try to write, 
			//  it will still work if we are also reading on this update
			if (oe_buffered) begin
				if (startPointer != endPointer) begin
					startPointer = startPointer + 1;
				end
			end

			if (we_buffered) begin
				// TODO: Should we allow the buffer to overwrite itself when a write occurs and it is already full
				if (endPointer + 1 != startPointer) begin
					buffer[endPointer] = data_in_buffered;
					endPointer = endPointer + 1;
				end
			end
		end
	end

	assign data_out = buffer[startPointer];
	

endmodule