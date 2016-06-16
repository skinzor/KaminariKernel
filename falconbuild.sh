#!/bin/bash

# Variables
sequence=`seq 1 100`;
numjobs=0;
this="ThunarKernel";

# Set up the cross-compiler
export PATH=$HOME/Toolchains/Linaro-5.3-Generic/bin:$PATH;
export ARCH=arm;
export SUBARCH=arm;
export CROSS_COMPILE=arm-linux-gnueabihf-;

# Clear the screen, bud!
clear;

# Output some basic info
echo -e "Building Thunar Kernel...";

if [ $1 ]; then
	case $1 in
		"clean" | "clean_full" | "cleanfull" | "clean_all" | "cleanall" ) 
			echo -e "Cleaning everything...\n";
			make --quiet mrproper;
			if [ $2 ]; then
				for i in $sequence; do
					if [ $2 = $i ]; then
						numjobs=$2;
					fi;
				done;
			fi;
			;;
		*)
			if [[ `echo $1 | gawk --re-interval "/r/"` != "" ]]; then
				version=`echo $1 | cut -d"r" -f2`;
				if [ $2 ]; then
					case $2 in
						"clean" | "clean_full" | "cleanfull" | "clean_all" | "cleanall" ) 
							echo -e "Cleaning everything...\n";
							make mrproper;
							;;
						*)
							for i in $sequence; do
								if [ $2 = $i ]; then
									numjobs=$2;
								fi;
							done;
							;;
					esac;
					if [ $3 ]; then
						for i in $sequence; do
							if [ $3 = $i ]; then
								numjobs=$3;
							fi;
						done;
					fi;
				fi;
			else
				for i in $sequence; do
					if [ $1 = $i ]; then
						numjobs=$1;
					fi;
				done;
			fi;
			;;				
	esac;
fi;

if [ $version ] && [ "$version" != "" ]; then
	echo -e "Release: R$version\n";
else
	echo -e "No release number specified. Assuming nightly build.";
fi;
	

echo -e "Build started on: `date +"%A, %d %B %Y @ %H:%M:%S %Z (GMT %:z)"`";
[ $numjobs != 0 ] && echo -e "Number of parallel jobs: $numjobs";
			
# Build the kernel
make falcon_defconfig;

if [ $numjobs ] && [ $numjobs != 0 ]; then
	make -j$numjobs;
else
	make -j4;
fi;

# Tell when the build was finished
echo -e "Build finished on: `date +"%A, %d %B %Y @ %H:%M:%S %Z (GMT %:z)"`\n";
	
# Set the build date & time after it has been completed
builddate=`date +%Y%m%d.%H%M%S`;
builddate_full=`date +"%d %b %Y | %H:%M:%S %Z"`;

# Make the zip dir if it doesn't exist
if [ ! -d ../Zip_Stock_Falcon ]; then 
	mkdir ../Zip_Stock_Falcon;
fi;

# Make the modules dir if it doesn't exist
if [ ! -d ../Zip_Stock_Falcon/modules ]; then mkdir ../Zip_Stock_Falcon/modules; fi;

# Make the release dir if it doesn't exist
if [ ! -d ../Out_Stock_Falcon ]; then mkdir ../Out_Stock_Falcon; fi;

# Remove previous modules
if [ -d ../Zip_Stock_Falcon/modules ]; then rm -rf ../Zip_Stock_Falcon/modules/*; fi;

# Make wi-fi module dir
if [ ! -d ../Zip_Stock_Falcon/modules/pronto ]; then mkdir ../Zip_Stock_Falcon/modules/pronto; fi;

# Modules
find ./ -type f -name '*.ko' -exec cp -f {} ../Zip_Stock_Falcon/modules/ \;
mv ../Zip_Stock_Falcon/modules/wlan.ko ../Zip_Stock_Falcon/modules/pronto/pronto_wlan.ko;

# Copy zImage-dtb
cp -f arch/arm/boot/zImage-dtb ../Zip_Stock_Falcon/;
ls -l ../Zip_Stock_Falcon/zImage-dtb;
cd ../Zip_Stock_Falcon;

# Set zip name
if [ $version ] && [ "$version" != "" ]; then
	zipname="Thunar_v"$version"_Falcon";
else
	zipname="Thunar_"$builddate"_Falcon";
fi;

# Make the zip
if [ $version ] && [ "$version" != "" ]; then
	echo -e "Version: $version" > version.txt && echo -e "Build date and time: $builddate_full" > builddate.txt;
else
	[ -e version.txt ] && rm version.txt;	
	echo -e "Build date and time: $builddate_full" > builddate.txt;
fi;
zip -r9 $zipname.zip * > /dev/null;
mv $zipname.zip ../Out_Stock_Falcon;