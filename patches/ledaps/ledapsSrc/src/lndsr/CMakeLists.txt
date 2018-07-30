set( TARGET_VERSION ${${CMAKE_PROJECT_NAME}_VERSION} )
set( TARGET_EXPORT ${CMAKE_PROJECT_NAME}Targets )
set( TARGET_CATEGORY App )

include_directories( ${ESPA_INCLUDE_DIRS} )
include_directories( ${HDF4_INCLUDE_DIR} )
include_directories( ${LIBXML2_INCLUDE_DIR} )

set( TARGET_NAME lndsr )

file( GLOB HEADERS RELATIVE "${CMAKE_CURRENT_SOURCE_DIR}" "*.h" )
file( GLOB SOURCES RELATIVE "${CMAKE_CURRENT_SOURCE_DIR}" "*.c" )
list( REMOVE_ITEM SOURCES "read_data.c" )
if( WIN32 )
    list( APPEND SOURCES "${WIN_DIR}/mkstemp.c" )
endif()

add_executable( ${TARGET_NAME} ${SOURCES} ${HEADERS} )
target_link_libraries( ${TARGET_NAME}
  PUBLIC
    lndsrf
  PRIVATE
    ${ESPA_LIBRARIES}
    ${GeoTIFF_LIBRARIES}
    ${HDFEOS_LIBRARIES}
    ${LIBXML2_LIBRARIES} )

include( ModuleInstall )
