#!/bin/bash

# Call this script from a "Run Script" target in the Xcode project to
# cross compile MuPDF and third party libraries using the regular Makefile.
# Also see "iOS" section in Makerules.

build_dir="libmupdf/build"
output_dir="libs"
for i in mupdf mupdfthird; do
	LIB=lib${i}.a
	lipo -create -output "${output_dir}/${LIB}" "${build_dir}/release-ios-arm64/${LIB}"  "${build_dir}/release-ios-x86_64/${LIB}"
done
