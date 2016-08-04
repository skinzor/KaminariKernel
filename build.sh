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
echo -e "Building KaminariKernel...";
echo -e "Device: Moto G (falcon)\n";

devicestr="Which device do you want to build for?
1. Moto G (1st gen, GSM/CDMA) (falcon)
2. Moto G (1st gen, LTE) (peregrine)
3. Moto G (2nd gen, GSM/LTE) (titan/thea)";

while read -p "$devicestr " dev; do
	case $dev in
		"1")
			echo -e "Selected device: Moto G GSM/CDMA (falcon)\n"
			defconfig="falcon";
			name="Falcon";
			break;;
		"2")
			echo -e "Selected device: Moto G LTE (peregrine)\n"
			defconfig="peregrine";
			name="Peregrine";
			break;;
		"3")
			echo -e "Selected device: Moto G 2nd Gen (GSM/LTE) (titan/thea)\n"
			defconfig="titan";
			name="Titan";
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
				version=`date "+%Y%m%d.%H%M%S"`;
				break;;
			*)
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
	
echo -e "Build started on: `date +"%A, %d %B %Y @ %H:%M:%S %Z (GMT %:z)"`";
			
# Build the kernel
make "$defconfig"_defconfig;

if [ "$jobs" != "0" ]; then
	make -j$jobs;
else
	make;
fi;

# Tell when the build was finished
echo -e "Build finished on: `date +"%A, %d %B %Y @ %H:%M:%S %Z (GMT %:z)"`\n";

# Make the zip dir if it doesn't exist
if [ ! -d ../Zip_CustomMM_$name ]; then 
	mkdir ../Zip_CustomMM_$name;
fi;

# Make the modules dir if it doesn't exist
if [ ! -d ../Zip_CustomMM_$name/modules ]; then mkdir ../Zip_CustomMM_$name/modules; fi;

# Make the release dir if it doesn't exist
if [ ! -d ../Out_CustomMM_$name ]; then mkdir ../Out_CustomMM_$name; fi;

# Remove previous modules
if [ -d ../Zip_CustomMM_$name/modules ]; then rm -rf ../Zip_CustomMM_$name/modules/*; fi;

# Make wi-fi module dir
if [ ! -d ../Zip_CustomMM_$name/modules/pronto ]; then mkdir ../Zip_CustomMM_$name/modules/pronto; fi;

# Modules
find ./ -type f -name '*.ko' -exec cp -f {} ../Zip_CustomMM_$name/modules/ \;
mv ../Zip_CustomMM_$name/modules/wlan.ko ../Zip_CustomMM_$name/modules/pronto/pronto_wlan.ko;

# Copy zImage-dtb
cp -f arch/arm/boot/zImage-dtb ../Zip_CustomMM_$name/;
ls -l ../Zip_CustomMM_$name/zImage-dtb;
cd ../Zip_CustomMM_$name;

# Set zip name
zipname="Kaminari_"$version"_"$name;

# Make the zip
echo -e "Version: $version" > version.txt;
zip -r9 $zipname.zip * > /dev/null;
mv $zipname.zip ../Out_CustomMM_$name;