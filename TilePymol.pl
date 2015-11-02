#!/usr/bin/perl
use strict;

my $Pdb=lc $ARGV[0];
my $Chain=$ARGV[1];

my $seedPdb="4db6";
my $seedChain="A";
my $seedStart=12;
my $seedEnd=53;

my $SeedFile=uc($Pdb)."/Hanging/SeedsCoverageHang_".lc($Pdb)."_".$Chain;

print "$SeedFile\n";

my @PDB=split("_", $SeedFile);

print "@PDB\n";

#my $Pdb=lc $PDB[0];
#my $Chain= substr($PDB[1], 0, 1);

my $Seed=1;
my @SeedData=qx(awk '{if(\$1==$Seed) print }' $SeedFile);
my @SplittedData=split("\t", $SeedData[0]);
my @Ranks=split("-", $SplittedData[23]);

my $SegmentBeg=$SplittedData[2];
my $SegmentEnd=$SplittedData[3];

open (SCRIPT, ">$Pdb\_$Chain\_script.tm");           
print SCRIPT "set frac 1\n";
print SCRIPT "set amax 2000\n";
print SCRIPT "set nbr 3.7\n";
print SCRIPT "set pad 3.7\n";
print SCRIPT "set bcomp 0\n";
print SCRIPT "m $seedPdb,$seedChain($seedStart:$seedEnd) $Pdb,$Chain\n";

for(my $i=1; $i<@Ranks;$i++)
{
if ($i<(@Ranks-1))
{
print SCRIPT "transformations $Ranks[$i]\n";
}
else
{
print SCRIPT "transformations $Ranks[$i]";
}

}
close SCRIPT;

system ("/home/gonzalo/topmatch/topmatch < $Pdb\_$Chain\_script.tm > $Pdb\_$Chain\_out.tm");


my @OUT=qx(awk '{print}' $Pdb\_$Chain\_out.tm);



my $line3=();
my @splitted3=();
my $line2=();
my @splitted2=();
my $line1=();
my @splitted1=();

print "@splitted1\n@splitted2\n@splitted3\n";

open (PML, ">$Pdb\_$Chain\_align.pml");
print PML "reinitialize\n";

print PML "load /home/gonzalo/topmatch/PDB/pdb$Pdb.ent.gz, molecule\n";



for(my $i=0; $i<(@Ranks-1); $i++)
{
my $Seed=$i+1;
if ($Seed == (@Ranks-1))
{
print PML "load /home/gonzalo/topmatch/PDB/pdb$seedPdb.ent.gz, aux$Seed\n";
print PML "create Seed, resi $seedStart-$seedEnd AND chain $seedChain AND aux$Seed\n";
print PML "delete aux$Seed\n";
$line3=$OUT[-2-(5*$i)];
@splitted3=split(" ", $line3);
$line2=$OUT[-3-(5*$i)];
@splitted2=split(" ", $line2);
$line1=$OUT[-4-(5*$i)];
@splitted1=split(" ", $line1);
print "@splitted1\n@splitted2\n@splitted3\n";
print PML "cmd.transform_selection(\"Seed\",( $splitted1[0], $splitted1[1], $splitted1[2],$splitted1[4],$splitted2[0], $splitted2[1], $splitted2[2],$splitted2[4], $splitted3[0], $splitted3[1], $splitted3[2],$splitted3[4], -$splitted1[3], -$splitted2[3], -$splitted3[3], 0))\n";
}
else
{
print PML "load /home/gonzalo/topmatch/PDB/pdb$seedPdb.ent.gz, aux$Seed\n";
print PML "create SubOpt$Seed, resi $seedStart-$seedEnd AND chain $seedChain AND aux$Seed\n";
print PML "delete aux$Seed\n";
$line3=$OUT[-2-(5*$i)];
@splitted3=split(" ", $line3);
$line2=$OUT[-3-(5*$i)];
@splitted2=split(" ", $line2);
$line1=$OUT[-4-(5*$i)];
@splitted1=split(" ", $line1);
print "@splitted1\n@splitted2\n@splitted3\n";
print PML "cmd.transform_selection(\"SubOpt$Seed\",( $splitted1[0], $splitted1[1], $splitted1[2],$splitted1[4],$splitted2[0], $splitted2[1], $splitted2[2],$splitted2[4], $splitted3[0], $splitted3[1], $splitted3[2],$splitted3[4], -$splitted1[3], -$splitted2[3], -$splitted3[3], 0))\n";
}

}

print PML "hide all\n";
print PML "show cartoon, molecule AND chain $Chain\n";
print PML "color gray, molecule\n";
print PML "show cartoon, Seed\n";
print PML "color yellow, Seed\n";
print PML "color red, SubOpt3\n";
for(my $i=1; $i<=(@Ranks-2); $i++)
{
print PML "show cartoon, SubOpt$i\n";
#print PML "color black, SubOpt$i\n";
}


print PML "zoom molecule AND chain $Chain\n";
print PML "bg_color white\n";
print PML "set cartoon_transparency, 0.6, molecule\n";
print PML "set opaque_background, off\n";
#print PML "color black, SubOpt*\n";
close PML;

my $workdir=qx(pwd);
chomp $workdir;

my $LogoFile=uc($Pdb)."/Hanging/$Pdb\_$Chain.logo";
#my $LogoPng=uc($Pdb)."_".$Chain."/Hanging/Logo_$Pdb\_$Chain.png";
my $LogoPng=uc($Pdb)."/Hanging/$Pdb\_$Chain.png";


print "perl RetrieveReps2.pl $Pdb $Chain $Seed $workdir\n";
system ("perl RetrieveReps2.pl $Pdb $Chain $Seed $workdir $seedPdb $seedChain $seedStart $seedEnd");


system ("perl /home/gonzalo/Desktop/Doctorado/Programas/WebLogo/weblogo-3.3/seqLogo.pl -f $LogoFile -o $LogoPng -l 55");
##system("cp $LogoPng Logos");
#system ("eog $LogoPng &");


system ("pymol $Pdb\_$Chain\_align.pml ");



