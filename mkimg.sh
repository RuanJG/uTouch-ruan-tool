R_bin=1
R_root=1

ANDROID_SRC="$(pwd)/.."
OUT="$ANDROID_SRC/out/target/product/rk3188"
VM_PATH="$HOME/vmware/vmShared"
KERNEL_PATH="$ANDROID_SRC/kernel/rockchip/kernel"
IMAGE_PATH=outImages


if [ "0" = $R_bin ];then
	export PATH=$ANDROID_SRC/out/host/linux-x86/bin:$PATH
else
	. include-bin.sh
fi

if [ "0" = $R_root ];then
	UROOT=$OUT/ubuntu-root
else
	UROOT=$(pwd)/ubuntu-boot/ubuntu-root
fi

if [ ! -d $IMAGE_PATH ]; then
	mkdir -p $IMAGE_PATH
fi


convert_android_img()
{
	local TMPMOUNT=xxx_tmpmountdir
	local WORKDIR=xxx_tmpdir
	[ -d $TMPMOUNT ] && rm $TMPMOUNT -rf
	[ -d $WORKDIR ] && rm $WORKDIR -rf
	mkdir $TMPMOUNT
	mkdir $WORKDIR
	simg2img $1 $WORKDIR/system.img.raw
	sudo mount -t ext4 -o loop $WORKDIR/system.img.raw $TMPMOUNT
	make_ext4fs -l 120M $IMAGE_PATH/system.img $TMPMOUNT >/dev/null 2>&1
	cp -v $IMAGE_PATH/system.img $VM_PATH/
	sudo umount $TMPMOUNT
	rm $TMPMOUNT $WORKDIR -rf
	echo -n"the ext4fs system.img place in $WORKDIR/system.img..."
}


mk_not_ota_boot_img()
{
	echo -n "create $1 boot.img without kernel... "
	[ -d $1 ] && \
	mkbootfs $1 | minigzip > ./xxx_tmpramdisk.img && \
	mkkrnlimg ./xxx_tmpramdisk.img $IMAGE_PATH/boot.img >/dev/null
	cp -v $IMAGE_PATH/boot.img $VM_PATH/
	rm xxx_tmpramdisk.img
	echo "done."
}

######################################  main process 


if [ -n $1 ];then
	if [ $1 = 'r' ]; then
		echo -n "create recovery.img with kernel... "
		cp -v $ANDROID_SRC/device/rockchip/tr101q/recovery_init.rc $OUT/recovery/root/init.rc
		cp $KERNEL_PATH/arch/arm/boot/Image $OUT/kernel
		[ -e $OUT/rk_ramdisk-recovery.img ] && rm $OUT/rk_ramdisk-recovery.img
		[ -d $OUT/recovery/root ] && \
		mkbootfs $OUT/recovery/root | minigzip > $OUT/rk_ramdisk-recovery.img && \
		mkbootimg --kernel $OUT/kernel --ramdisk $OUT/rk_ramdisk-recovery.img --output $IMAGE_PATH/recovery.img && \
		cp -v $IMAGE_PATH/recovery.img $VM_PATH/
		echo ".... done."
	elif [ $1 = 'b' ]; then
		echo -n " create boot img in $UROOT ...."
		cp $KERNEL_PATH/arch/arm/boot/Image $OUT/kernel
		[ -e $OUT/rk_ramdisk-boot.img ] && rm $OUT/rk_ramdisk-boot.img
		[ -d $UROOT ] && \
		mkbootfs $UROOT | minigzip > $OUT/rk_ramdisk-boot.img && \
		mkbootimg --kernel $OUT/kernel --ramdisk $OUT/rk_ramdisk-boot.img --output $IMAGE_PATH/boot.img && \
		cp -v $IMAGE_PATH/boot.img $VM_PATH/
		echo " ... done."
	
	elif [ $1 = 's' ]; then
		echo -n " create system img ...."
        system_size=`ls -l $OUT/system.img | awk '{print $5;}'`
        [ $system_size -gt "0" ] || { echo "Please make first!!!" && exit 1; }
        MAKE_EXT4FS_ARGS=" -L system -S $OUT/root/file_contexts -a system $IMAGE_PATH/system.img $OUT/system"
		ok=0
		while [ "$ok" = "0" ]; do
			make_ext4fs -l $system_size $MAKE_EXT4FS_ARGS >/dev/null 2>&1 &&
			tune2fs -c -1 -i 0 $IMAGE_PATH/system.img >/dev/null 2>&1 &&
			ok=1 || system_size=$(($system_size + 5242880))
		done
		e2fsck -fyD $IMAGE_PATH/system.img >/dev/null 2>&1 || true
		cp -v $IMAGE_PATH/system.img $VM_PATH/
		echo " create $IMAGE_PATH/system.img .... done."

	elif [ $1 = 'cs' ]; then
		echo -n " convert_android_img $2 ..."
		[ -e $2 ] && convert_android_img $2
		echo "[done]"
	elif [ $1 = 'cb' ]; then
		echo -n " make a boot.img by a dir... "
		mk_not_ota_boot_img $2
		echo "[done]"
	elif [ $1 = 'all' ]; then
		cp -v device/rockchip/tr101q/recovery_init.rc out/target/product/rk3188/recovery/root/init.rc
	fi
fi
