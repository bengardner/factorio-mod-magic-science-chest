#!/usr/bin/env python3
import os, sys
import json
import tempfile
import subprocess
import fnmatch
import shutil

# files that might be checked in that should not be in the zip
exclude = {
	"*.py",
	"*.xcf",
  "Makefile",
  ".git*",
	}

def makedirs(dn):
	try:
		os.makedirs(dn)
	except:
		pass

def zip_it_up(dest, zip_fn):
	xx = subprocess.run(['git', 'ls-files'], capture_output = True, text = True)
	for line in xx.stdout.splitlines():
		name = line.strip()
		keep = True
		for pp in exclude:
			if fnmatch.fnmatch(line, pp):
				keep = False
				break
		if keep:
			dfn = os.path.join(dest, name)
			print("copy", name, '=>', dfn)
			makedirs(os.path.dirname(dfn))
			shutil.copy(name, dfn)

	old_cwd = os.getcwd()
	os.chdir(os.path.dirname(dest))
	subprocess.run(['zip', '-r9', zip_fn, os.path.basename(dest)])
	os.chdir(old_cwd)

def main(args):
	info = json.load(open("info.json"))
	name = info.get('name')
	vers = info.get('version')
	print('version:', vers)
	print(json.dumps(info, indent=2))
	name_vers = f'{name}_{vers}'
	zip_fn = os.path.abspath(f'{name_vers}.zip')
	print(zip_fn)

	with tempfile.TemporaryDirectory() as dd:
		# copy files into the folder
		zdn = os.path.join(dd, name_vers)
		os.makedirs(zdn)
		zip_it_up(zdn, zip_fn)

if __name__ == '__main__':
	sys.exit(main(sys.argv[1:]))
