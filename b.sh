#!/bin/bash
#
# Build script
#

source xect

decho "Executing build script..."

#
# Build functions
#

watch_func() {
	if [[ $1 != "n" ]]; then
		if [ ! -d $LOG_DIR ]; then
			create_dir $LOG_DIR
		fi

		if [ ! -f $LOG ]; then
			touch $LOG_DIR/$KNAME.log
		else
			echo "" > $LOG
		fi

		decho "Build start: $DATE_FULL" >> $LOG
		watch_logs $LOG
	else
		LOG=/dev/null
	fi
}

define_kname() {
	if [[ $SRCN == "fourteen" ]]; then
		SRC_VER="$BRNCH_VER"
		KNAME="$SRCN-$SRC_VER-$VER"
	else
		SRC_VER="v$HEAD_VER-$BRNCH_VER"
		KNAME="$SRCN-$SRC_BRNCH-$SRC_VER-$VER"
	fi
	if [[ $TEST_BUILD == "y" ]]; then
		KNAME="$KNAME-test"
	fi
}

define_clang() {
	CC="clang-$CVER"
	CXX="clang++-$CVER"
	LD="ld.lld-$CVER"
	AS="llvm-as-$CVER"
	AR="llvm-ar-$CVER"
	NM="llvm-nm-$CVER"
	DIS="llvm-dis-$CVER"
	OBJCOPY="llvm-objcopy-$CVER"
	OBJDUMP="llvm-objdump-$CVER"
	STRIP="llvm-strip-$CVER"
	READELF="llvm-readelf-$CVER"
	CLANG_TRIPLE=$C64

	CLANGMKP=" \
		CC=$CC \
		CXX=$CXX \
		HOSTCC=$CC \
		HOSTCXX=$CXX \
		AS=$AS \
		AR=$AR \
		LLVM_AR=$AR \
		HOSTAR=$AR \
		LD=$LD \
		HOSTLD=$LD \
		NM=$NM \
		LLVM_NM=$NM \
		DIS=$DIS \
		LLVM_DIS=$DIS \
		OBJCOPY=$OBJCOPY \
		OBJDUMP=$OBJDUMP \
		STRIP=$STRIP \
		READELF=$READELF \
		CLANG_TRIPLE=$CLANG_TRIPLE \
		"
}

define_debug() {
	DEBUGMKP="	\
		CONFIG_DEBUG_SECTION_MISMATCH=y \
		"
}

define_env() {
	border
	if [[ $SRC_BRNCH != "" ]]; then
		echo "Checking out to branch:"
		git checkout $SRC_BRNCH
	else
		CURRBRNCH="$(git rev-parse --abbrev-ref HEAD)"
		SRC_BRNCH=$CURRBRNCH

		echo "Using current branch:"
	fi
	echo $SRC_BRNCH
	border

	OUT=$OUT_DIR/$SRCN/$SRC_BRNCH
	BTI=$OUT/arch/arm64/boot

	define_kname

	if [[ $FORCE_VER != "y" ]]; then
		while [[ -f $PUSH_DIR/$KNAME.zip ]]
			do
			VER="$(($VER + 1))"
			define_kname
		done
	fi

	LOG=$LOG_DIR/$KNAME.log
	{
		if [[ $CONFIGURE == "y" ]]; then
			watch_func n
			border
			echo "Configure only, no builds will be made..."
		else
			watch_func y
			border
			echo "Branch to be built: $SRC_BRNCH"
		fi

		echo "Last Commit:"
		echo $(git -C $SRC_DIR log -1 --pretty=%B)
		border
	} >> $LOG

	LOCALVERSION="-$KNAME"

	if [[ $CVER != "" ]]; then
		define_clang
	fi

	if [[ $DEBUG != "n" ]]; then
		define_debug
	fi

	CF="$($CC --version | head -1)"
	decho_log "Compiler being used: $CF"

	BUILD_STR="$SRCN release: $SRC_BRNCH-$SRC_VER-$VER built using $CF | Date: $DATE_FULL"

	MKP=" \
		$CLANGMKP \
		$DEBUGMKP \
		ARCH=$ARCH \
		SUBARCH=$SUBARCH \
		CROSS_COMPILE=$C64 \
		CROSS_COMPILE_ARM32=$C32 \
		LOCALVERSION=-$KNAME \
		O=$OUT \
		-j$JN \
		-l$LN \
		"

	decho "Make variables: $MKP" >> $LOG
}

