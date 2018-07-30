set( TARGET_VERSION ${${CMAKE_PROJECT_NAME}_VERSION} )
set( TARGET_EXPORT ${CMAKE_PROJECT_NAME}Targets )
set( TARGET_CATEGORY App )

include_directories( ${CMAKE_SOURCE_DIR}/src/raw_binary/common )
include_directories( ${CMAKE_SOURCE_DIR}/src/raw_binary/io_libs )
include_directories( ${CMAKE_SOURCE_DIR}/src/raw_binary/format_conversion_libs )
include_directories( ${GeoTIFF_INCLUDE_DIRS} )
include_directories( ${HDF4_INCLUDE_DIR} )
include_directories( ${HDFEOS_INCLUDE_DIRS} )
include_directories( ${JPEG_INCLUDE_DIR} )
include_directories( ${TIFF_INCLUDE_DIR} )
include_directories( ${LIBXML2_INCLUDE_DIR} )

set( TARGET_NAME convert_espa_to_gtif )

set( HEADERS "" )
set( SOURCES ${TARGET_NAME}.c )
if( WIN32 )
    list( APPEND HEADERS ${WIN_DIR}/getopt.h )
    list( APPEND SOURCES ${WIN_DIR}/getopt.c ${WIN_DIR}/getopt1.c )
endif()

add_executable( ${TARGET_NAME} ${SOURCES} ${HEADERS} )
target_link_libraries( ${TARGET_NAME}
  PUBLIC
    _espa_common
    _espa_raw_binary
    _espa_format_conversion
  PRIVATE
    ${GeoTIFF_LIBRARIES}
    ${LIBXML2_LIBRARIES} )

include( ModuleInstall )

set( TARGET_NAME convert_lpgs_to_espa )

set( HEADERS "" )
set( SOURCES ${TARGET_NAME}.c )
if( WIN32 )
    list( APPEND HEADERS ${WIN_DIR}/getopt.h )
    list( APPEND SOURCES ${WIN_DIR}/getopt.c ${WIN_DIR}/getopt1.c )
endif()

add_executable( ${TARGET_NAME} ${SOURCES} ${HEADERS} )
target_link_libraries( ${TARGET_NAME}
  PUBLIC
    _espa_common
    _espa_raw_binary
    _espa_format_conversion
  PRIVATE
    ${GeoTIFF_LIBRARIES}
    ${HDFEOS_LIBRARIES}
    ${LIBXML2_LIBRARIES} )

include( ModuleInstall )
