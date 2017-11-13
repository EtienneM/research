#!/bin/bash

# This script generate the data file and generate the plot.

# set -x
set -o nounset

cur_dir=$(cd $(dirname $0) && pwd)
cd $cur_dir

which vegeta > /dev/null
if [[ $? -ne 0 ]]; then
	echo "vegeta is mandatory"
	exit -1
fi

results_dir="${cur_dir}/results"

echo "============================="
echo "Generating data files"

for results_filename in ${results_dir}/*.bin; do
  vegeta report -inputs $results_filename -reporter plot > $results_filename.html
  vegeta report -inputs $results_filename -reporter json > $results_filename.json
done

if [[ ! -x "./compute_results.rb" ]]; then
  echo "Cannot find the compute_results.rb script" >&2
  exit -1
fi
./compute_results.rb ${results_dir}/*.json

# Sort numerically the first column (mean response time) of the data files
#for datafile in results/*.dat; do
#  tmp_file=$(mktemp)
#  cat $datafile | sort -k 1 -n > $tmp_file
#  mv $tmp_file $datafile
#done

template_file="template-response.plot"
if [[ ! -f "$template_file" ]]; then
  echo "No template for plot of response time" >&2
  exit -1
fi

echo "============================="
echo "Generating the PDF output"

for datafile in ${results_dir}/*_run1.dat; do
  # plot_basename equals something like "results/scheduling_memory_60"
  basename_without_run="$(echo $datafile | cut -d '_' -f 1-3)"
  plot="$basename_without_run.plot"
  tmp_plot=$(mktemp --suffix ".plot")
  cat $template_file |
      sed "s#__OUTPUT_FILE__#${basename_without_run}#g" > $tmp_plot

  gnuplot_histogram=""
  for f in ${basename_without_run}_run*.dat; do
    if [[ -n "$gnuplot_histogram" ]]; then
      gnuplot_histogram="${gnuplot_histogram}, "
    fi
    run_number=$(echo $f | cut -d '.' -f 1 | cut -d '_' -f 4 | cut -d 'n' -f 2)
    gnuplot_histogram="${gnuplot_histogram} newhistogram \"Exécution $run_number\", "
    gnuplot_histogram="${gnuplot_histogram}\"$f\" using 2:2:3:xticlabels(1) title \"\""
  done

  sed 's#__HISTOGRAM__#'"${gnuplot_histogram}"'#g' "$tmp_plot" > $plot

  gnuplot $plot > /dev/null

  # In order to generate figure that do not integrate to an existing latex file, modify the first
  # line of the template with "set terminal epslatex standalone color colortext"
  # and uncomment the line below.
  pdflatex -interaction nonstopmode -output-directory results/ ${tmp_plot%.*}.tex > /dev/null
done
