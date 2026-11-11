# Lab01 Design Rule Check Accelerator

16 個 shape 先依規則挑出對應 layer，填成 15×15 的佔用圖。沿每一列累加連續的 metal（寬度檢查），或把圖轉置後累加連續的空隙（間距檢查）。一段 run 在長度還小於規則要求時就中斷，而且上一列同一位置不是這一段的延續，才記一次 violation，所以同一條細線不會每一列都重複計分。

累加本身是一格接一格的長鏈。每一列從左右各切成兩半，分別由外往中間累加，中間交界再補一次判斷，避免跨過切點的 run 被漏算或重算。Critical path 因此從整條邊長變成約一半。

但最後rank很爛，因為其他人是用5格大小的window去判斷，critical path小很多，導致面積小很多。所以我的作法很慘。

# lab01 tips: 
想辦法讓critical path小一點，這樣面積會比較小，可以透過調整算法去實現。比如說我這次是用h/2個大小的entry去累加，就比別人5 entry累加爛很多。

## Performance

- Rank 79 / Score 78.92
- CT 12 / Area 224648.1
- Cost: \(CT \times Area\)
