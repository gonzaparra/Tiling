#Ejemplo uso: perl TileOne.pl 1n0r A 28 60 1sw6 A

#!/usr/bin/perl
use strict;
use DBI;
use POSIX qw(floor ceil);
use ParsePDB;
##################Function
##################Function
##################Function
##################Function
##################Function

sub BuildLine
{
		my ($File, $WindowSize, $StepStart, $StepEnd, $ProtLength, $Prot_beg, $Prot_end, $NSeed, $Pdb, $Chain, $TypeRestriction)=@_;
		my @FuncSteps=qx(awk '{print}' $File);
		my @Region=();
		my @Scoress=();
		my @Lengthss=();
		my @Errorss=();
		my @Ranks=();
		my @Identities=();
		my @Hangs=();

		my $EntireLength=0;
		my $EntireScore=0;
		my $EntireError=0;
		my $EntireIdentity=0;
		my $TestLeft=0;
		my $TestRight=0;

		my $TrivialScore=0;
		my $TrivialLength=0;
		my $TrivialIdentity=0;
		my $TrivialIdenticalRes=0;

		my $overlapping="false";
		foreach my $func_line(@FuncSteps)
		{
				my @splittedfunc=split("\t", $func_line);
#				print "$splittedfunc[3] $splittedfunc[4]\n";
				chomp ($splittedfunc[-1]);

				if($splittedfunc[6]<=$WindowSize/2)
				{last;}

 		 if($TypeRestriction eq "Any")
				{
				if(@Region)
				{
							for(my $i=0; $i<@Region; $i+=2)
							{ 
									unless((($splittedfunc[3] < $Region[$i] && $splittedfunc[4] < $Region[$i] ) || ($splittedfunc[3] > $Region[$i+1] && $splittedfunc[4] > $Region[$i+1])))
									{$overlapping="true"; }
							}
						if($overlapping eq "false")
						{#Aca sumo los segmentos no overlapeantes excluyendo el trivial
						push(@Region, $splittedfunc[3]);
						push(@Region, $splittedfunc[4]);
						push(@Scoress, $splittedfunc[5]);
						push(@Lengthss, $splittedfunc[6]);
						push(@Identities, $splittedfunc[9]);
						push(@Errorss, $splittedfunc[8]);
						push(@Ranks, $splittedfunc[17]);						

						if($splittedfunc[6] eq $WindowSize)
						{
								$EntireLength+=$splittedfunc[6];
								$EntireScore+=$splittedfunc[5];
								$EntireError+=$splittedfunc[8];
								$EntireIdentity+=$splittedfunc[9];
						}
				 	}
				}
				else
				{
						push(@Region, $splittedfunc[3]);
						push(@Region, $splittedfunc[4]);
						push(@Scoress, $splittedfunc[5]);
						push(@Lengthss, $splittedfunc[6]);
						push(@Errorss, $splittedfunc[8]);
						push(@Identities, $splittedfunc[9]);
						push(@Ranks, $splittedfunc[17]);						
						$TrivialScore=$splittedfunc[5];
						$TrivialLength=$splittedfunc[6];
						$TrivialIdentity=$splittedfunc[9];
						$TrivialIdenticalRes=($splittedfunc[9]/100)*$TrivialLength;
				}
		}
		elsif($TypeRestriction eq "Hang")
		{

				my $HangingRes=0;				

				if(@Region)
				{
#       print "Step\n";

									$TestLeft=$splittedfunc[3]+2;
									$TestRight=$splittedfunc[4]-2;

									if ($TestLeft<$Prot_beg){$TestLeft=$Prot_beg;}
									if ($TestRight>$Prot_end){$TestRight=$Prot_end;}


							for(my $i=0; $i<@Region; $i+=2)
							{ 
									$HangingRes=$splittedfunc[15]+$splittedfunc[16];

#									print "test: $TestLeft < region: $Region[$i] && test: $TestRight < region: $Region[$i] ) || ($TestLeft > $Region[$i+1] && $TestRight > $Region[$i+1]\n";

									unless((($TestLeft < $Region[$i] && $TestRight < $Region[$i] ) || ($TestLeft > $Region[$i+1] && $TestRight > $Region[$i+1])))
									{$overlapping="true"; }
							}
						if($overlapping eq "false")
						{#Aca sumo los segmentos no overlapeantes excluyendo el trivial
						push(@Region, $TestLeft);
						push(@Region, $TestRight);
						push(@Hangs, $splittedfunc[15]);
						push(@Hangs, $splittedfunc[16]);
						#$splittedfunc[5]-=$HangingRes;
						push(@Scoress, $splittedfunc[5]);
#						$splittedfunc[6]-=$HangingRes;
						push(@Lengthss, $splittedfunc[6]);
						push(@Identities, $splittedfunc[9]);
						push(@Errorss, $splittedfunc[8]);
						push(@Ranks, $splittedfunc[17]);						

						if($splittedfunc[6] eq $WindowSize)
						{
						$EntireLength+=$splittedfunc[6];
						$EntireScore+=$splittedfunc[5];
						$EntireError+=$splittedfunc[8];
						$EntireIdentity+=$splittedfunc[9];
						}
				 	}
				}
				else
				{
					 $TestLeft=$splittedfunc[3]-$splittedfunc[15];
					 $TestRight=$splittedfunc[4]+$splittedfunc[16];
						push(@Region, $TestLeft);
						push(@Region, $TestRight);
						push(@Hangs, $splittedfunc[15]);
						push(@Hangs, $splittedfunc[16]);
						#$splittedfunc[5]-=$HangingRes;
						push(@Scoress, $splittedfunc[5]);
#						$splittedfunc[6]-=$HangingRes;
						push(@Lengthss, $splittedfunc[6]);
						push(@Errorss, $splittedfunc[8]);
						push(@Identities, $splittedfunc[9]);
						push(@Ranks, $splittedfunc[17]);
						$TrivialScore=$splittedfunc[5];
						$TrivialLength=$splittedfunc[6];
						$TrivialIdentity=$splittedfunc[9];
						$TrivialIdenticalRes=($splittedfunc[9]/100)*$TrivialLength;
				}
  }
	elsif($TypeRestriction eq "Entire")
	{
		if(@Region)
				{
						if($splittedfunc[6] eq $WindowSize)
						{
							for(my $i=0; $i<@Region; $i+=2)
							{ 
									#print "Segment $splittedfunc[3]:$splittedfunc[4]\n";							
									#print "($splittedfunc[3] < $Region[$i] && $splittedfunc[4] < $Region[$i] ) || ($splittedfunc[3] > $Region[$i+1] && $splittedfunc[4] > $Region[$i+1])\n";
									unless((($splittedfunc[3] < $Region[$i] && $splittedfunc[4] < $Region[$i] ) || ($splittedfunc[3] > $Region[$i+1] && $splittedfunc[4] > $Region[$i+1])))
									{$overlapping="true"; }
									#print"overlaps\? $overlapping\n";
							}
						if($overlapping eq "false")
						{#Aca sumo los segmentos no overlapeantes excluyendo el trivial
						push(@Region, $splittedfunc[3]);
						push(@Region, $splittedfunc[4]);
						push(@Scoress, $splittedfunc[5]);
						push(@Lengthss, $splittedfunc[6]);
						push(@Identities, $splittedfunc[9]);
						push(@Errorss, $splittedfunc[8]);
						push(@Ranks, $splittedfunc[17]);						


						if($splittedfunc[6] eq $WindowSize)
						{
									$EntireLength+=$splittedfunc[6];
									$EntireScore+=$splittedfunc[5];
									$EntireError+=$splittedfunc[8];
									$EntireIdentity+=$splittedfunc[9];
						}

						}
				 	}
				}
				else
				{
						push(@Region, $splittedfunc[3]);
						push(@Region, $splittedfunc[4]);
						push(@Scoress, $splittedfunc[5]);
						push(@Lengthss, $splittedfunc[6]);
						push(@Errorss, $splittedfunc[8]);
						push(@Identities, $splittedfunc[9]);
						push(@Ranks, $splittedfunc[17]);		
						$TrivialScore=$splittedfunc[5];
						$TrivialLength=$splittedfunc[6];
						$TrivialIdentity=$splittedfunc[9];				
						$TrivialIdenticalRes=($splittedfunc[9]/100)*$TrivialLength;
				}
	}
		$overlapping="false";
		}

		my $TotalScore = 0; 
		($TotalScore+=$_) for @Scoress; 
		my $TotalLength = 0; 
		($TotalLength+=$_) for @Lengthss; 
		my $TotalErrors = 0; 
		($TotalErrors+=$_) for @Errorss; 
		my $TotalIdentities = 0; 
	($TotalIdentities+=$_) for @Identities; 
		#AuxVar to calculate TileIdentity
		my $TotalIdenticalRes = 0; 
		for (my $i=0; $i<@Identities; $i++)
		{
				$TotalIdenticalRes+= ($Identities[$i]/100)*$Lengthss[$i];
		}

		my $NSegments=@Region;
		$NSegments/=2;

		my $JoinedRegion=join("-",@Region);
		my $JoinedScoress=join("-",@Scoress);
		my $JoinedLengthss=join("-",@Lengthss);
		my $JoinedRanks=join("-",@Ranks);
		my $JoinedErrors=join("-",@Errorss);
		my $JoinedIdentities=join("-",@Identities);
		my $JoinedHangs=join("-",@Hangs);

		my @SortedRegion= sort {$a <=> $b} @Region;

#print "	 $JoinedScoress\n";
#Modificar centro, sumar valor inicial
#Agregar NSegments enteros
my $Center=$StepStart+(($StepEnd-$StepStart+1)/2);

my $TileScore=();
my $TileLength=();
my $TileIdentity=();

if($ProtLength == $WindowSize)
{
#print "$TileScore=$EntireLength/($ProtLength-$WindowSize);\n";
$TileScore=0;
$TileIdentity=0;
$TileLength=0;
}
else
{
#print "$TileScore=$EntireLength/($ProtLength-$WindowSize);\n";
#print "$TileScore=($TotalScore-$TrivialScore)/($ProtLength-$WindowSize);\n";
$TileScore=($TotalScore-$TrivialScore)/($ProtLength-$WindowSize);
$TileIdentity=($TotalIdenticalRes-$TrivialIdenticalRes)/($ProtLength-$WindowSize);
$TileLength=($TotalLength-$TrivialLength)/($ProtLength-$WindowSize);
}

if($TileScore<0)
{
$TileScore=0;
}
if($TileLength<0)
{
$TileLength=0;
}


#Agregar dos columnas begin y end fragment al seed

my $ToPrint=();
my $UPdb=uc($Pdb);
if ($TypeRestriction eq "Hang")
{

print "$Pdb\t$Chain\t$TileScore\t$NSegments\t@SortedRegion\tSeed-$Region[0]-$Region[1]\n";

$ToPrint="$NSeed\t$Pdb,$Chain($StepStart:$StepEnd)\t$StepStart\t$StepEnd\t$WindowSize\t$Center\t$TotalErrors\t$EntireError\t$TotalScore\t$EntireScore\t$TotalLength\t$EntireLength\t$TotalIdentities\t$EntireIdentity\t$NSegments\t$TileScore\t$TileIdentity\t$TileLength\tRegion-$JoinedRegion\tScores-$JoinedScoress\tLengths-$JoinedLengthss\tIdentities-$JoinedIdentities\tErrors-$JoinedErrors\tRanks-$JoinedRanks\tHangs-$JoinedHangs\n ";
}
else
{
$ToPrint="$NSeed\t$Pdb,$Chain($StepStart:$StepEnd)\t$StepStart\t$StepEnd\t$WindowSize\t$Center\t$TotalErrors\t$EntireError\t$TotalScore\t$EntireScore\t$TotalLength\t$EntireLength\t$TotalIdentities\t$EntireIdentity\t$NSegments\t$TileScore\t$TileIdentity\t$TileLength\tRegion-$JoinedRegion\tScores-$JoinedScoress\tLengths-$JoinedLengthss\tIdentities-$JoinedIdentities\tErrors-$JoinedErrors\tRanks-$JoinedRanks\n ";
}
return ($ToPrint, $TileScore, $TileIdentity, $TileLength);
}

