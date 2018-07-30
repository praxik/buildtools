#Required variables:
    #TARGET_NAME
    #TARGET_VERSION
    #TARGET_EXPORT
    #TARGET_CATEGORY - App/Lib/Test
    #TARGET_LANGUAGE - C/CXX/Fortran/...
    #PRIVATE_HEADERS - must be relative
    #PUBLIC_HEADERS - must be relative
    #PRIVATE_SOURCES - must be relative
    #INCDIR_NAME

#
if( NOT TARGET_LANGUAGE )
    set( TARGET_LANGUAGE CXX )
endif()

#
set_target_properties( ${TARGET_NAME}
    PROPERTIES PROJECT_LABEL "${TARGET_CATEGORY} ${TARGET_NAME}" )
set_target_properties( ${TARGET_NAME} PROPERTIES VERSION ${TARGET_VERSION} )
set_target_properties( ${TARGET_NAME} PROPERTIES SOVERSION ${TARGET_VERSION} )

#
if( WIN32 )
    foreach( HDR ${PRIVATE_HEADERS} )
        get_filename_component( PATH ${HDR} PATH )
        file( TO_NATIVE_PATH "${PATH}" PATH )
        source_group( "Header Files\\${PATH}" FILES ${HDR} )
    endforeach()

    foreach( SRC ${PRIVATE_SOURCES} )
        get_filename_component( PATH ${SRC} PATH )
        file( TO_NATIVE_PATH "${PATH}" PATH )
        source_group( "Source Files\\${PATH}" FILES ${SRC} )
    endforeach()

    include( InstallPDBFiles )
endif()

if( ${TARGET_CATEGORY} STREQUAL "App" OR ${TARGET_CATEGORY} STREQUAL "Test" )
    #
    install(
        TARGETS ${TARGET_NAME}
        DESTINATION ${INSTALL_BINDIR} )
elseif( ${TARGET_CATEGORY} STREQUAL "Lib" )
    #
    install(
        TARGETS ${TARGET_NAME}
        EXPORT ${TARGET_EXPORT}
        RUNTIME DESTINATION ${INSTALL_BINDIR}
        LIBRARY DESTINATION ${INSTALL_LIBDIR}
        ARCHIVE DESTINATION ${INSTALL_LIBDIR} )

    #
    if( INCDIR_NAME )
        foreach( HDR ${PUBLIC_HEADERS} )
            get_filename_component( PATH ${HDR} PATH )
            install(
                FILES ${HDR}
                DESTINATION ${INSTALL_INCDIR}/${INCDIR_NAME}/${PATH} )
        endforeach()
    endif()
endif()
