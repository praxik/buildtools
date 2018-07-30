set( TARGET_VERSION ${${CMAKE_PROJECT_NAME}_VERSION} )
set( TARGET_EXPORT ${CMAKE_PROJECT_NAME}Targets )
set( TARGET_CATEGORY App )

include_directories( ${ESPA_INCLUDE_DIRS} )
include_directories( ${LIBXML2_INCLUDE_DIR} )

set( TARGET_NAME lndcal )

file( GLOB HEADERS RELATIVE "${CMAKE_CURRENT_SOURCE_DIR}" "*.h" )
file( GLOB SOURCES RELATIVE "${CMAKE_CURRENT_SOURCE_DIR}" "*.c" )

add_executable( ${TARGET_NAME} ${SOURCES} ${HEADERS} )
target_link_libraries( ${TARGET_NAME}
  PRIVATE
    ${ESPA_LIBRARIES}
    ${GeoTIFF_LIBRARIES}
    ${LIBXML2_LIBRARIES} )
if( UNIX )
    target_link_libraries( ${TARGET_NAME}
      PRIVATE
        m )
endif()

include( ModuleInstall )
