#!/usr/bin/env ruby
#
# This script SHOULD NOT be called directly. It will be called by the makePlot.sh script.

require 'json'
require 'fileutils'

if ARGV.count.zero?
  STDERR.puts "Usage: #{$PROGRAM_NAME} <json files>"
  exit
end

results_dir = 'results'
scheduler_hosts = %w[ovh-sbg-hos03.staging.scalingo.com ovh-sbg-hos04.staging.scalingo.com]
latencies = {}

ARGV.each do |json_file|
  file = File.read json_file
  results = JSON.parse file

  fname_split = File.basename(json_file).split '_'
  app_name = fname_split[-1].split('.')[0]
  next if app_name == 'biniou'
  # hash_key is something like "scheduling_memory_60_run1_biniou-01"
  hash_key = "#{fname_split[0..-2].join('_')}_#{app_name}"
  latencies[hash_key] = Hash.new(0) if !latencies.key? hash_key

  latencies[hash_key]['appName'] = app_name
  latencies[hash_key]['mean'] = latencies[hash_key]['mean'] + results['latencies']['mean']
  latencies[hash_key]['99th'] = latencies[hash_key]['99th'] + results['latencies']['99th']
  latencies[hash_key]['nbErrors'] = 0
  results['status_codes'].reject do |status_code|
    status_code == '200'
  end.each_value do |amount|
    latencies[hash_key]['nbErrors'] += amount
  end
  latencies[hash_key]['nbRun'] += 1

  # Filter the scheduler log file starting from the latest "strategy=..." to the end of the file.
  scheduler_hosts.each do |host|
    host_id = host.split('.')[0].split('-')[-1] # e.g. hos01
    logfile_base = json_file.split('_')[0..-2].join('_')
    log_file = "#{logfile_base}_#{host_id}_app-scheduler.log"
    filtered_log_file = "#{logfile_base}_#{host_id}_app-scheduler_filtered.log"

    next if File.exist? filtered_log_file

    if !File.exist? log_file
      STDERR.puts "Missing log file (#{File.basename log_file}). Skip to the next experiment."
      next
    end

    rx = Regexp.new('.*(time=.* strategy=.*)', Regexp::MULTILINE)
    File.open(filtered_log_file, 'w') do |filtered_log|
      filtered_log.write(rx.match(File.read(log_file))[1])
    end

    # Remove some useles error message to make it easier to read by a human eye
    filtered_lines = File.new(filtered_log_file)
                         .readlines
                         .grep_v(/error monitoring the resources/)
                         .grep_v(/TOPIC_NOT_FOUND/)
    File.open(filtered_log_file, 'w') do |filtered_log|
      filtered_lines.each do |line|
        filtered_log.write(line)
      end
    end
  end

  # Test if the XP is valid
  nb_filtered_log_files = `ls -l #{results_dir}/#{fname_split[0..-2].join('_')}_*_app-scheduler_filtered.log | wc -l`.strip.to_i
  if nb_filtered_log_files != 2
    STDERR.puts "Lack a filtered log file (#{fname_split[0..-2].join('_')})"
    next
  end
  nb_scheduled_container = `cat #{results_dir}/#{fname_split[0..-2].join('_')}_*_app-scheduler_filtered.log | grep "_event=start-container container=biniou/" | wc -l`.strip.to_i
  if nb_scheduled_container != 4
    STDERR.puts "#{results_dir}/#{fname_split[0..-2].join('_')}"
    STDERR.puts "Wrong number of scheduled containers (#{nb_scheduled_container} != 4)"
    next
  end
end

# Remove any existing dat file
latencies.each do |xp, _|
  data_filename = xp.split('_')[0..-2].join('_')
  data_file = "#{results_dir}/#{data_filename}.dat"
  FileUtils.remove_file data_file if File.exist? data_file
end

# Print the results and save them in a file for further plot
latencies.each do |xp, results|
  # puts "XP: #{xp}"

  # Results are in nanoseconds, convert to miliseconds
  results['mean'] = results['mean'] / results['nbRun'] * 10e-7
  results['99th'] = results['99th'] / results['nbRun'] * 10e-7
  results['nbErrors'] = results['nbErrors'] / results['nbRun']
  # puts "mean: #{results['mean']} ms\n99th: #{results['99th']} ms\n# errors: #{results['nbErrors']}"

  data_filename = xp.split('_')[0..-2].join('_')
  data_file = "#{results_dir}/#{data_filename}.dat"

  File.open(data_file, 'a') do |f|
    f.write(results.each_value.to_a.join("\t") + "\n")
  end
end
