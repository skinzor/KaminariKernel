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
echo -e "Building Optimized Stock Kernel...";
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

# Clear the result of previous builds if $2 == clean
if [ $2 ]; then
	if [ $2 == "clean" ]; then
		echo -e "The output of previous builds will be removed.\n";
		make clean && make mrproper;
	fi;
fi;

# Build the kernel
make "$device"_defconfig;
if [ $3 ]; then
	make -j$3;
else
	make -j3;
fi;

zipdir="Zip_"$device2"_StockOpt";
outdir="Release_"$device2"_StockOpt";

# Make dirs if they don't exist
if [ ! -d ../$zipdir ]; then mkdir ../$zipdir; fi;
if [ ! -d ../$zipdir/modules ]; then mkdir ../$zipdir/modules; fi;
if [ ! -d ../$outdir ]; then mkdir ../$outdir; fi;

# Remove previous modules
if [ -d ../$zipdir/modules ]; then rm -rf ../$zipdir/modules/*; fi;

# Make dirs part 2
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
		zipname="OptStock-"$device2;
	;;
	*)
		zipname="OptStock-"$device2;
	;;
esac;

# Make the zip
zip -r9 $zipname.zip * > /dev/null;
mv $zipname.zip ../$outdir;
