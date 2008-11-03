#!/usr/bin/perl

$|=1;

if (@ARGV != 2) {
	print "usage: gen_wave.pl Config.pm GENDIR\n";
	exit(1);
}

require($ARGV[0]);



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
sub lf02pitch($$) {
   my($base,$gendir) = @_;
   my($t,$T,$data);

   # read log f0 file
   open(IN,"$gendir/${base}.lf0");
   @STAT=stat(IN);
   read(IN,$data,$STAT[7]);
   close(IN);

   # log f0 -> pitch conversion
   $T = $STAT[7]/4;
   @frq = unpack("f$T",$data);
   for ($t=0; $t<$T; $t++) {
      if ($frq[$t] == -1.0e+10) {
         $out[$t] = 0.0;
      } else {
         $out[$t] = $sr/exp($frq[$t]);
      }
   }
   $data = pack("f$T",@out);

   # output data
   open(OUT,">$gendir/${base}.pit");
   print OUT $data;
   close(OUT);
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
   my($line,@FILE,$num,$period,$file,$base);

   $line   = `ls $gendir/*.mgc`;
   @FILE   = split('\n',$line);
   $num    = @FILE;
   $lgopt = "-l" if ($lg);

   print "Processing directory $gendir:\n";  
   foreach $file (@FILE) {
      $base = `basename $file .mgc`;
      chomp($base);
      if ( -s $file && -s "$gendir/$base.lf0" ) {
         print " Synthesizing a speech waveform from $base.mgc and $base.lf0...";
         
         # convert log F0 to pitch
         lf02pitch($base,$gendir);
         
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
         
         # synthesize waveform
         $line = "$EXCITE -p $fs $gendir/$base.pit | "
               . "$MGLSADF -m ".($ordr{'mgc'}-1)." -p $fs -a $fw -g $gm $mgc | "
               . "$X2X +fs | "
               . "$SOX -c 1 -s -w -t raw -r $sr - -c 1 -s -w -t wav -r $sr $gendir/$base.wav";

         shell($line);
         
         print "done\n";
      }
   }
   print "done\n";
}
