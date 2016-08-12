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

# Variables for bold & normal text
bold=`tput bold`;
normal=`tput sgr0`;

# Let's start...
echo -e "Building KaminariKernel...\n";

devicestr="Which device do you want to build for?
1. Moto G (1st gen, GSM/CDMA) (falcon)
2. Moto G (1st gen, LTE) (peregrine)
3. Moto G (2nd gen, GSM/LTE) (titan/thea) ";

romstr="Which ROM do you want to build for?
1. Motorola Stock / Identity Crisis 6.0
2. AOSP 6.0.x / CyanogenMod 13 and derivatives ";

zipstr="Which installation type do you want to use?
1. AnyKernel (recommended)
2. Classic (boot.img) (Use if you have problems with AK - or if you just prefer old school)

${bold}Note:${normal} Classic mode is not yet available for AOSP/CM.
If you choose it anyway, AnyKernel will be automatically selected. ";

selstr="Do you want to force SELinux to stay in Permissive mode?
Only say Yes if you're aware of the possible security risks this may introduce! (Y/N) ";

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
		"3")
			echo -e "Selected device: Moto G 2nd Gen (GSM/LTE) (titan/thea)\n"
			device="titan";
			break;;
		*)
			echo -e "\nInvalid option. Try again.\n";;
	esac;
done;

# Select which ROM the kernel should be built for
while read -p "$romstr" rom; do
	case $rom in
		"1")
			echo -e "Selected ROM: Motorola Stock / IDCrisis 6.0\n"
			rom="stock";
			break;;
		"2")
			echo -e "Selected ROM: AOSP / CM13 & derivatives\n"
			rom="cm";
			break;;
		*)
			echo -e "\nInvalid option. Try again.\n";;
	esac;
done;		
	
		
# Clean everything via `make mrproper`.
# Recommended if there were extensive changes to the source code.
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

# Select how many parallel CPU jobs should be used.
# The ideal number is 2x the number of CPU cores.
# E.g. for a quad-core CPU, the ideal would be 8 jobs, and so on.
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

# Select which installation type will be used
while read -p "$zipstr" zipmode; do
	case $zipmode in
		"1")
			zipmode="ak";
			echo -e "Selected installation type: AnyKernel\n";
			break;;
		"2")
			if [[ $rom = "stock" ]]; then
				zipmode="classic";
				echo -e "Selected installation type: Classic\n";
			else
				zipmode="ak";
				echo -e "Didn't I already say that Classic mode isn't available for CM right now? We're gonna use AnyKernel.\nEnd of story.\n";
			fi;
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
			
