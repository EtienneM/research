#!/usr/bin/env bash
#
# Test read and write performance using pgbench. This script outputs the `tps` =
# transactions per seconds. The higher, the better.
#
# Run with sscalingo -a encryption-at-rest run ./bin/run_pgbench.sh

# set -x
set -o nounset

_cur_dir=$(cd $(dirname $0) && pwd)
cd $_cur_dir

nb_runs=${NB_RUNS:-2}
# https://blog.codeship.com/tuning-postgresql-with-pgbench/
# These two come from https://wiki.postgresql.org/wiki/Pgbenchtesting
nb_clients=2
nb_threads=$(($nb_clients * 2))

# In seconds. Should run ideally for 1h
ro_time=$((15 * 60))
rw_time=$((15 * 60))

pgbench="${_cur_dir}/pgbench"

# DB memory = 512MB
# Shared buffer size = 512 / 4 = 128MB
host="$(echo $SCALINGO_POSTGRESQL_URL | cut -d ":" -f 3 | cut -d "@" -f 2)"
port="$(echo $SCALINGO_POSTGRESQL_URL | cut -d ":" -f 4 | cut -d "/" -f 1)"
username="$(echo $SCALINGO_POSTGRESQL_URL | cut -d "/" -f 3 | cut -d ":" -f 1)"
db_name="$username"
export PGPASSWORD="$(echo $SCALINGO_POSTGRESQL_URL | cut -d "@" -f 1 | cut -d ":" -f 3)"

function log_message
{
  echo "RUN $run - $(date +'%Y-%m-%d %H:%M:%S'): $1"
}
# The default DB size is 16MB. Depending on what you want to test, the scale factor vary:
#  - For mostly cached: 0.9 x RAM
#  - For mostly on disk: 4 x RAM
#
# We provisioned database of size 512 MB. The scale is computed with `scale = (4 * 512) / 16`
for run in $(seq 1 $nb_runs); do
  for scale in 128 30; do
    log_message "===   Initialize table with scale = $scale"
    log_message ""
    # Initialize the tables with the defined scale factor
    $pgbench --host=$host --port=$port --username=$username \
      --initialize --scale=$scale $db_name

    log_message ""
    log_message ""
    log_message "Execute the read-only tests for $(($ro_time / 60)) minutes"
    log_message ""
    $pgbench --host=$host --port=$port --username=$username \
      --progress=60 \
      --no-vacuum --client=$nb_clients --jobs=$nb_threads --select-only \
      --time=$ro_time $db_name

    log_message ""
    log_message ""
    log_message "Execute the read-write tests for $(($rw_time / 60)) minutes"
    log_message ""
    $pgbench --host=$host --port=$port --username=$username \
      --progress=60 \
      --no-vacuum --client=$nb_clients --jobs=$nb_threads --skip-some-updates \
      --time=$rw_time $db_name
  done
done
