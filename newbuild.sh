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

# Output some basic info
echo -e "Building KaminariKernel (IDCrisis version)...\n";

devicestr="Which device do you want to build for?
1. Moto G (1st gen, GSM/CDMA) (falcon)
2. Moto G (1st gen, LTE) (peregrine)
3. Moto G (2nd gen, GSM/LTE) (titan/thea) ";

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
			echo -e "Invalid option. Try again.\n";;
	esac;
done;
		

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

while read -p "Do you want to specify a release/version number? (Just press enter if you don't.) " rel; do
	if [[ `echo $rel | gawk --re-interval "/^R/"` != "" ]]; then
		for i in $sequence; do
			if [ `echo $rel | gawk --re-interval "/$i/"` ]; then
				echo -e "Release number: $rel\n";
				export LOCALVERSION="-Kaminari-$rel";
				version=$rel;
			fi;
		done;
	elif [[ `echo $rel | gawk --re-interval "/^v/"` ]]; then
		echo -e "Version number: $rel\n";
		export LOCALVERSION="-Kaminari-$rel";
		version=$rel;
	else
		case $rel in
			"" | " " )
				echo -e "No release number specified. Assuming test/nightly build.\n";
				export LOCALVERSION="-Kaminari-Testing";
				version=`date --utc "+%Y%m%d.%H%M%S"`;
				break;;
			*)
				echo -e "Localversion set as: $rel\n";
				export LOCALVERSION="-Kaminari-$rel";
				version=$rel;
				break;;
		esac;
	fi;
	break;
done;

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
	
echo -e "Build started on:\n`date +"%A, %d %B %Y @ %H:%M:%S %Z (GMT %:z)"`\n`date --utc +"%A, %d %B %Y @ %H:%M:%S %Z"`\n";

# Delete all previous dtbs to avoid conflicts
rm -rf arch/arm/boot/*.dtb;	
			
# Build the kernel
make "$device"_defconfig;

if [ "$jobs" != "0" ]; then
	make -j$jobs;
else
	make;
fi;

# Dirs
maindir=$HOME/Zip_CustomIdCrisis;
outdir=$HOME/Out_CustomIdCrisis/$device;
devicedir=$maindir/$device;
kerneldir=$HOME/$this;

# Tell when the build was finished
echo -e "Build finished on:\n`date +"%A, %d %B %Y @ %H:%M:%S %Z (GMT %:z)"`\n`date --utc +"%A, %d %B %Y @ %H:%M:%S %Z"`\n";

# Modules
echo -e "Copying kernel modules...\n";
for module in `find . -type f -name "*.ko"`; do
	cp -f $module $devicedir/system/lib/modules/;
done;
mv $devicedir/system/lib/modules/wlan.ko $devicedir/system/lib/modules/pronto/pronto_wlan.ko;

# Create dt.img, create boot.img & copy it
echo -e "Generating dt.img...\n"
./bootimgtools/dtbTool -s 2048 -o /tmp/dt.img -p scripts/dtc/ arch/arm/boot/;
echo -e "Creating boot.img...\n";
./bootimgtools/mkbootimg --kernel arch/arm/boot/zImage --ramdisk $maindir/packed_ramdisks/ramdisk_"$device".cpio.gz --board "" --base 0x00000000 \
	--kernel_offset 0x00008000 --ramdisk_offset 0x01000000 --tags_offset 0x00000100 \
	--cmdline "console=ttyHSL0,115200,n8 androidboot.console=ttyHSL0 androidboot.hardware=qcom user_debug=31 msm_rtb.filter=0x37 vmalloc=400M utags.blkdev=/dev/block/platform/msm_sdcc.1/by-name/utags movablecore=160M" \
	--pagesize 2048 --dt /tmp/dt.img --output $devicedir/boot.img;

# Set zip name
zipname="Kaminari_"$version"_"`echo "${device^}"`;

# Make the zip
case $device in
	"falcon")
		echo -e "Device: Moto G 1st Gen (falcon)" > $devicedir/device.txt;;
	"peregrine")
		echo -e "Device: Moto G 1st Gen w/ LTE (peregrine)" > $devicedir/device.txt;;
	"titan")
		echo -e "Device: Moto G 2nd Gen (titan/thea)" > $devicedir/device.txt;;
esac;
echo -e "Version: $version" > $devicedir/version.txt;
cd $maindir/common;
zip -r9 $outdir/$zipname.zip . > /dev/null;
cd $devicedir;
zip -r9 $outdir/$zipname.zip * > /dev/null;