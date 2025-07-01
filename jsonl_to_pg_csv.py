import csv
import json
import jsonlines
import sys
lines = (json.dumps(line) for line in jsonlines.Reader(sys.stdin))
lines = (line.replace('\\u0000', '\\\\u0000') for line in lines)
lines = (line.replace('\\\\\\u0000', '\\\\u0000') for line in lines)
lines = ([line] for line in lines)
csv.writer(sys.stdout, dialect=csv.unix_dialect).writerows(lines)
