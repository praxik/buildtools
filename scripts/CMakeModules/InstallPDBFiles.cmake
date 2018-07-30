
#On windows provide the user with the pdb files for debugging if they are present
if( MSVC )
    #Debug symbols are only created for executable and shared library targets
    get_target_property( TARGET_TYPE ${TARGET_NAME} TYPE )
    if( ${TARGET_TYPE} STREQUAL "STATIC_LIBRARY" )
        return()
    endif()
    get_target_property( PDB ${TARGET_NAME} PDB_NAME )
    if( ${PDB} STREQUAL "PDB-NOTFOUND" )
        set( PDB ${TARGET_NAME} )
    endif()
    install(
        FILES ${CMAKE_CURRENT_BINARY_DIR}/\${CMAKE_INSTALL_CONFIG_NAME}/${PDB}.pdb
        DESTINATION ${INSTALL_BINDIR}
        CONFIGURATIONS RelWithDebInfo Debug )
endif()
