#!/bin/bash
export PATH=/usr/lib64/openmpi/bin:$PATH
export LD_LIBRARY_PATH=/usr/lib64/openmpi/lib:$LD_LIBRARY_PATH
export PKG_CONFIG_PATH=/usr/lib64/openmpi/lib/pkgconfig:$PKG_CONFIG_PATH
export MANPATH=/usr/share/man/openmpi-x86_64:$MANPATH
export MPI_BIN=/usr/lib64/openmpi/bin
export MPI_SYSCONFIG=/etc/openmpi-x86_64
export MPI_FORTRAN_MOD_DIR=/usr/lib64/gfortran/modules/openmpi
export MPI_INCLUDE=/usr/include/openmpi-x86_64
export MPI_LIB=/usr/lib64/openmpi/lib
export MPI_MAN=/usr/share/man/openmpi-x86_64
export MPI_PYTHON_SITEARCH=/usr/lib64/python2.7/site-packages/openmpi
export MPI_PYTHON2_SITEARCH=/usr/lib64/python2.7/site-packages/openmpi
export MPI_PYTHON3_SITEARCH=/usr/lib64/python3.4/site-packages/openmpi
export MPI_COMPILER=openmpi-x86_64
export MPI_SUFFIX=_openmpi
export MPI_HOME=/usr/lib64/openmpi
ctest -S ${HOME}/Merlin/Scripts/MerlinNightlyMPICDash.cmake
