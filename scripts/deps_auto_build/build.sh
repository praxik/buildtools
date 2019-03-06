#!/bin/bash
set -ex

if [ -z "${VES_SRC_DIR}" ]; then
  export VES_SRC_DIR=$PWD/../../
fi

VES_22_PACKAGES+=("osg")
VES_22_PACKAGES+=("vtk")
VES_22_PACKAGES+=("boost.1.44.0")
VES_22_PACKAGES+=("juggler.3.0")
VES_22_PACKAGES+=("osgbullet")
VES_22_PACKAGES+=("bullet")
VES_22_PACKAGES+=("ace+tao")
VES_22_PACKAGES+=("cppdom")
VES_22_PACKAGES+=("gmtl")
VES_22_PACKAGES+=("osgworks")
VES_22_PACKAGES+=("poco")
VES_22_PACKAGES+=("xerces")

VES_30_PACKAGES+=("osg")
VES_30_PACKAGES+=("vtk")
VES_30_PACKAGES+=("boost")
VES_30_PACKAGES+=("juggler")
VES_30_PACKAGES+=("osgbullet")
VES_30_PACKAGES+=("bullet")
VES_30_PACKAGES+=("cppdom")
VES_30_PACKAGES+=("sdl")
VES_30_PACKAGES+=("osgworks")
VES_30_PACKAGES+=("poco")
VES_30_PACKAGES+=("switchwire")
VES_30_PACKAGES+=("storyteller")
VES_30_PACKAGES+=("crunchstore")
VES_30_PACKAGES+=("propertystore")
VES_30_PACKAGES+=("osgephemeris")
VES_30_PACKAGES+=("bdfx")
VES_30_PACKAGES+=("xerces")
VES_30_PACKAGES+=("latticefx")
VES_30_PACKAGES+=("gmtl")
VES_30_PACKAGES+=("minerva")

#
# Define the platform
#
function platform()
{
  PLATFORM=$( uname -s )
  #http://en.wikipedia.org/wiki/Uname
  case $PLATFORM in
    CYGWIN*)
      #Test for environment variables $TMP and $TEMP which mess with VS builds
      if [ ${TMP+x} ]; then unset TMP; fi
      if [ ${TEMP+x} ]; then unset TEMP; fi

      #Test for 64-bit capability
      OS_ARCH=$( wmic OS get OSArchitecture /value | grep -Eo '[^=]*$' | findstr /r /v "^$" | tr -d '\r' )
      if [[ "${OS_ARCH}" = "32-bit" ]] || [ "${platform_32}" = "yes" ]; then
        ARCH=32-bit
        VCVARSALL_ARG=x86
      else
        ARCH=64-bit
        VCVARSALL_ARG=amd64
      fi
      echo "Building ${ARCH} on ${OS_ARCH}"
      PLATFORM=Windows
      HOME=$USERPROFILE
      REGROOT="/proc/registry"
      REGPATH="HKEY_LOCAL_MACHINE/SOFTWARE"
      ;;
    Darwin | Linux)
      ;;
    *)
      echo "Unrecognized OS: $PLATFORM" >&2
      kill -SIGINT $$
      ;;
  esac
  export PLATFORM
  export ARCH
}

#
# Define the architecture
#
function arch()
{
  if [ $PLATFORM = "Darwin" ]; then
    ARCH=64-bit
  else
    [ -z "${ARCH}" ] && ARCH=`uname -m`
  fi

  #http://en.wikipedia.org/wiki/Uname
  case $ARCH in
    i[3-6]86 | x86 | 32-bit)
      ARCH=32-bit
      ;;
    x86_64 | x64 | 64-bit)
      ARCH=64-bit
      ;;
    *)
      echo "Unrecognized Architecture: $ARCH" >&2
      kill -SIGINT $$
      ;;
  esac
  export ARCH
}

