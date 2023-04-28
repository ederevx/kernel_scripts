#!/bin/bash
#
# Commit script
#

source xect

decho "Executing commit script..."

param_func "$@"

DIR_LIST=(
	"$REL_DIR"
	"$SRT_DIR"
	"$ZIP_DIR"
	"$SRC_DIR/$SRCN"
	"$REL_DIR"
)

for DIR in ${DIR_LIST[@]}; do
	commit_repo $DIR "$@"
done

exit 0
