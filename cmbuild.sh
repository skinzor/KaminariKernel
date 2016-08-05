#!/bin/bash

# Variables
sequence=`seq 1 100`;
numjobs=0;
this="KaminariCM";

# Set up the cross-compiler
export PATH=$HOME/Toolchains/Linaro-4.9-CortexA7/bin:$PATH;
export ARCH=arm;
export SUBARCH=arm;
export CROSS_COMPILE=arm-cortex_a7-linux-gnueabihf-;

# Clear the screen, bud!
clear;

# Output some basic info
echo -e "Building KaminariKernel (CyanogenMod version)...\n";

devicestr="Which device do you want to build for?
1. Moto G (1st gen, GSM/CDMA) (falcon)
2. Moto G (1st gen, LTE) (peregrine)
3. Moto G (2nd gen, GSM/LTE) (titan/thea) ";

while read -p "$devicestr" dev; do
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
				export LOCALVERSION="-KaminariCM-$rel";
				version=$rel;
			fi;
		done;
	elif [[ `echo $rel | gawk --re-interval "/^v/"` ]]; then
		echo -e "Version number: $rel\n";
		export LOCALVERSION="-KaminariCM-$rel";
		version=$rel;
	else
		case $rel in
			"" | " " )
				echo -e "No release number specified. Assuming test/nightly build.\n";
				export LOCALVERSION="-KaminariCM-Testing";
				version=`date --utc "+%Y%m%d.%H%M%S"`;
				break;;
			*)
				echo -e "Localversion set as: $rel\n";
				export LOCALVERSION="-KaminariCM-$rel";
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
			
# Build the kernel
make cm/"$defconfig"_defconfig;

if [ "$jobs" != "0" ]; then
	make -j$jobs;
else
	make;
fi;

# Tell when the build was finished
echo -e "Build finished on:\n`date +"%A, %d %B %Y @ %H:%M:%S %Z (GMT %:z)"`\n`date --utc +"%A, %d %B %Y @ %H:%M:%S %Z"`\n";

# Make the zip & out dirs if they don't exist
if [ ! -d ../Zip_Cm13_$name ] || [ ! -d ../Out_Cm13_$name ]; then 
	mkdir ../Zip_Cm13_$name;
	mkdir ../Out_Cm13_$name;
fi;

# Copy zImage-dtb
cp -f arch/arm/boot/zImage-dtb ../Zip_Cm13_$name/;
ls -l ../Zip_Cm13_$name/zImage-dtb;
cd ../Zip_Cm13_$name;

# Set zip name
zipname="KaminariCM13_"$version"_"$name;

# Make the zip
echo -e "Version: $version" > version.txt;
zip -r9 $zipname.zip * > /dev/null;
mv $zipname.zip ../Out_Cm13_$name/;