#!/bin/bash

# Variables
sequence=`seq 1 100`;
numjobs=0;
this="KaminariKernel";

# Set up the cross-compiler
export PATH=$HOME/Toolchains/Linaro-4.9-CortexA7/bin:$PATH;
export ARCH=arm;
export SUBARCH=arm;
export CROSS_COMPILE=arm-cortex_a7-linux-gnueabihf-;

# Clear the screen, bud!
clear;

# Variables for bold & normal text
bold=`tput bold`;
normal=`tput sgr0`;

# Let's start...
echo -e "Building KaminariKernel (Stock IDCrisis version)...\n";

devicestr="Which device do you want to build for?
1. Moto G (1st gen, GSM/CDMA) (falcon)
2. Moto G (1st gen, LTE) (peregrine) ";

# Select which device the kernel should be built for
while read -p "$devicestr" dev; do
	case $dev in
		"1")
			echo -e "Selected device: Moto G GSM/CDMA (falcon)\n"
			device="falcon";
			break;;
		"2")
			echo -e "Selected device: Moto G LTE (peregrine)\n"
			device="peregrine";
			break;;
		"3")
			echo -e "Selected device: Moto G 2nd Gen (GSM/LTE) (titan/thea)\n"
			device="titan";
			break;;
		*)
			echo -e "\nInvalid option. Try again.\n";;
	esac;
done;
		
# Clean everything via `make mrproper`.
# Recommended if there were extensive changes to the source code.
while read -p "Do you want to clean everything (generated files, etc.)? (Y/N) " clean; do
	case $clean in
		"y" | "Y" | "yes" | "Yes")
			echo -e "Cleaning everything...\n";
			make --quiet mrproper && echo -e "Done!\n";
			break;;
		"n" | "N" | "no" | "No" | "" | " ")
			echo -e "Not cleaning anything.\n";
			break;;
		*)
			echo -e "\nInvalid option. Try again.\n";;
	esac;
done;

version=`date --utc "+%Y%m%d.%H%M%S"`;

# Select how many parallel CPU jobs should be used.
# The ideal number is 2x the number of CPU cores.
# E.g. for a quad-core CPU, the ideal would be 8 jobs, and so on.
while read -p "How many parallel jobs do you want to use? (Default is 4.) " numjobs; do
	for i in $sequence; do
		if [[ $numjobs = $i ]]; then
			echo -e "Number of custom jobs: $numjobs\n";
			jobs=$numjobs;
		else
			case $numjobs in
				"" | " ")
					echo -e "No custom number of jobs specified. Using default number.\n";
					jobs="4";
					break;;
				*)
					echo -e "\nInvalid option. Try again.\n";;
			esac;
		fi;
	done;
	break;
done;
	
# Tell exactly when the build started
echo -e "Build started on:\n`date +"%A, %d %B %Y @ %H:%M:%S %Z (GMT %:z)"`\n`date --utc +"%A, %d %B %Y @ %H:%M:%S %Z"`\n";
starttime=`date +"%s"`;
			
# Remove all DTBs to avoid conflicts
rm -rf arch/arm/boot/*.dtb;
			
# Build the kernel
make "$device"_defconfig;

if [[ $jobs != "0" ]]; then
	make -j$jobs;
else
	make;
fi;

if [[ -f arch/arm/boot/zImage ]]; then
	echo -e "Code compilation finished on:\n`date +"%A, %d %B %Y @ %H:%M:%S %Z (GMT %:z)"`\n`date --utc +"%A, %d %B %Y @ %H:%M:%S %Z"`\n";
	maketime=`date +"%s"`;
	makediff=$(($maketime - $starttime));
	echo -e "Code compilation took: $(($makediff / 60)) minute(s) and $(($makediff % 60)) second(s).\n";
else
	echo -e "zImage not found. Kernel build failed. Aborting.\n";
	exit 1;
fi;

# Define directories (zip, out)
maindir=$HOME/Kernel/Zip_StockIdCrisis;
outdir=$HOME/Kernel/Out_StockIdCrisis/$device;
devicedir=$maindir/$device;

# Make the zip and out dirs if they don't exist
if [ ! -d $maindir ] || [ ! -d $outdir ]; then
	mkdir -p $maindir && mkdir -p $outdir;
fi;

# Make the modules dir if it doesn't exist.
# Remove any previously built modules as well.
[ -d $devicedir/modules ] || mkdir -p $devicedir/modules;
[ -d $devicedir/modules ] && rm -rf $devicedir/modules/*;
[ -d $devicedir/modules/pronto ] || mkdir -p $devicedir/modules/pronto;
moduledir=$devicedir/modules;
# Copy the modules
echo -e "Copying kernel modules...\n";
for mod in `find . -type f -name "*.ko"`; do
	cp -f $mod $moduledir/;
done;
# Move wi-fi module (wlan.ko) to modules/pronto & rename it to pronto_wlan.ko. This is very important!!
# A symlink to it (named wlan.ko) will be created at installation time.
mv $moduledir/wlan.ko $moduledir/pronto/pronto_wlan.ko;

# Use zImage + dt.img to generate a boot image.
# Create a dt.img first.
echo -e "Creating dt.img..."
./bootimgtools/dtbTool -s 2048 -o /tmp/dt.img -p scripts/dtc/ arch/arm/boot/;

# Create our boot.img from zImage + dt.img + a prepacked ramdisk.
echo -e "Creating boot.img...";
./bootimgtools/mkbootimg --kernel arch/arm/boot/zImage --ramdisk $maindir/packed_ramdisks/ramdisk_"$device".cpio.gz --board "" --base 0x00000000 \
	--kernel_offset 0x00008000 --ramdisk_offset 0x01000000 --tags_offset 0x00000100 \
	--cmdline "console=ttyHSL0,115200,n8 androidboot.console=ttyHSL0 androidboot.hardware=qcom user_debug=31 msm_rtb.filter=0x37 vmalloc=400M utags.blkdev=/dev/block/platform/msm_sdcc.1/by-name/utags movablecore=160M" \
	--pagesize 2048 --dt /tmp/dt.img --output $devicedir/boot.img;

# Set the zip's name
zipname="IdCrisisStock_"$version"_"`echo "${device^}"`;

# Zip the stuff we need & finish
echo -e "Creating flashable ZIP...\n";
case $device in
	"falcon")
		echo -e "Device: Moto G 1st Gen (falcon)" > $devicedir/device.txt;;
	"peregrine")
		echo -e "Device: Moto G 1st Gen w/ LTE (peregrine)" > $devicedir/device.txt;;
esac;
echo -e "Version: $version" > $devicedir/version.txt;
cd $maindir/common;
zip -r9 $outdir/$zipname.zip . > /dev/null;
cd $devicedir;
zip -r9 $outdir/$zipname.zip * > /dev/null;
echo -e "Done!"
# Tell exactly when the build finished
echo -e "Build finished on:\n`date +"%A, %d %B %Y @ %H:%M:%S %Z (GMT %:z)"`\n`date --utc +"%A, %d %B %Y @ %H:%M:%S %Z"`\n";
finishtime=`date +"%s"`;
finishdiff=$(($finishtime - $starttime));
echo -e "This build took: $(($finishdiff / 60)) minute(s) and $(($finishdiff % 60)) second(s).\n";

