#!/bin/bash

# Variables
sequence=`seq 1 100`;
this="KaminariKernel";

# Set up the cross-compiler (pt. 1)
export ARCH=arm;
export SUBARCH=arm;

# Clear the screen, bud!
clear;

# Variables for bold & normal text
bold=`tput bold`;
normal=`tput sgr0`;

# Let's start...
echo -e "Building KaminariKernel (CM14.1)...\n";

toolchainstr="Which cross-compiler toolchain do you want to use?
1. Linaro GCC 4.9
2. Google/AOSP GCC 4.8
3. Google/AOSP GCC 4.9 
4. Uber GCC 4.9 (default) ";

devicestr="Which device do you want to build for?
1. Moto G (1st gen, GSM/CDMA) (falcon)
2. Moto G (1st gen, LTE) (peregrine) ";

hpstr="Which hotplug driver should this build use?
1. MPDecision (default)
2. AutoSMP ";

cleanstr="Do you want to remove everything from the last build? (Y/N)

You ${bold}MUST${normal} do this if: 
1. You have changed toolchains;
2. You have built a CM Standard version and will now build a CM Alternative (or vice-versa). ";

zipstr="Which installation type do you want to use?
1. AnyKernel (recommended/default)
2. Classic (boot.img) (Use only if you have problems with AnyKernel) ";

selstr="Do you want to force SELinux to stay in Permissive mode?
Only say Yes if you're aware of the security risks this may introduce! (Y/N) ";

# Select which toolchain should be used & Set up the cross-compiler (pt. 2)
while read -p "$toolchainstr" tc; do
	case $tc in
		"1")
			echo -e "Selected toolchain: Linaro GCC 4.9\n";
			export PATH=$HOME/Toolchains/Linaro-4.9-CortexA7/bin:$PATH;
			export CROSS_COMPILE=arm-cortex_a7-linux-gnueabihf-;
			break;;
		"2")
			echo -e "Selected toolchain: Google/AOSP GCC 4.8\n";
			export PATH=$HOME/Toolchains/Google-4.8-Generic/bin:$PATH;
			export CROSS_COMPILE=arm-eabi-;
			break;;

		"3")
			echo -e "Selected toolchain: Google/AOSP GCC 4.9\n";
			export PATH=$HOME/Toolchains/Google-4.9-Generic/bin:$PATH;
			export CROSS_COMPILE=arm-linux-androideabi-;
			break;;
		"4" | "" | " ")
			echo -e "Selected toolchain: Uber GCC 4.9\n";
			export PATH=$HOME/Toolchains/Uber-4.9-Generic/bin:$PATH;
			export CROSS_COMPILE=arm-eabi-;
			break;;
			
		*)
			echo -e "\nInvalid option. Try again.\n";;
	esac;
done;			
		

# Select which device the kernel should be built for
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
#		"3")
#			echo -e "Selected device: Moto G 2nd Gen (GSM/LTE) (titan/thea)\n"
#			device="titan";
#			break;;
		*)
			echo -e "\nInvalid option. Try again.\n";;
	esac;
done;

# Select which hotplug should be used
while read -p "$hpstr" hp; do
	case $hp in
		"1" | "" | " ")
			echo -e "Selected driver: MPDecision\n"
			hp="mpdec";
			break;;
		"2")
			echo -e "Selected driver: AutoSMP\n"
			hp="asmp";
			break;;
		*)
			echo -e "\nInvalid option. Try again.\n";;
	esac;
done;		
	
		
# Clean everything via `make mrproper`.
# Recommended if there were extensive changes to the source code.
while read -p "$cleanstr" clean; do
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

# (Optional) Specify a release number.
# A "Testing" label will be used if this is left blank.
while read -p "Do you want to specify a release/version number? (Just press enter if you don't.) " rel; do
	if [[ `echo $rel | gawk --re-interval "/^R/"` != "" ]]; then
		for i in $sequence; do
			if [ `echo $rel | gawk --re-interval "/^R$i/"` ]; then
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
				echo -e "No release number was specified. Labelling this build as testing/nightly.\n";
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

# Select which installation type will be used
while read -p "$zipstr" zipmode; do
	case $zipmode in
		"1" | "" | " ")
			zipmode="ak";
			echo -e "Selected installation type: AnyKernel\n";
			break;;
		"2")
			zipmode="classic";
			echo -e "Selected installation type: Classic\n";
			break;;
		*)
			echo -e "\nInvalid option. Try again.\n";;
	esac;
done;

# Determine if we should force SELinux permissive mode
while read -p "$selstr" forceperm; do
	case $forceperm in
		"y" | "Y" | "yes" | "Yes")
			echo -e "${bold}WARNING: SELinux will stay in Permissive mode at all times. You won't be able to change it to Enforcing.\nBe careful.\n${normal}";
			forceperm="Y";
			break;;
		"n" | "N" | "no" | "No" | "" | " ")
			echo -e "SELinux will remain configurable (Android will always default it to Enforcing).\n";
			forceperm="N";			
			break;;
		*)
			echo -e "\nInvalid option. Try again.\n";;
	esac;
done;
	
# Tell exactly when the build started
echo -e "Build started on:\n`date +"%A, %d %B %Y @ %H:%M:%S %Z (GMT %:z)"`\n`date --utc +"%A, %d %B %Y @ %H:%M:%S %Z"`\n";
starttime=`date +"%s"`;
			