build_func() {
	cd $SRC_DIR

	define_env

	if [ -d "$OUT" ]; then
		time make_cmd clean
		time make_cmd mrproper 
	else
		create_dir $OUT
	fi

	time make_cmd $DC

	if [[ $MAKE_ONLY == "y" ]]; then
		decho_log "Done generating .config at $OUT"
		code $OUT/.config
		exit 0
	fi

	if [[ $CONFIGURE != "y" ]]; then
		time make_cmd
	else
		time make_cmd menuconfig
		cp -v $OUT/.config $SRC_DIR/$AF/$DC
		decho "Copied .config to $DC"
		exit 0
	fi
}

zip_func() {
	cd $ZIP_DIR

	if [ ! -d $PUSH_DIR ]; then
		create_dir $PUSH_DIR
	fi

	mv -f $BTI/$LWIMG $ZIP_DIR
	touch version

	{
		border
		echo "You are flashing:"
		echo "$SRCN kernel by ederekun"
		echo "Build code: $SRC_BRNCH-$BRNCH_VER-$VER"
		border
	} >> version

	zip_image $PUSH_DIR/$KNAME

	rm -f $LWIMG
	rm -f version
}

main_func() {
	if [ ! -d $SRC_DIR ] || [[ $SRCN == "" ]]; then
		decho_log "Abort, source directory must exist and source name must be defined."
		exit 1
	fi

	build_func

	if [ ! -f $BTI/$LWIMG ]; then
		decho_log "There's no image found in $OUT!"
		err_tg_msg
	elif [ ! -d $ZIP_DIR ]; then
		decho_log "There's no zip directory, abort."
		err_tg_msg
	else
		zip_func

		push_update $PUSH_DIR/$KNAME

		if [[ $TEST_BUILD != "y" ]]; then
			cd $REL_DIR
			git checkout $HEAD_VER
			commit_repo "$(pwd)" -m "$BUILD_STR" -a
		fi
	fi

	decho_log "Build done: $DATE_FULL"
}

param_main_func() {
	param_func "$@"
	main_func
}

#
# Build script
#

param_func "$@"

SRC_DIR=$SRC_DIR/$SRCN

CHAT_ID=-1001255168395
BOT_ID=1705973222:AAFjMihR-1nivjo2U3Tic9tbztJBnUK0eEY

if [[ $TEST_BUILD == "y" ]]; then
	PUSH_DIR=$TEST_DIR
else
	PUSH_DIR=$REL_DIR
fi

# lazy extension
if [[ $SRCN == "lazy" ]]; then
	DC="lazy_defconfig"
	BOT_ID=1164940747:AAGWc84XThFpq1xLdUuA2t745uJPjBmDHg4
	HEAD_VER=2.4
	if [[ $BUILD_ALL == "y" ]]; then
		decho "Building all branches"
		param_main_func -b custom-develop
		param_main_func -b custom-old-develop
		param_main_func -b oos-develop
		param_main_func -b pa-develop
		exit 0
	fi
fi

# x extension
if [[ $SRCN == "x" ]]; then
	DC="oneplus5_defconfig"
	BOT_ID=1705973222:AAFjMihR-1nivjo2U3Tic9tbztJBnUK0eEY
	HEAD_VER=1
	if [[ $BUILD_ALL == "y" ]]; then
		decho "Building all branches"
		param_main_func -b base
		param_main_func -b base-old
		param_main_func -b base-oos
		exit 0
	fi
fi

main_func

exit 0
