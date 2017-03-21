#Experimental/Continuous/Nightly
set(MODEL_TYPE "Nightly")
set(CTEST_BUILD_CONFIGURATION "Release")
set(CTEST_BUILD_OPTIONS "${CTEST_BUILD_OPTIONS} -DENABLE_MPI=ON")
set(BUILD_IDENTIFIER "MPI")


include(${CMAKE_CURRENT_LIST_DIR}/Merlin.cmake)
