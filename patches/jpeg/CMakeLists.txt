if( WIN32 )
    cmake_minimum_required( VERSION 3.0.0 )
else()
    cmake_minimum_required( VERSION 2.8.8 )
endif()

project( jpeg )

set( INSTALL_LIBDIR lib )
set( INSTALL_BINDIR bin )
set( INSTALL_INCDIR include )

#Set a default build type if none was specified
if( NOT WIN32 AND NOT CMAKE_BUILD_TYPE )
    set( CMAKE_BUILD_TYPE RelWithDebInfo CACHE STRING "Set build type" FORCE )
endif()

#find headers/sources
file( STRINGS ${CMAKE_CURRENT_SOURCE_DIR}/makejvcx.v15
    HEADER_LINES REGEX "ClInclude Include=" )
foreach( h ${HEADER_LINES} )
    string( REGEX REPLACE "^.+ClInclude Include=\"(.+)\".+$" "\\1" h ${h} )
    list( APPEND HEADERS ${h} )
endforeach()
file( STRINGS ${CMAKE_CURRENT_SOURCE_DIR}/makejvcx.v15
    SOURCE_LINES REGEX "ClCompile Include=" )
foreach( s ${SOURCE_LINES} )
    string( REGEX REPLACE "^.+ClCompile Include=\"(.+)\".+$" "\\1" s ${s} )
    list( APPEND SOURCES ${s} )
endforeach()

#libjpeg
set( TARGET_NAME jpeg )
add_library( ${TARGET_NAME} STATIC ${SOURCES} ${HEADERS} )

#Install binaries
install(
    TARGETS ${TARGET_NAME}
    RUNTIME DESTINATION ${INSTALL_BINDIR}
    LIBRARY DESTINATION ${INSTALL_LIBDIR}
    ARCHIVE DESTINATION ${INSTALL_LIBDIR} )

#Install headers
install(
    FILES ${HEADERS}
    DESTINATION ${INSTALL_INCDIR} )
