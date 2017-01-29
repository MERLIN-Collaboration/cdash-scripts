#!/usr/bin/env python
from __future__ import print_function
import os
import subprocess
import tempfile

continuous_timespec = "0 * * * *"
nightly_timespec = "30 2 * * *"

cron_line = "{timespec} /usr/bin/ctest -S {script_path}"

current_dir = os.path.dirname(os.path.abspath(__file__))

with tempfile.NamedTemporaryFile() as tmp_crontab:
	# get existing crontab
	proc = subprocess.Popen(["crontab", "-l"],
	                         stdout=subprocess.PIPE, stderr=subprocess.PIPE)
	outs, errs = proc.communicate()
	ret = proc.wait()
	tmp_crontab.write(outs)

	for filename in os.listdir(os.path.join(current_dir,"scripts")):
		if not filename.endswith("CDash.cmake"): continue

		mode = filename[:-11]
		script_path = os.path.join(current_dir,"scripts", filename)

		print(mode)

		if "Continuous" in mode: timespec = continuous_timespec
		else: timespec = nightly_timespec


		tmp_crontab.write(cron_line.format(timespec=timespec, script_path=script_path)+"\n")

	tmp_crontab.flush()
	proc = subprocess.Popen(["crontab", tmp_crontab.name])
	ret = proc.wait()
	if ret != 0:
		print("Could not set crontab")
		exit(2)

