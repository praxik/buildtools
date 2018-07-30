set( TARGET_VERSION ${${CMAKE_PROJECT_NAME}_VERSION} )
set( TARGET_EXPORT ${CMAKE_PROJECT_NAME}Targets )
set( TARGET_CATEGORY App )

include_directories( ${ESPA_INCLUDE_DIRS} )
include_directories( ${LIBXML2_INCLUDE_DIR} )

set( TARGET_NAME lndpm )

set( HEADERS "" )
set( SOURCES ${TARGET_NAME}.c )

add_executable( ${TARGET_NAME} ${SOURCES} ${HEADERS} )
target_link_libraries( ${TARGET_NAME}
  PRIVATE
    ${ESPA_LIBRARIES}
    ${GeoTIFF_LIBRARIES}
    ${LIBXML2_LIBRARIES} )

include( ModuleInstall )
