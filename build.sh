#!/bin/bash -e

# Builds an AppImage using appimagetool.
# You need to run this inside of a build directory in the source tree,
# it will generate the build files and compile Minetest for you.

# This script should be run on Debian 11 Bullseye.

# COMPILE LUAJIT
pushd luajit
make amalg -j4
popd

pushd luanti
mkdir -p build; cd build

# Download appimagetool
if [ ! -f appimagetool ]; then
	# Old version of appimagetool:
	#wget https://github.com/AppImage/AppImageKit/releases/download/continuous/appimagetool-x86_64.AppImage -O appimagetool
	wget https://github.com/AppImage/appimagetool/releases/download/continuous/appimagetool-x86_64.AppImage -O appimagetool
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
ninja

objcopy --only-keep-debug ../bin/luanti luanti.debug
objcopy --strip-debug --add-gnu-debuglink=luanti.debug ../bin/luanti

ninja install

cd AppDir

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
for i in "${INCLUDE_LIBS[@]}"; do
	cp /usr/lib/x86_64-linux-gnu/$i usr/lib/
done

# Copy our own built SDL2
cp /usr/lib/libSDL2-2.0.so.0 usr/lib/

# Actually build the appimage
cd ..
ARCH=x86_64 ./appimagetool --appimage-extract-and-run AppDir/
