if [ $# -ne 1 ]
	then
	echo useage: $0 xxxx.bmp
	exit
fi
bmptoppm $1 > temp1.ppm
ppmquant 224 temp1.ppm > temp2.ppm
pnmnoraw temp2.ppm > tmp3.ppm
mv tmp3.ppm $1.ppm
rm temp*
echo output to $1.ppm
