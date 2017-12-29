# Processor-Cache
A Verilog implementation of a data and instruction processor cache, created as part of a final project for Computer Architecture (EENG 467) at Yale. Auxillary modules such as memory and testbench initialization were created by Jakub Szefer.

The data cache implements a 32 KiB, 4-way set associative, 2-word block cache with 32 bit words. The instruction cache implements a 16 KiB, 2-way set associative, 1-word block cache with 32 bit words. Both are write-back, write-allocate caches with an LRU replacement policy.