# Remove all DTBs to avoid conflicts
rm -rf arch/arm/boot/*.dtb;
			
# Build the kernel
make cm/"$device"_defconfig;

# Permissive selinux? Edit .config
if [[ $forceperm = "Y" ]]; then
	sed -i s/"# CONFIG_SECURITY_SELINUX_FORCE_PERMISSIVE is not set"/"CONFIG_SECURITY_SELINUX_FORCE_PERMISSIVE=y"/ .config;
fi;

# AutoSMP? Also edit .config
if [[ $hp = "asmp" ]]; then
	sed -i s/"# CONFIG_ASMP is not set"/"CONFIG_ASMP=y"/ .config;
	sed -i s/"# CONFIG_CPU_BOOST is not set"/"CONFIG_CPU_BOOST=y"/ .config;
fi;

make -j4;

if [[ -f arch/arm/boot/zImage ]]; then
	echo -e "Code compilation finished on:\n`date +"%A, %d %B %Y @ %H:%M:%S %Z (GMT %:z)"`\n`date --utc +"%A, %d %B %Y @ %H:%M:%S %Z"`\n";
	maketime=`date +"%s"`;
	makediff=$(($maketime - $starttime));
	echo -e "Code compilation took: $(($makediff / 60)) minute(s) and $(($makediff % 60)) second(s).\n";
else
	echo -e "zImage not found. Kernel build failed. Aborting.\n";
	exit 1;
fi;

# Define directories (zip, out)
if [[ $zipmode = "ak" ]]; then
	maindir=$HOME/Kernel/Zip_CM_AK;
	outdir=$HOME/Kernel/Out_CM_AK/$device;
else
	maindir=$HOME/Kernel/Zip_CM_BootImg;
	outdir=$HOME/Kernel/Out_CM_BootImg/$device;
fi;
devicedir=$maindir/$device"_N";


# Make the zip and out dirs if they don't exist
if [ ! -d $maindir ] || [ ! -d $outdir ]; then
	mkdir -p $maindir && mkdir -p $outdir;
fi;


# Use zImage + dt.img
./bootimgtools/dtbToolCM -2 -s 2048 -o /tmp/dt.img -p scripts/dtc/ arch/arm/boot/;

if [[ $zipmode = "classic" ]]; then
	cmdline="androidboot.bootdevice=msm_sdcc.1 androidboot.hardware=qcom vmalloc=400M utags.blkdev=/dev/block/platform/msm_sdcc.1/by-name/utags"
	echo -e "Creating boot.img...";
	./bootimgtools/mkbootimg --kernel arch/arm/boot/zImage --ramdisk $maindir/prepacked_ramdisks/ramdisk_"$device".cpio.gz --board "" --base 0x00000000 \
	--kernel_offset 0x00008000 --ramdisk_offset 0x01000000 --tags_offset 0x00000100 \
	--cmdline "$cmdline" \
	--pagesize 2048 --dt /tmp/dt.img --output $devicedir/boot.img;
else # Just copy zImage and dt.img. AnyKernel will do the rest later.
	echo -e "Copying zImage & dt.img...";
	cp -f /tmp/dt.img $devicedir/;
	cp -f arch/arm/boot/zImage $devicedir/;
fi;

# Set the zip's name
if [[ $hp = "asmp" ]]; then
	if [[ $forceperm = "Y" ]]; then
		zipname="KaminariCMAlt_"$version"-N_"`echo "${device^}"`"_Permissive";
	else
		zipname="KaminariCMAlt_"$version"-N_"`echo "${device^}"`;
	fi;
else
	if [[ $forceperm = "Y" ]]; then
		zipname="KaminariCM_"$version"-N_"`echo "${device^}"`"_Permissive";
	else
		zipname="KaminariCM_"$version"-N_"`echo "${device^}"`;
	fi;
fi;

# Zip the stuff we need & finish
echo -e "Creating flashable ZIP...\n";
case $device in
	"falcon")
		echo -e "Device: Moto G 1st Gen (falcon)" > $devicedir/device.txt;;
	"peregrine")
		echo -e "Device: Moto G 1st Gen w/ LTE (peregrine)" > $devicedir/device.txt;;
	# "titan")
		# echo -e "Device: Moto G 2nd Gen (titan/thea)" > $devicedir/device.txt;;
esac;
if [[ $hp = "asmp" ]]; then
	echo -e "Version: $version-alt" > $devicedir/version.txt;
else
	echo -e "Version: $version" > $devicedir/version.txt;
fi;	
cd $maindir/common;
zip -r9 $outdir/$zipname.zip . > /dev/null;
cd $devicedir;
zip -r9 $outdir/$zipname.zip * > /dev/null;
echo -e "Done!"
# Tell exactly when the build finished
echo -e "Build finished on:\n`date +"%A, %d %B %Y @ %H:%M:%S %Z (GMT %:z)"`\n`date --utc +"%A, %d %B %Y @ %H:%M:%S %Z"`\n";
finishtime=`date +"%s"`;
finishdiff=$(($finishtime - $starttime));
echo -e "This build took: $(($finishdiff / 60)) minute(s) and $(($finishdiff % 60)) second(s).\n";


