use strict;

my $Pdb=$ARGV[0];
my $Chain=$ARGV[1];

my $FileName="RetrivedReps_".lc($Pdb)."_".$Chain;

my @File=qx(awk {'print'} $FileName);
chomp @File;

my @Seeds=();
my @Reps=();
my $NPos=split("",$File[1]);


#print $NPos,"\n";

for(my $i=0;$i<@File; $i+=6)
{
push(@Reps, [split("",$File[$i+2])]);
push(@Seeds, [split("",$File[$i+5])]);
}

for(my $i=0; $i<$NPos; $i++)
{
my $aligned="true";

for (my $j=0; $j<@Seeds; $j++)
{
#  if( lc($Seeds[$j][$i]) ne lc ($Seeds[0][$i]))
  if( lc ($Seeds[$j][$i]) eq '-')
		{
				$aligned="false";
#				print "$Seeds[0][$i] $j $i\n";		

   #Corregir
			for (my $k=0; $k<@Seeds; $k++)
			{
					if($Seeds[$k][$i] ne "-")
					{
						splice @{$Seeds[$k]}, $i, 0, '-';
						splice @{$Reps[$k]}, $i, 0, '-';
      $NPos++;
#      print @{$Reps[$k]}, "\n";
#      print @{$Seeds[$k]}, "\n";
					}
			}

		}
}
}

#--------------------------------

for(my $i=0; $i<$NPos; $i++)
{
my $aligned="true";

for (my $j=0; $j<@Seeds; $j++)
{
#  if( lc($Seeds[$j][$i]) ne lc ($Seeds[0][$i]))
  if( lc ($Seeds[$j][$i]) eq '-')
		{
				$aligned="false";
#				print "$Seeds[0][$i] $j $i\n";		

   #Corregir
			for (my $k=0; $k<@Seeds; $k++)
			{
					if($Seeds[$k][$i] ne "-")
					{
						splice @{$Seeds[$k]}, $i, 0, '-';
						splice @{$Reps[$k]}, $i, 0, '-';

#      print @{$Reps[$k]}, "\n";
#      print @{$Seeds[$k]}, "\n";
					}
			}

		}
}
}

#--------------------------------

#for (my $i=0; $i<$NPos; $i++)
#{

#   my $gapped="true";

#   for (my $j=0; $j<@Seeds; $j++)
#   {
#     if($Seeds[$j][$i] ne "-")
#     {
#      $gapped="false";
#     }
#   }

#   if ($gapped eq "true")
#   {
#     for (my $j=0; $j<@Seeds; $j++)
#     {
##        splice @{$Seeds[$j]}, $i, 1;   
##        splice @{$Reps[$j]}, $i, 1;
##        print "After triming\n", @{$Reps[$j]}, "\n";
##        print @{$Seeds[$j]}, "\n";

#     }
#   }

#}

my $LogoFile=uc($Pdb)."/Hanging/$Pdb\_$Chain.logo";

open (ToLogo, ">$LogoFile");
for (my $i=0; $i<@Seeds; $i++)
{
 print ToLogo ">$Pdb\_$Chain\_rep$i","\n",@{$Reps[$i]},"\n";
}

close ToLogo;
