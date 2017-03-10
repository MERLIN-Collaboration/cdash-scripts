include(${CMAKE_CURRENT_LIST_DIR}/local.cmake OPTIONAL)

if(NOT DEFINED BUILD_ROOT)
	set(BUILD_ROOT "/var/tmp/merlin-cdash")
endif()

site_name(CTEST_SITE)

set(PLATFORM "${CMAKE_SYSTEM_NAME}")

if(NOT DEFINED CMAKE_CXX_COMPILER)
	set(CMAKE_CXX_COMPILER "g++")
endif()

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
elseif (${PLATFORM} MATCHES "FreeBSD")
	set ( PLATFORM ${CMAKE_SYSTEM})
endif()

execute_process(COMMAND ${CMAKE_CXX_COMPILER} --version OUTPUT_VARIABLE CXX_VERSION)
string (REGEX MATCH "[0-9.]+" CXX_VERSION "${CXX_VERSION}")
set(CXX_VERSION "${CMAKE_CXX_COMPILER} ${CXX_VERSION}")

set(CTEST_BUILD_NAME "${PLATFORM} ${CMAKE_HOST_SYSTEM_PROCESSOR} ${CXX_VERSION} (${CTEST_BUILD_CONFIGURATION}) ${MPI_VERSION} ${BUILD_IDENTIFIER}")

set(CTEST_BUILD_OPTIONS "-DBUILD_TESTING=ON -DCOVERAGE=ON")

if(NOT DEFINED MERLIN_GIT_ADDR)
	set(MERLIN_GIT_ADDR "https://github.com/MERLIN-Collaboration/MERLIN.git")
endif()

if(NOT DEFINED MERLIN_GIT_BRANCH)
	set(MERLIN_GIT_BRANCH "master")
endif()


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

if(DEFINED MERLIN_TEST_TIMEOUT)
	set(CTEST_BUILD_OPTIONS "${CTEST_BUILD_OPTIONS} -DTEST_TIMEOUT=${MERLIN_TEST_TIMEOUT}")
endif()

if(${CTEST_BUILD_CONFIGURATION} MATCHES "Debug")
	set(WITH_MEMCHECK TRUE)
else()
	set(WITH_MEMCHECK FALSE)
endif()

if(NOT DEFINED WITH_COVERAGE)
	set(WITH_COVERAGE TRUE)
endif()

if(NOT DEFINED CTEST_CMAKE_GENERATOR)
	set(CTEST_CMAKE_GENERATOR "Unix Makefiles")
endif()

find_program(CTEST_GIT_COMMAND NAMES git)
find_program(CTEST_COVERAGE_COMMAND NAMES gcov)
find_program(CTEST_MEMORYCHECK_COMMAND NAMES valgrind)


set(CTEST_CUSTOM_MAXIMUM_NUMBER_OF_WARNINGS "10000000")
set(CTEST_CUSTOM_MAXIMUM_NUMBER_OF_ERRORS   "10000000")

set(CTEST_SOURCE_DIRECTORY "${BUILD_ROOT}/Merlin/${MODEL_TYPE}/${CTEST_BUILD_CONFIGURATION}/${CMAKE_CXX_COMPILER}/${BUILD_IDENTIFIER}/source")
set(CTEST_BINARY_DIRECTORY "${BUILD_ROOT}/Merlin/${MODEL_TYPE}/${CTEST_BUILD_CONFIGURATION}/${CMAKE_CXX_COMPILER}/${BUILD_IDENTIFIER}/build")

set(CTEST_MEMORYCHECK_COMMAND_OPTIONS "--tool=memcheck --leak-check=yes --show-reachable=yes --trace-children=yes")
set(CTEST_MEMORYCHECK_SUPPRESSIONS_FILE ${CTEST_SOURCE_DIRECTORY}/MerlinTests/data/python.supp)
#######################################################################
set(CONTINUOUS_FIRST_RUN NO)
if(NOT EXISTS "${CTEST_SOURCE_DIRECTORY}")
  set(CTEST_CHECKOUT_COMMAND "${CTEST_GIT_COMMAND} clone ${MERLIN_GIT_ADDR} --branch ${MERLIN_GIT_BRANCH} --depth 1 ${CTEST_SOURCE_DIRECTORY}")
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
set(CTEST_CONFIGURE_COMMAND "${CTEST_CONFIGURE_COMMAND} \"-DCMAKE_CXX_COMPILER=${CMAKE_CXX_COMPILER}\"")
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
