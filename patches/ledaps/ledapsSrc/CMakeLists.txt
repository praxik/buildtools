add_subdirectory( src )

#Install python files
install(
    FILES "bin/do_ledaps.py"
    DESTINATION ${INSTALL_BINDIR} )
