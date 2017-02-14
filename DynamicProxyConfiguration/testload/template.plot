# -*- coding: utf-8 -*-
set terminal epslatex color colortext
set output '__OUTPUT_FILE__.tex'
set encoding utf8

set autoscale

set xlabel "Requêtes par seconde"
set xtic auto
set xtic rotate by -45
set xtic offset 1
set xrange [0:1250]

set ylabel "Temps de réponse moyen (en ms)"
set ytic auto
set logscale y

set xtics nomirror
set ytics nomirror

set style line 1 lt 1 linecolor rgb "purple"
set style line 2 lt 1 linecolor rgb "blue"
set style line 3 lt 1 linecolor rgb "red"
set style line 4 lt 1 linecolor rgb "orange"

plot \
  "__INPUT_LEGACY__" using 1:2 with linespoints linestyle 1 title "Legacy",\
  "__INPUT_LEGACY__" using 1:2:2:3 with yerrorbars linestyle 4 title "",\
  "__INPUT_OPENRESTY__" using 1:2 with linespoints linestyle 2 title "OpenResty",\
  "__INPUT_OPENRESTY__" using 1:2:2:3 with yerrorbars linestyle 3 title ""

