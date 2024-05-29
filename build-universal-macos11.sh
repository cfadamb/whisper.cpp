#!/bin/sh
set -eux
[ ! -f Makefile ] && echo "Makefile not found." && exit 1

TARGET=11.0
CREATE_PACKAGE=1

mkdir -p build/whisper/package
make clean
CC_CXX_EXTRA_FLAGS="-target x86_64-apple-macos${TARGET}" \
	MACOSX_DEPLOYMENT_TARGET=${TARGET} \
	WHISPER_NO_ACCELERATE_NEW_LAPACK=1 \
	WHISPER_METAL_EMBED_LIBRARY=1 \
	make main	
mv -f main build/main-x86_64

make clean
CC_CXX_EXTRA_FLAGS="-target arm64-apple-macos${TARGET}" \
	MACOSX_DEPLOYMENT_TARGET=${TARGET} \
	WHISPER_NO_ACCELERATE_NEW_LAPACK=1 \
	WHISPER_METAL_EMBED_LIBRARY=1 \
	make main
mv -f main build/main-arm64 

lipo -create -output build/main_universal build/main-x86_64 build/main-arm64
lipo -info build/main_universal 

if [ ${CREATE_PACKAGE} ]; then
	PACKAGE_DIR=build/package
	VERSION=$(git describe --tags --abbrev=0)
	cp -f build/main_universal "${PACKAGE_DIR}/whisper"
	cp -f models/download-ggml-model.sh "${PACKAGE_DIR}/whisper"
	cd "${PACKAGE_DIR}" && zip -vprTX -9 ../whisper.cpp-${VERSION}-macos-universal.zip . && cd -
	ls -l build/*.zip
fi
