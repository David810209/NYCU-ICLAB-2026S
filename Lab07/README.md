# Lab07 Harvester with Clock Domain Crossing

## Harvester:
Calc 用 stack 做，value stack 和 operation stack 都是 shift register。這次最深只會到 13 和 8，所以就只開這兩個深度，面積少很多。

## DRAM controller: 
controller 收進一條 8 深的 address queue。每個 bank 記著目前開著的 row：同一個 row 直接 READ，換 row 才 PRECHARGE 再 ACT。Queue 或 FIFO 滿就停發，DRAM 的等待不會卡住 clk2 的計算。

## AXI:
AXI 的 data 是 64-bit，FIFO 只有 32-bit，所以一筆拆成兩拍。R channel 先送 `[63:32]`，再送 `[31:0]`，用一個 flag 分前後半。clk2 把第一拍留在 `r_last_data`，第二拍拼成 `{r_last_data, r_fifo_rdata}`。輸出到 clk1 也是兩拍 32-bit 到齊再拼回 64-bit，FIFO 滿就擋住 `out_valid`。

`ar_out_valid` 被 `ar_fifo_full` 組合邏輯直接閘住。FIFO 一滿，ready 往回拉的那條 path 會吃掉 cycle time。解法很爛但有效：兩 cycle 才送一筆 request。latency會比較爛，但幸運地過了goal拿到滿分。

Mean / variance 的除法做成一拍一位的 iterative divider。優化面積。

## 心得：
FIFO的size比axi data bit width小真的很難做，需要做比較複雜的控制。
dram controller其實很難寫，可以用fifo設計，會簡單很多。
像這次lab這種會因為output module的clock rate太慢，導致back pressure的問題，蠻難解決的，我聽說其他人是用比較複雜的條件判斷跟控制，我因為想趕快通過所以我直接從源頭2 cycle才送一筆request，其實蠻笨的，因為如果clock rate差更多就沒有用了，所以可以不用參考，如果只是要過lab甚至有機會過goal，還是可以參考這個怪解法。

## Performance

- Pass goal / Score 100
- Latency 795238 / Area 987938
- Constraint: Latency ≤ 800000, Area ≤ 1200000
