#!/usr/bin/env bash

#set -x
set -o nounset

output="results/prod_ycsb_mongodb.dat"
echo -e "\t\tOPS_RO\tOPS_RW" > $output

for f in $*; do
  for run in $(seq 1 10); do
    first_line=$(cat $f |  grep "=== RUN $run" -n | cut -d ":" -f1 | head -n 1)
    if [[ "x$first_line" = "x" ]]; then
      continue
    fi
    next_run=$(($run+1))
    last_line=$(($(cat $f |  grep "=== RUN $next_run" -n | cut -d ":" -f1 | head -n 1) - 1))
    [[ $last_line -eq -1 ]] && last_line=$(cat $f | wc -l)

    echo -n -e "$(echo $f | cut -d "_" -f 4 | cut -d "-" -f 2)\t" >> $output

    ops_ro=$(cat $f | sed --quiet "${first_line},${last_line}p" | grep "Throughput(ops/sec)" | sed --quiet "2p" | cut -d " " -f 3)
    ops_rw=$(cat $f | sed --quiet "${first_line},${last_line}p" | grep "Throughput(ops/sec)" | sed --quiet "3p" | cut -d " " -f 3)

    echo -e "$ops_ro\t$ops_rw" >> $output
  done
done

for col in 2 3; do
  for e in encrypted unencrypted; do
    mean_stddev=$(cat $output | grep -E "^$e" | cut -f $col | awk '
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
      print  sum/NR " (" sqrt(sum2/NR - (sum/NR)^2) ")"
    }')
    echo -n -e "$mean_stddev\t"
  done
  echo ""
done
