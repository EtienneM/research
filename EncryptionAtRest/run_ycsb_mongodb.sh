#!/usr/bin/env bash
#
# Test read and write performance of MongoDB using [YCSB](https://github.com/brianfrankcooper/YCSB).
# This script outputs numerous information amongst which the throughput (in ops/sec). The higher,
# the better.
#
# Run with scalingo -a test-encrypted run ./bin/run_ycsb_mongodb.sh

# set -x
set -o nounset

_cur_dir=$(cd $(dirname $0) && pwd)
cd $_cur_dir

ycsb_dir="${_cur_dir}/../ycsb"

nb_runs=${NB_RUNS:-1}

ycsb="${ycsb_dir}/bin/ycsb.sh"
if [[ ! -f "$ycsb" ]]; then
  echo "YCSB is not installed" >&2
  exit -1
fi
workload_ro="${ycsb_dir}/workloads/workloadc"
if [[ ! -f "$workload_ro" ]]; then
  echo "Workload file does not exist" >&2
  exit -1
fi
workload_rw="${ycsb_dir}/workloads/workloada"
if [[ ! -f "$workload_rw" ]]; then
  echo "Workload file does not exist" >&2
  exit -1
fi
default_collection_name="usertable"
recordcount=1000000

host="$(echo $SCALINGO_MONGO_URL | cut -d ":" -f 3 | cut -d "@" -f 2)"
port="$(echo $SCALINGO_MONGO_URL | cut -d ":" -f 4 | cut -d "/" -f 1)"
username="$(echo $SCALINGO_MONGO_URL | cut -d "/" -f 3 | cut -d ":" -f 1)"
db_name="$username"
export MONGOPASSWORD="$(echo $SCALINGO_MONGO_URL | cut -d "@" -f 1 | cut -d ":" -f 3)"

function log_message
{
  echo "$(date +'%Y-%m-%d %H:%M:%S'): $1"
}

log_message "== Downloads the MongoDB CLI"
dbclient-fetcher mongo 3.6 > /dev/null

for run in $(seq 1 $nb_runs); do
  log_message ""
  log_message ""
  log_message "=== RUN ${run}"
  log_message ""

  log_message ""
  log_message "===   Delete '${default_collection_name}' collection"
  log_message ""
  mongo "$SCALINGO_MONGO_URL" --eval "db.${default_collection_name}.drop();"

  log_message ""
  log_message "===   Load the data in the database (${recordcount} records)"
  log_message ""
  ${ycsb} load mongodb -p mongodb.url="$SCALINGO_MONGO_URL" -s -P $workload_rw -p recordcount=${recordcount}

  log_message ""
  log_message ""
  log_message "Execute the read-only tests"
  log_message ""
  ${ycsb} run mongodb -p mongodb.url="$SCALINGO_MONGO_URL" -s -P $workload_ro -p operationcount=${recordcount}

  log_message ""
  log_message ""
  log_message "Execute the read-write tests"
  log_message ""
  ${ycsb} run mongodb -p mongodb.url="$SCALINGO_MONGO_URL" -s -P $workload_rw -p operationcount=${recordcount}
done
