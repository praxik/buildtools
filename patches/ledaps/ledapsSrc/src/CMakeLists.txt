add_subdirectory( lndpm )
add_subdirectory( lndcal )

#Do this for building with cygwin on windows
if( WIN32 )
    set( CMAKE_Fortran_COMPILER NOTFOUND )
endif()

include( CMakeAddFortranSubdirectory )

set( TARGET_NAME lndsrf )
file(
    COPY "lndsr/CHAND.f" "lndsr/CSALBR.f"
    DESTINATION ${CMAKE_CURRENT_SOURCE_DIR}/${TARGET_NAME} )

cmake_add_fortran_subdirectory( ${TARGET_NAME}
    PROJECT ${TARGET_NAME}
    ARCHIVE_DIR ${CMAKE_CURRENT_BINARY_DIR}/${TARGET_NAME}
    RUNTIME_DIR ${CMAKE_CURRENT_BINARY_DIR}/${TARGET_NAME}
    LIBRARIES ${TARGET_NAME}
    LINK_LIBRARIES
    LINK_LIBS
    CMAKE_COMMAND_LINE
        -DCMAKE_SH=NOTFOUND #Hack for CMakeMinGWFindMake.cmake
        -DCMAKE_SYSTEM_NAME=${CMAKE_SYSTEM_NAME}
    NO_EXTERNAL_INSTALL )

if( WIN32 )
    #Override hack for CMakeAddFortranSubdirectory
    set_target_properties( ${TARGET_NAME} PROPERTIES
        IMPORTED_IMPLIB_NOCONFIG ${CMAKE_CURRENT_BINARY_DIR}/${TARGET_NAME}/${TARGET_NAME}.lib
        IMPORTED_LOCATION_NOCONFIG ${CMAKE_CURRENT_BINARY_DIR}/${TARGET_NAME}/${TARGET_NAME}.dll )

    install(
        FILES ${CMAKE_CURRENT_BINARY_DIR}/${TARGET_NAME}/${TARGET_NAME}.lib
        DESTINATION lib )

    install(
        FILES ${CMAKE_CURRENT_BINARY_DIR}/${TARGET_NAME}/${TARGET_NAME}.dll
        DESTINATION bin )
endif()

add_subdirectory( lndsr )
add_subdirectory( lndsrbm )

set( TARGET_NAME  6sV-1.0B )
cmake_add_fortran_subdirectory( ${TARGET_NAME}
    PROJECT ${TARGET_NAME}
    ARCHIVE_DIR ${CMAKE_CURRENT_BINARY_DIR}/${TARGET_NAME}
    RUNTIME_DIR ${CMAKE_CURRENT_BINARY_DIR}/${TARGET_NAME}
    LIBRARIES ${TARGET_NAME}
    LINK_LIBRARIES
    LINK_LIBS
    CMAKE_COMMAND_LINE
        -DCMAKE_SH=NOTFOUND #Hack for CMakeMinGWFindMake.cmake
        -DCMAKE_SYSTEM_NAME=${CMAKE_SYSTEM_NAME}
    NO_EXTERNAL_INSTALL )

if( WIN32 )
    #Override hack for CMakeAddFortranSubdirectory
    set_target_properties( ${TARGET_NAME} PROPERTIES
        IMPORTED_LOCATION_NOCONFIG ${CMAKE_CURRENT_BINARY_DIR}/${TARGET_NAME}/sixsV1.0B.exe )

    install(
        FILES ${CMAKE_CURRENT_BINARY_DIR}/${TARGET_NAME}/sixsV1.0B.exe
        DESTINATION bin )
endif()
