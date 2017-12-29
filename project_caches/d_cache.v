
/*
 *
 * A data cache module
 *
 */

`define TAG 31:13		// position of tag in address
`define INDEX 12:3		// position of index in address
`define OFFSET 2:0		// position of offset in address
 
module d_cache
#(
  // Cache parameters
  parameter SIZE = 32*1024*8,
  parameter NWAYS = 4,
  parameter NSETS = 1024,
  parameter BLOCK_SIZE = 64,
  parameter WIDTH = 32,
  // Memory related paramter, make sure it matches memory module
  parameter MWIDTH = 64,  // same as block size
  // More cache related parameters
  parameter INDEX_WIDTH = 10,
  parameter TAG_WIDTH = 19,
  parameter OFFSET_WIDTH = 3,
  parameter WORD1 = 3,
  parameter WORD2 = 7
)
(
  input  wire                      clock,
  input  wire [WIDTH-1:0]          address,    // address form CPU
  input  wire [WIDTH-1:0]          din,        // data from CPU (if st inst)
  input  wire                      rden,       // 1 if ld instruction
  input  wire                      wren,       // 1 if st instruction
  output wire                      hit_miss,   // 1 if hit, 0 while handling miss
  output wire [WIDTH-1:0]          q,          // data from cache to CPU
  output wire [MWIDTH-1:0]         mdout,      // data from cache to memory
  output wire [WIDTH-1:0]          mrdaddress, // memory read address
  output wire                      mrden,      // read enable, 1 if reading from memory
  output wire [WIDTH-1:0]          mwraddress, // memory write address
  output wire                      mwren,      // write enable, 1 if writing to memory
  input  wire [MWIDTH-1:0]         mq          // data coming from memory
);

/*******************************************************************
* Global Parameters and Initializations
*******************************************************************/

// WAY 1 cache data
reg					valid1 [0:NSETS-1];
reg					dirty1 [0:NSETS-1];
reg [1:0] 			lru1   [0:NSETS-1];
reg [TAG_WIDTH-1:0] tag1   [0:NSETS-1];
reg [MWIDTH-1:0]	mem1   [0:NSETS-1] /* synthesis ramstyle = "M20K" */;

// WAY 2 cache data
reg					valid2 [0:NSETS-1];
reg 				dirty2 [0:NSETS-1];
reg [1:0]			lru2   [0:NSETS-1];
reg [TAG_WIDTH-1:0]	tag2   [0:NSETS-1];
reg [MWIDTH-1:0]	mem2   [0:NSETS-1] /* synthesis ramstyle = "M20K" */;

// WAY 3 cache data
reg					valid3 [0:NSETS-1];
reg					dirty3 [0:NSETS-1];
reg [1:0]			lru3   [0:NSETS-1];
reg [TAG_WIDTH-1:0]	tag3   [0:NSETS-1];
reg [MWIDTH-1:0]	mem3   [0:NSETS-1] /* synthesis ramstyle = "M20K" */;

// WAY 4 cache data
reg					valid4 [0:NSETS-1];
reg					dirty4 [0:NSETS-1];
reg [1:0]			lru4   [0:NSETS-1];
reg [TAG_WIDTH-1:0]	tag4   [0:NSETS-1];
reg [MWIDTH-1:0]	mem4   [0:NSETS-1] /* synthesis ramstyle = "M20K" */;

// initialize the cache to zero
integer k;
initial
begin
	for(k = 0; k < NSETS; k = k +1)
	begin
		valid1[k] = 0;
		valid2[k] = 0;
		valid3[k] = 0;
		valid4[k] = 0;
		dirty1[k] = 0;
		dirty2[k] = 0;
		dirty3[k] = 0;
		dirty4[k] = 0;
		lru1[k] = 2'b00;
		lru2[k] = 2'b00;
		lru3[k] = 2'b00;
		lru4[k] = 2'b00;
	end
end

// internal registers
reg				 _hit_miss = 1'b0;
reg [WIDTH-1:0]	 _q = {WIDTH{1'b0}};
reg [MWIDTH-1:0] _mdout = {MWIDTH{1'b0}};
reg [WIDTH-1:0]	 _mwraddress = {WIDTH{1'b0}};
reg				 _mwren = 1'b0;

// output assignments of internal registers
assign hit_miss = _hit_miss;
assign mrden = !((valid1[address[`INDEX]] && (tag1[address[`INDEX]] == address[`TAG]))
			 ||  (valid2[address[`INDEX]] && (tag2[address[`INDEX]] == address[`TAG]))
			 ||  (valid3[address[`INDEX]] && (tag3[address[`INDEX]] == address[`TAG]))
			 ||  (valid4[address[`INDEX]] && (tag4[address[`INDEX]] == address[`TAG])));
assign mwren = _mwren;
assign mdout = _mdout;
assign mrdaddress = {address[`TAG],address[`INDEX]};
assign mwraddress = _mwraddress;
assign q = _q;

// state parameters
parameter idle = 1'b0;		// receive requests from CPU 
parameter miss = 1'b1;	 	// write back dirty block and put in new data

// state register
reg currentState = idle;

/*******************************************************************
* State Machine
*******************************************************************/

always @(posedge clock)
begin	
	case (currentState)
		idle: begin
			// reset write enable, if it was turned on
			_mwren <= 0;
			// set _hit_miss register
			_hit_miss <= ((valid1[address[`INDEX]] && (tag1[address[`INDEX]] == address[`TAG]))
					  ||  (valid2[address[`INDEX]] && (tag2[address[`INDEX]] == address[`TAG]))
					  ||  (valid3[address[`INDEX]] && (tag3[address[`INDEX]] == address[`TAG]))
					  ||  (valid4[address[`INDEX]] && (tag4[address[`INDEX]] == address[`TAG])));

			// do nothing on a null request
			if(~rden && ~wren) currentState <= idle;

			// check way 1
			else if(valid1[address[`INDEX]] && (tag1[address[`INDEX]] == address[`TAG]))
			begin
				// read hit
				if(rden) _q <= (address[`OFFSET] <= WORD1) ? mem1[address[`INDEX]][WIDTH-1:0] : mem1[address[`INDEX]][2*WIDTH-1:WIDTH];
				// write hit
				else if(wren)
				begin
					_q = {WIDTH{1'b0}};
					dirty1[address[`INDEX]] <= 1;
					if(address[`OFFSET] <= WORD1) mem1[address[`INDEX]][WIDTH-1:0] <= din;
					else mem1[address[`INDEX]][2*WIDTH-1:WIDTH] <= din;
				end
				// update LRU data
				if(lru2[address[`INDEX]] <= lru1[address[`INDEX]]) lru2[address[`INDEX]] <= lru2[address[`INDEX]] + 1;
				if(lru3[address[`INDEX]] <= lru1[address[`INDEX]]) lru3[address[`INDEX]] <= lru3[address[`INDEX]] + 1;
				if(lru4[address[`INDEX]] <= lru1[address[`INDEX]]) lru4[address[`INDEX]] <= lru4[address[`INDEX]] + 1;
				lru1[address[`INDEX]] <= 0;
			end
			
			// check way 2
			else if(valid2[address[`INDEX]] && (tag2[address[`INDEX]] == address[`TAG]))
			begin
				// read hit
				if(rden) _q <= (address[`OFFSET] <= WORD1) ? mem2[address[`INDEX]][WIDTH-1:0] : mem2[address[`INDEX]][2*WIDTH-1:WIDTH];
				// write hit
				else if(wren)
				begin
					_q = {WIDTH{1'b0}};
					dirty2[address[`INDEX]] <= 1;
					if(address[`OFFSET] <= WORD1) mem2[address[`INDEX]][WIDTH-1:0] <= din;
					else mem2[address[`INDEX]][2*WIDTH-1:WIDTH] <= din;
				end
				// update LRU data
				if(lru1[address[`INDEX]] <= lru2[address[`INDEX]]) lru1[address[`INDEX]] <= lru1[address[`INDEX]] + 1;
				if(lru3[address[`INDEX]] <= lru2[address[`INDEX]]) lru3[address[`INDEX]] <= lru3[address[`INDEX]] + 1;
				if(lru4[address[`INDEX]] <= lru2[address[`INDEX]]) lru4[address[`INDEX]] <= lru4[address[`INDEX]] + 1;
				lru2[address[`INDEX]] <= 0;
			end
			
			// check way 3
			else if(valid3[address[`INDEX]] && (tag3[address[`INDEX]] == address[`TAG]))
			begin
				// read hit
				if(rden) _q <= (address[`OFFSET] <= WORD1) ? mem3[address[`INDEX]][WIDTH-1:0] : mem3[address[`INDEX]][2*WIDTH-1:WIDTH];
				// write hit
				else if(wren)
				begin
					_q = {WIDTH{1'b0}};
					dirty3[address[`INDEX]] <= 1;
					if(address[`OFFSET] <= WORD1) mem3[address[`INDEX]][WIDTH-1:0] <= din;
					else mem3[address[`INDEX]][2*WIDTH-1:WIDTH] <= din;
				end
				// update LRU data
				if(lru1[address[`INDEX]] <= lru3[address[`INDEX]]) lru1[address[`INDEX]] <= lru1[address[`INDEX]] + 1;
				if(lru2[address[`INDEX]] <= lru3[address[`INDEX]]) lru2[address[`INDEX]] <= lru2[address[`INDEX]] + 1;
				if(lru4[address[`INDEX]] <= lru3[address[`INDEX]]) lru4[address[`INDEX]] <= lru4[address[`INDEX]] + 1;
				lru3[address[`INDEX]] <= 0;
			end
			
			// check way 4
			else if(valid4[address[`INDEX]] && (tag4[address[`INDEX]] == address[`TAG]))
			begin
				// read hit
				if(rden) _q <= (address[`OFFSET] <= WORD1) ? mem4[address[`INDEX]][WIDTH-1:0] : mem4[address[`INDEX]][2*WIDTH-1:WIDTH];
				// write hit
				else if(wren)
				begin
					_q = {WIDTH{1'b0}};
					dirty4[address[`INDEX]] <= 1;
					if(address[`OFFSET] <= WORD1) mem4[address[`INDEX]][WIDTH-1:0] <= din;
					else mem4[address[`INDEX]][2*WIDTH-1:WIDTH] <= din;
				end
				// update LRU data
				if(lru1[address[`INDEX]] <= lru4[address[`INDEX]]) lru1[address[`INDEX]] <= lru1[address[`INDEX]] + 1;
				if(lru2[address[`INDEX]] <= lru4[address[`INDEX]]) lru2[address[`INDEX]] <= lru2[address[`INDEX]] + 1;
				if(lru3[address[`INDEX]] <= lru4[address[`INDEX]]) lru3[address[`INDEX]] <= lru3[address[`INDEX]] + 1;
				lru4[address[`INDEX]] <= 0;
			end
			
			// miss
			else currentState <= miss;
		end
	
		miss: begin
			// one of the ways is invalid -- no need to evict
			if(~valid1[address[`INDEX]])
			begin
				mem1[address[`INDEX]] <= mq;
				tag1[address[`INDEX]] <= address[`TAG];
				dirty1[address[`INDEX]] <= 0;
				valid1[address[`INDEX]] <= 1;
			end

			else if(~valid2[address[`INDEX]])
			begin
				mem2[address[`INDEX]] <= mq;
				tag2[address[`INDEX]] <= address[`TAG];
				dirty2[address[`INDEX]] <= 0;
				valid2[address[`INDEX]] <= 1;
			end

			else if(~valid3[address[`INDEX]])
			begin
				mem3[address[`INDEX]] <= mq;
				tag3[address[`INDEX]] <= address[`TAG];
				dirty3[address[`INDEX]] <= 0;
				valid3[address[`INDEX]] <= 1;
			end

			else if(~valid4[address[`INDEX]])
			begin
				mem4[address[`INDEX]] <= mq;
				tag4[address[`INDEX]] <= address[`TAG];
				dirty4[address[`INDEX]] <= 0;
				valid4[address[`INDEX]] <= 1;
			end
			
			// way 1 is LRU
			else if(lru1[address[`INDEX]] == 3)
			begin
				// dirty block writeback
				if(dirty1[address[`INDEX]] == 1)
				begin
					_mwraddress <= {tag1[address[`INDEX]],address[`INDEX]}; 
					_mwren <= 1;
					_mdout <= mem1[address[`INDEX]];
				end
				mem1[address[`INDEX]] <= mq;
				tag1[address[`INDEX]] <= address[`TAG];
				dirty1[address[`INDEX]] <= 0;
				valid1[address[`INDEX]] <= 1;
			end
			
			// way 2 is LRU
			else if(lru2[address[`INDEX]] == 3)
			begin
				// dirty block writeback
				if(dirty2[address[`INDEX]] == 1)
				begin
					_mwraddress <= {tag2[address[`INDEX]],address[`INDEX]};  
					_mwren <= 1;
					_mdout <= mem2[address[`INDEX]];
				end
				mem2[address[`INDEX]] <= mq;
				tag2[address[`INDEX]] <= address[`TAG];
				dirty2[address[`INDEX]] <= 0;
				valid2[address[`INDEX]] <= 1;
			end
			
			// way 3 is LRU
			else if(lru3[address[`INDEX]] == 3)
			begin
				// dirty block writeback
				if(dirty3[address[`INDEX]] == 1)
				begin
					_mwraddress <= {tag3[address[`INDEX]],address[`INDEX]};  
					_mwren <= 1;
					_mdout <= mem3[address[`INDEX]];
				end
				mem3[address[`INDEX]] <= mq;
				tag3[address[`INDEX]] <= address[`TAG];
				dirty3[address[`INDEX]] <= 0;
				valid3[address[`INDEX]] <= 1;
			end
			
			// way 4 is LRU
			else if(lru4[address[`INDEX]] == 3)
			begin
				// dirty block writeback
				if(dirty4[address[`INDEX]] == 1)
				begin
					_mwraddress <= {tag4[address[`INDEX]],address[`INDEX]};  
					_mwren <= 1;
					_mdout <= mem4[address[`INDEX]];
				end
				mem4[address[`INDEX]] <= mq;
				tag4[address[`INDEX]] <= address[`TAG];
				dirty4[address[`INDEX]] <= 0;
				valid4[address[`INDEX]] <= 1;
			end

			currentState <= idle;
		end

		default: currentState <= idle;

	endcase

end

endmodule

