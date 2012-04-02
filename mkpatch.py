#!/usr/bin/env python

import subprocess, re, os

def main(argv):
	stdout = sys.stdout
	stderr = sys.stderr
	sep = os.path.sep
	src = argv[1]
	dst = argv[2]
	re_minus	= re.compile(r'^'+re.escape('--- '+src+sep)+r'(.*?)\t.*$')
	re_plus		= re.compile(r'^'+re.escape('+++ '+dst+sep)+r'(.*?)\t.*$')
	only = 'Only in '+src+sep
	onlyl = len(only)
	p = subprocess.Popen(['diff','-aur',src,dst],stdout=subprocess.PIPE)
	for line in p.stdout:
		if line.startswith('diff'):
			continue
		elif line.startswith('Only'):
			if line.startswith(only):
				stderr.write(line.replace(': ',sep)[onlyl:])
		else:
			stdout.write(re_plus.sub(r'+++ \1',re_minus.sub(r'--- \1',line)))

if __name__ == '__main__':
	import sys
	main(sys.argv)
