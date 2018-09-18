#!/usr/bin/env bash

#set -x
set -o nounset

output="results/prod_pgbench.dat"
echo -e "\t\tTPS_RO_DISK\tTPS_RW_DISK\tTPS_RO_RAM\tTPS_RW_RAM" > $output

for f in results/prod_pgbench_test-encrypted_2.log results/prod_pgbench_test-unencrypted_3.log; do
  for run in $(seq 1 10); do
    echo -n -e "$(echo $f | cut -d "_" -f 3 | cut -d "-" -f 2)\t" >> $output
    first_line=$(cat $f |  grep "RUN $run " -n | cut -d ":" -f1 | head -n 1)
    next_run=$(($run+1))
    last_line=$(($(cat $f |  grep "RUN $next_run " -n | cut -d ":" -f1 | head -n 1) - 1))
    [[ $last_line -eq -1 ]] && last_line=$(cat $f | wc -l)

    tps_ro_disk=$(cat $f | sed --quiet "${first_line},${last_line}p" | grep "tps = " | sed -n "2p" | cut -d " " -f 3)
    tps_rw_disk=$(cat $f | sed --quiet "${first_line},${last_line}p" | grep "tps = " | sed -n "4p" | cut -d " " -f 3)
    tps_ro_ram=$(cat $f | sed --quiet "${first_line},${last_line}p" | grep "tps = " | sed -n "6p" | cut -d " " -f 3)
    tps_rw_ram=$(cat $f | sed --quiet "${first_line},${last_line}p" | grep "tps = " | sed -n "8p" | cut -d " " -f 3)

    echo -e "$tps_ro_disk\t$tps_rw_disk\t$tps_ro_ram\t$tps_rw_ram" >> $output
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
