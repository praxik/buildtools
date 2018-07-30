file( GLOB HEADERS RELATIVE "${CMAKE_CURRENT_SOURCE_DIR}" "*.h" )
file( GLOB SOURCES RELATIVE "${CMAKE_CURRENT_SOURCE_DIR}" "*.c" )

set( TARGET_NAME _espa_format_conversion )
set( TARGET_VERSION ${${CMAKE_PROJECT_NAME}_VERSION} )
set( TARGET_EXPORT ${CMAKE_PROJECT_NAME}Targets )
set( TARGET_CATEGORY Lib )
set( PRIVATE_HEADERS ${HEADERS} )
set( PUBLIC_HEADERS ${HEADERS} )
set( PRIVATE_SOURCES ${SOURCES} )
set( INCDIR_NAME "." )

include_directories( ${CMAKE_SOURCE_DIR}/src/raw_binary/common )
include_directories( ${CMAKE_SOURCE_DIR}/src/raw_binary/io_libs )
include_directories( ${GeoTIFF_INCLUDE_DIRS} )
include_directories( ${HDF4_INCLUDE_DIR} )
include_directories( ${HDFEOS_INCLUDE_DIRS} )
include_directories( ${JPEG_INCLUDE_DIR} )
include_directories( ${TIFF_INCLUDE_DIR} )
include_directories( ${LIBXML2_INCLUDE_DIR} )

add_library( ${TARGET_NAME} STATIC ${SOURCES} ${HEADERS} )
target_link_libraries( ${TARGET_NAME}
  PUBLIC
    _espa_raw_binary )

include( ModuleInstall )
