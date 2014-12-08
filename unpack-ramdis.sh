. include-bin.sh

[ -d xxx_tmp_ramdisk ] && rm xxx_tmp_ramdisk -rf
mkdir xxx_tmp_ramdisk
img_path=$(cd `dirname $1`; pwd)/$(basename $1)
cd xxx_tmp_ramdisk


unpackage_boot.pl $img_path 
ramdisk_package=$(basename $1)-ramdisk.gz
if [ -e $ramdisk_package ];then
	mkdir ramdisk
	cd ramdisk
	gzip -dc ../$ramdisk_package | cpio -i
	cd ..
fi

