
/*
 *
 * An instruction cache module
 *
 */
 
`define TAG 31:13		// position of tag in address
`define INDEX 12:2		// position of index in address
`define OFFSET 1:0		// position of offset in address

module i_cache
#(
  // Cache parameters
  parameter SIZE = 16*1024*8,
  parameter NWAYS = 2,
  parameter NSETS = 2048,
  parameter BLOCK_SIZE = 32,
  parameter WIDTH = 32,
  // Memory related paramter, make sure it matches memory module
  parameter MWIDTH = 32,		// same as block size
  // More cache related parameters
  parameter INDEX_WIDTH = 11,
  parameter TAG_WIDTH = 19,
  parameter OFFSET_WIDTH = 2
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
reg					lru1   [0:NSETS-1];
reg [TAG_WIDTH-1:0]	tag1   [0:NSETS-1];
reg [MWIDTH-1:0]	mem1   [0:NSETS-1] /* synthesis ramstyle = "M20K" */;

// WAY 2 cache data
reg					valid2 [0:NSETS-1];
reg					dirty2 [0:NSETS-1];
reg					lru2   [0:NSETS-1];
reg [TAG_WIDTH-1:0]	tag2   [0:NSETS-1];
reg [MWIDTH-1:0]	mem2   [0:NSETS-1] /* synthesis ramstyle = "M20K" */;

// initialize everything to 0
integer k;
initial
begin
	for(k = 0; k < NSETS; k = k +1)
	begin
		valid1[k] = 0;
		valid2[k] = 0;
		dirty1[k] = 0;
		dirty2[k] = 0;
		lru1[k] = 0;
		lru2[k] = 0;
	end
end

// internal registers
reg					_hit_miss = 1'b0;
reg [WIDTH-1:0]		_q = {WIDTH{1'b0}};
reg [MWIDTH-1:0]	_mdout = {MWIDTH{1'b0}};
reg [WIDTH-1:0]		_mwraddress = {WIDTH{1'b0}};
reg					_mwren = 1'b0;

// output assignments of internal registers
assign hit_miss = _hit_miss;
assign mrden = !((valid1[address[`INDEX]] && (tag1[address[`INDEX]] == address[`TAG]))
			  || (valid2[address[`INDEX]] && (tag2[address[`INDEX]] == address[`TAG])));
assign mwren = _mwren;
assign mdout = _mdout;
assign mrdaddress = {address[`TAG],address[`INDEX]};
assign mwraddress = _mwraddress;
assign q = _q;

// state parameters
parameter idle = 1'b0;		// receive requests from CPU 
parameter miss = 1'b1;	// miss state: write back dirty block and request memory data

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
					  ||  (valid2[address[`INDEX]] && (tag2[address[`INDEX]] == address[`TAG])));

			// do nothing on null request
			if(~rden && ~wren) currentState <= idle;
			
			// check way 1
			else if(valid1[address[`INDEX]] && (tag1[address[`INDEX]] == address[`TAG]))
			begin
				// read hit
				if(rden) _q <= mem1[address[`INDEX]];
				// write hit
				else if(wren)
				begin
					_q = {WIDTH{1'b0}};
					mem1[address[`INDEX]] <= din;
					dirty1[address[`INDEX]] <= 1;
				end
				// update LRU data
				lru1[address[`INDEX]] <= 0;
				lru2[address[`INDEX]] <= 1;
			end
			
			// check way 2
			else if(valid2[address[`INDEX]] && (tag2[address[`INDEX]] == address[`TAG]))
			begin
				// read hit
				if(rden) _q <= mem2[address[`INDEX]];
				// write hit
				else if(wren)
				begin
					_q = {WIDTH{1'b0}};
					mem2[address[`INDEX]] <= din;
					dirty2[address[`INDEX]] <= 1;
				end
				// update LRU data
				lru1[address[`INDEX]] <= 1;
				lru2[address[`INDEX]] <= 0;
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
			
			// way 1 is LRU
			else if(lru1[address[`INDEX]] == 1)
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
			else if(lru2[address[`INDEX]] == 1)
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

			currentState <= idle;
		end

		default: currentState <= idle;

	endcase

end

endmodule
