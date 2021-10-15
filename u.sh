#!/bin/bash
#
# Update script
#

source xect

decho "Executing update script..."

param_func "$@"

if [[ $1 == "-x" ]]; then
	update_linux
else
	update_repo $REL_DIR
	update_repo $SRT_DIR
	update_repo $ZIP_DIR
	update_repo $PACK_DIR
	update_repo $CLANG_DIR
	update_repo ${GCC_DIR}64
	update_repo ${GCC_DIR}32
fi

exit 0
