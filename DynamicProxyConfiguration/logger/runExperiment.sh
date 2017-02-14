#!/bin/bash

go build

(
  while true ; do
    sleep 20
    echo "Send SIGUSR1"
    logger_pid=$(ps aux | grep "logger"|tail -n2|head -n1|tr -s " "|cut -d " " -f2)
    sudo kill -USR1 $logger_pid
  done
) &

for rate in 100 250 312 375 500; do
  echo "========================= rate = ${rate}"

  ./test-logger -rate $rate > /dev/null

  date
  logger_pid=$(ps aux | grep "logger"|tail -n2|head -n1|tr -s " "|cut -d " " -f2)
  echo "Logger PID = $logger_pid"
  sudo kill -USR2 $logger_pid
done

# Kill job which sends SIGUSR1
trap 'kill $(jobs -p)' EXIT
