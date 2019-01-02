#!/usr/bin/env python
from __future__ import print_function
import os
import subprocess
import tempfile

continuous_timespec = "0 * * * *"
nightly_timespec = "30 2 * * *"

cron_line = "{timespec} {current_dir}/scripts/run_tests.sh {mode}"

current_dir = os.path.dirname(os.path.abspath(__file__))

with tempfile.NamedTemporaryFile() as tmp_crontab:
	# get existing crontab
	proc = subprocess.Popen(["crontab", "-l"],
	                         stdout=subprocess.PIPE, stderr=subprocess.PIPE)
	outs, errs = proc.communicate()
	ret = proc.wait()
	tmp_crontab.write(outs)

        for mode in ["nightly", "continuous"]:
		print(mode)

		if "continuous" in mode: timespec = continuous_timespec
		else: timespec = nightly_timespec

		tmp_crontab.write(cron_line.format(timespec=timespec, mode=mode, current_dir=current_dir)+"\n")

	tmp_crontab.flush()
	proc = subprocess.Popen(["crontab", tmp_crontab.name])
	ret = proc.wait()
	if ret != 0:
		print("Could not set crontab")
		exit(2)

