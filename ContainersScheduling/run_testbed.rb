#!/usr/bin/env ruby
#
# Run all the experiments.

if ARGV.count.positive?
  STDERR.puts "Usage: #{$PROGRAM_NAME}"
  exit
end

run_experiment = './run_experiment.rb'
if !FileTest.executable?(run_experiment)
  STDERR.puts "#{run_experiment} is missing or not executable"
  exit
end

xp_durations = %w[60 300]
strategies = %w[memory random sandpiper vsl queue-length]
nb_run = 5

xp_durations.each do |xp_duration|
  strategies.each do |strategy|
    puts '==========================='
    puts "Test scheduling strategy '#{strategy}' for #{xp_duration} seconds"
    puts ''

    (1..nb_run).each do |i|
      puts "Run ##{i}"
      cmd = "#{run_experiment} #{strategy} #{xp_duration}"
      system(cmd)

      sleep 60
    end
    puts ''
  end
end
