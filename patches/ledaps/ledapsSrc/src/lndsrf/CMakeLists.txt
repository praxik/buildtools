
cmake_minimum_required( VERSION 2.8.12 )

#The autofortran library linking does not work unless Fortran is enabled
include( CheckLanguage )
check_language( Fortran )
if( CMAKE_Fortran_COMPILER )
    enable_language( Fortran )
else()
    return()
endif()

set( SOURCES "CHAND.f" "CSALBR.f" )

set( TARGET_NAME lndsrf )
set( TARGET_VERSION ${${CMAKE_PROJECT_NAME}_VERSION} )
set( TARGET_CATEGORY Lib )

set( BUILD_SHARED_LIBS ON )
set( CMAKE_GNUtoMS ON )

add_definitions( -c )

set( LIB_TYPE STATIC )
if( WIN32 )
    set( LIB_TYPE SHARED )
endif()
add_library( ${TARGET_NAME} ${LIB_TYPE} ${SOURCES} )
if( WIN32 )
    set_target_properties( ${TARGET_NAME} PROPERTIES
        LINK_FLAGS "-static-libgcc"
        PREFIX ""
        IMPORT_PREFIX "" )
else()
    include( ModuleInstall )
endif()
