site_name(CTEST_SITE)

#Experimental/Continuous/Nightly
set(MODEL_TYPE "Nightly")

set(CTEST_BUILD_CONFIGURATION "Release")
set(CMAKE_CXX_COMPILER "g++")

set(CTEST_CMAKE_GENERATOR "Unix Makefiles")
set(CTEST_BUILD_OPTIONS "-DBUILD_TESTING=ON -DCOVERAGE=ON")

#https://cmake.org/cmake/help/latest/module/ProcessorCount.html
include(ProcessorCount)
ProcessorCount(N)
if(NOT N EQUAL 0)
	MESSAGE(STATUS "Found ${N} processors")
	set(CTEST_BUILD_FLAGS -j${N})
	set(ctest_test_args ${ctest_test_args} PARALLEL_LEVEL ${N})
endif()

set(WITH_MEMCHECK FALSE)
set(WITH_COVERAGE TRUE)

include(${CMAKE_CURRENT_LIST_DIR}/Merlin.cmake)
