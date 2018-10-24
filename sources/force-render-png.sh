#!/bin/bash

set -e

SCRIPT_DIR=$(cd `dirname "$0"`; pwd)


MODE=$1

SYNFIG_OPTION="-q"

if [ "$MODE" = "references" ]; then
	rm -rf ${SCRIPT_DIR}/../references/*
fi

DEFAULT_VERSION=`cat ${SCRIPT_DIR}/default-version.txt`

# Get synfig pre-build for default version

SYNFIG=""

get-synfig-tar () {
SYNFIG="/tmp/synfig-$VERSION/synfig $SYNFIG_OPTION"
if [ ! -d "/tmp/synfig-$VERSION" ]; then
	wget --quiet "https://sourceforge.net/projects/synfig/files/releases/$VERSION/linux/synfigstudio-$VERSION.x86_64.tar.bz2/download" -O "/tmp/synfig-$VERSION.tar.bz2"
	mkdir -p /tmp/synfig-$VERSION
	tar jxf /tmp/synfig-$VERSION.tar.bz2 -C /tmp/synfig-$VERSION --strip-components=1
fi
}

get-synfig-appimage () {
SYNFIG="/tmp/synfig-$VERSION.appimage --appimage-exec synfig $SYNFIG_OPTION" 
if [ ! -d "/tmp/synfig-$VERSION.appimage" ]; then
	if [ "$#" -eq 3 ]; then
		LINK=$3
	else
		LINK="https://sourceforge.net/projects/synfig/files/releases/$VERSION/linux/synfigstudio-$2.appimage/download"
	fi
	wget --quiet $LINK -O "/tmp/synfig-$VERSION.appimage"
	chmod +x /tmp/synfig-$VERSION.appimage
fi
}

get-synfig () {
VERSION=$1
PARSED_VERSION=${VERSION//./}

if [ "$MODE" = "results" ]; then 
	SYNFIG="/usr/bin/synfig"
elif [ $PARSED_VERSION -lt 120 ]; then
	get-synfig-tar $VERSION
elif [ $PARSED_VERSION -eq 120 ]; then
	get-synfig-appimage $VERSION "1.2.0-64bit-r2"
elif [ $PARSED_VERSION -eq 121 ]; then
	get-synfig-appimage $VERSION "1.2.1-64bit"
elif [ $PARSED_VERSION -eq 122 ]; then
	get-synfig-appimage $VERSION "18.09.14-linux64-286f1" "https://sourceforge.net/projects/synfig/files/releases/1.2.2/SynfigStudio-1.2.2-18.09.14-linux64-286f1.appimage/download"
fi
}

COMPONENTS="blend-methods converters layers"

if [ $MODE = "results" ]; then
	mkdir -p ${SCRIPT_DIR}/../$MODE
fi

for COMPONENT in $COMPONENTS; do
	pushd "${SCRIPT_DIR}/$COMPONENT"
	for dir in * ; do
		if [ -d ${dir} ]; then
			pushd $dir

			# Check if version file already exist
			if [ -f "$dir.txt" ]; then
				VERSION=`cat $dir.txt`
			else
				VERSION=$DEFAULT_VERSION
			fi

			# Check if the required version binaries already exist
			if [ ! -d "/tmp/synfig-$VERSION" ]; then
				get-synfig $VERSION
			fi
			pushd ../../../$MODE
			mkdir -p ./$COMPONENT/$dir
			popd
			CURRENT_DIR=`pwd`
			for sample in * ; do
				# Renders every sif file present 
				if [ "${sample##*.}" = "sif" ]; then
					$SYNFIG --time 0 -i $CURRENT_DIR/$sample -o $CURRENT_DIR/../../../$MODE/$COMPONENT/$dir/"${sample%.*}".png
				fi
				if [ "$MODE" = "results" ]; then
					echo $sample
					idiff $CURRENT_DIR/../../../$MODE/$COMPONENT/$dir/"${sample%.*}".png  $CURRENT_DIR/../../../results/$COMPONENT/$dir/"${sample%.*}".png
				fi
			done
			popd
		fi
	done
	popd 
done
