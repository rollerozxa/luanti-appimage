#!/bin/bash -e

# Builds an AppImage using appimagetool.
# You need to run this inside of a build directory in the source tree,
# it will generate the build files and compile Luanti for you.

# This script should be run on Debian 11 Bullseye.

get_tar_archive() {
	# $1: folder to extract to, $2: URL
	local filename="${2##*/}"
	[ -d "$1" ] && return 0

	wget -nc -c "$2" -O "$filename"
	mkdir -p "$1"
	tar -xaf "$filename" -C "$1" --strip-components=1
}

# Ensure the architecture argument is set correctly
arch="${1:-x86_64}"
: "${LOCAL_RUN:=0}"

# COMPILE SDL2
sdl_ver="2.32.10"
get_tar_archive SDL2 "https://github.com/libsdl-org/SDL/releases/download/release-${sdl_ver}/SDL2-${sdl_ver}.tar.gz"

pushd SDL2

mkdir -p build; cd build
cmake .. -G Ninja \
	-DSDL_INSTALL_CMAKEDIR=usr/lib/cmake/SDL2 \
	-DCMAKE_BUILD_TYPE=Release \
	-DCMAKE_INSTALL_PREFIX=/ \
	-DCMAKE_C_FLAGS="-DSDL_LEAN_AND_MEAN=1" \
	-DSDL_{AUDIO,RENDER,VULKAN,TEST,STATIC}=OFF
ninja
strip -s *.so
if [ "${LOCAL_RUN}" != "1" ]; then
	DESTDIR="/" ninja install
else
	DESTDIR="../../" ninja install
fi

popd

# COMPILE LUAJIT
pushd luajit
make amalg -j4
popd

pushd luanti
mkdir -p build; cd build

# Download appimagetool
if [ ! -f appimagetool ]; then
	wget https://github.com/AppImage/appimagetool/releases/download/continuous/appimagetool-${arch}.AppImage -O appimagetool
	chmod +x appimagetool
fi

# Compile and install into AppDir
cmake .. -G Ninja \
	-DCMAKE_BUILD_TYPE=RelWithDebInfo \
	-DCMAKE_INSTALL_PREFIX=AppDir/usr \
	-DBUILD_UNITTESTS=OFF \
	-DENABLE_SYSTEM_JSONCPP=OFF \
	-DLUA_INCLUDE_DIR=../../luajit/src/ \
	-DLUA_LIBRARY=../../luajit/src/libluajit.a
ninja; ninja install

cd AppDir

objcopy --only-keep-debug usr/bin/luanti ../luanti.debug
objcopy --strip-debug --add-gnu-debuglink=../luanti.debug usr/bin/luanti

# Put desktop and icon at root
ln -sf usr/share/applications/org.luanti.luanti.desktop luanti.desktop
ln -sf usr/share/icons/hicolor/128x128/apps/luanti.png luanti.png
ln -sf luanti.png .DirIcon

# Fix locales
mv usr/share/locale usr/share/luanti

cat > AppRun <<\APPRUN
#!/bin/sh
APP_PATH="$(dirname "$(readlink -f "${0}")")"
export LD_LIBRARY_PATH="${APP_PATH}"/usr/lib/:"${LD_LIBRARY_PATH}"
exec "${APP_PATH}/usr/bin/luanti" "$@"
APPRUN
chmod +x AppRun

# List of libraries from the system that should be bundled in the AppImage.
INCLUDE_LIBS=(
	libopenal.so.1
	 libsndio.so.7.0
	  libbsd.so.0
	   libmd.so.0
	libjpeg.so.62
	libpng16.so.16
	libvorbisfile.so.3
	 libogg.so.0
	 libvorbis.so.0
	libzstd.so.1
	libsqlite3.so.0
	libleveldb.so.1d
	 libsnappy.so.1
)

mkdir -p usr/lib/

if [ "${LOCAL_RUN}" != "1" ]; then
	for i in "${INCLUDE_LIBS[@]}"; do
		cp /usr/lib/${arch}-linux-gnu/$i usr/lib/
	done
fi

# Copy our own built SDL2
if [ "${LOCAL_RUN}" != "1" ]; then
	cp /usr/lib/libSDL2-2.0.so.0 usr/lib/
else
	cp ../../../usr/lib/libSDL2-2.0.so.0 usr/lib/
fi

# Actually build the appimage
cd ..
ARCH=${arch} ./appimagetool --appimage-extract-and-run AppDir/
