
if( WIN32 )
    cmake_minimum_required( VERSION 3.0.0 )
else()
    cmake_minimum_required( VERSION 2.8.8 )
endif()

project( ledaps )

set( ${CMAKE_PROJECT_NAME}_MAJOR_VERSION 2 )
set( ${CMAKE_PROJECT_NAME}_MINOR_VERSION 2 )
set( ${CMAKE_PROJECT_NAME}_PATCH_VERSION 1 )
set( v ${CMAKE_PROJECT_NAME}_VERSION )
set( ${v} ${${CMAKE_PROJECT_NAME}_MAJOR_VERSION} )
set( ${v} ${${v}}.${${CMAKE_PROJECT_NAME}_MINOR_VERSION} )
set( ${v} ${${v}}.${${CMAKE_PROJECT_NAME}_PATCH_VERSION} )
set( v ${${v}} )
message( STATUS "Configuring ${CMAKE_PROJECT_NAME}: v${v}\n" )

set( INSTALL_LIBDIR lib )
set( INSTALL_BINDIR bin )
set( INSTALL_INCDIR include )
set( INSTALL_SHRDIR share )

#Set a default build type if none was specified
if( NOT WIN32 AND NOT CMAKE_BUILD_TYPE )
    set( CMAKE_BUILD_TYPE RelWithDebInfo CACHE STRING "Set build type" FORCE )
endif()

#Update CMake module path
set( CMAKE_MODULE_PATH
    "${PROJECT_SOURCE_DIR}/CMakeModules"
    ${CMAKE_MODULE_PATH} )

#ESPA
find_package( ESPA 1.3.1 REQUIRED )

#GeoTIFF
find_package( GeoTIFF 1.4.1 REQUIRED )

#HDF4
find_package( HDF4 4.2.10 REQUIRED )

#hdf-eos2
find_package( hdf-eos2 REQUIRED )
add_definitions( -DPACKAGE_VERSION="2.19.0" )

#LibXml2
find_package( LibXml2 2.7.8 REQUIRED )

#MinGW GFortran
if( WIN32 )
    set( MINGW_GFORTRAN "Please specify"
        CACHE FILEPATH "Full path to the MinGW GFortran compiler" )
endif()

#global
add_definitions( -D_CRT_SECURE_NO_WARNINGS )
if( WIN32 )
    add_definitions( -DMAXNAMLEN=255 )
    add_definitions( -DNAME_MAX=255 )
    add_definitions( -D_USE_MATH_DEFINES )
    add_definitions( -Drindex=strchr )
    set( WIN_DIR ${PROJECT_SOURCE_DIR}/windows )
    include_directories( ${WIN_DIR} )
endif()

add_subdirectory( ledapsAncSrc )
add_subdirectory( ledapsSrc )