#
# define the command used for downloading sources
#
function wget()
{
  case $PLATFORM in
    Windows|Linux)
      WGET_METHOD=$( which wget )" --no-check-certificate"
      ;;
    Darwin)
      WGET_METHOD=$( which curl )
      WGET_METHOD=${WGET_METHOD}" -O --fail -L"
      ;;
  esac
}
#
# Some Windows-only variables
#
function windows()
{
  if [ $PLATFORM != "Windows" ]; then return; fi

  if [ $OS_ARCH = "64-bit" ]; then
      REGROOT=${REGROOT}64
      REGPATH=${REGPATH}/Wow6432Node
      PROGRAM_FILES="Program Files (x86)"
  else
      REGROOT=${REGROOT}32
      PROGRAM_FILES="Program Files"
  fi

  #Find installed VS versions
  declare -a VS_VERSIONS=( "${REGROOT}"/HKEY_CLASSES_ROOT/VisualStudio.DTE.* )
  VS_VERSIONS=( "${VS_VERSIONS[@]#*DTE.*}" )
  echo "Installed Visual Studio versions: ${VS_VERSIONS[@]}"
  [ -z "${VS_VERSION}" ] && export VS_VERSION="${VS_VERSIONS[@]: -1}"

  #Set VS specific variables
  BOOST_TOOLSET="msvc-${VS_VERSION}"
  case $VS_VERSION in
    11.0)
      CMAKE_GENERATOR="Visual Studio 11"
      VS_YEAR=2012
      ;;
    12.0)
      CMAKE_GENERATOR="Visual Studio 12"
      VS_YEAR=2013
      ;;
    14.0)
      CMAKE_GENERATOR="Visual Studio 14"
      VS_YEAR=2015
      ;;
    15.0)
      BOOST_TOOLSET="msvc-14.1"
      CMAKE_GENERATOR="Visual Studio 15"
      VS_YEAR=2017
      ;;
    *)
      echo "Unrecognized VS version: $VS_VERSION" >&2
      kill -SIGINT $$
      ;;
  esac
  echo "Using Visual Studio version: ${VS_VERSION}"

  if [ $ARCH = "64-bit" ]; then
    CMAKE_GENERATOR="${CMAKE_GENERATOR} Win64"
    BOOST_ARCH=x64
  else
    BOOST_ARCH=x32
  fi

  if (( "${VS_VERSION/.*}" < 15 )); then
    #.NET version is hardcoded to 3.5 for now
    DOTNET_REGVAL="${REGROOT}/${REGPATH}/Microsoft/.NETFramework/InstallRoot"
    MSBUILD_PATH=$( awk '{ gsub( "", "" ); print }' "${DOTNET_REGVAL}" | tr -d '\000' )v3.5

    VC_REGPATH="${REGROOT}/${REGPATH}/Microsoft/VisualStudio/${VS_VERSION}/Setup/VC/ProductDir"
    VCVARSALL_PATH=$( awk '{ print }' "${VC_REGPATH}" | tr -d '\000' )
    VS_REGPATH="${REGROOT}/${REGPATH}/Microsoft/VisualStudio/${VS_VERSION}/InstallDir"
    DEVENV_PATH=$( awk '{ print }' "${VS_REGPATH}" | tr -d '\000' )
  else
    #Starting with Visual Studio 15.2
    #vswhere.exe is installed in a fixed location that will be maintained
    VsWherePath="C:\\${PROGRAM_FILES}\Microsoft Visual Studio\Installer"
    VsWhere="cmd /c \"\
      set Path=${VsWherePath};%Path%; && \
      vswhere -latest -products * -requires Microsoft.Component.MSBuild -property installationPath\""
    VsInstanceDir=$( eval "${VsWhere}" | tr -d '\r' )

    #The Developer Command prompt in Visual Studio 2017 can be used to set
    #the path to the VC++ toolset in the VCToolsInstallDir environment variable
    #VsDevCmdPath="${VsInstanceDir}\Common7\Tools"
    #VsDevCmd="cmd /c \"\
      #set Path=${VsDevCmdPath};%Path%; && \
      #vsdevcmd.bat -winsdk=10.0.16299.0\""
    #eval "${VsDevCmd}"

    MSBUILD_PATH="${VsInstanceDir}\MSBuild\\${VS_VERSION}\Bin"
    VCVARSALL_PATH="${VsInstanceDir}\VC\Auxiliary\Build"
    DEVENV_PATH="${VsInstanceDir}\Common7\IDE"
  fi
  PATH=${MSBUILD_PATH}:${VCVARSALL_PATH}:${DEVENV_PATH}:$PATH
  WIN32_MAKPATH="C:\\${PROGRAM_FILES}\Microsoft SDKs\Windows\v7.1A\Include"
  CMD="cmd /c"
  MSBUILD="MSBuild.exe"

  #Get _MSC_VER...
  TMPFILE="_msc_ver"
  if [ ! -e "${TMPFILE}.exe" ]; then
    find . -type f -name "${TMPFILE}.*" -delete
    echo "void main(){ printf( \"%d\", _MSC_VER ); }" >> "${TMPFILE}.c"
    CL=( "${CMD}" )
    CL+=( "vcvarsall.bat "${VCVARSALL_ARG}"" )
    CL+=( "\&\&" )
    CL+=( "cl.exe ${TMPFILE}.c" )
    eval "${CL[@]}" >/dev/null 2>&1
    find . -type f -name "${TMPFILE}.*" -and -not -name "${TMPFILE}.exe" -delete
  fi
  MSVC_VER="$( ./${TMPFILE}.exe )"
  echo "Using Visual C++ compiler version: ${MSVC_VER}"
}
#
# Windows devenv cmd
#
function devenv_cmd()
{
  DEVENV=( "${CMD}" )
  DEVENV+=( "set \"VSCMD_START_DIR=%CD%\"" )
  DEVENV+=( "\&\&" )
  DEVENV+=( "vcvarsall.bat "${VCVARSALL_ARG}"" )
  DEVENV+=( "\&\&" )
  DEVENV+=( "devenv.com \""${SolutionName}"\" /useenv "${DEVENV_SWITCHES[@]}"" )
  printf '%s ' "${DEVENV[@]//\\&/&}"; printf '\n\n'
  eval "${DEVENV[@]}"
}
#
# Windows make cmd
#
function make_cmd()
{
  MAKE=( "${CMD}" )
  MAKE+=( "set \"INCLUDE=%INCLUDE%;${WIN32_MAKPATH};\"" )
  MAKE+=( "\&\&" )
  MAKE+=( "set \"VSCMD_START_DIR=%CD%\"" )
  MAKE+=( "\&\&" )
  MAKE+=( "set \"Path=${mingw_INSTALL_DIR//\//\\}\bin;%Path%;\"" )
  MAKE+=( "\&\&" )
  MAKE+=( "vcvarsall.bat "${VCVARSALL_ARG}"" )
  MAKE+=( "\&\&" )
  MAKE+=( "mingw32-make "${MAKE_ARGS[@]}"" )
  printf '%s ' "${MAKE[@]//\\&/&}"; printf '\n\n'
  eval "${MAKE[@]}"
}
#
# Windows nmake cmd
#
function nmake_cmd()
{
  NMAKE=( "${CMD}" )
  NMAKE+=( "set \"INCLUDE=%INCLUDE%;${WIN32_MAKPATH};\"" )
  NMAKE+=( "\&\&" )
  NMAKE+=( "set \"VSCMD_START_DIR=%CD%\"" )
  NMAKE+=( "\&\&" )
  NMAKE+=( "vcvarsall.bat "${VCVARSALL_ARG}"" )
  NMAKE+=( "\&\&" )
  NMAKE+=( "nmake "${NMAKE_ARGS[@]}"" )
  printf '%s ' "${NMAKE[@]//\\&/&}"; printf '\n\n'
  eval "${NMAKE[@]}"
}

