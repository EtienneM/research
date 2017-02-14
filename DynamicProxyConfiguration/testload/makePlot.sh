#!/bin/bash

# This script generate the data file and generate the plot.

#set -x
set -o nounset

_CUR_DIR=$(cd $(dirname $0) && pwd) 
cd $_CUR_DIR

echo "============================="
echo "Generating data files"

if [[ ! -x "./computeResults.py" ]]; then
  echo "Cannot find the computeResults.py script" >&2
  exit -1
fi
./computeResults.py results/*.json > /dev/null

# Sort numerically the first column of the data files
for datafile in results/*.dat; do
  tmp_file=$(mktemp)
  cat $datafile | sort -k 1 -n > $tmp_file
  mv $tmp_file $datafile
done

template_file="template.plot"
if [[ ! -f "$template_file" ]]; then
  echo "No template for plot" >&2
  exit -1
fi
template_hist_file="template-histograms.plot"
if [[ ! -f "$template_file" ]]; then
  echo "No template for plot" >&2
  exit -1
fi

echo "============================="
echo "Generating the PDF output"

for datafile in results/*legacy*.dat; do
  # testload or testload-with-reload
  xp_type=$(echo $datafile | cut -d '_' -f 1 | cut -d '/' -f 2)
  if [[ $xp_type = "testload" ]]; then
    reload="sans"
  else
    reload="avec"
  fi
  # openresty or legacy
  front=$(echo $datafile | cut -d '_' -f 2)
  # http or https
  web_protocol=$(echo $datafile | cut -d '_' -f 3)
  # 1m, 2m, 5m...
  duration=$(echo $datafile | cut -d '_' -f 4 |cut -d '.' -f 1)
  input_openresty="results/${xp_type}_openresty_${web_protocol}_${duration}.dat"
  tmp_plot="results/${xp_type}_${web_protocol}_${duration}.plot"

  cat $template_file | sed "s#__INPUT_LEGACY__#${datafile}#g" |
      sed "s#__INPUT_OPENRESTY__#$input_openresty#g" | 
      sed "s/__WEB_PROTOCOL__/${web_protocol^^}/g" | 
      sed "s/__RELOAD__/${reload}/g" | 
      sed "s#__OUTPUT_FILE__#${tmp_plot%.*}#g" > $tmp_plot
  gnuplot $tmp_plot > /dev/null

  tmp_plot="results/${xp_type}_${web_protocol}_${duration}_hist.plot"
  cat $template_hist_file | sed "s#__INPUT_LEGACY__#${datafile}#g" |
      sed "s#__INPUT_OPENRESTY__#$input_openresty#g" | 
      sed "s/__WEB_PROTOCOL__/${web_protocol^^}/g" | 
      sed "s/__RELOAD__/${reload}/g" | 
      sed "s#__OUTPUT_FILE__#${tmp_plot%.*}#g" > $tmp_plot
  gnuplot $tmp_plot > /dev/null

  # In order to generate figure that do not integrate to an existing latex file, modify the first
  # line of the template with "set terminal epslatex standalone color colortext"
  # and uncomment the line below.
  #pdflatex -interaction nonstopmode -output-directory results/ ${tmp_plot%.*}.tex > /dev/null
done
