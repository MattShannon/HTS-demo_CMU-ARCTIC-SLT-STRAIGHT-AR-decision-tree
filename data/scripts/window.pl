#!/usr/bin/perl

# Copyright 2011 Matt Shannon
# Copyright 2001-2008 Nagoya Institute of Technology, Department of Computer Science
# Copyright 2001-2008 Tokyo Institute of Technology, Interdisciplinary Graduate School of Science and Engineering

# This file is part of HTS-demo_CMU-ARCTIC-SLT-STRAIGHT-AR-decision-tree.
# See `License` for details of license and warranty.


if (@ARGV<3) {
   print "window.pl dimensionality infile winfile1 winfile2 ... \n";
   exit(0);
}

$ignorevalue = -1.0e+10;

# dimensionality of input vector
$dim = $ARGV[0];

# open infile as a sequence of static coefficients 
open(INPUT,"$ARGV[1]") || die "cannot open file : $ARGV[1]";
@STAT=stat(INPUT);
read(INPUT,$data,$STAT[7]);
close(INPUT);

$nwin = @ARGV-2;

$n = $STAT[7]/4;  # number of data
$T = $n/$dim;     # number of frames of original data


# load original data
@original = unpack("f$n",$data);  # original data must be stored in float, natural endian


# apply window
for($i=1;$i<=$nwin;$i++) {
   # load $i-th window coefficients
   open(INPUT,"$ARGV[$i+1]") || die "cannot open file : $ARGV[$i+1]";
   $data = <INPUT>;
   @win = split(' ',$data);
   $size = $win[0];   # size of this window

   if ($size % 2 != 1) {             
      die "Size of window must be 2*n + 1 and float"; 
   }

   $nlr = ($size-1)/2;
   $nlrLeft = -($size-1)/2;
   $nlrRight = ($size-1)/2;
   while ($win[$nlrRight+$nlr+1] == $ignorevalue) {
      $nlrRight--;
   }
   while ($win[$nlrLeft+$nlr+1] == $ignorevalue) {
      $nlrLeft++;
   }

   # calcurate $i-th coefficients
   for ($t=0; $t<$T; $t++) {
      for ($j=0; $j<$dim; $j++) {
         # check space boundary (ex. voiced/unvoiced boundary)
         $boundary = 0;
         for ($k=$nlrLeft; $k<=$nlrRight; $k++) {
            if ($t+$k>=0 && $t+$k<$T && $original[($t+$k)*$dim+$j] == $ignorevalue) {
               $boundary = 1;
            }
         }
         if ($boundary==0) {
            $transformed[$t*$nwin*$dim+$dim*($i-1)+$j] = 0.0;
            for ($k=$nlrLeft; $k<=$nlrRight; $k++) {
               if ($t+$k>=0 && $t+$k<$T) { 
                  $transformed[$t*$nwin*$dim+$dim*($i-1)+$j] += $win[$k+$nlr+1]*$original[($t+$k)*$dim+$j];
               }
            }
         }
         else {
            $transformed[$t*$nwin*$dim+$dim*($i-1)+$j] = $ignorevalue;
         }
      }
   }
}

$n = $n*$nwin;

$data = pack("f$n",@transformed);

print $data;

# end of delta.pl