##############################
##############################
##############################
##############################

use strict;

my $al_ini=0;
my $Prot_beg=0;
my $Prot_end=0;
my $ProtLength=0;
my $Blocks=0;
my $Blocks_ant=1000000;
my $N_ali;
my $plot_line=();
my $NSeed=1;

my $Pdb=$ARGV[4];
$Pdb=lc($Pdb);
my $Chain=$ARGV[5];
my $UPdb=uc($Pdb);

my $qPDB=$ARGV[0];
my $qChain=$ARGV[1];
my $qIni=$ARGV[2];
my $qEnd=$ARGV[3];
my $tPdb=$ARGV[4];
my $tChain=$ARGV[5];

unless (-d "$UPdb")
{
	system("mkdir $UPdb");
}
unless (-d "$UPdb/Hanging")
{
	system("mkdir $UPdb/Hanging");
}
unless (-d "$UPdb/Entire")
{
	system("mkdir $UPdb/Entire");
}
unless (-d "$UPdb/NotHanging")
{
	system("mkdir $UPdb/NotHanging");
}

unless (-e "/home/gonzalo/topmatch/PDB/pdb$Pdb.ent.gz")
{
system("cp /home/gonzalo/Pdb2013Febrero/pdb/*/pdb$Pdb.ent.gz /home/gonzalo/topmatch/PDB");
}



