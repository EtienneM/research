#!/usr/bin/env ruby
#
# Run all the experiments.

require 'fileutils'
require 'logger'
require 'English'

if ARGV.count != 2
  STDERR.puts "Usage: #{$PROGRAM_NAME} scheduling_strategy duration"
  STDERR.puts "Example: #{$PROGRAM_NAME} memory 60"
  exit
end

# Use the staging infrastructure
ENV['SSH_HOST'] = 'staging.scalingo.com:22'
ENV['SCALINGO_API_URL'] = 'https://api-staging.scalingo.com'

class MultiIO
  def initialize(*targets)
    @targets = targets
  end

  def write(*args)
    @targets.each { |t| t.write(*args) }
  end

  def close
    @targets.each(&:close)
  end
end

def ssh_exec(host, cmd)
  `ssh root@#{host} "#{cmd}"`
end

def scale_down(log)
  return if `scalingo --app biniou ps | grep web | tr -s ' ' | cut -d '|' -f 3`.strip.to_i <= 0

  # Scale the `biniou` application to 0
  msg = 'scale down to 0 the biniou application'
  if log.nil?
    puts msg
  else
    log.info "msg='#{msg}'"
  end
  `scalingo --app biniou scale --synchronous web:0 > /dev/null 2>&1`
  sleep 5
end

def clean(scheduler_hosts, results_filename_run)
  `scalingo --app biniou logs --lines 10000 2>&1 > #{results_filename_run}_biniou.log`

  # Kill all Vegeta
  puts 'Kill Vegeta processes'
  `killall vegeta`

  scale_down(nil)

  # Get some logs from schedulers
  scheduler_hosts.each do |host|
    puts "Get results on #{host}"
    ssh_exec host, '[[ -e /tmp/stop-chef-solo ]] && rm /tmp/stop-chef-solo'

    host_id = host.split('.')[0].split('-')[-1] # e.g. hos01
    app_scheduler_logfile = "#{results_filename_run}_#{host_id}_app-scheduler.log"
    `scp root@#{host}:/var/log/scalingo/app-scheduler.log "#{app_scheduler_logfile}"`
  end
end

def run_vegeta(app_name, rate, duration, results_bin)
  `echo "GET http://#{app_name}.staging.scalingo.io/?prime=29907533" | vegeta attack \
    -rate #{rate} -duration #{duration} \
    -header "X-Request-ID: 0000000000000000000" \
    -insecure=true -keepalive=false -http2=false > #{results_bin} &`
end

cur_dir = File.dirname(__FILE__)

results_dir = File.join(cur_dir, '/results')
FileUtils.mkdir_p results_dir

if !system('which vegeta > /dev/null')
  STDERR.puts 'vegeta is mandatory'
  exit
end

scheduling_strategy = ARGV[0]
xp_duration = ARGV[1].to_i

results_filename = File.join(results_dir, "scheduling_#{scheduling_strategy}_#{xp_duration}_run")
total_run = Dir.glob("#{results_filename}*_biniou-02.bin").count
run = total_run + 1
results_filename_run = "#{results_filename}#{run}"

log_file = File.open "#{results_filename_run}.log", 'a'
log = Logger.new(MultiIO.new(STDOUT, log_file))
log.level = Logger::DEBUG
log.level = Logger::INFO

log.info "strategy='#{scheduling_strategy}' xp_duration='#{xp_duration}' run='#{run}'"

# Use the staging infrastructure

# Array of hosts where the app-scheduler is hosted
scheduler_hosts = %w[ovh-sbg-hos03.staging.scalingo.com ovh-sbg-hos04.staging.scalingo.com]
hosts = %w[ovh-sbg-hos01.staging.scalingo.com ovh-sbg-hos02.staging.scalingo.com ovh-sbg-hos03.staging.scalingo.com ovh-sbg-hos04.staging.scalingo.com]

Signal.trap('EXIT') do
  puts 'Bye bye'
  clean scheduler_hosts, results_filename_run
end

scale_down log

log.info "msg='stop Chef solo'"
hosts.each do |host|
  ssh_exec host, 'touch /tmp/stop-chef-solo'
end

log.info "msg='modify the scheduling strategy to #{scheduling_strategy}'"
scheduler_hosts.each do |host|
  ssh_exec host, "sed --in-place 's/SCHEDULING_STRATEGY=.*/SCHEDULING_STRATEGY=#{scheduling_strategy}/g' /etc/init/app-scheduler.conf"
  ssh_exec host, 'stop app-scheduler ; start app-scheduler'
end

# These Vegeta instances are just to test how each server is impacted. We run a request every
# second.
rate = 1 # Make a request every second
duration = 0 # No limit
(1..4).each do |i|
  app_name = "biniou-0#{i}"
  log.info "msg='run Vegeta on #{app_name}'"

  results_bin = "#{results_filename_run}_#{app_name}.bin"
  log.info "msg='results will be in #{File.basename results_bin}'"

  run_vegeta(app_name, rate, duration, results_bin)
end
log.info "msg='wait #{xp_duration} seconds'"
sleep xp_duration

# Scale the `biniou` application up to 4 containers, one at a time, waiting 30 seconds before
# scaling up.
app_name = 'biniou'
(1..4).each do |nb_containers|
  log.info "msg='#{app_name} application is being scaled to #{nb_containers} containers'"
  output = `scalingo --app #{app_name} scale --synchronous web:#{nb_containers}:M 2>&1`
  log.debug "msg='#{output}'"
  log.info "msg='#{app_name} application scaled'"

  if nb_containers == 1
    results_bin = "#{results_filename_run}_#{app_name}.bin"
    log.info "msg='results will be in #{File.basename results_bin}'"
    rate = 15
    run_vegeta(app_name, rate, duration, results_bin)
  end

  # On the staging infrastructure, the metrics are collected every 10 seconds. We wait 20 seconds to
  # ensure we have them collected for the next scheduling decision.
  sleep 30
end

# Gather metrics for 5 minutes
log.info "msg='wait #{xp_duration} seconds before finishing the XP'"
sleep xp_duration
log.info "msg='End of experiment'"
