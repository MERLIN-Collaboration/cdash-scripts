site_name(CTEST_SITE)

#Experimental/Continuous/Nightly
set(MODEL_TYPE "Continuous")


set(CTEST_BUILD_CONFIGURATION "Release")
set(CMAKE_CXX_COMPILER "g++")

set(CTEST_CMAKE_GENERATOR "Unix Makefiles")
set(CTEST_BUILD_OPTIONS "-DBUILD_TESTING=ON -DCOVERAGE=ON")


set(WITH_MEMCHECK FALSE)
set(WITH_COVERAGE TRUE)

include(${CMAKE_CURRENT_LIST_DIR}/Merlin.cmake)