open (Progreso, ">$UPdb/Progreso");
open (SEEDSHANG, ">$UPdb/Hanging/SeedsCoverageHang_$Pdb\_$Chain");
open (ACUMHANG, ">$UPdb/Hanging/AcumHang_$Pdb\_$Chain");
system("gunzip -c -d /home/gonzalo/topmatch/PDB/pdb$Pdb.ent.gz >> $UPdb/Hanging/pdb$Pdb.ent;");

#####-------Parse The PDB to get the extreme residues and the length -------------
my $PDB = ParsePDB->new (FileName => "$UPdb/Hanging/pdb$Pdb.ent", NoHETATM => 1, Header=> 0, NoANISIG => 1, AtomLocations => "First");
$PDB->Parse;
my $ProtLength = $PDB->CountResidues (Model => 0, ChainLabel => $Chain, ResidueIndex => 1);
my @AtomIndex = $PDB->IdentifyResidueNumbers (Model => 0, ChainLabel => $Chain, AtomIndex => 1, AtomStart => 1);

$Prot_beg=$AtomIndex[0];
$Prot_end=$AtomIndex[-1];
print "$Pdb-$Chain - Prot Beg - $Prot_beg Prot End - $Prot_end  $ProtLength\n";

#####-------END Parse The PDB to get the extreme residues and the length -------------

