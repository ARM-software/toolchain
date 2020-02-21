#!/bin/bash

set -e

BUILD_SCRIPT=build.sh

usage () {
echo "main-build.sh [--target= --revision= --compiler= --host=]"
echo "--target="
echo "  arm-none-eabi-gcc : GNU AArch32 Bare-metal toolchain"
echo ""
echo "--revision="
echo "  A git revision hash of a subproject"
echo "  A git tag"
echo ""
echo "--compiler="
echo "  gcc"
echo ""
echo "--host="
echo "  linux"
echo "  mingw"
echo "  darwin"
}

options_to_subproj=
compiler=gcc
target=arm-none-eabi
for ac_arg; do
    case $ac_arg in
        --compiler=*)
        compiler=$(echo $ac_arg | sed -e "s/--compiler=//g" -e "s/,/ /g")
        ;;
        --target=*)
        target=$(echo $ac_arg | sed -e "s/--target=//g" -e "s/,/ /g")
        ;;
        --revision=*)
        revision=$(echo $ac_arg | sed -e "s/--revision=//g" -e "s/,/ /g")
        ;;
        --host=*)
        hosts=$(echo $ac_arg | sed -e "s/--host=//g" -e "s/,/ /g" | sed 'y/LINUXDARWINMINGW/linuxdarwinmingw/')
        ;;
        *)
        options_to_subproj="$options_to_subproj $ac_arg"
        ;;
    esac
done

uname_string=`uname | sed 'y/LINUXDARWIN/linuxdarwin/'`

# Set default hosts
if [ "x$hosts" = "x" ]; then
    case $uname_string in
        linux)
            hosts="linux mingw"
            ;;
        darwin)
            hosts="darwin"
            ;;
        *)
            echo Error: Unknown host architecture $uname_string >&2
            exit 1
            ;;
    esac
fi

mingw_build=no
for host in $hosts; do
    case $host in
        mingw)
            mingw_build=yes
            if [ "x$uname_string" != "xlinux" ]; then
                echo Error: Cannot build $host from $uname_string >&2
                exit 1
            fi
            ;;
        linux)
            if [ "x$uname_string" != "xlinux" ]; then
                echo Error: Cannot build $host from $uname_string >&2
                exit 1
            fi
            ;;
        darwin)
            if [ "x$uname_string" != "xdarwin" ]; then
                echo Error: Cannot build $host from $uname_string >&2
                exit 1
            fi
            ;;
        -h|*)
            usage
            exit 1
            ;;
    esac
done

if [ "x$mingw_build" != "xyes" ]; then
options_to_subproj="$options_to_subproj --skip_steps=mingw"
fi

# Choose subproject
case $target in
    arm-none-eabi)
        if [ "x$compiler" = "xgcc" ]; then
            SUB_PROJ_URL=https://github.com/ARM-software/toolchain-gnu-bare-metal
            SUB_PROJ=$(basename $SUB_PROJ_URL)
        else
            echo Error: Target $target compiler $compiler not supported. >&2
            exit 1
        fi
        ;;
    *)
        echo Error: Target $target not supported. >&2
        exit 1
        ;;
esac

# Checkout subproject scripts
if [ ! -d $SUB_PROJ -o ! -x $SUB_PROJ/$BUILD_SCRIPT ]; then
  git clone $SUB_PROJ_URL $SUB_PROJ
  if [ ! -x $SUB_PROJ/$BUILD_SCRIPT ]; then
    echo Error: Invalid subproject: $SUB_PROJ. >&2
    exit 1
  fi
fi
cd $SUB_PROJ
git checkout master
git pull
if [ "x$revision" != "x" ]; then
    git checkout $revision
fi

# Invoke the build script in subproject
./$BUILD_SCRIPT $options_to_subproj
