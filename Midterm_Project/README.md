# Midterm Project Dual-Core CPU

兩顆 core 輪流跟同一套 instruction cache 要指令。每顆 core 只留一個 block，miss 時用 AXI burst 一次抓 128 筆（256 byte）。

Data cache 有兩個 block。Store 只記下 dirty 的起點和終點，writeback 只送這一段，不把整條 cache line 寫回 DRAM。

## 詳情可以看MP_bestcode_sharing.pdf

## Performance

- Rank 2 / Score 109.49/110
- CT 3.5 / Latency 56750 / Area 203112.9
- Cost: \(CT \times Latency \times Area^2\)
