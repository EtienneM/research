#!/usr/bin/python -O
# -*- coding:utf8 -*-

# This script SHOULD NOT be called directly. It will be called by the makePlot.sh script.
# The input JSON files are the output of vegeta.

import os
import sys
import glob
import json

def usage():
    print >> sys.stderr, 'Usage: {0} <json files>'.format(sys.argv[0])

def parseResultsFilename(filename):
    fSplit = os.path.basename(filename).split('_')
    return {
        'xp_type': fSplit[0],
        'front': fSplit[1],
        'web_protocol': fSplit[2],
        'rate': fSplit[3],
        'duration': fSplit[4],
        'run': fSplit[5],
    }

if __name__ == '__main__':
    if len(sys.argv) < 2: 
        usage()
        sys.exit(-1)
    sys.argv.pop(0)

    latencies = {}

    for f in sys.argv:
        with open(f) as fp:
            results = json.load(fp)
            if results['errors'] is None:
                results['errors'] = []
        
        fSplit = os.path.basename(f).split('_')
        if fSplit[3] == '1500':
            continue
        hashKey = '_'.join(fSplit[0:-1])
        if hashKey not in latencies:
            latencies[hashKey] = {}
        latencies[hashKey]['mean'] = latencies[hashKey].get('mean', 0) + results['latencies']['mean']
        latencies[hashKey]['99th'] = latencies[hashKey].get('99th', 0) + results['latencies']['99th']
        latencies[hashKey]['nbErrors'] = 0
        for statusCode in results['status_codes']:
                if statusCode != '200':
                    latencies[hashKey]['nbErrors'] += results['status_codes'][statusCode]

        latencies[hashKey]['nbRun'] = latencies[hashKey].get('nbRun', 0) + 1

    # Purge old results files
    for name in glob.glob('results/*.dat'):
        os.remove(name)

    # Print the results and save them in a file for further plot
    for xp in sorted(latencies.keys()):
        print xp
        latencies[xp]['mean'] = latencies[xp]['mean'] / latencies[xp]['nbRun']
        latencies[xp]['99th'] = latencies[xp]['99th'] / latencies[xp]['nbRun']
        latencies[xp]['nbErrors'] = latencies[xp]['nbErrors'] / latencies[xp]['nbRun']
        # Results are in nanoseconds
        print 'mean: {0} ms\n99th: {1} ms\n# errors: {2}\n'.format(latencies[xp]['mean']*10e-7,
                latencies[xp]['99th']*10e-7, latencies[xp]['nbErrors'])
        xpSplit = xp.split('_')
        dataFilename = './results/' + '_'.join(xpSplit[0:3]) + '_' + xpSplit[-1] + ".dat"
        with open(dataFilename, 'a') as dataFile:
            dataFile.write("{}\t{}\t{}\n".format(xpSplit[3], latencies[xp]['mean']*10e-7,
                latencies[xp]['99th']*10e-7))
