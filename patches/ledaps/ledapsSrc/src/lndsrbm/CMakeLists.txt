set( TARGET_VERSION ${${CMAKE_PROJECT_NAME}_VERSION} )
set( TARGET_EXPORT ${CMAKE_PROJECT_NAME}Targets )
set( TARGET_CATEGORY App )

include_directories( ${ESPA_INCLUDE_DIRS} )
include_directories( ${HDF4_INCLUDE_DIR} )
include_directories( ${LIBXML2_INCLUDE_DIR} )

#dump_meta
set( TARGET_NAME dump_meta )


set( HEADERS "" )
set( SOURCES ${TARGET_NAME}.c )

add_executable( ${TARGET_NAME} ${SOURCES} )
target_link_libraries( ${TARGET_NAME}
  PRIVATE
    ${ESPA_LIBRARIES}
    ${GeoTIFF_LIBRARIES}
    ${HDFEOS_LIBRARIES}
    ${LIBXML2_LIBRARIES} )

include( ModuleInstall )

#SDSreader3.0
set( TARGET_NAME SDSreader3.0 )

set( SOURCES ${TARGET_NAME}.c )

add_executable( ${TARGET_NAME} ${SOURCES} )
target_link_libraries( ${TARGET_NAME}
  PRIVATE
    ${HDF4_LIBRARIES} )

include( ModuleInstall )

#comptemp
set( TARGET_NAME comptemp )

set( SOURCES ${TARGET_NAME}.c )

add_executable( ${TARGET_NAME} ${SOURCES} )
target_link_libraries( ${TARGET_NAME}
  PRIVATE
    ${ESPA_LIBRARIES}
    ${GeoTIFF_LIBRARIES}
    ${HDFEOS_LIBRARIES}
    ${LIBXML2_LIBRARIES} )

include( ModuleInstall )

#LS_geoloc
set( TARGET_NAME LS_geoloc )

set( SOURCES ${TARGET_NAME}.c )
if( WIN32 )
    list( APPEND SOURCES "${WIN_DIR}/sincos.c" )
endif()

add_library( ${TARGET_NAME} STATIC ${SOURCES} )

include( ModuleInstall )

#xy2geo
set( TARGET_NAME xy2geo )

set( SOURCES "LS_geoloc_driver.c" )

add_executable( ${TARGET_NAME} ${SOURCES} )
target_link_libraries( ${TARGET_NAME}
  PRIVATE
    LS_geoloc
    ${ESPA_LIBRARIES}
    ${GeoTIFF_LIBRARIES}
    ${HDFEOS_LIBRARIES}
    ${LIBXML2_LIBRARIES} )
set_target_properties( ${TARGET_NAME} PROPERTIES
    COMPILE_FLAGS "-DINV" )

include( ModuleInstall )

#geo2xy
set( TARGET_NAME geo2xy )

set( SOURCES "LS_geoloc_driver.c" )

add_executable( ${TARGET_NAME} ${SOURCES} )
target_link_libraries( ${TARGET_NAME}
  PRIVATE
    LS_geoloc
    ${ESPA_LIBRARIES}
    ${GeoTIFF_LIBRARIES}
    ${HDFEOS_LIBRARIES}
    ${LIBXML2_LIBRARIES} )

include( ModuleInstall )

#lndsrbm
set( TARGET_NAME lndsrbm )

set( SOURCES ${TARGET_NAME}.c )
if( WIN32 )
    list( APPEND SOURCES "${WIN_DIR}/getopt.c" "${WIN_DIR}/getopt1.c" )
endif()

add_executable( ${TARGET_NAME} ${SOURCES} )
target_link_libraries( ${TARGET_NAME}
  PRIVATE
    ${ESPA_LIBRARIES}
    ${GeoTIFF_LIBRARIES}
    ${HDFEOS_LIBRARIES}
    ${LIBXML2_LIBRARIES} )

include( ModuleInstall )

#Install shell files
install(
    FILES "lndsrbm.ksh"
    PERMISSIONS
        OWNER_EXECUTE OWNER_WRITE OWNER_READ
        GROUP_EXECUTE GROUP_READ
        WORLD_EXECUTE WORLD_READ
    DESTINATION ${INSTALL_BINDIR} )
