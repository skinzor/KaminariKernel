#!/bin/bash

# Variables
sequence=`seq 1 100`;
numjobs=0;
this="KaminariKernel";

# Set up the cross-compiler
export PATH=$HOME/Toolchains/Linaro-5.3-Generic/bin:$PATH;
export ARCH=arm;
export SUBARCH=arm;
export CROSS_COMPILE=arm-linux-gnueabihf-;

# Clear the screen, bud!
clear;

# Output some basic info
echo -e "Building KaminariKernel...";

while read -p "Do you wanna clean everything (generated files, etc.)? (Y/N) " clean; do
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

while read -p "Do you wanna specify a release/version number? (Just press enter if you don't.) " rel; do
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
				version=`date "+%Y%m%d.%H%M%S"`;
				break;;
			*)
				break;;
		esac;
	fi;
	break;
done;

while read -p "How many parallel jobs do you wanna use? (Default is 4.) " numjobs; do
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
	
echo -e "Build started on: `date +"%A, %d %B %Y @ %H:%M:%S %Z (GMT %:z)"`";
			
# Build the kernel
make peregrine_defconfig;

if [ "$jobs" != "0" ]; then
	make -j$jobs;
else
	make;
fi;

# Tell when the build was finished
echo -e "Build finished on: `date +"%A, %d %B %Y @ %H:%M:%S %Z (GMT %:z)"`\n";

# Make the zip dir if it doesn't exist
if [ ! -d ../Zip_Stock_Peregrine_Overclock ]; then 
	mkdir ../Zip_Stock_Peregrine_Overclock;
fi;

# Make the modules dir if it doesn't exist
if [ ! -d ../Zip_Stock_Peregrine_Overclock/modules ]; then mkdir ../Zip_Stock_Peregrine_Overclock/modules; fi;

# Make the release dir if it doesn't exist
if [ ! -d ../Out_Stock_Peregrine_Overclock ]; then mkdir ../Out_Stock_Peregrine_Overclock; fi;

# Remove previous modules
if [ -d ../Zip_Stock_Peregrine_Overclock/modules ]; then rm -rf ../Zip_Stock_Peregrine_Overclock/modules/*; fi;

# Make wi-fi module dir
if [ ! -d ../Zip_Stock_Peregrine_Overclock/modules/pronto ]; then mkdir ../Zip_Stock_Peregrine_Overclock/modules/pronto; fi;

# Modules
find ./ -type f -name '*.ko' -exec cp -f {} ../Zip_Stock_Peregrine_Overclock/modules/ \;
mv ../Zip_Stock_Peregrine_Overclock/modules/wlan.ko ../Zip_Stock_Peregrine_Overclock/modules/pronto/pronto_wlan.ko;

# Copy zImage-dtb
cp -f arch/arm/boot/zImage-dtb ../Zip_Stock_Peregrine_Overclock/;
ls -l ../Zip_Stock_Peregrine_Overclock/zImage-dtb;
cd ../Zip_Stock_Peregrine_Overclock;

# Set zip name
zipname="Kaminari_"$version"_Peregrine_Overclock";

# Make the zip
echo -e "Version: $version" > version.txt;
zip -r9 $zipname.zip * > /dev/null;
mv $zipname.zip ../Out_Stock_Peregrine_Overclock;