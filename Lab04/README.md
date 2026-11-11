# Lab04 Convolution and Deconvolution Network Accelerator

Conv 一次算兩個 channel，各掛 9 顆 `DW_fp_mult`，後面用 `DW_fp_sum3` 。convolution的主要解法跟Lab02的DPC一樣，用 shift register 跟固定 window 的定址來做靜態選址，可以降低很多面積。

`DW_fp_div` 和 `DW_fp_exp` 全設計只留一顆，preprocess、conv、unpool 輪流用。

Pooling 直接在 conv 的 shift register 上做 2×2 max，不用再把 feature map 讀出來。偶數拍比左右兩點並記下是哪一格，奇數拍把同一顆 `DW_fp_cmp` 的輸入改成這兩個勝者，所以 2×2 只花兩顆比較器。每個 window 只留最大值和 2-bit 的位置。Unpool 用這 2 bit 決定寫回 window 的哪一格，另外三格補 0。

## Performance

- Rank 6 / Score 98.26
- CT 24.5 / Latency 12400 / Area 3755865
- Cost: \((CT \times Latency)^2 \times Area\)
