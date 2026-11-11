# Lab12 Diffusion Model APR

Core 沿用 Lab05。Floorplan 改成接近正方形、utilization 0.5，IO margin 拉到 250，SRAM 靠邊界排，中間留給標準元件和電源。

每顆 macro 有 block ring。M2 垂直、M3 水平 stripe 寬 4、間距 90，比 Lab11 的 160 密，core ring 寬 9。IR drop 靠 stripe 密度，不靠把 utilization 塞滿。

## Performance

- Score 100
