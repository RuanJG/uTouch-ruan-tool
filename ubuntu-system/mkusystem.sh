TARBALL=/data/touch.tar.gz
SYSIMG=/data/android-system.img
CUST_TAR=/data/cust-touch.tar.gz

echo -n "preparing system-image on device ... "
rm -f /data/system.img
for data in system android; do
	rm -rf /data/$data-data
done
if [ -z "$KEEP" ]; then
	rm -rf /data/user-data
else
	echo -n "keep option set, keeping user data ... "
fi
dd if=/dev/zero of=/data/system.img seek=500K bs=4096 count=0 >/dev/null 2>&1
mkfs.ext2 -F /data/system.img >/dev/null 2>&1
mkdir -p /cache/system
mount -o loop /data/system.img /cache/system/
echo "[done]"

echo -n "unpacking rootfs tarball to system-image ... "
cd /cache/system && zcat $TARBALL | tar xf -
cd /
mkdir -p /cache/system/android/firmware
mkdir -p /cache/system/android/persist
mkdir -p /cache/system/userdata
[ -e /cache/system/SWAP.swap ] && mv /cache/system/SWAP.swap /data/SWAP.img
cd /cache/system 
for link in cache data factory firmware persist system; do
	ln -s /android/$link $link
done
cd /cache/system/lib && ln -s /system/lib/modules modules
cd /cache/system && ln -s /android/system/vendor vendor
[ -e /cache/system/etc/mtab ] && rm /cache/system/etc/mtab
cd /cache/system/etc && ln -s /proc/mounts mtab
if [ ! -z "$WIPE_PATH" ]; then
	echo ' ' >/cache/system/$WIPE_PATH || true
fi
echo "[done]"

echo -n "adding custom path .... "
mkdir /cache/system/custom -p
cd /cache
zcat $CUST_TAR | tar xf -
cd /
echo "[done]"

echo -n "adding rules ... "
chomd 0777 /data/*rules
cp -v /data/*.rules /cache/system/usr/lib/lxc-android-config/
cp -v /data/*.rules /cache/system/lib/udev/rules.d/
echo "[done]"

echo -n "adding android system image to installation ... "
#convert_android_img
ANDROID_DIR="/cache/system/var/lib/lxc/android/"
#adb push $WORKDIR/system.img $ANDROID_DIR >/dev/null 2>&1
cp -v $SYSIMG $ANDROID_DIR/system.img 
echo "[done]"

echo -n "enabling Mir ... "
touch /cache/system/home/phablet/.display-mir
echo "[done]"

echo -n "cleaning up on device ... "
cd /
umount /cache/system 
rm -rf /cache/system 
echo "[done]"


