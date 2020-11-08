#!/usr/bin/perl -w
use strict;
use warnings;
use feature 'state';
use Fcntl qw(SEEK_SET SEEK_CUR SEEK_END);
use Digest::CRC ();
use Digest::MD5 ();
use Getopt::Long qw(GetOptions);

# Patch the RKAF firmware image header to make the machine model be 'Hudl HT7S3' as
# the recovery program checks this when trying to flash the firmware from SD Card
# The RKAF file can be stand-alone or embedded in an RKFW wrapper.
# Originally we modified the machine model in the paramter file and allowed
# imgrepackrk to do this, but avoiding the change in the parameters block is
# adventageous as it removes one source of needing the device to reboot while
# flashing.

sub usage {
	my $exit_val = shift;

	print "\nUsage: patch-rkimg.pl [-v | --verbose] [-m <model> | --model <model>] <imgfile>\n\n";
	print "Performs some checks to ensure <imgfile> is a valid Rockchip firmware image, and\n";
	print "replaces the model name in the RKAF header with the provided <model>. Defaults to\n";
	print "'Hudl H7S3' if not provided.\n\n";

	exit $exit_val;
}

my $new_model='Hudl HT7S3';
my $verbose=0;
my $help=0;
GetOptions(
	"model|m=s" => \$new_model,
	"verbose|v" => \$verbose,
	"help|h|?"  => \$help,
) or usage(1);
usage(0) if $help;

my $num_args = $#ARGV + 1;
die "Wrong number of command line arguements (Got: $num_args, expected 1)" if $num_args != 1;
my ($file) = @ARGV;

# TODO: refactor all the reading/writing of the img file to do the CRC and MD5 checksums so that the
# data is only read twice (as oppsed to more than 4 times currently).  If we want speed, then add
# an option to remove the CRC/MD5 checks and it should be possible to read the data only once.
# might also want an option to allow us to specify a different output file and not touch the
# input file?
#
# TODO: It would be reasonably straightforward to extend this to extract and pack the image files,
# allowing us to remove our dependancy on imgrepackrk.

open(my $fh, "+<", $file) or die "Failed to open '$file' [$!]";
binmode $fh;
my $size = sysseek($fh, 0, SEEK_END) or die "Failed to seek to end of file [$!]";

#Check the first 4 bytes are RKAF or RKFW
# If RKFW, then read header offest, and find RKAF at that offset
# Once at RKAF write 'Hudl HT7S3' at Machine Model position
# Following the code from https://github.com/Nu3001/bootable_recovery/blob/3d0b52516c9f4fc82a2c487da257d014e5b765d8/rkimage.cpp#L425

# RKFW header

my $has_rkfw = 0;
my $buf;
my $chunk_size = 32<<9;

sysseek($fh, 0, SEEK_SET) or die "Failed to seek to start of file [$!]";
sysread($fh, $buf, 512) or die "Read failed [$!]";

my ($rkfw_sig, $fw_offset, $fw_size) = unpack("a4 x29 V V", $buf);

if ( $rkfw_sig ne 'RKFW' ) {
	$fw_offset = 0;
	$fw_size = 0;
}
else {
	$has_rkfw = 1;
	printf("%1\$s: fw_offset: %2\$d(%2\$#.6x) fw_zise: %3\$d(%3\$#.6x)\n", $rkfw_sig, $fw_offset, $fw_size) if $verbose;

	# Check MD5
	my $md5 = Digest::MD5->new();
	my $remain = $size - 32;
	sysseek($fh, 0, SEEK_SET) or die "Failed to seek to start of file [$!]";

	while ($remain > 0) {
		my $read_size = $remain > $chunk_size ? $chunk_size : $remain;

		my $read = sysread($fh, $buf, $read_size);
		die "Read error: $!" if not defined $read;
		die "Unexpected end of file" if $read == 0;

		$md5->add($buf);

		$remain -= $read;
	}

	sysread($fh, $buf, 32);
	my $expected_md5 = unpack "Z32", $buf;

	if ($md5->hexdigest ne $expected_md5) {
		die sprintf("MD5 Error\nCalculated: %s\nExpected:   %s", $md5->hexdigest, $expected_md5);
	}
	else {
		print "RKFW MD5 Check passed (MD5: $expected_md5)\n" if $verbose;
	}
}

sysseek($fh, $fw_offset, SEEK_SET) or die "Failed to seek to start of RKAF [$!]";
sysread($fh, $buf, 512) or die "Read failed: [$!]";

