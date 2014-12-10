#!/bin/bash
# 使用该工具的时候需要修改/etc/sudoers，添加upgrade_tool的sudo权限，如：
# %zhansb ALL=(root) /usr/bin/rkupgrade_tool

RKUPGRADE_TOOL='/usr/bin/rk31upgrade_tool'
PARA_PATH=''

if [ ! -e $RKUPGRADE_TOOL ];then
	echo !!!!!!!!!! no rkupgrade_tool find in $RKUPGRADE_TOOL
	exit 0
fi

usage()
{
    echo "usage: $(basename $0) [-h]  -p parameter -l loader -m misc.img -k kernel.img -b boot.img -r recovery.img -s system.img -a imgs_dir -u update.img"
}

tool_help() {
cat <<EOF
    [-p:l:m:k:b:r:s:u: 来源文件]：分别对应文件parameter loader misc.img kernel.img boot.img recovery.img system.img update.img
    
    [-a 来源目录]：可包含misc.img kernel.img boot.img recovery.img system.img的目录
    
使用例子：
    rkupgrade.sh -a /mnt/server/images/
    rkupgrade.sh -k /mnt/server/images/kernel.img -b /mnt/server/images/boot.img

EOF

}

# 处理参数
process_opts()
{
	if [ $# -eq "0" ] ;	then
		usage
		exit 1
	fi

    # parameter  loader misc.img kernel.img boot.img recovery.img system.img update.img
	while getopts "p:l:m:k:b:r:s:u:a:h" arg #选项后面的冒号表示该选项需要参数
	do
        case $arg in
             p)
				PARA_PATH=$OPTARG
                ;;
             l)
				LOADER_PATH=$OPTARG
                ;;
             m)
				MISC_PATH=$OPTARG
                ;;
             k)
				KERNEL_PATH=$OPTARG
                ;;
             b)
				BOOT_PATH=$OPTARG
                ;;
             r)
				RECOVERY_PATH=$OPTARG
                ;;  
             s)
				SYSTEM_PATH=$OPTARG
                ;;
             u)
				UPDATE_PATH=$OPTARG
                ;;        
             a)
                MISC_PATH=$OPTARG/misc.img
                KERNEL_PATH=$OPTARG/kernel.img
                BOOT_PATH=$OPTARG/boot.img
                RECOVERY_PATH=$OPTARG/recovery.img
                SYSTEM_PATH=$OPTARG/system.img
                ;;           
             h)
				tool_help
				exit 0
                ;;
             ?) #当有不认识的选项的时候arg为?
            	usage
        		exit 1
        		;;
        esac
	done
}

wait_device()
{
    echo "Wait for device."
    while [ `$RKUPGRADE_TOOL td | grep -c "Test Device OK."` == 0 ]
    do
        $RKUPGRADE_TOOL sd > /dev/null
	    sleep 0.5
    done
}

# $1 option
# $2 file
# $3 parameter
download()
{
    [ "z$2" = "z" ] && return
    
    echo ""
    if [ ! -f "$2" ] ; then
        echo "No exist file<$2>"
    else
        echo "Download $2: "
        $RKUPGRADE_TOOL $1 "$2" "$3"
    fi
}
download_loader()
{
    [ "z$1" = "z" ] && return
    
    if [ ! -f "$1" ] ; then
        echo "No exist file<$2>"
    else
        wait_device
        echo "Download $1: "
        $RKUPGRADE_TOOL ul $1
    fi
}
# $1 firmware
download_firmware()
{
    if [ ! -f "$1" ] ; then
        echo "No exist file<$1>"
        exit 1
    else
        wait_device
        
        echo "Download $1: "
        $RKUPGRADE_TOOL lf
        #upgrade_tool ef "$1"
        $RKUPGRADE_TOOL uf "$1"
        exit 0
    fi
}

################################ main ##################################
set -e
#set -x

process_opts "$@"

[ "z$UPDATE_PATH" != "z" ] && download_firmware "$UPDATE_PATH" && exit 0

[ "z$LOADER_PATH" != "z" ] && download_loader "$LOADER_PATH"



echo "####################### download #######################"
if [ "x$PARA_PATH" == "x" ] || [ ! -e "$PARA_PATH" ] ; then
	    [ "z$LOADER_PATH" != "z" ] && $RKUPGRADE_TOOL rd
    	echo "No exist parameter<$PARA_PATH>!"
    	exit 1
fi
wait_device
download "di -p" "$PARA_PATH"
download "di -m" "$MISC_PATH"       "$PARA_PATH"
download "di -k" "$KERNEL_PATH"     "$PARA_PATH"
download "di -b" "$BOOT_PATH"       "$PARA_PATH"
download "di -r" "$RECOVERY_PATH"   "$PARA_PATH"
download "di -s" "$SYSTEM_PATH"     "$PARA_PATH"
			
echo ""				
$RKUPGRADE_TOOL rd

echo "######################### done #########################"
exit 0
