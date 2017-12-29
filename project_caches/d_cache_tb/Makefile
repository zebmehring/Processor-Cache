SHELL := /bin/bash

all: run

d_cache.vvp: ../d_cache.v ../clog2.v ../mem.v d_cache_tb.v
	@echo "Building..."
	iverilog -Wall -Wno-timescale -o d_cache.vvp ../d_cache.v ../clog2.v ../mem.v d_cache_tb.v
	@echo "Done building."
 
run: d_cache.vvp
	@echo "Simulating..."
	@./d_cache.vvp
	@echo "Done simulating."

clean:
	rm -f d_cache.vvp

