#!/usr/bin/env python
import sys,re

if len(sys.argv) != 3:
    print ("usage\npython remove_diff_marks.py <input_file> <output_file>\n")
else:
    ifile = open(sys.argv[1], 'r')
    wholefile = ifile.read()
    ifile.close()

    reflags = re.S | re.M

    replaced = re.sub(r"<ins>(.*?)</ins>", r"\1", wholefile, count = 0, flags = reflags)
    replaced = re.sub(r"<del>.*?</del>", r"", replaced, count = 0, flags = reflags)

    res_file = open(sys.argv[2], 'w')
    res_file.write(replaced)
    res_file.close()
