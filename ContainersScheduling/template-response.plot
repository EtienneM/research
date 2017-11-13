# -*- coding: utf-8 -*-
set terminal eps color
set output '__OUTPUT_FILE__.eps'
#set terminal epslatex color colortext
#set terminal epslatex standalone color colortext
#set output '__OUTPUT_FILE__.tex'
set encoding utf8

set autoscale

set xlabel ""
set xtic auto
set xtic rotate by -45
set xtic offset 1
#set xrange [0:1250]
#set logscale x

set ylabel "Temps de réponse moyen (en ms)"
set ytic auto
#set logscale y
#set yrange [0.1:600]

set xtics nomirror
set ytics nomirror

set style data histogram
set style fill solid border
set style histogram errorbars linewidth 1
#set bars front
#set boxwidth 0.60

set style line 1 lt 1 linecolor rgb "purple"
set style line 2 lt 1 linecolor rgb "blue"
set style line 3 lt 1 linecolor rgb "red"
set style line 4 lt 1 linecolor rgb "orange"

plot \
  __HISTOGRAM__
  # newhistogram "Exécution 1", "__INPUT_RUN1__" using 2:2:3:xticlabels(1) title ""
