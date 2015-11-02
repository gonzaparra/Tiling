#Usage perl Alignments.pl SeedsCoverageHang_Pdb_Chain NSeed

#!/usr/bin/perl
use strict;
use lib "/usr/share/perl/5.10.1/pod/";

my $Pdb=$ARGV[0];
my $Chain=$ARGV[1];
my $Seed=$ARGV[2];
my $workdir=$ARGV[3];
my $seedPdb=$ARGV[4];
my $seedChain=$ARGV[5];
my $seedStart=$ARGV[6];
my $seedEnd=$ARGV[7];

my $FILE=uc($Pdb)."/Hanging/SeedsCoverageHang_$Pdb\_$Chain";

my $ProtEdges=qx(awk '{if(\$1==1) print }' $FILE);
my @splittedEdges=split("\t", $ProtEdges);
my $ProtIniEdge=$splittedEdges[2];
my $ProtTermEdge=$splittedEdges[3];

#print "Prot Edges: $ProtIniEdge $ProtTermEdge\n";

my @SeedData=qx(awk '{if(\$1==$Seed) print }' $FILE);
my @SplittedData=split("\t", $SeedData[0]);
my @Ranks=split("-", $SplittedData[23]);

my @Hangs=();

if($ARGV[0]=~/Hang/)
{
@Hangs=split("-", $SplittedData[24]);
}

my $SegmentBeg=$SplittedData[2];
my $SegmentEnd=$SplittedData[3];

open (SCRIPT, ">$workdir/$Pdb\_$Chain\_script.tm");           
print SCRIPT "set frac 1\n";
print SCRIPT "set amax 2000\n";
print SCRIPT "set nbr 3.7\n";
print SCRIPT "set pad 3.7\n";
print SCRIPT "set bcomp 0\n";
print SCRIPT "m $seedPdb,$seedChain($seedStart:$seedEnd) $Pdb,$Chain\n";

for(my $i=1, my $h=0; $i<@Ranks;$i++, $h=2)
{
if ($i<(@Ranks-1))
{
print SCRIPT "alg $Ranks[$i]\n";
}
else
{
print SCRIPT "alg $Ranks[$i]";
}

}
close SCRIPT;

system ("/home/gonzalo/topmatch/topmatch < $workdir/$Pdb\_$Chain\_script.tm > $workdir/$Pdb\_$Chain\_ALIGNMENTS_out.tm");

open (ALGS, "$workdir/$Pdb\_$Chain\_ALIGNMENTS_out.tm");
my @ALGS=<ALGS>;
close ALGS;


my $Repeat="";
my $nRep=1;
my $LenRep=0;
my $SingleAlg="";
my $Deletions=0;
my $Insertions=0;

my @inis=();
my @terms=();
my @RepAlg=();
my @RepRef=();

for (my $i=26; $i<@ALGS; $i+=4 )
{

chomp($ALGS[$i]);
$SingleAlg.=substr($ALGS[$i],24);

if($ALGS[$i+3] =~ /TopMatch-7.3:/)
{
my @SearchLimits=split("", $SingleAlg);
my $ini="NONE";
my $term=();

for ( my $k=0; $k<@SearchLimits; $k++)
{
		if($SearchLimits[$k] ne '-')
		{
				if($ini eq "NONE")
				{
						$ini=$k;
				}
				$term=$k;
#			print "$SearchLimits[$k] $k\n";
		}		
}

my $Len=$term-$ini+1;

push(@inis, $ini);
push(@terms,$term);
push(@RepRef, $SingleAlg);

################
my $RepRecup="";
my $SingleAlgR ="";

for (my $i=27; $i<@ALGS; $i+=4 )
{
chomp($ALGS[$i]);
#print "$ALGS[$i]";
$SingleAlgR.=substr($ALGS[$i],24);

if($ALGS[$i+2] =~ /TopMatch-7.3:/)
{
		push (@RepAlg, $SingleAlgR);
		$SingleAlgR="";
		$RepRecup=substr($SingleAlgR, $ini, $Len);
}
}

##################
$ini=0;
$term=0;
$SingleAlg="";
}
}
open (RETRIEVE, ">RetrivedReps_$Pdb\_$Chain");
open (MODIF, ">$Pdb\_$Chain\_RepModifications");
open (FASTA, ">Fasta_$Pdb\_$Chain");

