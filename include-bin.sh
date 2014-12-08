#/bin/sh
if [ ! -d ./bin ] || [ ! -d ./rbin ];then
	echo "!!!!!!!!!!  no bin path ,, check it !"
	exit
fi
export PATH=$(pwd)/bin:$(pwd)/rbin:$PATH