# RKAF header
# Details from: https://github.com/Nu3001/bootable_recovery/blob/3d0b52516c9f4fc82a2c487da257d014e5b765d8/rkimage.h#L33
#
# typedef struct tagRKIMAGE_HDR
#{
#	unsigned int tag;
#	unsigned int size;
#	char machine_model[MAX_MACHINE_MODEL];  [#define MAX_MACHINE_MODEL		64]
#	char manufacturer[MAX_MANUFACTURER];    [#define MAX_MANUFACTURER		60]
#	unsigned int version;
#	int item_count;
#	RKIMAGE_ITEM item[MAX_PACKAGE_FILES];
#}RKIMAGE_HDR;
#

my ($rkaf_sig, $rkaf_size, $model, $manu) = unpack("a4 V Z64 Z60", $buf);

if ( $rkaf_sig ne 'RKAF' ) {
	die "No RKAF container found";
}

printf("%1\$s: size: %2\$d(%2\$#.6x) fw_offset: %3\$d(%3\$#.6x) fw_zise: %4\$d(%4\$#.6x)\n", $rkaf_sig, $rkaf_size, $fw_offset, $fw_size) if $verbose;

# Check the CRC32

sysseek($fh, $fw_offset, SEEK_SET) or die "Failed to seek to start of RKAF [$!]";

my $crc = 0;
my $remain = $rkaf_size;

while ($remain > 0) {
	my $read_size = $remain > $chunk_size ? $chunk_size : $remain;

	my $read = sysread($fh, $buf, $read_size);
	die "Read error: $!" if not defined $read;
	die "Unexpected end of file" if $read == 0;

	$crc = rkcrc32($buf, $crc);

	$remain -= $read;
}

sysread($fh, $buf, 4);
my $expected_crc = unpack "V", $buf;

if ($crc != $expected_crc) {
	die sprintf("CRC Error (Calculated: %#08x Expected: %#08x", $crc, $expected_crc);
}
else {
	printf "RKAF CRC32 Check passed (CRC %#08x)\n", $expected_crc if $verbose;
}

# All seems good, so make the update, if needed
if ($model ne $new_model) {
	print "replacing '$model' with '$new_model'\n";

	# Write the new model
	sysseek($fh, $fw_offset + 8 , SEEK_SET) or die "Failed to seek to the model offset [$!]";

	# Ensure the new model is null terminated and write
	# enough nulls to overwrite the old model
	# TODO: should check new length doesn't exceed space in header
	my $diff = length($model) - length($new_model);
	$diff < 0 ? $diff=1 : $diff++;
	$new_model .= "\0" x $diff;

	if ( syswrite($fh, $new_model, length($new_model)) != length($new_model) ) {
		die "write failed [$!]";
	}
	
	# Fix the RKAF CRC
	sysseek($fh, $fw_offset, SEEK_SET) or die;

	my $crc = 0;
	my $remain = $rkaf_size;

	while ($remain > 0) {
		my $read_size = $remain > $chunk_size ? $chunk_size : $remain;

		my $read = sysread($fh, $buf, $read_size);
		die "Read error: $!" if not defined $read;
		die "Unexpected end of file" if $read == 0;

		$crc = rkcrc32($buf, $crc);

		$remain -= $read;
	}

	$buf = pack "V", $crc;
	if ( syswrite($fh, $buf, 4) != 4 ) {
		die "write failed [$!]";
	}

	printf "RKAF CRC32 Updated (CRC %#08x)\n", $crc if $verbose;
	
	# Fix the RKFW MD5
	if($has_rkfw) {
		my $md5 = Digest::MD5->new();
		my $remain = $size - 32;
		sysseek($fh, 0, SEEK_SET) or die "Failed to seek to start of file [$!]";

		while ($remain > 0) {
			my $read_size = $remain > $chunk_size ? $chunk_size : $remain;

			my $read = sysread($fh, $buf, $read_size);
			die "Read error: $!" if not defined $read;
			die "Unexpected end of file" if $read == 0;

			$md5->add($buf);

			$remain -= $read;
		}

		if ( syswrite($fh, $md5->hexdigest, 32) != 32 ) {
			die "write failed [$!]";
		}

		printf "RKFW MD5 Updated (MD5: %s)\n", $md5->hexdigest if $verbose;
	}

	
}

close($fh);
exit 0;

# Make use of Digest::CRC to provide the code for doing RockChip CRC32
# calculations, but it needs to be a non-standard config, so set it
# up with: width=32 xorout=0x00000000 refout=no, refin=no, cont=0 poly=0x04c10db7
# Calculate the table only once to eliminate the overhead of calcualating on
# each call to _crc (about 10% faster when passing 16k blocks)
sub rkcrc32 {
        my ($message,$init) = @_;
	state $table = Digest::CRC::_tabinit(32,0x04c10db7,0);
        Digest::CRC::_crc($message,32,$init,0,0,0,0,$table);
}