for (my $i=0; $i<@inis; $i++)
{
		my $RealIni=$inis[$i]+$ProtIniEdge;
		my $RealTerm=$RealIni + $terms[$i] - $inis[$i];

  my $FinalRepeat=substr($RepAlg[$i], $inis[$i], $terms[$i] - $inis[$i] +1);
  my $FinalRef=substr($RepRef[$i], $inis[$i], $terms[$i] - $inis[$i] +1);

  print "Repeat $i\n$FinalRepeat\n$FinalRef\n";
		print RETRIEVE "\nRepeat ",$i+1," Len ", $terms[$i] - $inis[$i] +1 ," region [$RealIni:$RealTerm]\n$FinalRepeat\n";
		print RETRIEVE "\nRefRepeat ",$i+1," Len ", $terms[$i] - $inis[$i] +1 ," region [$RealIni:$RealTerm]\n$FinalRef\n";

#Detection of modifications in the repeat
  my @SplittedRep=split("", $FinalRepeat);
  my @SplittedRef=split("", $FinalRef);

  my $InsertionStarted="false";
  my $DeletionStarted="false";

  my $InsertionLength=0;
  my $InsertionStart;

  my $DeletionLength=0;
  my $DeletionStart;

  my $CurrentInsPos=$RealIni;
  my $CurrentDelPos=$RealIni;
  my $CurrentCharacPos=0;

  my @ConsensusPos=();
  my @RelativeConsensusPos=();

  for (my $r=0; $r<@SplittedRef; $r++)
  {
    #Vemos Inserciones
    if ($SplittedRef[$r] eq '-')
    {
      if ($InsertionStarted eq "false")
      {
      $InsertionStarted="true";
      $InsertionStart=$CurrentInsPos;
      }
      $InsertionLength++;
      $CurrentInsPos++;
    }
    elsif ($SplittedRef[$r] ne '-')
    {
      if ($InsertionStarted eq "true")
      {
       $InsertionStarted="false";
       #The position informed as start of insertion is: Position starts after position $i
       print MODIF "Insertion in Repeat",$i+1," $InsertionStart $InsertionLength\n";
       $InsertionLength=0;
      }
      $CurrentInsPos++;
      $CurrentCharacPos++;
      #As characteristic positions are numered relative to the reference we can assign them here
      push(@ConsensusPos, $CurrentCharacPos);
      if ($SplittedRep[$r] eq '-')
      {push(@RelativeConsensusPos, 'D');}
      elsif ($SplittedRep[$r] ne '-')
      {push(@RelativeConsensusPos, $CurrentInsPos);}
    }
  #Vemos Deleciones
  if ($SplittedRep[$r] eq '-')
  {
   if ($DeletionStarted eq "false")
   {
    $DeletionStarted="true";
    $DeletionStart=$CurrentDelPos;
   }
   $DeletionLength++;
  }
  elsif ($SplittedRep[$r] ne '-')
  {
    if ($DeletionStarted eq "true")
    {
      $DeletionStarted="false";
      print MODIF "Deletion in Repeat",$i+1," $DeletionStart $DeletionLength\n";
      $DeletionLength=0;
    }
    $CurrentDelPos++;
  }
  }

   #Uno el vector de posiciones consenso y relativas
		my $JoinedConsensusPos=join("-",@ConsensusPos);
		my $JoinedRelativeConsensusPos=join("-",@RelativeConsensusPos);
 print MODIF "CharacteristicPos Rep",$i+1," $JoinedConsensusPos\n";
 print MODIF "RelativeCharacteristicPos Rep",$i+1," $JoinedRelativeConsensusPos\n";

		print FASTA ">$Pdb-$Chain-Repeat",$i+1,"-Len:", $terms[$i] - $inis[$i] +1 ,"-region:[$RealIni:$RealTerm]\n$FinalRepeat\n";

}



print ("rm $workdir/$Pdb\_$Chain\_ALIGNMENTS_out.tm\n");
#system ("rm $workdir/$Pdb\_$Chain\_ALIGNMENTS_out.tm");
#system ("rm $workdir/$Pdb\_$Chain\_script.tm");

close RETRIEVE;
close FASTA;
close MODIF;
system ("perl AlinearSeeds.pl $Pdb $Chain");


