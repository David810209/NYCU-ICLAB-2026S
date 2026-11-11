# Lab09 Dessert Shop Simulator

Price、cost、salary、hire fee、threshold、除以 10 全部做成 LUT。乘法只留一顆 16×11 shift-add，用 7-to-1 mux 選操作數。DRAM 的第二筆 read 在用不到時直接 abort，少一次 round trip。

這次我用很大量的look up table去省面積跟latency，不過後來跟同學討論後，發現其實有部分的運算還是可以用算的，像是cost of restocking，可以只LUT那個level/10就好，其他自己算，這樣有可能可以衝到前十名。

心得：
1. look up table很好用，尤其在數值範圍很固定的時候，但還是可以觀察一下，有的運算其實可以直接算，最後會比較好，可以多嘗試。
2. 當遇到這種DRAM latency很大的時候，大家的latency都會很高，所以要盡量壓低cycle time，越低越好。我的作法是乘法器直接用shift add、然後那些運算全部都用LUT。

## Performance

- Rank 12 / Score 95.6
- CT 2.9 / Latency 761292 / Area 155361.9
- Cost: \(CT \times Latency \times Area\)
