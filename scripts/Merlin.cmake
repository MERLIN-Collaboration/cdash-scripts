include(${CMAKE_CURRENT_LIST_DIR}/local.cmake OPTIONAL)

if(NOT DEFINED BUILD_ROOT)
	set(BUILD_ROOT "/var/tmp/merlin-cdash")
endif()

set(PLATFORM "${CMAKE_SYSTEM_NAME}")

if (${PLATFORM} MATCHES "Linux")
	if(EXISTS "/etc/debian_version")
		set ( PLATFORM "Debian")
		file (STRINGS "/etc/issue" PLATFORM REGEX "[A-Za-z0-9/. ]+")
		string (REGEX MATCH "[A-Za-z0-9/. ]+" PLATFORM "${PLATFORM}")
	elseif(EXISTS "/etc/redhat-release")
		set ( PLATFORM "Redhat")
		file (STRINGS "/etc/redhat-release" PLATFORM REGEX "[A-Za-z0-9. ]+")
		string (REGEX MATCH "[A-Za-z0-9. ]+" PLATFORM "${PLATFORM}")
		string (REGEX REPLACE "release" "" PLATFORM "${PLATFORM}")
	endif()
	
	execute_process(COMMAND ${CMAKE_CXX_COMPILER} --version OUTPUT_VARIABLE CXX_VERSION)
	string (REGEX MATCH "[0-9.]+" CXX_VERSION "${CXX_VERSION}")
	set(CXX_VERSION "${CMAKE_CXX_COMPILER} ${CXX_VERSION}")
endif()

set(CTEST_BUILD_NAME "${PLATFORM} ${CMAKE_HOST_SYSTEM_PROCESSOR} ${CXX_VERSION} (${CTEST_BUILD_CONFIGURATION}) ${MPI_VERSION}")


if(NOT DEFINED N)
	#https://cmake.org/cmake/help/latest/module/ProcessorCount.html
	include(ProcessorCount)
	ProcessorCount(N)
endif()

if(NOT N EQUAL 0)
	MESSAGE(STATUS "Found ${N} processors")
	set(CTEST_BUILD_FLAGS -j${N})
	set(ctest_test_args ${ctest_test_args} PARALLEL_LEVEL ${N})
endif()

find_program(CTEST_GIT_COMMAND NAMES git)
find_program(CTEST_COVERAGE_COMMAND NAMES gcov)
find_program(CTEST_MEMORYCHECK_COMMAND NAMES valgrind)

#set(CTEST_MEMORYCHECK_SUPPRESSIONS_FILE ${CTEST_SOURCE_DIRECTORY}/tests/valgrind.supp)

set(CTEST_CUSTOM_MAXIMUM_NUMBER_OF_WARNINGS "10000000")
set(CTEST_CUSTOM_MAXIMUM_NUMBER_OF_ERRORS   "10000000")

set(CTEST_SOURCE_DIRECTORY "${BUILD_ROOT}/Merlin/${MODEL_TYPE}/${CTEST_BUILD_CONFIGURATION}/source")
set(CTEST_BINARY_DIRECTORY "${BUILD_ROOT}/Merlin/${MODEL_TYPE}/${CTEST_BUILD_CONFIGURATION}/build")
#######################################################################
set(CONTINUOUS_FIRST_RUN NO)
if(NOT EXISTS "${CTEST_SOURCE_DIRECTORY}")
  set(CTEST_CHECKOUT_COMMAND "${CTEST_GIT_COMMAND} clone https://github.com/MERLIN-Collaboration/MERLIN.git ${CTEST_SOURCE_DIRECTORY}")
  set(CONTINUOUS_FIRST_RUN YES)
endif()

set(CTEST_UPDATE_COMMAND "${CTEST_GIT_COMMAND}")
#######################################################################

if(EXISTS "${CTEST_BINARY_DIRECTORY}/CMakeCache.txt")
	ctest_empty_binary_directory(${CTEST_BINARY_DIRECTORY})
endif()

set(CTEST_CONFIGURE_COMMAND "${CMAKE_COMMAND} -DCMAKE_BUILD_TYPE:STRING=${CTEST_BUILD_CONFIGURATION}")
set(CTEST_CONFIGURE_COMMAND "${CTEST_CONFIGURE_COMMAND} ${CTEST_BUILD_OPTIONS}")
set(CTEST_CONFIGURE_COMMAND "${CTEST_CONFIGURE_COMMAND} \"-G${CTEST_CMAKE_GENERATOR}\"")
set(CTEST_CONFIGURE_COMMAND "${CTEST_CONFIGURE_COMMAND} \"${CTEST_SOURCE_DIRECTORY}\"")

#makes the build and source folder
ctest_start(${MODEL_TYPE})

SET(UPDATED_RUN "-2")
#pulls the latest source from github
ctest_update(RETURN_VALUE UPDATED_RUN)

if(${UPDATED_RUN} MATCHES 0 AND MODEL_TYPE MATCHES "Continuous" AND NOT ${CONTINUOUS_FIRST_RUN}  MATCHES "YES")
	MESSAGE(STATUS "No updated MERLIN on github.")
elseif(${UPDATED_RUN} MATCHES -1)
	MESSAGE(STATUS "Error in the update step")
else()
	MESSAGE(STATUS "MERLIN is updated on github with ${UPDATED_RUN} new files.")

#generates the configuration
ctest_configure()

#builds MERLIN
ctest_build()

#runs the tests
ctest_test(PARALLEL_LEVEL ${N})

if (WITH_COVERAGE AND CTEST_COVERAGE_COMMAND)
  ctest_coverage()
endif (WITH_COVERAGE AND CTEST_COVERAGE_COMMAND)
if (WITH_MEMCHECK AND CTEST_MEMORYCHECK_COMMAND)
  ctest_memcheck()
endif (WITH_MEMCHECK AND CTEST_MEMORYCHECK_COMMAND)

#submits to the dashboard
ctest_submit()
endif()
#######################################################################
