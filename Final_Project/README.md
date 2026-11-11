# Final Project Dual-Core CPU APR

CPU 沿用 Midterm。三塊 cache 塞進同一顆 `SRAM_384x16`：0–255 是 data cache，256–319、320–383 是兩顆 core 的 instruction cache。Instruction block 從 128 筆縮成 64 筆，instruction 的 AXI write port 拿掉。Data cache 還是只 writeback dirty 的那一段。
## APR

只有一顆 SRAM，轉 90 度貼在左邊、垂直置中。Aspect ratio 0.73、utilization 0.9，cell 集中在 SRAM 右邊那塊長方形。Pin 拉到四邊的角落，讓相關邏輯可以靠過去。

面積還是靠 Lab11 那套：power pad 用最少、core ring 少、pad 到 core 的距離縮小。這次因為允許修改halo，所以我也將halo改到最小，讓core utilization可以最大。

## 詳情可以參考FP_bestcode_sharing.pdf

## Performance

- Area: rank 1 / 25/25
- Power: rank 9 / 22.18/25
- Overall: rank 1 / 97.18/100
- Latency 45307 / Area 576109.7
