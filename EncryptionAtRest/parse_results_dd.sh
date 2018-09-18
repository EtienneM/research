#!/usr/bin/env bash

# 1. I first parse the logs to have only the throughput
# 2. The awk script computes the mean and the standard deviation

output="results/staging_dd.dat"

# 11GB copied: 5 blocs of 2GB
# 1GB copied:  1 bloc  of 1GB
# 51MB copied: 100 000 blocs of 512B
# 512kB copied: 1 000 blocs of 512B
echo -e "\t\t11GB\t\t\t51MB" > $output
for e in encrypted unencrypted; do

  echo "$e XPs"
  echo -n -e "$e\t" >> $output

  for copied in "(11 GB," "(51 MB,"; do
    echo "For $copied"

    throughput_unit=$(cat results/staging_dd_${e}_4.log | grep "$copied" | head -n 1 | cut -d " " -f 11)

    res=$(cat results/staging_dd_${e}_4.log | grep "$copied" | cut -d " " -f 10 | awk '
    BEGIN {
      min = max = sum = sum2 = stddev = 0
    }
    {
      if (min == 0 || $1 < min) min = $1
      if ($1 > max) max = $1
      sum += $1
      sum2 += $1 * $1
    }
    END {
      print  sum/NR " " sqrt(sum2/NR - (sum/NR)^2)
    }')
    avg=$(echo $res | cut -d " " -f 1)
    stddev=$(echo $res | cut -d " " -f 2)
    echo -n -e "$avg$throughput_unit\t$stddev\t" >> $output
  done
  echo "" >> $output
done
