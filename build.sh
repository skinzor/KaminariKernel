#!/bin/bash

# Variables
sequence=`seq 1 100`;
numjobs=0;
this="KaminariKernel";

# Set up the cross-compiler
export PATH=$HOME/Toolchains/Linaro-4.9-A7/bin:$PATH;
export ARCH=arm;
export SUBARCH=arm;
export CROSS_COMPILE=arm-cortex_a7-linux-gnueabihf-;

# Clone the custom anykernel repo
if [ ! -d ../Custom_AnyKernel ]; then
	echo -e "Custom AnyKernel not detected. Cloning git repository...\n";	
	git clone -q -b $device https://github.com/Kamin4ri/Custom_AnyKernel ../Custom_AnyKernel;
else
	cd ../Custom_AnyKernel;
	git checkout -q falcon;
	cd ../$this;
fi;

# Output some basic info
echo -e "Building KaminariKernel...";

if [ $1 ]; then
	case $1 in
		"clean")
			echo -e "All compiled files from previous builds will be removed.\n";
			make clean;
			;;
		"clean_full" | "cleanfull" | "clean_all" | "cleanall" ) 
			echo -e "The configuration file, dependencies and all compiled files from previous builds will be removed.\n";
			make mrproper;
			;;
		*)
			for i in $sequence; do
				if [ $1 = $i ]; then
					numjobs=$1;
				fi;
			done;
			;;
	esac;
fi;
					
echo -e "Build started on: `date +"%A, %d %B %Y @ %H:%M:%S %Z (GMT %:z)"`\nNumber of parallel jobs: $numjobs\n";
			
# Build the kernel
make falcon_defconfig;

if [ $numjobs != 0 ]; then
	make -j$numjobs;
else
	make;
fi;

# Tell when the build was finished
echo -e "Build finished on: `date +"%A, %d %B %Y @ %H:%M:%S %Z (GMT %:z)"`\n";
	
# Set the build date & time after it has been completed
builddate=`date +%Y%m%d.%H%M%S`;
builddate_full=`date +"%d %b %Y | %H:%M:%S %Z"`;

# Make the zip dir if it doesn't exist
if [ ! -d ../zip_falcon ]; then 
	mkdir ../zip_falcon;
	cp -rf ../Custom_AnyKernel/* ../zip_falcon;
fi;

# Make the modules dir if it doesn't exist
if [ ! -d ../zip_falcon/modules ]; then mkdir ../zip_falcon/modules; fi;

# Make the release dir if it doesn't exist
if [ ! -d ../release_falcon ]; then mkdir ../release_falcon; fi;

# Remove previous modules
if [ -d ../zip_falcon/modules ]; then rm -rf ../zip_falcon/modules/*; fi;

# Make wi-fi module dir
if [ ! -d ../zip_falcon/modules/pronto ]; then mkdir ../zip_falcon/modules/pronto; fi;

# Modules
find ./ -type f -name '*.ko' -exec cp -f {} ../zip_falcon/modules/ \;
mv ../zip_falcon/modules/wlan.ko ../zip_falcon/modules/pronto/pronto_wlan.ko;

# Copy zImage-dtb
cp -f arch/arm/boot/zImage-dtb ../zip_falcon/;
ls -l ../zip_falcon/zImage-dtb;
cd ../zip_falcon;

# Set zip name
zipname="Kaminari_"$builddate"_Falcon";

# Make the zip
echo "Build date and time: $builddate_full" > version.txt;
zip -r9 $zipname.zip * > /dev/null;
mv $zipname.zip ../release_falcon;
