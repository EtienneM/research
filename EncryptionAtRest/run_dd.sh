#!/usr/bin/env bash
#
# Test raw write performance with dd. This script outputs the throughput. The higher, the better.
#
#    1073741824 bytes (1.1 GB) copied, 123.37 s, 8.7 MB/s
#                                                   ^
# https://www.thomas-krenn.com/en/wiki/Linux_I/O_Performance_Tests_using_dd
# https://www.cyberciti.biz/faq/howto-linux-unix-test-disk-performance-with-dd-command/

# set -x
set -o nounset

if [[ $# -ne 1 ]]; then
	echo "Usage: $0 destination_folder" >&2
	echo "Example: $0 /root/testfile" >&2
	exit -1
fi
destination="$1"

_cur_dir=$(cd $(dirname $0) && pwd)
cd $_cur_dir

nb_runs=${NB_RUNS:-1}

function log_message
{
  echo "$(date +'%Y-%m-%d %H:%M:%S'): $1"
}
for run in $(seq 1 $nb_runs); do
  log_message ""
  log_message ""
  log_message "=== RUN ${run} - Write 5 blocs of 2GB"
  log_message ""
  if [[ -f "$destination/one_bloc" ]]; then
    rm $destination/one_bloc
  fi
  dd if=/dev/zero of=$destination/one_bloc bs=2G count=5 oflag=direct 2>&1
  rm $destination/one_bloc

  log_message ""
  log_message ""
  log_message "Write 512 bytes hundred thousand times"
  log_message ""
  if [[ -f "$destination/multiple_blocs" ]]; then
    rm $destination/multiple_blocs
  fi
  dd if=/dev/zero of=$destination/multiple_blocs bs=512 count=100000 oflag=direct 2>&1
  rm $destination/multiple_blocs
done | tee staging_dd.log
