#!/bin/bash -l
set -e
module load mpi/openmpi-x86_64
bash -c "$*"

