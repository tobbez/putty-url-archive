#!/bin/bash -ue

usage() {
	echo "Usage: $0 <VERSION>"
	echo
	echo "The source directory, expected in ~/sources-\$VERSION/, must contain only the putty tar, the patch, and the icons tar"
        echo "The produced files will be placed in PWD"
	exit
}

if [ $# -ne 1 ]
then
	usage
fi

for arg; do
	if [ "$arg" = "-h" ] || [ "$arg" = "--help" ]; then
		usage
	fi
done


VERSION="$1"
DIRECTORY="/home/build/sources-$VERSION"
PUTTY_TAR="$(ls "$DIRECTORY/putty-"*".tar.gz" | grep -v icons)"
PATCH="$(ls "$DIRECTORY/"*".patch")"
ICONS_TAR="$DIRECTORY/putty-url-icons.tar.gz"

[ -e "$DIRECTORY" ] || { echo "The specified directory does not exist"; exit; }
[ -e "$PUTTY_TAR" ] || { echo "The specified directory does not contain a PuTTY source tar"; exit; }
[ -e "$PATCH" ] || { echo "The specified directory does not contain a PuTTY-url patch"; exit; }
[ -e "$ICONS_TAR" ] || { echo "The specified directory does not contain the PuTTY-url icons tar"; exit; }

MSVC_FILES_ROOT="/home/build/vfatfs2"

MSVC_INCLUDES=$(echo "$MSVC_FILES_ROOT/Contents/VC/Tools/MSVC/"*"/include/")
MSVC_LIBS=$(echo "$MSVC_FILES_ROOT/Contents/VC/Tools/MSVC/"*"/lib/")
MSVC_LIBS="$MSVC_LIBS#ARCH#/"

for i in shared ucrt um; do
	MSVC_INCLUDES="$MSVC_INCLUDES;$(echo "$MSVC_FILES_ROOT/Program Files/Windows Kits/10/Include/"*"/$i")"
done

for l in ucrt um; do
	MSVC_LIBS="$MSVC_LIBS;$(echo "$MSVC_FILES_ROOT/Program Files/Windows Kits/10/Lib/"*"/$l/")"
	MSVC_LIBS="$MSVC_LIBS#ARCH#/"
done

set | grep MSVC

set -x

BUILD_ROOT="$PWD"

rm -rf "sources" "build"
mkdir sources
tar xf "$PUTTY_TAR" -C "sources"
cd "sources/putty-"*
patch -p1 < "$PATCH"
tar xf "$ICONS_TAR"

cd "$BUILD_ROOT"

for platform in x86 x64; do
	mkdir -p "build/$platform"
	(
		cd "build/$platform"
		export INCLUDE="$MSVC_INCLUDES" LIB="$(echo "${MSVC_LIBS//#ARCH#/$platform}")" Platform="$platform"

		# x86 for x86, AMD64 for x86_64
		cmake_sys_proc=$platform
		[ "$platform" = "x64" ] && CMAKE_SYS_PROC=AMD64

		clang_arch=i386
		[ "$platform" = "x64" ] && clang_arch=x86_64

		# semicolons to separate compiler from args (???)
		# CMAKE_AR must be a full path, *sigh* https://gitlab.kitware.com/cmake/cmake/-/issues/18087
		cmake ../../sources/putty-*/ -DCMAKE_SYSTEM_NAME=Windows -DCMAKE_SYSTEM_PROCESSOR="$cmake_sys_proc" -DCMAKE_C_COMPILER="clang-cl-15;-target ${clang_arch}-pc-windows-msvc" -DCMAKE_LINKER=lld-link-15 -DCMAKE_AR=/usr/bin/llvm-lib-15 -DCMAKE_MT=llvm-mt-15 -DCMAKE_RC_COMPILER=llvm-rc-15 -DCMAKE_BUILD_TYPE=Release -DCMAKE_MSVC_RUNTIME_LIBRARY=MultiThreaded -DCMAKE_C_FLAGS_RELEASE="/MT /O2"
		make -j$(nproc) putty
	)

done

install -D build/x86/putty.exe dist/$VERSION/x86/putty.exe
install -D build/x64/putty.exe dist/$VERSION/x86_64/putty.exe
cp -v "$PATCH" dist/

ls -l dist/*/*/*
file dist/*/*/*
