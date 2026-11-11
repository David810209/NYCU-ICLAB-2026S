# Lab03 Tree Harvester

Calc 用 stack 做，value stack 和 operation stack 都是 shift register。這次最深只會到 13 和 8，所以就只開這兩個深度，面積少很多。

Sort 先把一個 bank 的 256 筆放進 `sort_buffer`，做 odd-even sort。四個 bank 都排好寫回後，各自留一小段已排序的 head；每拍先比 bank0 和 bank1、bank2 和 bank3，再比兩個勝者，只把最小的那筆吐出來，吐完再補那個 bank。

我在這裡的 dram controller 做法比較爛，並不理想，不能參考，可以直接參考我lab07的，是有用fifo來做優化，也比較robust。

## Lab03 tips: 
這次的面積有限制1000萬、latency有限制10000，要在這個限制下做出1024筆資料的排序其實是非常困難的，用odd even sort和4 way的merge sort是非常優化dram latency和面積的做法，感謝一起寫lab的學長提供想法。

stack算法可以找一個算法需要的最小stack size，對面積有幫助。

dram controller的做法可以參考lab07。

## Performance

- 2 de
- Rank 4 / Score 75.73
- CT 4.5 / Latency 578345 / Area 3154851
- Cost: \(CT \times Latency \times Area^2\)
