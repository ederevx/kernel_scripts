#!/bin/bash
#
# Update script
#

source xect

decho "Executing update script..."

param_func "$@"

update_linux

if [[ $1 == "-x" ]]; then
	exit 0
fi

if [ -d $REL_DIR ]; then
	update_repo $ZIP_DIR
fi

if [ -d $SRT_DIR ]; then
	update_repo $SRT_DIR
fi

if [ -d $ZIP_DIR ]; then
	update_repo $ZIP_DIR
fi

exit 0
