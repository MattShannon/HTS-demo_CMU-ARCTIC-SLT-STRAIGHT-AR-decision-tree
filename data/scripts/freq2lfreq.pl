#!/usr/bin/perl

# Copyright 2001-2008 Nagoya Institute of Technology, Department of Computer Science
# Copyright 2001-2008 Tokyo Institute of Technology, Interdisciplinary Graduate School of Science and Engineering

# This file is part of HTS-demo_CMU-ARCTIC-SLT-STRAIGHT-AR-decision-tree.
# See `License` for details of license and warranty.


open(INPUT,"$ARGV[0]") || die "cannot open file : $ARGV[0]";;

@STAT=stat(INPUT);
read(INPUT,$data,$STAT[7]);
close(INPUT);

$n = $STAT[7]/4;
@f0 = unpack("f$n",$data);

for ($i=0; $i<$n; $i++) {
   if ($f0[$i] == 0.0) {
      $lf0[$i] = -1.0E10;   # "-1.0E10" corresponds to log(0) in HTK  
   } else {
      $lf0[$i] = log($f0[$i]);
   }
}

$data = pack("f$n",@lf0);

print $data;

# end of freq2lfreq.pl
