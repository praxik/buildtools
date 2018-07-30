set( TARGET_VERSION ${${CMAKE_PROJECT_NAME}_VERSION} )
set( TARGET_EXPORT ${CMAKE_PROJECT_NAME}Targets )
set( TARGET_CATEGORY App )

include_directories( ${HDF4_INCLUDE_DIR} )

set( TARGET_NAME convert_ozone )

set( HEADERS "" )
set( SOURCES ${TARGET_NAME}.c )

add_executable( ${TARGET_NAME} ${SOURCES} ${HEADERS} )
target_link_libraries( ${TARGET_NAME}
  PRIVATE
    ${HDF4_LIBRARIES} )

include( ModuleInstall )

#Install python files
install(
    FILES "updatetoms.py"
    DESTINATION ${INSTALL_BINDIR} )
