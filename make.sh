#!/bin/sh

cd `dirname $0`

# ===== VARIABLES =====

build_dir="build"
sources_dir="sources"

# ===== MAKE =====

rm -rf "$build_dir"
mkdir "$build_dir"

cp -r $sources_dir/* $build_dir

makeself --notemp "$build_dir" installer.sh "arch linux installer" ./install.sh
rm -rf $build_dir
