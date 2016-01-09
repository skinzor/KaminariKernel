#!/bin/bash

# Variables
device="$1";
zipname="";

# Set up the cross-compiler
export PATH=$HOME/Toolchains/Linaro-5.2-A7/bin:$PATH;
export ARCH=arm;
export SUBARCH=arm;
export CROSS_COMPILE=arm-cortex_a7-linux-gnueabihf-;

# Output some basic info
echo -e "Building KaminariKernel...";
if [ $device == "falcon" ]; then
	echo -e "Device: Moto G (falcon)";
	device2="Falcon";
elif [ $device == "peregrine" ]; then
	echo -e "Device: Moto G 4G (peregrine)";
	device2="Peregrine";
else
	echo -e "Invalid device. Aborting.";
	exit 1;
fi;
if [ $2 ]; then
	if [ ! $2 == "clean" ]; then
		version="$2";		
		echo -e "Version: "$version"\n";
	else
		echo -e "No version number has been set. The build date & time will be used instead.\n";
	fi;
else
	echo -e "No version number has been set. The build date & time will be used instead.\n";
fi;

# Clear the result of previous builds if $2 (or $3) == clean
if [ $3 ]; then
	if [ $3 == "clean" ]; then
		echo -e "The output of previous builds will be removed.\n";
		make clean && make mrproper;
	fi;
elif [ $2 ]; then
	if [ $2 == "clean" ]; then
		echo -e "The output of previous builds will be removed.\n";
		make clean && make mrproper;
	fi;
fi;

# Build the kernel
make kaminari/"$device"_defconfig;
if [ $4 ]; then
	make -j$4;
elif [ $3 ]; then
	make -j$3;
else
	make -j3;
fi;

# Set the build date & time after it has been completed
builddate=`date +%Y%m%d.%H%M%S`;
builddate_full=`date +"%d %b %Y | %H:%M:%S %Z"`;

zipdir="zip_"$device;
outdir="release_"$device;

# Clone the git repo if the zip dir doesn't exist
if [ ! -d ../$zipdir ]; then
	git clone -b $device https://github.com/Kamin4ri/Custom_Anykernel ../$zipdir;
fi;

# Make the release dir if it doesn't exist
if [ ! -d ../$outdir ]; then mkdir ../$outdir; fi;

# Remove previous modules
if [ -d ../$zipdir/modules ]; then rm -rf ../$zipdir/modules/*; fi;

# Make wi-fi module dir
if [ ! -d ../$zipdir/modules/pronto ]; then mkdir ../$zipdir/modules/pronto; fi;

# Modules
find ./ -type f -name '*.ko' -exec cp -f {} ../$zipdir/modules/ \;
mv ../$zipdir/modules/wlan.ko ../$zipdir/modules/pronto/pronto_wlan.ko;

# Copy zImage-dtb
cp -f arch/arm/boot/zImage-dtb ../$zipdir/;
ls -l ../$zipdir/zImage-dtb;
cd ../$zipdir;

# Set zip name
case $version in
	"" | " ")
		# In case the version number hasn't been specified, use the build date and time instead.
		zipname="Kaminari_"$builddate"_"$device2;
	;;
	*)
		zipname="Kaminari_v"$version"_"$device2;
	;;
esac;

# Make the zip
if [ $version ]; then
	echo "Version: $version" > version.txt;
else
	echo "Build date and time: $builddate_full" > version.txt;
zip -r9 $zipname.zip * > /dev/null;
mv $zipname.zip ../$outdir;
