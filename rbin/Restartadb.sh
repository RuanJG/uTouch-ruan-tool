thispath=`dirname $0`

if [ $1 == 'nadb' ];then
	adbtool=$thispath/nadb
else
	adbtool=$thispath/adb
fi
sudo $adbtool kill-server
sudo $adbtool devices
