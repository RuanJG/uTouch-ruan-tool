if [ $# -ne 1 ]
	then
	echo useage: $0 xxxx.png
	exit
fi
pngtopnm $1 > utulinux_logo.pnm
pnmquant 224 utulinux_logo.pnm > utulinux_logo_224.pnm
pnmtoplainpnm utulinux_logo_224.pnm > utulinux_logo_224.ppm
mv utulinux_logo_224.ppm $1.ppm
rm utulinux_*
echo output to $1.ppm
