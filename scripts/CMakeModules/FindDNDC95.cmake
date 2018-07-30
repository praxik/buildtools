# - Find DNDC95
# This module tries to find the DNDC95 library and headers.
# Once done this will define
#
#   DNDC95_FOUND - system has DNDC95 headers and libraries
#   DNDC95_INCLUDE_DIRS - the include directories needed for DNDC95
#   DNDC95_LIBRARIES - the libraries needed to use DNDC95
#
# Variables used by this module, which can change the default behaviour and
# need to be set before calling find_package:
#
#   DNDC95_ROOT            Root directory to DNDC95 installation. Will
#                           be used ahead of CMake default path.
#
# The following advanced variables may be used if the module has difficulty
# locating DNDC95 or you need fine control over what is used.
#
#   DNDC95_INCLUDE_DIR
#
#   DNDC95_LIBRARY


# Look for the header - preferentially searching below DNDC95_ROOT
find_path(
    DNDC95_INCLUDE_DIR
    NAMES DNDC_Interface.h
    PATHS ${DNDC95_ROOT}
    PATH_SUFFIXES include
    NO_DEFAULT_PATH
)

# Look for the library, preferentially searching below DNDC95_ROOT
find_library(
    DNDC95_LIBRARY
    NAMES DNDC95.lib
    PATHS ${DNDC95_ROOT}
    PATH_SUFFIXES lib64 lib32 lib
    NO_DEFAULT_PATH
)

include(FindPackageHandleStandardArgs)
find_package_handle_standard_args(
    DNDC95
    DEFAULT_MSG
    DNDC95_LIBRARY
    DNDC95_INCLUDE_DIR
)

set(DNDC95_FOUND ${DNDC95_FOUND})

if(DNDC95_FOUND)
    set(DNDC95_LIBRARIES ${DNDC95_LIBRARY})
    set(DNDC95_INCLUDE_DIRS ${DNDC95_INCLUDE_DIR})
else(DNDC95_FOUND)
    set(DNDC95_LIBRARIES)
    set(DNDC95_INCLUDE_DIRS)
endif(DNDC95_FOUND)


mark_as_advanced(
    DNDC95_LIBRARY
    DNDC95_INCLUDE_DIR
)

