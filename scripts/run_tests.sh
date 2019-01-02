#!/bin/bash
set -o nounset

SCRIPTPATH="$( cd "$(dirname "$0")" ; pwd -P )"
CTEST=/usr/bin/ctest

case "$1" in
	"nightly" )
		echo Running Merlin++ Nightly CTests

		$CTEST -V -S ${SCRIPTPATH}/MerlinNightlyReleaseCDash.cmake
		$CTEST -V -S ${SCRIPTPATH}/MerlinNightlyDebugCDash.cmake
		${SCRIPTPATH}/mpi_wrap.sh $CTEST -V -S ${SCRIPTPATH}/MerlinNightlyMPICDash.cmake
	;;

	"continuous" )
		echo Running Merlin++ Continuous CTests

		$CTEST -V -S ${SCRIPTPATH}/MerlinContinuousReleaseCDash.cmake
		$CTEST -V -S ${SCRIPTPATH}/MerlinContinuousDebugCDash.cmake
		${SCRIPTPATH}/mpi_wrap.sh $CTEST -V -S ${SCRIPTPATH}/MerlinContinuousMPICDash.cmake
	;;

	* )
		echo Usage:
		echo   $0 mode
		echo mode is either nightly or continuous
	;;
esac




