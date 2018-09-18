#!/usr/bin/env bash
#
# set -x
set -o nounset

_cur_dir=$(cd $(dirname $0) && pwd)
cd $_cur_dir

function log_message
{
  echo "$(date +'%Y-%m-%d %H:%M:%S'): $1"
}

for app in test-unencrypted test-encrypted; do
  log_message "Start experiment for $app"
  scalingo --app $app run ./bin/run_pgbench.sh \
    | tee --append ./results/prod_pgbench_${app}.log
done
