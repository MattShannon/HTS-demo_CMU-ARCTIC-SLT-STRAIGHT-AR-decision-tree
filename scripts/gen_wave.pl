#!/usr/bin/perl

$|=1;

if (@ARGV != 2) {
	print "usage: gen_wave.pl Config.pm GENDIR\n";
	exit(1);
}

require($ARGV[0]);


# File locations =========================
# data directory
$datdir = "$prjdir/data";


# =============================================================
# ===================== Main Program ==========================
# =============================================================

gen_wave($ARGV[1]);

sub shell($) {
   my($command) = @_;
   my($exit);

   $exit = system($command);

   if($exit/256 != 0){
      die "Error in $command\n"
   }
}

# sub routine for log f0 -> f0 conversion
sub lf02f0($$) {
   my($base,$gendir) = @_;
   my($t,$T,$data);

   # read log f0 file
   open(IN,"$gendir/${base}.lf0");
   @STAT=stat(IN);
   read(IN,$data,$STAT[7]);
   close(IN);

   # log f0 -> f0 conversion
   $T = $STAT[7]/4;
   @frq = unpack("f$T",$data);
   for ($t=0; $t<$T; $t++) {
      if ($frq[$t] == -1.0e+10) {
         $out[$t] = 0.0;
      } else {
         $out[$t] = exp($frq[$t]);
      }
   }
   $data = pack("f$T",@out);

   # output data
   open(OUT,">$gendir/${base}.f0");
   print OUT $data;
   close(OUT);
   
   return $T;
}

# sub routine for formant emphasis in Mel-cepstral domain
sub postfiltering($$) {
   my($base,$gendir) = @_;
   my($i,$line);

   # output postfiltering weight coefficient 
   $line = "echo 1 1 ";
   for ($i=2; $i<$ordr{'mgc'}; $i++) {
      $line .= "$pf ";
   }
   $line .= "| $X2X +af > $gendir/weight";
   shell($line);

   # calculate auto-correlation of original mcep
   $line = "$FREQT -m ".($ordr{'mgc'}-1)." -a $fw -M $co -A 0 < $gendir/${base}.mgc |"
         . "$C2ACR -m $co -M 0 -l $fl > $gendir/${base}.r0";
   shell($line);
         
   # calculate auto-correlation of postfiltered mcep   
   $line = "$VOPR  -m -n ".($ordr{'mgc'}-1)." < $gendir/${base}.mgc $gendir/weight | "
         . "$FREQT    -m ".($ordr{'mgc'}-1)." -a $fw -M $co -A 0 | "
         . "$C2ACR -m $co -M 0 -l $fl > $gendir/${base}.p_r0";
   shell($line);

   # calculate MLSA coefficients from postfiltered mcep 
   $line = "$VOPR -m -n ".($ordr{'mgc'}-1)." < $gendir/${base}.mgc $gendir/weight | "
         . "$MC2B    -m ".($ordr{'mgc'}-1)." -a $fw | "
         . "$BCP     -n ".($ordr{'mgc'}-1)." -s 0 -e 0 > $gendir/${base}.b0";
   shell($line);
   
   # calculate 0.5 * log(acr_orig/acr_post)) and add it to 0th MLSA coefficient     
   $line = "$VOPR -d < $gendir/${base}.r0 $gendir/${base}.p_r0 | "
         . "$SOPR -LN -d 2 | "
         . "$VOPR -a $gendir/${base}.b0 > $gendir/${base}.p_b0";
   shell($line);
   
   # generate postfiltered mcep
   $line = "$VOPR  -m -n ".($ordr{'mgc'}-1)." < $gendir/${base}.mgc $gendir/weight | "
         . "$MC2B     -m ".($ordr{'mgc'}-1)." -a $fw | "
         . "$BCP      -n ".($ordr{'mgc'}-1)." -s 1 -e ".($ordr{'mgc'}-1)." | "
         . "$MERGE    -n ".($ordr{'mgc'}-2)." -s 0 -N 0 $gendir/${base}.p_b0 | "
         . "$B2MC     -m ".($ordr{'mgc'}-1)." -a $fw > $gendir/${base}.p_mgc";
   shell($line);
}

