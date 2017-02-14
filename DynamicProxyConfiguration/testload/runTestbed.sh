#!/bin/bash
#
# Run all the tests
#
if [[ $# -ne 0 ]]; then
	echo "Usage: $0" >&2
	exit -1
fi

# set -x
set -o nounset

_CUR_DIR=$(cd $(dirname $0) && pwd) 
cd $_CUR_DIR

if [[ ! -x "./runExperiment.sh" ]]; then
	echo "runExperiment.sh is missing" >&2
	exit -1
fi

web_protocol=https
duration=1m
rate=500
nb_run=5
for duration in 1m 2m 5m 10m; do
	for rate in 100 250 500 1000 1500 ; do
		for web_protocol in http https; do
			for front in openresty legacy; do
				echo "==========================="
				echo "Test load with $web_protocol for $duration with $rate req/sec on ${front}"

				for run in $(seq 1 $nb_run); do
					echo ""
					echo "Run #${run}"
					./runExperiment.sh $front $web_protocol $rate $duration
					echo ""
					sleep 3
				done
			done
		done
  done
done
