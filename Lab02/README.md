# Lab02 mini Image Signal Process

## Layer1 BLC: 
在pipeline中做。

## Layer2 LSC: 
四個 channel 的 6×6 gain 各放一條 36 格 shift register，不用位址去查。目前只用最前面兩列 12 格，裡面滑一個 2×2。影像每 3 個 pixel 才換一格，位置只有 0、1/3、2/3，所以橫向、縱向都用同一顆 4-stage shift-add（×85、×171）。一列 gain 用完就把這條 shift register 轉 6 格，下一列補到最前面。總而言之就是用shifter register去比較複雜的控制，可以省面積。

## Layer3 DPC: 
主要是操作 5×5 kernel，且有 padding。用一條長度 `(5-1)×16+5 = 69` 的 shift register 當 sliding window，每拍只推進一顆 pixel。5×5 的 addressing 是固定的：影像寬 16，相鄰列在這條 shift register 裡就差 16，中心在 `dpc_mem[221]`，五列分別從 187、203、219、235、251 接出來。Padding 不另外補 pixel，x 或 y 在 0、1、14、15 時改查這張 5×5 裡面的格子。

## Layer4 Bilinear: 
跟 DPC 用同一條 shift regiser ，把 DPC 的結果先推進另一條 shift register 暫存，再整張灌回這 69 格，原本的水平、垂直、對角 tap 直接拿來做插值。

為了共用這條 window，我另外放了一條 69 格的 shift register 當 buffer，等一段時間再灌回去做 bilinear。Demo 結果出來才發現，bilinear 自己留一條運算用的 shift register 比較好：latency 可以壓到 256，面積也比較小。Lab11 是使用 Lab2 的 design 來 APR，我有改成 bilinear 單獨一條。

bilinear 的 `×85`、`×171` 用 shift-add，並切成 4 stage，critical path 才壓到 3.1。

## Layer5 CCM:
每個顏色本來要跟 R、G、B 各乘一次，三個顏色就是 9 個乘法。這組係數是固定的：自己乘上 1.15，再減去 `0.05 × (R+G+B)`。後面這項三個顏色都一樣，所以 R+G+B 只加一次、`-0.05` 只算一次，再加回 R、G、B。1.15 和 -0.05 都是常數，用移位加減做出來，沒有乘法器。

## Lab02 tips: 

可以盡量切 pipeline 把 cycle time 壓低，latency 也要往下限壓。一張 16×16 理論上最低是 256 cycle，我是 309；下面的 30900 是 100 張加總。排在我前面的幾乎都是 256，所以能做到最低 latency 還是比較賺。

Sliding window 的題目，像 DPC、bilinear、convolution，都可以用這套 shift register 加座標的做法，我覺得很有效率。

shift register可以盡量的使用，像我輸入的image和 weight我都是用shift register存，面積會小很多。

## Performance

- Rank 16 / Score 95.54
- CT 3.1 / Latency 30900 / Area 768301.9
- Cost: \(CT \times Latency \times Area^2\)