#Tamaño de la ventana inicial
my $WindowSize=$qEnd-$qIni+1;

my $AcumTileScoreAny=0;
my $AcumTileIdentityAny=0;
my $AcumTileLengthAny=0;

my $AcumTileScoreHang=0;
my $AcumTileIdentityHang=0;
my $AcumTileLengthHang=0;

my $AcumTileScoreEntire=0;
my $AcumTileIdentityEntire=0;
my $AcumTileLengthEntire=0;

print SEEDSHANG '	$NSeed	$Pdb,$Chain($StepStart:$StepEnd)	Segmentbeg	Segmentend	$WindowSize	$Center	$TotalErrors	$EntireError	$TotalScore	$EntireScore	$TotalLength	$EntireLength	$TotalIdentities	$EntireIdentity	$NSegments	$TileScore	$TileIdentity	$TileLength Region-$JoinedRegion	Scores-$JoinedScoress	Lengths-$JoinedLengthss	Identities-$JoinedIdentities	Errors-$JoinedErrors	Ranks-$JoinedRanks Hangs-$JoinedHangs',"\n ";

print Progreso "$Pdb $Chain Working with WindowSize=$WindowSize\n";
my $Step=1; #Nombre en la salida Step_Function
my $WindowShift=1;
my $Offset=0;
my $StepStart=$qIni;
my $StepEnd=$qEnd;

            #Analisis de la salida
            open (SCRIPT, ">$UPdb/$Pdb\_$Chain\_script.tm");
            my $RepSize=$Prot_beg +$WindowSize;
            print SCRIPT "set frac 1\n";
            print SCRIPT "set amax 2000\n";
            print SCRIPT "set nbr 3.7\n";
            print SCRIPT "set pad 3.7\n";
            print SCRIPT "set bcomp 0\n";
            print SCRIPT "m $qPDB,$qChain($qIni:$qEnd) $tPdb,$tChain\n";
            print SCRIPT "exit";
            close SCRIPT;
            system ("/home/gonzalo/topmatch/topmatch < $UPdb/$Pdb\_$Chain\_script.tm > $UPdb/$Pdb\_$Chain\_out.tm");
            #Averiguar la cantidad de alineamientos:            
            open (OUT, "$UPdb/$Pdb\_$Chain\_out.tm");
            while (<OUT>)
            {
            		if ($_ =~ /Alignments/)
            		{	
            				my @splited= split(" ", $_);
            				$N_ali=$splited[0];
            		}
            }
            close OUT;
            
            open (SCRIPT, ">$UPdb/$Pdb\_$Chain\_script.tm");           
            print SCRIPT "set frac 1\n";
            print SCRIPT "set amax 2000\n";
            print SCRIPT "set nbr 3.7\n";
            print SCRIPT "set pad 3.7\n";
            print SCRIPT "set bcomp 0\n";
            print SCRIPT "m $qPDB,$qChain($qIni:$qEnd) $tPdb,$tChain\n";
            print SCRIPT "top $N_ali\n";

            for (my $i=1; $i<=$N_ali; $i++)
            {
            	print SCRIPT "blocks $i\n";
            }
            print SCRIPT "exit";
            close SCRIPT;
            system ("/home/gonzalo/topmatch/topmatch < $UPdb/$Pdb\_$Chain\_script.tm > $UPdb/$Pdb\_$Chain\_out.tm");
            
            $Blocks_ant=100000;
            $Blocks=0;
            my $Blocks_detail=0;
            
            open (Blocks, ">$UPdb/$Pdb\_$Chain\_blocks_table");
            #-------Escribo archivo de bloques---------
            open (OUT, "$UPdb/$Pdb\_$Chain\_out.tm");
            
            print Blocks "#Top  Segment_$StepStart\_$StepEnd     R  T      L    Qc    Tc      S     Sr     Er     Is    P  angle blks  seed clust     sim     sum      rs       g\n";
            while (<OUT>)
            {
            		if($_ =~ /Alignments of/)
            		{
            					$Blocks++;
            		}
            		elsif($_ =~/Blocks of alignment/)
            		{
            			$Blocks_detail++;
            		}
            		if($Blocks_detail eq 1 && $_=~/     1/)
            			{print Blocks"#Block    Segment_$StepStart\_$StepEnd   Blocks_num		 block   Q-start   Q-end   T-start   T-end size   diag  l-rms  g-rms  l-rsim g-rsim  angle  sh     sum  r_sab   g_a   zn_a\n";}
            		
            		if( $Blocks eq 2 && $_=~/  b    /)
            						{
            							 print Blocks "Top   Segment_$StepStart\_$StepEnd   $_";
            						}
            		elsif($Blocks_detail > 0 && $_=~/     [1-9]/)
            		{
            							 print Blocks "Block   Segment_$StepStart\_$StepEnd   $Blocks_detail   $_";
            		}
            		$Blocks_ant=$Blocks;				
            }
            
											close Blocks;
            #---------------Fin deteccion-----------------------------------------------------
            system ("$Pdb\_$Chain\_blocks_table");
            
            open (FUNC, ">$UPdb/$Pdb\_$Chain\_$Step\_Function");
            
            for(my $i=1; $i<=$N_ali; $i++)
            {
            
            my @Tops=qx(awk '{if(\$1~/^Top/ && \$3==$i) print} ' $UPdb/$Pdb\_$Chain\_blocks_table);
            my @Blocks=qx(awk '{if(\$1~/^Block/ && \$3==$i) print} ' $UPdb/$Pdb\_$Chain\_blocks_table);
            
            my @Top_line=split(" ", $Tops[0]);
            my @Block_beg=split(" ", $Blocks[0]);
            my @Block_end=split(" ", $Blocks[-1]);
            
												my $TopPosition=$Top_line[2];
												my $Sr=$Top_line[8];
												my $Permut=$Top_line[11];
            my $Sim=$Top_line[7];
												my $L=$Top_line[4];
												my $Is=$Top_line[10];
												my $angle=$Top_line[15];
												my $sim=$Top_line[16];
												my $sum=$Top_line[17];
												my $rs=$Top_line[18];
												my $g=$Top_line[19];
            my $Block_start=$Block_beg[9];
            my $Block_finish=$Block_end[11];
												my $LeftHang=$Block_beg[5]-$StepStart;
												my $RightHang=$StepEnd-$Block_end[7];
            my $Segment=$Block_end[1];
            my $Ranking=$Block_end[2];            

												if($Permut == 0)
												{
            print FUNC "$Pdb,$Chain($StepStart:$StepEnd)\t$Ranking\t",($Block_finish - ($Block_finish-$Block_start)/2),"\t$Block_start\t$Block_finish\t$Sim\t$L\t",$Sim,"\t$Sr\t$Is\t$Permut\t$sim\t$sum\t$rs\t$g\t$LeftHang\t$RightHang\t$TopPosition\n";
            }
            }
		close FUNC;


