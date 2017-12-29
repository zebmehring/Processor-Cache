SHELL := /bin/bash

all: run

i_cache.vvp: ../i_cache.v ../clog2.v ../mem.v i_cache_tb.v
	@echo "Building..."
	iverilog -Wall -Wno-timescale -o i_cache.vvp ../i_cache.v ../clog2.v ../mem.v i_cache_tb.v
	@echo "Done building."
 
run: i_cache.vvp
	@echo "Simulating..."
	@./i_cache.vvp
	@echo "Done simulating."

clean:
	rm -f i_cache.vvp

