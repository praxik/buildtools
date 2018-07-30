# - Find SAGA
# Find the native SAGA includes and libraries
# This module defines
#  SAGA_INCLUDE_DIR, where to find saga_api.h, etc.
#  SAGA_LIBRARIES, libraries to link against to use SAGA.
#  SAGA_VERSION, version in CMake decimal version# format (e.g., 1.4.1.1)
#  SAGA_FOUND, If false, do not try to use SAGA.

#Find the main saga header
set( SAGA_INCLUDE_DIR )
find_path( SAGA_INCLUDE_DIR saga_api/api_core.h
  PATHS ${SAGA_ROOT}
    ENV SAGA_ROOT
  PATH_SUFFIXES include/saga/saga_core )

#Extract the version number from the header
set( SAGA_VERSION )
if( SAGA_INCLUDE_DIR )
  set( versionFile "${SAGA_INCLUDE_DIR}/saga_api/saga_api.h" )
  if( NOT EXISTS ${versionFile} )
    message( WARNING "Can't find ${versionFile}" )
    return()
  endif()

  set( versionRegex
    "^#define[ \t]+SAGA_VERSION[ \t]+.*\"([0-9]+)\\.([0-9]+)\\.([0-9])\".*$" )
  file( STRINGS
    "${versionFile}" versionContents
    LIMIT_COUNT 1 REGEX "${versionRegex}" )
  string( REGEX REPLACE
    "${versionRegex}" "\\1.\\2.\\3"
    SAGA_VERSION "${versionContents}" )
endif()


#Get a list of requested saga components
#saga_api and saga_gdi are assumed as always requested
set( requestedComponents )
foreach( component ${SAGA_FIND_COMPONENTS} )
  list( APPEND requestedComponents ${component} )
endforeach()
list( APPEND requestedComponents "saga_api" )
#list( APPEND requestedComponents "saga_gdi" )
list( REMOVE_DUPLICATES requestedComponents )

#Determine the library suffix on Windows
if( WIN32 )
  set( crtSuffix "" )
  set( crtDebugSuffix "d" )
else()
  set( crtSuffix "" )
  set( crtDebugSuffix "" )
endif()

#Find each library
set( SAGA_LIBRARIES )
foreach( lib ${requestedComponents} )
  find_library( SAGA_${lib}_LIBRARY
    NAMES ${lib}${crtSuffix}
    PATHS ${SAGA_ROOT}
      ENV SAGA_ROOT
    PATH_SUFFIXES lib
    NO_DEFAULT_PATH )
  if( NOT SAGA_${lib}_LIBRARY )
    message( WARNING "Could not find SAGA component library ${lib}" )
  endif()

  if( SAGA_${lib}_LIBRARY )
    list( APPEND SAGA_LIBRARIES ${SAGA_${lib}_LIBRARY} )
  endif()

  find_library( SAGA_${lib}_LIBRARY_DEBUG
    NAMES ${lib}${crtDebugSuffix}
    PATHS ${SAGA_ROOT}
      ENV SAGA_ROOT
    PATH_SUFFIXES lib
    NO_DEFAULT_PATH )
  if( SAGA_${lib}_LIBRARY_DEBUG )
    list( APPEND SAGA_LIBRARIES ${SAGA_${lib}_LIBRARY_DEBUG} )
  endif()

  mark_as_advanced( FORCE
    SAGA_${lib}_LIBRARY
    SAGA_${lib}_LIBRARY_DEBUG )
endforeach()

mark_as_advanced( FORCE
  SAGA_INCLUDE_DIR
  SAGA_LIBRARIES
  SAGA_VERSION )

#Handle the QUIETLY and REQUIRED arguments
#Set SAGA_FOUND to TRUE if all listed variables are TRUE
include( FindPackageHandleStandardArgs )
FIND_PACKAGE_HANDLE_STANDARD_ARGS( SAGA
  REQUIRED_VARS SAGA_INCLUDE_DIR SAGA_LIBRARIES
  VERSION_VAR SAGA_VERSION )