my ($ToPrint, $TileScore, $TileIdentity, $TileLength) = &BuildLine("$UPdb/$Pdb\_$Chain\_$Step\_Function", $WindowSize, $qIni, $qEnd, $ProtLength, $Prot_beg, $Prot_end, $NSeed, $Pdb, $Chain, "Hang");

$AcumTileScoreHang+=$TileScore;
$AcumTileIdentityHang+=$TileIdentity;
$AcumTileLengthHang+=$TileLength;

print SEEDSHANG "$ToPrint";


#system ("rm $UPdb/$Pdb\_$Chain\_$Step\_Function");
$StepStart+=$WindowShift;
$StepEnd=$StepStart+$WindowSize-1;
$Step++;
$NSeed++;


print ACUMHANG "$WindowSize\t$AcumTileScoreHang\t$AcumTileIdentityHang\t$AcumTileLengthHang\n";
$AcumTileScoreHang=0;
$AcumTileIdentityHang=0;
$AcumTileLengthHang=0; 

 
$WindowSize--;

close SEEDSHANG;
close ACUMHANG;

system("perl Acum2.pl Hanging/SeedsCoverageHang_$ARGV[0]\_$ARGV[1] Hanging/Acum_$ARGV[0]\_$ARGV[1]", "Hanging");

close Progreso;

