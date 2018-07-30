
cmake_minimum_required( VERSION 2.8.12 )

#The autofortran library linking does not work unless Fortran is enabled
include( CheckLanguage )
check_language( Fortran )
if( CMAKE_Fortran_COMPILER )
    enable_language( Fortran )
else()
    return()
endif()

file( GLOB HEADERS RELATIVE "${CMAKE_CURRENT_SOURCE_DIR}" "*.inc" )
file( GLOB SOURCES RELATIVE "${CMAKE_CURRENT_SOURCE_DIR}" "*.f" )
list( REMOVE_ITEM SOURCES "OILA6.f" )
list( REMOVE_ITEM SOURCES "PINATUBO.f" )
list( REMOVE_ITEM SOURCES "printkw.f" )

set( TARGET_NAME sixsV1.0B )
set( TARGET_VERSION ${${CMAKE_PROJECT_NAME}_VERSION} )
set( TARGET_CATEGORY App )

add_definitions( -Ae )

add_executable( ${TARGET_NAME} ${SOURCES} ${HEADERS} )
if( WIN32 )
    set_target_properties( ${TARGET_NAME} PROPERTIES
        LINK_FLAGS "-static -static-libgcc" )
else()
    include( ModuleInstall )
endif()
