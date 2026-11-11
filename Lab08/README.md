# Lab08 Coupling Network

這次雖然pipeline很多，但是其實是可以1 cycle的，只要data輸入能算就開始做，然後讓AI優化一下，要1 cycle才會有比較好的分數。

clock gating的部分，就盡量很fine grain的做，只有要用到reg的那個cycle才enable，可以省很多電。

## Performance

- Rank 16 / Score 96.39
- Latency 100 / Area 135385
- Cost: \(Power^2 \times Latency \times Area\)
