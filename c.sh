#!/bin/bash
#
# Commit script
#

source xect

decho "Executing commit script..."

if [ -d $REL_DIR ]; then
	commit_repo $REL_DIR $1
fi

if [ -d $SRT_DIR ]; then
	commit_repo $SRT_DIR $1
fi

if [ -d $ZIP_DIR ]; then
	commit_repo $ZIP_DIR $1
fi

SRC_DIR=$SRC_DIR/$SRCN
if [ -d $SRC_DIR ]; then
	commit_repo $SRC_DIR $1
fi

exit 0