#
# DEV_BASE_DIR defines the base directory for all development packages.
# May be overriden with a shell variable
#
[ -z "${DEV_BASE_DIR}" ] && export DEV_BASE_DIR="${HOME}/dev/deps"

#
# Some useful global variables
#
export CTAGS_INSTALL_DIR=/opt/local
export TAGS_DIR=${HOME}/.vim/tags
export BUILD_TYPE=Release
#
# some "over-writeable" variables
#
CMAKE=cmake
CONFIGURE=./configure
SCONS=scons
MAKE=make
BJAM=./b2

function bye()
{
  [ $# -eq 0 ] && usage || echo Exiting: $1
  exit 1
}

#
# help statement for script usage
#
function usage()
{
echo "
  usage: $0 [ options ] <package> ....

  This function builds the named package.

  OPTIONS:
    -h      Show this message
    -k      Check out the source code
    -u      Update the source code
    -c      Clean the build directory
    -p      Execute prebuild script, e.g., cmake, configure, and autogen
    -b      Build
    -j      Build with multithreading enabled
            Requires argument to specify number of jobs (1:8) to use
    -U      Subversion username to use for private repo
    -d      Create an installer containing install files for package
                On linux this copies everything into DEPS_INSTALL_DIR
                On windows this should run the respective iss file
    -t      Create tag file with exuberant ctags
    -a      Specify if we want to build 32 bit on 64 bit
    -g      Install the deps for ves 2.2 or 3.0 - 22 or 30 are valid options
    -F      Install all of the valid deps that have been built
    -D      Build release with debug symbols
    -z      Compress the install directory of the specified library" >&2
}

#
# execute ctags
#
function ctags()
{
  ${CTAGS_INSTALL_DIR}/bin/ctags -RI --c++-kinds=+p --fields=+iaS --extra=+q --languages=c++ .
  [ -d "${TAGS_DIR}" ] || mkdir -p "${TAGS_DIR}"
  rm ${TAGS_DIR}/${1}
  mv tags ${TAGS_DIR}/${1}
}

#
# unset all of the vars for building
#
function unsetvars()
{
  SKIP_FPC_INSTALL="yes"
  SKIP_PREBUILD="no"
  unset ISS_FILENAME
  unset CMAKE_PARAMS
  if [ ! -z "${CMAKE_GENERATOR}" ]; then CMAKE_PARAMS+=( -G "${CMAKE_GENERATOR}" ); fi
  if [ $PLATFORM = "Windows" ]; then CMAKE_PARAMS+=( -DCMAKE_MAKE_PROGRAM=devenv.com ); fi
  unset CONFIGURE_PARAMS
  unset MSVC_PROJECT
  unset MSVC_SOLUTION
  unset DEVENV_SWITCHES
  unset MAKE_ARGS
  unset MAKE_INST_ARG
  unset NMAKE_ARGS
  unset NMAKE_INST_ARG
  unset SCONS_PARAMS
  unset BJAM_PARAMS
  unset INNO_PARAMS
  unset POST_RETRIEVAL_METHOD
  unset POST_BUILD_METHOD
  unset SOURCE_REVISION
  unset GIT_BRANCH_VERSION
  unset GIT_HASH
  unset SZIP_OUTPUT_DIR
  unset PREBUILD_METHOD
  unset FPC_FILE
  unset VES_INSTALL_PARAMS
  unset CUSTOM_PREBUILD
  unset CUSTOM_BUILD
  unset BUILD_METHOD
  unset PROJ_STR
  unset BUILD_TARGET
  unset BUILD_DIR
  unset CFLAGS
  unset CXXFLAGS
  unset LDFLAGS
  unset CL
  unset LINK
  unset EXDIR
}

#
# set the list of build files to consider
#
function buildfiles()
{
  declare -gA BUILD_FILES
  for file in *.build; do
    key=$( basename "${file}" )
    BUILD_FILES[ "${key}" ]+="${file}"
  done

  [ $PLATFORM = "Windows" ] && BUILD_FILES_PATH=$( cygpath -u "${BUILD_FILES_PATH}" )
  if [ -d "${BUILD_FILES_PATH}" ]; then
    for file in "${BUILD_FILES_PATH}"/*.build; do
      key=$( basename "${file}" )
      BUILD_FILES[ "${key}" ]+="${file}"
    done
  fi
}

#
# search all build files
#
function findvaliddeps()
{
    echo "Preparing to install valid dependencies."
    validatedeps "${BUILD_FILES[@]}"
    echo "Done installing valid dependencies."
}

#
# install all of the valid deps
#
function validatedeps()
{
    if [ ! -d "${DEPS_INSTALL_DIR}" ]; then mkdir -p "${DEPS_INSTALL_DIR}"; fi

    for f in $*; do
      . "$f"
      if [ -d "${INSTALL_DIR}" ]; then
        case $PLATFORM in
          Windows )
            if [ -z "${ISS_FILENAME}" ]; then echo "ISS_FILENAME undefined in package $package"; return; fi
            innosetup
            ;;
          Darwin | Linux )
            echo "Installing ${INSTALL_DIR}/. to ${DEPS_INSTALL_DIR}"
            cp -R "${INSTALL_DIR}"/. "${DEPS_INSTALL_DIR}"
            ;;
        esac
      fi
    done
}

#
# setup the function for controlling innosetup
#
function innosetup()
{
  #http://www.jrsoftware.org/ishelp/
  #/F"MyProgram-1.0"  - The output filename for the installer
  #/Sbyparam=$p - The sign tool for the installer
  #/Q - The Quiet mode of the compiler
  #/O"My Output" - Override the output directory
  echo "Building the ${VES_SRC_DIR}/dist/win/iss/${ISS_FILENAME} installer."
  INNO_PARAMS+=( "/dvesAutoBuild=1" )
  INNO_PARAMS+=( "/dINSTALLERINSTALLLOCATION=${DEV_BASE_DIR}" )
  if [  $ARCH = "64-bit" ]; then
    INNO_PARAMS+=( "/dMSVCVERSION=msvc-9.0-sp1-x64" )
    INNO_PARAMS+=( "/dLIBDIR=lib64" )
    INNO_PARAMS+=( "/dBUILDDIR=x64" )
    INNO_PARAMS+=( "/dDISTDIR=Win64" )
  else
    INNO_PARAMS+=( "/dMSVCVERSION=msvc-9.0-sp1-x86" )
    INNO_PARAMS+=( "/dLIBDIR=lib" )
    INNO_PARAMS+=( "/dBUILDDIR=x86" )
    INNO_PARAMS+=( "/dDISTDIR=Win32" )
  fi
  INNO_PARAMS+=( "/dVESGROUPNAME=VE-Suite" )
  INNO_PARAMS+=( "/dVEDEVHOME=${VES_SRC_DIR}" )

  if [  $OS_ARCH = "64-bit" ]; then
    /cygdrive/c/Program\ Files\ \(x86\)/Inno\ Setup\ 5/iscc /Q  "${INNO_PARAMS[@]}" /i${VES_SRC_DIR}/dist/win/iss ${VES_SRC_DIR}/dist/win/iss/${ISS_FILENAME}
  else
    /cygdrive/c/Program\ Files/Inno\ Setup\ 5/iscc /Q /i${VES_SRC_DIR}/dist/win/iss ${VES_SRC_DIR}/dist/win/iss/${ISS_FILENAME}
  fi
}

function source_retrieval()
{
  case ${SOURCE_RETRIEVAL_METHOD} in
    svn)
      cd "${DEV_BASE_DIR}"
      SVN_CO="svn co"

      if [ -n "${SOURCE_REVISION:+x}" ]; then
        SVN_CO="${SVN_CO} -r ${SOURCE_REVISION}"
        echo "using custom command ${SVN_CO}"
      fi

      if [ $PLATFORM = "Windows" ]; then
        TEMP_BASE_DIR=`cygpath -u "${BASE_DIR}"`
        ${SVN_CO} ${SOURCE_URL} "${TEMP_BASE_DIR}"
      else
        ${SVN_CO} ${SOURCE_URL} "${BASE_DIR}"
      fi
      ;;
    hg)
      cd "${DEV_BASE_DIR}"
      hg clone ${SOURCE_URL} "${BASE_DIR}"
      ;;
    git)
      cd "${DEV_BASE_DIR}"
      if [ $PLATFORM = "Windows" ]; then
        #Replace "/" with "\" on Windows; this prevents the "C" directory from being created
        git clone ${SOURCE_URL} "${BASE_DIR//\//\\}"
      else
        git clone ${SOURCE_URL} "${BASE_DIR}"
      fi
      if [ -n "${GIT_BRANCH_VERSION:+x}" ]; then
        cd "${BASE_DIR}"
        git checkout -t origin/${GIT_BRANCH_VERSION}
        git pull
        echo "using custom command ${GIT_BRANCH_VERSION}"
      fi
      if [ -n "${GIT_HASH:+x}" ]; then
        cd "${BASE_DIR}"
        git checkout ${GIT_HASH}
        echo "using hash ${GIT_HASH}"
      fi
      ;;
    private-svn)
      cd "${DEV_BASE_DIR}"
      SVN_CO="svn co"
      if [ -n "${SOURCE_REVISION:+x}" ]; then
        SVN_CO="${SVN_CO} -r ${SOURCE_REVISION}"
      fi
      ${SVN_CO} ${SOURCE_URL} "${BASE_DIR}" --username="${SVN_USERNAME}"
      ;;
    wget)
      [ -z "${SOURCE_FORMAT}" ] && ( echo "SOURCE_FORMAT undefined in package $package"; return; )
      cd "${DEV_BASE_DIR}"
      if [ -d "${BASE_DIR}" ]; then
        echo "We have already downloaded $package for ${BASE_DIR}"
        return
      fi
      # Settings (proxy etc.) for wget can be edited using /etc/wgetrc
      echo "${WGET_METHOD}"
      eval "${WGET_METHOD}" "${SOURCE_URL}" || exit
      case ${SOURCE_FORMAT} in
        zip)
          if [ -n "${EXDIR:+x}" ]; then
            unzip `basename ${SOURCE_URL}` -d "${BASE_DIR}"
          else
            unzip `basename ${SOURCE_URL}`
          fi
          rm -f `basename ${SOURCE_URL}`
          #if [ -d "${BASE_DIR}" ]; then
          #  echo "The BASE_DIR for $package already exists."
          #else
          #  mkdir -p "${BASE_DIR}"
          #fi
          ;;
        tgz)
          TEMPBASENAME=`basename ${SOURCE_URL}`
          PACKAGE_BASE_DIR_NAME=$( tar tf "${TEMPBASENAME}" | grep -o '^[^/]\+' | sort -u )
          tar xvf "${TEMPBASENAME}"
          rm -f `basename ${SOURCE_URL}`
          if [ -d "${BASE_DIR}" ]; then
            echo "The BASE_DIR for $package already exists."
          else
            mv "${PACKAGE_BASE_DIR_NAME}" "${BASE_DIR}"
          fi
          ;;
        bz2)
          TEMPBASENAME=`basename ${SOURCE_URL}`
          PACKAGE_BASE_DIR_NAME=$( tar tf "${TEMPBASENAME}" | grep -o '^[^/]\+' | sort -u )
          tar xvfjk "${TEMPBASENAME}"
          rm -f "${TEMPBASENAME}"
          if [ -d "${BASE_DIR}" ]; then
            echo "The BASE_DIR for $package already exists."
          else
            mv "${PACKAGE_BASE_DIR_NAME}" "${BASE_DIR}"
          fi
          ;;
        7z)
          SZIP_CMD="7z x $( basename ${SOURCE_URL} )"
          if [ -n "${SZIP_OUTPUT_DIR:+x}" ]; then
            SZIP_CMD="${SZIP_CMD} -o${SZIP_OUTPUT_DIR}"
          fi
          ${SZIP_CMD}
          rm -f $( basename ${SOURCE_URL} )
          ;;
        xz)
          xz -cd `basename ${SOURCE_URL}` | tar -xvf -
          rm -f `basename ${SOURCE_URL}`
          ;;
        bin)
          TEMPBASENAME=`basename ${SOURCE_URL}`
          sh "${TEMPBASENAME}"
          rm -f "${TEMPBASENAME}"
          #if [ -d "${BASE_DIR}" ]; then
          #  echo "The BASE_DIR for $package already exists."
          #else
          #  mv "${PACKAGE_BASE_DIR_NAME}" "${BASE_DIR}"
          #fi
          ;;
        *)
          echo "Source format ${SOURCE_FORMAT} not supported"
          ;;
      esac
      ;;
    *)
      echo "Source retrieval method ${SOURCE_RETRIEVAL_METHOD} not supported"
      ;;
  esac
}

function e()
{
  package=$1
  script="${BUILD_FILES[ "${package}" ]}"

  #is this option really a package
  if [ ! -e "$script" ]; then
    echo "$package is not a package."
    return
  fi

  #
  #reset the vars for the builds
  #
  unsetvars

  #
  # setup the build types unless other wise specified in a build file
  #
  case $PLATFORM in
    Windows)
      BUILD_METHOD=cmake
      BUILD_TARGET=INSTALL
      ;;
    Darwin | Linux )
      BUILD_METHOD=make
      BUILD_TARGET=install
      ;;
  esac

  #setup the package specific vars
  . $script

  #
  # check to make sure that the base dir is defined for the package
  #
  if [ -z "${BASE_DIR}" ]; then echo "BASE_DIR undefined in package $package"; return; fi

  #
  # checkout the source for download the source
  #
  if [ "${check_out_source}" = "yes" ]; then
    if [ -z "${SOURCE_URL}" ]; then echo "SOURCE_URL undefined in package $package"; return; fi
    if [ -z "${SOURCE_RETRIEVAL_METHOD}" ]; then echo "SOURCE_RETRIEVAL_METHOD undefined in package $package"; return; fi
    source_retrieval
    if [ ! -z "${POST_RETRIEVAL_METHOD}" ]; then
        echo "Running the POST_RETRIEVAL_METHOD for $package."
        cd "${SOURCE_DIR}"
        for cmd in "${POST_RETRIEVAL_METHOD[@]}"; do eval "${cmd}"; done
    fi
  fi

  #
  # update the source if needed
  #
  if [ "${update_source}" = "yes" ]; then
    if [ -z "${SOURCE_RETRIEVAL_METHOD}" ]; then echo "SOURCE_RETRIEVAL_METHOD undefined in package $package"; return; fi

    case ${SOURCE_RETRIEVAL_METHOD} in
      svn | private-svn)
        if [ -d "${BASE_DIR}" ]; then
            # If we have defined svn version there is no need to update the code
            if [ ! -n "${SOURCE_REVISION:+x}" ]; then
                cd "${BASE_DIR}"
                svn up
            fi

        # Assume that if the base directory does not exist, it has not been checked out
        # test and perform a checkout
        else
          echo "${BASE_DIR} non-existent, checking out ...."
          [ -z "${SOURCE_URL}" ] && ( echo "SOURCE_URL undefined in package $package"; return; )
          [ -z "${SOURCE_RETRIEVAL_METHOD}" ] && ( echo "SOURCE_RETRIEVAL_METHOD undefined in package $package"; return; )

          source_retrieval
        fi
        ;;
      hg)
        if [ -d "${BASE_DIR}" ]; then
          cd "${BASE_DIR}"
          hg pull
          hg update
        else
          echo "${BASE_DIR} non-existent, checking out ...."
          [ -z "${SOURCE_URL}" ] && ( echo "SOURCE_URL undefined in package $package"; return; )
          [ -z "${SOURCE_RETRIEVAL_METHOD}" ] && ( echo "SOURCE_RETRIEVAL_METHOD undefined in package $package"; return; )

          source_retrieval
        fi
        ;;
      git)
        if [ -d "${BASE_DIR}" ]; then
          cd "${BASE_DIR}"
          git pull
        else
          echo "${BASE_DIR} non-existent, checking out ...."
          [ -z "${SOURCE_URL}" ] && ( echo "SOURCE_URL undefined in package $package"; return; )
          [ -z "${SOURCE_RETRIEVAL_METHOD}" ] && ( echo "SOURCE_RETRIEVAL_METHOD undefined in package $package"; return; )

          source_retrieval
        fi
        ;;
      *)
        echo "Source update method ${SOURCE_RETRIEVAL_METHOD} not supported"
        ;;
    esac
  fi

  #
  # prebuild for the package
  #
  if [ "${prebuild}" = "yes" ] && [ "${SKIP_PREBUILD}" != "yes" ]; then
    if [ -z "${BUILD_DIR}" ]; then echo "BUILD_DIR undefined in package $package"; return; fi
    if [ -z "${PREBUILD_METHOD}" ]; then echo "PREBUILD_METHOD undefined in package $package"; return; fi
    if [ -z "${SOURCE_DIR}" ]; then echo "SOURCE_DIR undefined in package $package"; return; fi
    if [ ! -d "${SOURCE_DIR}" ]; then echo "SOURCE_DIR does not exist for package $package"; return; fi
    if [ ! -d "${BUILD_DIR}" ]; then mkdir -p "${BUILD_DIR}"; fi

    for method in "${PREBUILD_METHOD[@]}"; do case ${method} in
      bjam)
        cd "${SOURCE_DIR}"
        "${BJAM_PREBUILD}"
        ;;
      cmake)
        cd "${BUILD_DIR}"
        echo $BUILD_DIR
        which cmake
        ${CMAKE} "${SOURCE_DIR}" "${CMAKE_PARAMS[@]}"
        echo ${CMAKE_PARAMS[@]}
        echo "done prebuild"
        ;;
      configure)
        cd "${BUILD_DIR}"
        ${CONFIGURE} "${CONFIGURE_PARAMS[@]}"
        ;;
      custom)
        cd "${SOURCE_DIR}"
        for cmd in "${CUSTOM_PREBUILD[@]}"; do eval "${cmd}"; done
        echo "Ran custom prebuild step."
        ;;
      devenv)
        cd "${SOURCE_DIR}"
        for SolutionName in "${MSVC_SOLUTION[@]}"; do
          DEVENV_SWITCHES=( "/upgrade" )
          devenv_cmd
        done
        ;;
      *)
        echo "Pre-Build method ${PREBUILD_METHOD} unsupported"
        ;;
    esac done
  fi

  #build the package
  if [ "${build}" = "yes" ]; then
    if [ -z "${BUILD_DIR}" ]; then echo "BUILD_DIR undefined in package $package"; return; fi
    if [ -z "${BUILD_METHOD}" ]; then echo "BUILD_METHOD undefined in package $package"; return; fi
    if [ -z "${SOURCE_DIR}" ]; then echo "SOURCE_DIR undefined in package $package"; return; fi
    if [ ! -d "${SOURCE_DIR}" ]; then echo "SOURCE_DIR does not exist for package $package"; return; fi
    if [ ! -d "${BUILD_DIR}" ]; then mkdir -p "${BUILD_DIR}"; fi
    [ -z "$multithreading_jobs" ] || JCMD="-j $multithreading_jobs" || MCMD='/p:MultiProcessorCompilation=true /m:"$multithreading_jobs" /p:BuildInParallel=false'
    case ${BUILD_METHOD} in
      devenv)
        cd "${SOURCE_DIR}"
        for SolutionName in "${MSVC_SOLUTION[@]}"; do
          DEVENV_SWITCHES=( "/build \"${MSVC_CONFIG}^|${MSVC_PLATFORM}\"" )
          if [ -n "${MSVC_PROJECT:+x}" ]; then
            for ProjectName in "${MSVC_PROJECT[@]}"; do
              DEVENV_SWITCHES+=( "/project ${ProjectName}" )
              devenv_cmd
              unset 'DEVENV_SWITCHES[${#DEVENV_SWITCHES[@]}-1]'
            done
          else
            devenv_cmd
          fi
        done
        ;;
      msbuild)
        cd "${BUILD_DIR}"

        if [ -d "${BUILD_TARGET}" ]; then
          MSVC_PROJECT+=( "${BUILD_TARGET}" )
        fi

        for name in "${MSVC_PROJECT[@]}"; do
          PROJ_STR="$PROJ_STR$name$( [ "$name" != "${MSVC_PROJECT[@]: -1}" ] && echo ';' )"
        done

        if [ -z "${PROJ_STR}" ]; then
          "${MSBUILD}" "$MSVC_SOLUTION" "${MCMD}" \
          /p:Configuration="$MSVC_CONFIG" /p:Platform="$MSVC_PLATFORM" /p:TargetFrameworkVersion=v3.5 \
          /p:BuildProjectReferences=false /p:PostBuildEventUseInBuild=true /p:WarningLevel=1 \
          /toolsversion:3.5 /verbosity:Diagnostic
        else
          "${MSBUILD}" "$MSVC_SOLUTION" /t:"$PROJ_STR" "${MCMD}" \
          /p:Configuration="$MSVC_CONFIG" /p:Platform="$MSVC_PLATFORM" /p:TargetFrameworkVersion=v3.5 \
          /p:BuildProjectReferences=false /p:PostBuildEventUseInBuild=true /p:WarningLevel=1 \
          /toolsversion:3.5 /verbosity:Diagnostic
        fi
        ;;
      cmake)
        cd "${BUILD_DIR}"
        echo $BUILD_DIR
        case $PLATFORM in
          Windows)
            if [ ! -z "${BUILD_TARGET}" ]; then
              MSVC_PROJECT+=( "${BUILD_TARGET}" )
            fi

            unset PROJ_STR
            for name in "${MSVC_PROJECT[@]}"; do
              PROJ_STR="$PROJ_STR$name$( [ "$name" != "${MSVC_PROJECT[@]: -1}" ] && echo ';' )"
            done
            #http://www.cmake.org/cmake/help/cmake-2-8-docs.html#opt:--builddir
            echo "Build Command: --build ${BUILD_DIR} -- $MSVC_SOLUTION /build $MSVC_CONFIG|$MSVC_PLATFORM /project $PROJ_STR"
            ${CMAKE} --build "${BUILD_DIR}" -- "$MSVC_SOLUTION" /build "$MSVC_CONFIG"'|'"$MSVC_PLATFORM" /project "$PROJ_STR"
            ;;
          Darwin | Linux )
            #http://www.cmake.org/cmake/help/cmake-2-8-docs.html#opt:--builddir
            ${CMAKE} --build "${BUILD_DIR}" -- ${JCMD} ${BUILD_TARGET}
            ;;
        esac
        ;;
      make)
        cd "${BUILD_DIR}"
        case $PLATFORM in
          Windows)
            make_cmd
            if [ -n "${MAKE_INST_ARG:+x}" ]; then
              MAKE_ARGS+=( "${MAKE_INST_ARG}" )
              make_cmd
            fi
            ;;
          Darwin | Linux )
            eval "${MAKE} ${JCMD} ${BUILD_TARGET}"
            ;;
        esac
        ;;
      nmake)
        cd "${BUILD_DIR}"
        nmake_cmd
        if [ -n "${NMAKE_INST_ARG:+x}" ]; then
          NMAKE_ARGS+=( "${NMAKE_INST_ARG}" )
          nmake_cmd
        fi
        ;;
      scons)
        cd "${BUILD_DIR}"
        ${SCONS} "${SCONS_PARAMS[@]}" ${BUILD_TARGET} ${JCMD}
        ;;
      bjam)
        cd "${SOURCE_DIR}"
        echo "Build Comand: ${BJAM_PARAMS[@]} ${BUILD_TARGET} ${JCMD}"
        ${BJAM} "${BJAM_PARAMS[@]}" ${BUILD_TARGET} ${JCMD}
        ;;
      custom)
        cd "${SOURCE_DIR}"
        for cmd in "${CUSTOM_BUILD[@]}"; do eval "${cmd}"; done
        echo "Ran custom build step."
        ;;
      *)
        echo "Build method ${BUILD_METHOD} unsupported"
        ;;
    esac
    if [ "${SKIP_FPC_INSTALL}" != "yes" ]; then
      if [ ! -d "${INSTALL_DIR}/lib/flagpoll" ]; then mkdir -p "${INSTALL_DIR}/lib/flagpoll"; fi
      case $PLATFORM in
        Windows)
          cp "${VES_SRC_DIR}/dist/win/fpc_deps_files/release/${FPC_FILE}.in" "${INSTALL_DIR}/lib/flagpoll/${FPC_FILE}"
          echo "Installing ${VES_SRC_DIR}/dist/win/fpc_deps_files/release/${FPC_FILE}.in to ${INSTALL_DIR}/lib/flagpoll/${FPC_FILE}"
          ;;
        Darwin | Linux)
          cp "${VES_SRC_DIR}/dist/linux/fpc_deps_files/${FPC_FILE}.in" "${INSTALL_DIR}/lib/flagpoll/${FPC_FILE}"
          echo "Installing ${VES_SRC_DIR}/dist/linux/fpc_deps_files/${FPC_FILE}.in to ${INSTALL_DIR}/lib/flagpoll/${FPC_FILE}"
          ;;
      esac
      echo "Installing the fpc file ${FPC_FILE}"
    fi
    if [ ! -z "${POST_BUILD_METHOD}" ]; then
      echo "Running the POST_BUILD_METHOD for $package."
      cd "${BUILD_DIR}"
      for cmd in "${POST_BUILD_METHOD[@]}"; do eval "${cmd}"; done
    fi
  fi

  #
  # clean the build
  #
  if [ "${clean_build_dir}" = "yes" ]; then
    if [ -z "${BUILD_DIR}" ]; then echo "BUILD_DIR undefined in package $package"; return; fi
    if [ ! -d "${BUILD_DIR}" ]; then echo "${BUILD_DIR} non existent."; return; fi

    case ${BUILD_METHOD} in
      bjam)
        cd "${SOURCE_DIR}"
        ${BJAM} "${BJAM_PARAMS[@]}" --reconfigure --clean-all
        ;;
      msbuild)
        cd "${BUILD_DIR}"

        for name in "${MSVC_PROJECT[@]}"; do
          PROJ_STR="$PROJ_STR${name}:Clean$( [ "$name" != "${MSVC_PROJECT[@]: -1}" ] && echo ';' )"
        done

        "${MSBUILD}" "$MSVC_SOLUTION" /t:"$PROJ_STR" "${MCMD}" \
         /p:Configuration="$MSVC_CONFIG" /p:Platform="$MSVC_PLATFORM" \
         /verbosity:Normal /p:WarningLevel=0
        ;;
      make)
        cd "${BUILD_DIR}"
        case $PLATFORM in
          Windows)
            MAKE_ARGS+=( "clean" )
            make_cmd
            ;;
          Darwin | Linux )
            eval "${MAKE} clean"
            ;;
        esac
        ;;
      cmake)
        cd "${BUILD_DIR}"
        echo $BUILD_DIR
        case $PLATFORM in
          Windows)
            echo "I am not sure how to clean a cmake build on windows"
            ;;
          Darwin | Linux )
            #http://www.cmake.org/cmake/help/cmake-2-8-docs.html#opt:--builddir
            ${CMAKE} --build "${BUILD_DIR}" -- clean
            ;;
        esac
        ;;
      nmake)
        cd "${BUILD_DIR}"
        NMAKE_ARGS+=( "clean" )
        nmake_cmd
        ;;
      *)
        echo "Clean method ${BUILD_METHOD} unsupported"
        ;;
    esac
  fi

  #Build the ctag files
  if [ "${build_ctag_files}" = "yes" ]; then
    cd ${INSTALL_DIR}/include
    ctags $package
  fi

  #
  # Build the installer file
  #
  if [ "${build_installer}" = "yes" ]; then
    #if [ -z "${BUILD_DIR}" ]; then echo "BUILD_DIR undefined in package $package"; return; fi
    #if [ ! -d "${BUILD_DIR}" ]; then echo "${BUILD_DIR} non existent."; return; fi
    if [ -z "${INSTALL_DIR}" ]; then echo "INSTALL_DIR undefined in package $package"; return; fi
    if [ ! -d "${INSTALL_DIR}" ]; then echo "${INSTALL_DIR} non existent."; return; fi
    if [ ! -d "${DEPS_INSTALL_DIR}" ]; then mkdir -p "${DEPS_INSTALL_DIR}"; fi

    cd "${DEV_BASE_DIR}"
    REL_INSTALL_DIR="${INSTALL_DIR#$DEV_BASE_DIR/}"
    REL_BASE_DIR="${BASE_DIR#$DEV_BASE_DIR/}"

    case $PLATFORM in
      Windows )
        #if [ -z "${ISS_FILENAME}" ]; then echo "ISS_FILENAME undefined in package $package"; return; fi
        #innosetup
        zip -r "${REL_BASE_DIR}".zip "${REL_INSTALL_DIR}"
        ;;
      Darwin | Linux )
        #cd "${INSTALL_DIR}"
        #cp -R "${INSTALL_DIR}"/. "${DEPS_INSTALL_DIR}"
        #cd "${PRESENT_DIR}"
        #echo "${REL_INSTALL_DIR}"
        tar -jcvf "${REL_BASE_DIR}".tar.bz2 "${REL_INSTALL_DIR}"
        ;;
    esac
  fi

  #
  # Build the installer file
  #
  if [ "${build_auto_installer}" = "yes" ]; then
    #if [ -z "${BUILD_DIR}" ]; then echo "BUILD_DIR undefined in package $package"; return; fi
    #if [ ! -d "${BUILD_DIR}" ]; then echo "${BUILD_DIR} non existent."; return; fi
    if [ -z "${INSTALL_DIR}" ]; then echo "INSTALL_DIR undefined in package $package"; return; fi
    if [ ! -d "${INSTALL_DIR}" ]; then echo "${INSTALL_DIR} non existent."; return; fi
    if [ ! -d "${DEPS_INSTALL_DIR}" ]; then mkdir -p "${DEPS_INSTALL_DIR}"; fi

    case $PLATFORM in
      Windows )
        if [ -z "${ISS_FILENAME}" ]; then echo "ISS_FILENAME undefined in package $package"; return; fi
        innosetup
        ;;
      Darwin | Linux )
          for p in "${VES_PACKAGES[@]}"; do
              unsetvars
              cd "${PRESENT_DIR}"
              . "${p}".build
              if [ ! -z "${VES_INSTALL_PARAMS}" ]; then
                  echo "Installing ${INSTALL_DIR}/. to ${DEPS_INSTALL_DIR}"
                  cd "${INSTALL_DIR}"
                  rsync -a -R "${VES_INSTALL_PARAMS[@]}" "${DEPS_INSTALL_DIR}"/.
              fi
              cd "${PRESENT_DIR}"
          done
        ;;
    esac
  fi
}

#
# execute the script
#
while getopts "hkucpbj:U:tdg:aFDz" opts
do
case $opts in
  h)
    usage
    kill -SIGINT $$
    ;;
  k) export check_out_source="yes" ;;
  u) export update_source="yes" ;;
  c) export clean_build_dir="yes";;
  p) export prebuild="yes";;
  b) export build="yes";;
  j)
    if [[ $OPTARG =~ [^1-8] ]] ; then
      echo "Error: '$OPTARG' not a valid number." >&2
      usage
      kill -SIGINT $$
    fi
    export multithreading_jobs=$OPTARG
    #export build="yes"  # implied
    ;;
  U)export SVN_USERNAME=$OPTARG;;
  t)export build_ctag_files="yes";;
  d)export build_installer="yes";;
  g)
    export build_auto_installer="yes"
    if [[ "$OPTARG" -eq 30 ]] ; then
        export VES_PACKAGES=( "${VES_30_PACKAGES[@]}" )
    else
        export VES_PACKAGES=( "${VES_22_PACKAGES[@]}" )
    fi
    ;;
  a)
    export platform_32="yes"
    ;;
  F)# install all of the valid deps
    export install_valid_deps="yes"
    ;;
  D)
    export BUILD_TYPE=RelWithDebInfo
    ;;
  z)
    export build_installer="yes"
    ;;
  ?)
    echo "Invalid option: $OPTARG" >&2
    usage
    kill -SIGINT $$
    ;;
  :)
    echo "Option $OPTARG requires an argument." >&2
    usage
    kill -SIGINT $$
    ;;
  *) usage;;
esac
done
shift $(($OPTIND - 1))

platform
arch
windows
wget
buildfiles

[ -z "${DEPS_INSTALL_DIR}" ] && export DEPS_INSTALL_DIR="${HOME}/dev/deps/install-${PLATFORM}"
if [ "${install_valid_deps}" = "yes" ] ; then
  findvaliddeps
fi

[ -d "${DEV_BASE_DIR}" ] || mkdir -p "${DEV_BASE_DIR}"
#[ $# -lt 1 ] && [ "${build_installer}" = "no" ] && bye
[ $# -lt 1 ] && [ ! "${build_auto_installer}" = "yes" ] && bye

echo -e "\n          Kernel: $PLATFORM $ARCH"
echo -e "    DEV_BASE_DIR: ${DEV_BASE_DIR}"
echo -e "     VES_SRC_DIR: ${VES_SRC_DIR}\n"

#Set the pwd so that for every new build file we can reset to the pwd
#arg=$0; [[ -L $0 ]] && arg=$( stat -f '%Y' "$0" )
#PRESENT_DIR=$( 2>/dev/null cd "${arg%/*}" >&2; echo "`pwd -P`/${arg##*/}" )
#PRESENT_DIR=$( dirname "$PRESENT_DIR" )
PRESENT_DIR=$PWD

#
# Export the install directories for build dependencies and write to file
# Do not put spaces in ${PACKAGE_NAME}
#
export_config_vars()
{
    EXPORT_FILE="${DEV_BASE_DIR}/exports"
    rm -f "${EXPORT_FILE}"
    for f in $*; do
      #eval $( sed -n '/^\s*PACKAGE_NAME\s*=/p;/^\s*BASE_DIR\s*=/p;/^\s*INSTALL_DIR\s*=/p;' $f )
      unsetvars
      . "${f}"
      echo "export ${PACKAGE_NAME}_INSTALL_DIR=\"${INSTALL_DIR}\"" >> "${EXPORT_FILE}"
    done

    . "${EXPORT_FILE}"
}

if [ "${build_auto_installer}" = "yes" ] ; then
  # just pass in an arbitrary package to make e() happy
  e osg.build
else
  export_config_vars "${BUILD_FILES[@]}"

  test "${PLATFORM}" == "Linux" && PATH=${java_INSTALL_DIR}/bin:${swig_INSTALL_DIR}/bin:${PATH}
  for p in $@; do
    cd "${PRESENT_DIR}"
    e "${p}"
    cd "${PRESENT_DIR}"
  done
fi

exit 0
