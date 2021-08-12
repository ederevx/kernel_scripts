#!/bin/bash
#
# Build script
#

source xect

decho "Executing build script..."

#
# Build functions
#

define_kname() {
	KNAME="$SRCN-$SRC_BRNCH-$BRNCH_VER-$VER"
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
		CLANG_TRIPLE=$CLANG_TRIPLE"
}

define_env() {
	OUT=$OUT_DIR/$SRCN/$SRC_BRNCH
	BTI=$OUT/arch/arm64/boot

	define_kname

	while [[ -f $PUSH_DIR/$KNAME.zip ]]
		do
		VER="$(($VER + 1))"
		define_kname
	done

	LOCALVERSION="-$KNAME"

	LOG=$LOG_DIR/$KNAME.log

	if [[ $CVER != "" ]]; then
		define_clang
	fi

	MKP=" \
		$CLANGMKP \
		ARCH=$ARCH \
		SUBARCH=$SUBARCH \
		CROSS_COMPILE=$C64 \
		CROSS_COMPILE_ARM32=$C32 \
		LOCALVERSION=-$KNAME \
		O=$OUT \
		-j$JN \
		-l$LN"
}

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

		decho "Build start: $(date -R)" >> $LOG
		watch_logs $LOG
		send_tg_msg "Build started: $KNAME is being built using $CF"
		decho "Make variables: $MKP" >> $LOG
	else
		LOG=/dev/null
	fi
}

build_func() {
	cd $SRC_DIR

	if [[ $SRC_BRNCH != "" ]]; then
		decho "Checking out branch..."
		git checkout $SRC_BRNCH
	else
		CURRBRNCH="$(git rev-parse --abbrev-ref HEAD)"
		SRC_BRNCH=$CURRBRNCH

		decho "Using current branch..."
	fi

	define_env

	decho_log "Branch to be built: $SRC_BRNCH"

	if [[ $CONFIGURE == "y" ]]; then
		decho_log "Configure only, no builds will be made..."
		watch_func n
	else
		watch_func y
	fi

	{
		LC="$(git -C $SRC_DIR log -1 --pretty=%B)"
		decho "Last Commit: $LC"
	} >> $LOG

	if [ -d "$OUT" ]; then
		time make_cmd clean
		time make_cmd mrproper 
	else
		create_dir $OUT
	fi

	time make_cmd $DC

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
			commit_repo $REL_DIR "$BUILD_STR"
		fi
	fi

	decho_log "Build done: $(date -R)"
}

param_main_func() {
	param_func "$@"
	main_func
}

#
# Build script
#

param_func "$@"
define_env

SRC_DIR=$SRC_DIR/$SRCN
CF="$($CC --version | head -1)"

CHAT_ID=-1001255168395
BOT_ID=1705973222:AAFjMihR-1nivjo2U3Tic9tbztJBnUK0eEY

# Lazy props
if [[ $SRCN == "lazy" ]]; then
	DC="lazy_defconfig"
	BOT_ID=1164940747:AAGWc84XThFpq1xLdUuA2t745uJPjBmDHg4
	BRNCH_VER="v2.4-$BRNCH_VER"
fi

if [[ $TEST_BUILD == "y" ]]; then
	PUSH_DIR=$TEST_DIR
else
	PUSH_DIR=$REL_DIR
fi

if [[ $SRCN == "lazy" ]] && [[ $BUILD_ALL == "y" ]]; then
	decho "Building all branches"
	param_main_func -b custom-develop
	param_main_func -b custom-old-develop
	param_main_func -b oos-develop
	param_main_func -b pa-develop
else
	main_func
fi

exit 0
