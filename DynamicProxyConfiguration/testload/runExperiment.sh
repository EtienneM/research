#!/bin/bash
#
# Run a test load on a front server
#
if [[ $# -ne 4 ]]; then
	echo "Usage: $0 front web_protocol rate duration" >&2
	echo "Example: $0 openresty http 100 1m" >&2
	echo "front is either openresty, legacy or local" >&2
	echo "web_protocol is either http or https" >&2
	exit -1
fi

set -x
set -o nounset

_CUR_DIR=$(cd $(dirname $0) && pwd) 
cd $_CUR_DIR

which vegeta > /dev/null
if [[ $? -ne 0 ]]; then
	echo "vegeta is mandatory"
	exit -1
fi

results_dir="${_CUR_DIR}/results"
if [[ ! -d "$results_dir" ]]; then
	mkdir -p "$results_dir"
fi

front=$1
if [[ "$front" = "openresty" ]]; then
	endpoint="openresty.example.com"
elif [[ "$front" = "legacy" ]]; then
	endpoint="legacy.example.com"
elif [[ "$front" = "local" ]]; then
  endpoint="sinatra.172.17.0.1.xip.io"
else
	echo "Unknown front ($front)" >&2
	exit -1
fi

web_protocol=$2
if [[ "$web_protocol" != "http" ]] && [[ "$web_protocol" != "https" ]]; then
	echo "Unknown web_protocol ($web_protocol)" >&2
	exit -1
fi

rate=$3
duration=$4

if [[ "$front" = "local" ]]; then
	sample_app="sinatra.172.17.0.1.xip.io"
else
	sample_app="sample-ruby-sinatra.example.com"
fi

# Do not erase any of the previous results file
shopt -s nullglob
results_filename="$results_dir/testload_${front}_${web_protocol}_${rate}_${duration}_run"
results_files=(${results_filename}*.bin)
total_run=${#results_files[@]}
results_filename="${results_filename}$((total_run + 1)).bin"
shopt -u nullglob

if [[ $5 = "reload" ]]; then
  (
    while true ; do
      SCALINGO_API_URL=https://api.example.com scalingo -a sample-ruby-sinatra restart
      sleep 25
    done
  ) &
fi

echo "GET ${web_protocol}://${endpoint}" | vegeta attack -header "Host: $sample_app" \
  -insecure=true -rate $rate -duration $duration -keepalive=false | tee $results_filename | vegeta report
vegeta report -inputs $results_filename -reporter plot > $results_filename.html
vegeta report -inputs $results_filename -reporter json > $results_filename.json

echo "results are in $results_filename"