# Remove all DTBs to avoid conflicts
rm -rf arch/arm/boot/*.dtb;
			
# Build the kernel
if [[ $rom = "stock" ]]; then
	make "$device"_defconfig;
else
	make cm/"$device"_defconfig;
fi;

if [[ $jobs != "0" ]]; then
	if [[ $forceperm = "Y" ]]; then
		make -j$jobs CONFIG_SECURITY_SELINUX_FORCE_PERMISSIVE=y;
	else
		make -j$jobs CONFIG_SECURITY_SELINUX_FORCE_PERMISSIVE=n;
	fi;
else
	if [[ $forceperm = "Y" ]]; then
		make CONFIG_SECURITY_SELINUX_FORCE_PERMISSIVE=y;
	else
		make CONFIG_SECURITY_SELINUX_FORCE_PERMISSIVE=n;
	fi;
fi;

# Define directories (zip, out)
if [[ $rom = "stock" ]]; then
	if [[ $zipmode = "ak" ]]; then
		maindir=$HOME/Kernel/Zip_CustomIdC_AK;
		outdir=$HOME/Kernel/Out_CustomIdC_AK/$device;
	else
		maindir=$HOME/Kernel/Zip_CustomIdC_BootImg;
		outdir=$HOME/Kernel/Out_CustomIdC_BootImg/$device;
	fi;
else
	if [[ $zipmode = "ak" ]]; then
		maindir=$HOME/Kernel/Zip_CM_AK;
		outdir=$HOME/Kernel/Out_CM_AK/$device;
	else
		maindir=$HOME/Kernel/Zip_CM_BootImg;
		outdir=$HOME/Kernel/Out_CM_BootImg/$device;
	fi;
fi;
devicedir=$maindir/$device;


# Make the zip and out dirs if they don't exist
if [ ! -d $maindir ] || [ ! -d $outdir ]; then
	mkdir -p $maindir && mkdir -p $outdir;
fi;

# [For stock/IDCrisis ROM only] Make the modules dir if it doesn't exist.
# Remove any previously built modules as well.
if [[ $rom = "stock" ]]; then
	if [[ $zipmode = "ak" ]]; then
		[ -d $devicedir/modules ] || mkdir -p $devicedir/modules;
		[ -d $devicedir/modules ] && rm -rf $devicedir/modules/*;
		[ -d $devicedir/modules/pronto ] || mkdir -p $devicedir/modules/pronto;
		moduledir=$devicedir/modules;
	else
		[ -d $devicedir/system/lib/modules ] || mkdir -p $devicedir/system/lib/modules;
		[ -d $devicedir/system/lib/modules ] && rm -rf $devicedir/system/lib/modules/*;	
		[ -d $devicedir/system/lib/modules/pronto ] || mkdir -p $devicedir/system/lib/modules/pronto;
		moduledir=$devicedir/system/lib/modules;
	fi;

	# Copy the modules
	echo -e "Copying kernel modules...\n";
	for mod in `find . -type f -name "*.ko"`; do
		cp -f $mod $moduledir/;
	done;
	# Move wi-fi module (wlan.ko) to modules/pronto & rename it to pronto_wlan.ko. This is very important!!
	# A symlink to it (named wlan.ko) will be created at installation time.
	mv $moduledir/wlan.ko $moduledir/pronto/pronto_wlan.ko;
fi;

# Use zImage + dt.img instead of using zImage-dtb. This is what AnyKernel does by default.
# This dt.img will also be used for classic mode.
# The difference is, while AnyKernel does all its magic on the phone itself, classic mode will
# do its job using the build machine (i.e. the computer), creating a boot.img from zImage, dt.img and a prepacked ramdisk.
# In classic mode, we just need to dd the boot.img to the device-specific boot partition, thus using less resources.
# AnyKernel, on the other hand, makes it easier to modify the kernel, especially the ramdisk.
echo -e "Creating dt.img..."
# Use dtbTool if building for the stock ROM; dtbToolCM if building for AOSP.
if [[ $rom = "stock" ]]; then
	./bootimgtools/dtbTool -s 2048 -o /tmp/dt.img -p scripts/dtc/ arch/arm/boot/;
else
	./bootimgtools/dtbToolCM -2 -s 2048 -o /tmp/dt.img -p scripts/dtc/ arch/arm/boot/;
fi;
echo -e "\n";

# Only create a boot.img if we're using classic mode.
if [[ $zipmode = "classic" ]]; then
	echo -e "Creating boot.img...";
	./bootimgtools/mkbootimg --kernel arch/arm/boot/zImage --ramdisk $maindir/packed_ramdisks/ramdisk_"$device".cpio.gz --board "" --base 0x00000000 \
	--kernel_offset 0x00008000 --ramdisk_offset 0x01000000 --tags_offset 0x00000100 \
	--cmdline "console=ttyHSL0,115200,n8 androidboot.console=ttyHSL0 androidboot.hardware=qcom user_debug=31 msm_rtb.filter=0x37 vmalloc=400M utags.blkdev=/dev/block/platform/msm_sdcc.1/by-name/utags movablecore=160M" \
	--pagesize 2048 --dt /tmp/dt.img --output $devicedir/boot.img;
else # Just copy zImage and dt.img. AnyKernel will do the rest later.
	echo -e "Copying zImage & dt.img...";
	cp -f /tmp/dt.img $devicedir/;
	cp -f arch/arm/boot/zImage $devicedir/;
fi;

# Set the zip's name
if [[ $rom = "stock" ]]; then
	if [[ $forceperm = "Y" ]]; then
		zipname="Kaminari_"$version"_"`echo "${device^}"`"_Permissive";
	else
		zipname="Kaminari_"$version"_"`echo "${device^}"`;
	fi;
else
	if [[ $forceperm = "Y" ]]; then
		zipname="KaminariCM_"$version"_"`echo "${device^}"`"_Permissive";
	else
		zipname="KaminariCM_"$version"_"`echo "${device^}"`;
	fi;
fi;

# Zip the stuff we need & finish
echo -e "Creating flashable ZIP...\n";
case $device in
	"falcon")
		echo -e "Device: Moto G 1st Gen (falcon)" > $devicedir/device.txt;;
	"peregrine")
		echo -e "Device: Moto G 1st Gen w/ LTE (peregrine)" > $devicedir/device.txt;;
	"titan")
		echo -e "Device: Moto G 2nd Gen (titan/thea)" > $devicedir/device.txt;;
esac;
echo -e "Version: $version" > $devicedir/version.txt;
cd $maindir/common;
zip -r9 $outdir/$zipname.zip . > /dev/null;
cd $devicedir;
zip -r9 $outdir/$zipname.zip * > /dev/null;
echo -e "Done!"
# Tell exactly when the build finished
echo -e "Build finished on:\n`date +"%A, %d %B %Y @ %H:%M:%S %Z (GMT %:z)"`\n`date --utc +"%A, %d %B %Y @ %H:%M:%S %Z"`\n";
