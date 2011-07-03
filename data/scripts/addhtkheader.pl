#!/usr/bin/perl

# Copyright 2001-2008 Nagoya Institute of Technology, Department of Computer Science
# Copyright 2001-2008 Tokyo Institute of Technology, Interdisciplinary Graduate School of Science and Engineering

# This file is part of HTS-demo_CMU-ARCTIC-SLT-STRAIGHT-AR-decision-tree.
# See `License` for details of license and warranty.


if (@ARGV<5) {
   print "addhtkheader.pl sampling_rate frame_shift byte_per_frame HTK_feature_type infile\n";
   exit(0);
}

$samprate   = $ARGV[0];
$frameshift = $ARGV[1];
$byte       = $ARGV[2];
$type       = $ARGV[3];
$infile     = $ARGV[4];

# make HTK header
open(INPUT,"$infile") || die "Cannot open file: $infile";
@STAT = stat(INPUT);
read(INPUT,$DATA,$STAT[7]);
$nframe = $STAT[7]/$byte;
close(INPUT);

# number of frames in long
$NFRAME = pack("l", $nframe);

# frame shift in long
$frameshift = 10000000 * $frameshift/$samprate;
$FRAMESHIFT = pack("l", $frameshift);

# bytes of each frame in short
$BYTE = pack("s", $byte);

# HTK feature type in short
$TYPE = pack("s", $type);

# output header and data
print $NFRAME;
print $FRAMESHIFT;
print $BYTE;
print $TYPE;
print $DATA;

