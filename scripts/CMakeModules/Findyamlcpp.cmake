# From http://code.google.com/p/yaml-cpp/issues/detail?id=127
# Locate yaml-cpp
#
# This module defines
#  YAMLCPP_FOUND, if false, do not try to link to yaml-cpp
#  YAMLCPP_LIBRARIES, where to find yaml-cpp
#  YAMLCPP_INCLUDE_DIRS, where to find yaml.h
#
# By default, the dynamic libraries of yaml-cpp will be found. To find the static ones instead,
# you must set the YAMLCPP_STATIC_LIBRARY variable to TRUE before calling find_package(YamlCpp ...).
#
# If yaml-cpp is not installed in a standard path, you can use the YAMLCPP_ROOT CMake variable
# to tell CMake where yaml-cpp is.

# attempt to find static library first if this is set
if(YAMLCPP_STATIC_LIBRARY)
    set(YAMLCPP_LIB_NAME libyaml-cpp.a)

     if (MSVC)
          if (CMAKE_BUILD_TYPE MATCHES "debug")
               set(YAMLCPP_LIB_NAME libyaml-cppmdd.lib)
          else()
               set(YAMLCPP_LIB_NAME libyaml-cppmd.lib)
          endif()
     endif()
endif()


        
# find the yaml-cpp include directory
find_path(YAMLCPP_INCLUDE_DIRS yaml-cpp/yaml.h
          PATH_SUFFIXES include
          PATHS
          ~/Library/Frameworks/yaml-cpp/include/
          /Library/Frameworks/yaml-cpp/include/
          /usr/local/include/
          /usr/include/
          /sw/yaml-cpp/         # Fink
          /opt/local/yaml-cpp/  # DarwinPorts
          /opt/csw/yaml-cpp/    # Blastwave
          /opt/yaml-cpp/
          ${YAMLCPP_ROOT}/include/
            ENV{YAMLCPP_ROOT}/include/)

# find the yaml-cpp library
find_library(YAMLCPP_LIBRARIES
             NAMES ${YAMLCPP_LIB_NAME} yaml-cpp
             PATH_SUFFIXES lib64 lib
             PATHS ~/Library/Frameworks
                    /Library/Frameworks
                    /usr/local
                    /usr
                    /sw
                    /opt/local
                    /opt/csw
                    /opt
                    ${YAMLCPP_ROOT}/lib
                    ENV{YAMLCPP_ROOT}/lib/
             NO_DEFAULT_PATH)

mark_as_advanced(FORCE YAMLCPP_INCLUDE_DIRS YAMLCPP_LIBRARIES)

# handle the QUIETLY and REQUIRED arguments and set YAMLCPP_FOUND to TRUE if all listed variables are TRUE
include(FindPackageHandleStandardArgs)
FIND_PACKAGE_HANDLE_STANDARD_ARGS(YAMLCPP DEFAULT_MSG YAMLCPP_INCLUDE_DIRS YAMLCPP_LIBRARIES)
