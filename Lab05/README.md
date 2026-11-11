# Lab05 Diffusion Model

矩陣乘法都是用 8 x 8 systolic array，各種設計也是為了systolic array，結果 PPA 被超大數量的dot product 爆打，建議在 ic lab 遇到矩陣乘法可以考慮用 dot product，不要用systolic array，有可能 PPA 會被打爆。

convolution跟lab2, lab4一樣用shift register跟window addressing解決。


## 心得：
不要為了後續 APR 去做大小比較漂亮的 SRAM，先讓這個Lab分數高一點再說。



## Performance

- Rank 39 / Score 81.90
- CT 4.9 / Latency 70692 / Area 4037956
- Cost: \((CT \times Latency) \times Area \times NonCombArea\)
