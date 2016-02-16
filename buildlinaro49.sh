#!/bin/bash

# Variables
device="$1";
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
	git checkout -q $device;
	cd ../$this;
fi;

# Output some basic info
echo -e "Building KaminariKernel...";
if [ "$device" = "falcon" ]; then
	echo -e "Device: Moto G (falcon)";
	device2="Falcon";
elif [ "$device" = "falcon_gpe" -o "$device" = "falcongpe" ]; then
	echo -e "Device: Moto G Google Play Edition (falcon_gpe)";
	device2="FalconGPE";
else
	echo -e "Invalid device. Aborting.";
	exit 1;
fi;

if [ "$2" ]; then
	if [ $2 = "clean_full" ]; then
		echo -e "No version number has been set. The build date & time will be used instead.\n";
		echo -e "The output of previous builds will be removed.\n";
		echo -e "Build started on: `date +"%A, %d %B %Y @ %H:%M:%S %Z (GMT %:z)"`\n";
		if [ "$3" ]; then
			echo -e "Number of parallel jobs: $3\n";
		else
			echo -e "Number of parallel jobs: 3\n";
		fi;
		make clean && make mrproper;
	elif [ "$2" = "clean" ]; then
		echo -e "No version number has been set. The build date & time will be used instead.\n";
		echo -e "The output of previous builds will be removed.\n";
		echo -e "Build started on: `date +"%A, %d %B %Y @ %H:%M:%S %Z (GMT %:z)"`\n";
		if [ $3 ]; then
			echo -e "Number of parallel jobs: $3\n";
		else
			echo -e "Number of parallel jobs: 3\n";
		fi;
		make clean;
	else
		if [ "$2" != "none" ]; then
			version="$2";
			echo -e "Version: "$version"\n";
			if [ $3 ]; then
				if [ $3 = "clean_full" ]; then
					echo -e "The output of previous builds will be removed.\n";
					echo -e "Build started on: `date +"%A, %d %B %Y @ %H:%M:%S %Z (GMT %:z)"`\n";
					if [ $4 ]; then
						echo -e "Number of parallel jobs: $4\n";
					else
						echo -e "Number of parallel jobs: 4\n";
					fi;
					make clean && make mrproper;
				elif [ $3 = "clean" ]; then
					echo -e "The output of previous builds will be removed.\n";
					echo -e "Build started on: `date +"%A, %d %B %Y @ %H:%M:%S %Z (GMT %:z)"`\n";
					if [ $4 ]; then
						echo -e "Number of parallel jobs: $4\n";
					else
						echo -e "Number of parallel jobs: 4\n";
					fi;
					make clean;
				fi;
			fi;
		else
			echo -e "No version number has been set. The build date & time will be used instead.\n";
			echo -e "Build started on: `date +"%A, %d %B %Y @ %H:%M:%S %Z (GMT %:z)"`\n";
			if [ $3 ]; then
				echo -e "Number of parallel jobs: $3\n";
			else
				echo -e "Number of parallel jobs: 4\n";
			fi;
		fi;
	fi;
else
	echo -e "No version number has been set. The build date & time will be used instead.\n";
	echo -e "Build started on: `date +"%A, %d %B %Y @ %H:%M:%S %Z (GMT %:z)"`\n";
fi;

# Build the kernel
make kaminari/falcon_defconfig;

if [ "$2" = "clean" -o "$2" = "clean_full" ]; then
	if [ $3 ]; then	
		make -j$3;
	else
		make -j4;
	fi;
else
	if [ $4 ]; then	
		make -j$4;
	else
		make -j4;
	fi;
fi;

# Tell when the build was finished
echo -e "Build finished on: `date +"%A, %d %B %Y @ %H:%M:%S %Z (GMT %:z)"`\n";
	
# Set the build date & time after it has been completed
builddate=`date +%Y%m%d.%H%M%S`;
builddate_full=`date +"%d %b %Y | %H:%M:%S %Z"`;

zipdir="zip_"$device;
outdir="release_"$device;

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
fi;
zip -r9 $zipname.zip * > /dev/null;
mv $zipname.zip ../$outdir;
