#!/bin/bash

# Variables
device="$1";
this="KaminariKernel";

# Set up the cross-compiler
export PATH=$HOME/Toolchains/Linaro-5.2-A7/bin:$PATH;
export ARCH=arm;
export SUBARCH=arm;
export CROSS_COMPILE=arm-cortex_a7-linux-gnueabihf-;

# Clone the custom anykernel repo
if [ ! -d ../Custom_AnyKernel ]; then
	echo -e "Custom AnyKernel not detected. Cloning git repository...\n";	
	git clone -q -b $device"_stk" https://github.com/Kamin4ri/Custom_AnyKernel ../Custom_AnyKernel;
else
	cd ../Custom_AnyKernel;
	git checkout -q $device"_stk";
	cd ../$this;
fi;

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

if [ $2 ]; then
	if [ $2 == "clean" ]; then
		echo -e "No version number has been set. The build date & time will be used instead.\n";
		echo -e "The output of previous builds will be removed.\n";
		if [ $3 ]; then
			echo -e "Number of parallel jobs: $3\n";
		else
			echo -e "Number of parallel jobs: 3\n";
		fi;		
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
	

# Set the build date & time after it has been completed
builddate=`date +%Y%m%d.%H%M%S`;
builddate_full=`date +"%d %b %Y | %H:%M:%S %Z"`;

zipdir="zip_"$device"_stk";
outdir="release_"$device"_stk";

# Make the zip dir if it doesn't exist
if [ ! -d ../$zipdir ]; then
	mkdir ../$zipdir;	
	cp -rf ../Custom_AnyKernel/* ../$zipdir;
fi;

# Make the modules dir if it doesn't exist
if [ ! -d ../$zipdir/modules ]; then mkdir ../$zipdir/modules; fi;

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
zipname="OptimizedStk_"$builddate"_"$device2;

# Make the zip
echo "Build date and time: $builddate_full" > version.txt;
zip -r9 $zipname.zip * > /dev/null;
mv $zipname.zip ../$outdir;
