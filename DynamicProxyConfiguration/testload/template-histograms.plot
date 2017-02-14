# -*- coding: utf-8 -*-
set terminal epslatex color colortext
set output '__OUTPUT_FILE__.tex'
set encoding utf8

set autoscale

set xlabel "Requêtes par seconde"
set xtic auto
set xtic offset 2

set ylabel "Temps de réponse moyen (en ms)"
set ytic auto
set logscale y
set yrange [0.1:100000]

set xtics nomirror
set ytics nomirror

set style data histogram
set style fill solid border
set style histogram errorbars linewidth 1
set bars front
set boxwidth 0.60

set key top left

set style line 1 lt 1 linecolor rgb "purple"
set style line 2 lt 1 linecolor rgb "blue"

plot \
  newhistogram "" at 0.0, \
    "__INPUT_LEGACY__" using 2:2:3:xticlabels(1) linestyle 1 title "Legacy",\
  newhistogram "" at 0.25, \
    "__INPUT_OPENRESTY__" using 2:2:3 linestyle 2 title "OpenResty",\

