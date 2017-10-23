#!/usr/bin/env python
from __future__ import print_function
import os
import pwd
import sys
import errno
import subprocess

systemd_dir = os.path.expanduser("~/.config/systemd/user")

continuous_timespec = "hourly"
nightly_timespec = "*-*-* 02:30:00"

service_temp = """[Unit]
Description={mode}

[Service]
Type=oneshot
Nice=10
IOSchedulingPriority=6
ProtectHome=read-only
ProtectSystem=full
SyslogIdentifier=Ctest_{mode}
ExecStart={wrapper} /usr/bin/ctest -V -S {script_path}

# On systemd newer than 232, enable these. needs testing
#ProtectSystem=strict
#ReadWritePaths=/var/tmp/merlin-cdash
"""

timer_temp = """[Unit]
Description=Run Merlin Test {mode}

[Timer]
OnCalendar={oncal}
AccuracySec=5min
Persistent=true

[Install]
WantedBy=timers.target
"""

# Make systemd user directory if needed
try: os.makedirs(systemd_dir)
except OSError as exc:
	if exc.errno == errno.EEXIST: pass
	else: raise

# Check user is allowed to set timers while logged out
#username = os.getlogin()
username = pwd.getpwuid(os.getuid())[0]
proc = subprocess.Popen(["loginctl", "show-user", "-p", "Linger", username],
                         stdout=subprocess.PIPE, stderr=subprocess.PIPE)
outs, errs = proc.communicate()
ret = proc.wait()

if outs.strip() == "Linger=no":
	print("Error: User %s is not allowed to create systemd timers"%username)
	print("As admin run")
	print("loginctl enable-linger %s"%username)
	exit(1)
elif not outs.strip() == "Linger=yes" or ret != 0:
	print("Error: Could not determine is user is allowed to create systemd timers")
	print("loginctl returned %s"%ret)
	print("'%s'"%outs.strip())
	print("'%s'"%errs.strip())
	exit(2)

current_dir = os.path.dirname(os.path.abspath(__file__))

# Check for existing timers
existing_timers = []
existing_units = []
proc = subprocess.Popen(["systemctl", "--user", "show", "Merlin*", "--type", "timer", "--property", "Names,Unit"],
                         stdout=subprocess.PIPE, stderr=subprocess.PIPE)
outs, errs = proc.communicate()
ret = proc.wait()
for line in outs.split("\n"):
	if line.startswith("Names="):
		existing_timers.append(line.partition("=")[2])
	elif line.startswith("Unit="):
		existing_units.append(line.partition("=")[2])

# Remove old times and units
for unit, timer in zip(existing_units, existing_timers):
	proc = subprocess.Popen(["systemctl", "--user","disable", timer])
	ret = proc.wait()
	if ret != 0:
		print("Could not disable systemd timer for %s"%mode)
		exit(5)
	proc = subprocess.Popen(["systemctl", "--user","stop", timer])
	ret = proc.wait()
	if ret != 0:
		print("Could not stop systemd timer for %s"%mode)
		exit(6)

	os.remove(os.path.join(systemd_dir, timer))
	os.remove(os.path.join(systemd_dir, unit))

if "uninstall" in sys.argv[1:]:
	exit()

for filename in os.listdir(os.path.join(current_dir,"scripts")):
	if not filename.endswith("CDash.cmake"): continue

	mode = filename[:-11]
	script_path = os.path.join(current_dir,"scripts", filename)

	print(mode)

	if "Continuous" in mode: oncal = continuous_timespec
	else: oncal = nightly_timespec

        wrapper = ""
        if "MPI" in mode: wrapper = os.path.join(current_dir, "scripts", "mpi_wrap.sh")

	with open(os.path.join(systemd_dir, mode+".timer"), "w") as fh:
		fh.write(timer_temp.format(mode=mode, oncal=oncal))

	with open(os.path.join(systemd_dir, mode+".service"), "w") as fh:
		fh.write(service_temp.format(mode=mode, script_path=script_path, wrapper=wrapper))

	proc = subprocess.Popen(["systemctl", "--user","enable", mode+".timer"])
	ret = proc.wait()
	if ret != 0:
		print("Could not enable systemd timer for %s"%mode)
		exit(3)
	proc = subprocess.Popen(["systemctl", "--user","start", mode+".timer"])
	ret = proc.wait()
	if ret != 0:
		print("Could not start systemd timer for %s"%mode)
		exit(4)