# sub routine for speech synthesis from log f0 and Mel-cepstral coefficients 
sub gen_wave($) {
   my($gendir) = @_;
   my($line,@FILE,$num,$period,$file,$base,$T,$endian);

   $line   = `ls $gendir/*.mgc`;
   @FILE   = split('\n',$line);
   $num    = @FILE;
   $lgopt = "-l" if ($lg);

   print "Processing directory $gendir:\n";
   
   # synthesize a waveform STRAIGHT
   open(SYN, ">$datdir/scripts/synthesis.m") || die "Cannot open $!";
   printf SYN "path(path,'%s');\n", ${STRAIGHT};
   printf SYN "prm.spectralUpdateInterval = %f;\n\n", 1000.0*$fs/$sr;
   if ($bs==0) {
      $endian = "ieee-le";
   }
   else {
      $endian = "ieee-be";
   }

   foreach $file (@FILE) {
      $base = `basename $file .mgc`;
      chomp($base);
      if ( -s $file && -s "$gendir/$base.lf0" ) {
         print " Converting $base.mgc, $base.lf0, and $base.bap to STRAIGHT params...";
         
         # convert log F0 to pitch
         $T = lf02f0($base,$gendir);
         
         if ($ul) {
            # MGC-LSPs -> MGC coefficients
            $line = "$LSPCHECK -m ".($ordr{'mgc'}-1)." -s ".($sr/1000)." -r $file | "
                  . "$LSP2LPC  -m ".($ordr{'mgc'}-1)." -s ".($sr/1000)." $lgopt | "
                  . "$MGC2MGC  -m ".($ordr{'mgc'}-1)." -a $fw -g $gm -n -u -M ".($ordr{'mgc'}-1)." -A $fw -G $gm "
                  . " > $gendir/$base.c_mgc";
            shell($line);
            
            $mgc = "$gendir/$base.c_mgc";
         }
         else { 
            # apply postfiltering
            if ($gm==0 && $pf!=1.0 && $useGV==0) {
               postfiltering($base,$gendir);
               $mgc = "$gendir/$base.p_mgc";
            }
            else {
               $mgc = $file;
            }
         }
         
         # convert mgc to spectra
         shell("$MGC2SP -a $fw -g $gm -m ".($ordr{'mgc'}-1)." -l 1024 -o 2 $mgc > $gendir/$base.sp");

         # convert band-aperiodicity to aperiodicity
         $bap = "$gendir/$base.bap";
         shell("$BCP +f -l 5 -L 1 -s 0 -e 0 -S 0 $bap | ${DFS} -b 1 -1 | ${INTERPOLATE} -p  64 | ${DFS} -a 1 -1 > $gendir/$base.ap1");
         shell("$BCP +f -l 5 -L 1 -s 1 -e 1 -S 0 $bap | ${DFS} -b 1 -1 | ${INTERPOLATE} -p  64 | ${DFS} -a 1 -1 > $gendir/$base.ap2");
         shell("$BCP +f -l 5 -L 1 -s 2 -e 2 -S 0 $bap | ${DFS} -b 1 -1 | ${INTERPOLATE} -p 128 | ${DFS} -a 1 -1 > $gendir/$base.ap3");
         shell("$BCP +f -l 5 -L 1 -s 3 -e 3 -S 0 $bap | ${DFS} -b 1 -1 | ${INTERPOLATE} -p 128 | ${DFS} -a 1 -1 > $gendir/$base.ap4");
         shell("$BCP +f -l 5 -L 1 -s 4 -e 4 -S 0 $bap | ${DFS} -b 1 -1 | ${INTERPOLATE} -p 129 | ${DFS} -a 1 -1 > $gendir/$base.ap5");

         $line = "$MERGE -s   0 -l  64 -L  64 $gendir/$base.ap1 $gendir/$base.ap2 | "
               . "$MERGE -s 128 -l 128 -L 128 $gendir/$base.ap3 | "
               . "$MERGE -s 256 -l 256 -L 128 $gendir/$base.ap4 | "
               . "$MERGE -s 384 -l 384 -L 129 $gendir/$base.ap5 > $gendir/$base.ap";
         shell($line); 
         
         printf SYN "fprintf(1,'Synthesizing %s');\n",   "$gendir/$base.wav";
         printf SYN "fid1 = fopen('%s','r','%s');\n", "$gendir/$base.sp", $endian;
         printf SYN "fid2 = fopen('%s','r','%s');\n", "$gendir/$base.ap", $endian;
         printf SYN "fid3 = fopen('%s','r','%s');\n", "$gendir/$base.f0", $endian;

         printf SYN "sp = fread(fid1,[%d, %d],'float');\n", 513, $T;
         printf SYN "ap = fread(fid2,[%d, %d],'float');\n", 513, $T;
         printf SYN "f0 = fread(fid3,[%d, %d],'float');\n", 1,   $T;

         print  SYN  "fclose(fid1);\n";
         print  SYN  "fclose(fid2);\n";
         print  SYN  "fclose(fid3);\n";

         printf SYN "[sy] = exstraightsynth(f0,sp,ap,%d,prm);\n", $sr;
         printf SYN "wavwrite( sy/max(abs(sy)), %d, '%s');\n\n",  $sr, "$gendir/$base.wav";
                  
         print "done\n";
      }
   }
   printf SYN "quit;\n";
   close(SYN);
   
   print "Synthesizing waveform from STRAIGHT parameters...\n";
   shell("$MATLAB < $datdir/scripts/synthesis.m");
   print "done\n";
}
