#!/bin/bash
#
# Commit script
#

source xect

decho "Executing commit script..."

param_func "$@"

if [ -d $REL_DIR ]; then
	commit_repo $REL_DIR "$@"
fi

if [ -d $SRT_DIR ]; then
	commit_repo $SRT_DIR "$@"
fi

if [ -d $ZIP_DIR ]; then
	commit_repo $ZIP_DIR "$@"
fi

SRC_DIR=$SRC_DIR/$SRCN
if [ -d $SRC_DIR ]; then
	commit_repo $SRC_DIR "$@"
fi

exit 0
