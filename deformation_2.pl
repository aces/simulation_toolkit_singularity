#!/usr/bin/perl -w
# be sure to app PATHS before running this
# By Najmeh Khalili-Mahani 
use strict;
use Cwd qw/ abs_path /;
use Data::Dumper;
use Env qw/ USER LOGNAME PATH /;
use File::Basename;
use File::Temp qw/ tempdir /;
use Getopt::Tabular;
use IO::File;
use Sys::Hostname;
use MNI::Startup;
use MNI::Spawn;
use MNI::FileUtilities qw(check_output_dirs check_files);
use MNI::PathUtilities qw(replace_dir);
use Getopt::Tabular;
use MNI::DataDir;

$Clobber = 0;
$Execute = 1;
$Verbose = 1;

# Declare/initalize variables

my $InputFile;
my $OutputDir;
my $OutputFile;
my $Mask;
my $Tol_space;
my @Coordinate;
my $Blur;
my $Def_Tol=0.00001;
my $DefRatios;
my $Determinant;
my $iteration=1000;

my $dir_for_temp_files;
my $target_det_file;
my $target_xfm;
my $maskfile;
my $tolerance_area;
my $Determinant_area;
my $determinant;
my $basename;
my $Me;

my $neighbors=6;
my $maptolerance;
my $simulatedannealing=0; #False;
my $save_intermediate_grid_fields=0; #False;
my $verbose=0; #False;
my $keeptemp=0; #False;

# Flush output to make sure we get clean log files
$| = 1;

my $Usage = <<USAGE;

Usage: $Me -input <.mnc> -output <outputdir> [options] 

Mandatory options:
    -deformation_ratio    provide the ratio of deformation, values must be between 0.1 [shrinkage] to 1.50 [expansion] [e.g. 0.1,1.2,0.6,…]
    -mask                 Specify a tolerance map file (.mnc) indicating voxels that have a different amount of error allowed e.g., CSF, background [e.g. your-mask.mnc]
    -coordinate           Specify a hyperslab starting at <x> <y> <z> and extending in respective directions by <sizex> <sizey> <sizez> [e.g. 70 100 80 5 5 5]
    -tolerance_space      Define the buffer area around the deformation region [default = 4]
    
Other options:
    -blur_determinant     Blurring kernel size for blurring deformation determinant blurring kernel 0-1
    -error                Specify the amount of error that is allowed between the specified determinant and the final determinant (per voxel) [default =0.00001]
    -iteration            Specify the maximum number of iterations to update the deformations field (-1 means until convergence) [default 1000]
    
USAGE

my $Help = <<HELP;

$Me is a simulation program that generates minute local deformations based on method proposed by Matthijs Van Eede et al (2013) https://doi.org/10.1016/j.neuroimage.2013.06.004. Location and magnitude of deformation is specified either by a mask file <.mnc> or by a hyperslab of sizex sizey sizez generated at (x,y,z) coordinates. To expand, choose defromation ratios 1-1.5; to shrink, choose deformation rations 0.1-0.99.  

HELP
 
&Getopt::Tabular::SetHelp($Help, $Usage);

my @Args = 
(
  ["Default Options", "section"],
  ["-clobber", "boolean", 1, \$Clobber, "Clobber output files"],
  ["Options to run deformation", "section"],
  ["-input", "string", 1, \$InputFile, "input minc file", '<input.mnc>'],
  ["-output", "string", 1, \$OutputDir, "Output directory", '<Output>'],
  ["-deformation_ratio", "string", 1, \$DefRatios, "deformation ratios. Values must be between 0.1 to 1.50", '<r1,r2,r3,…>'],
  ["-mask", "string", 1, \$Mask,"Specify a tolerance map file (.mnc) indicating voxels that have a different amount of error allowed e.g., CSF, background", '<mask.mnc>'],
  ["-coordinate", "float", 6, \@Coordinate, '<x> <y> <z> <sizex> <sizey> <sizez>'],  
  ["-tolerance_space", "integer", 1, \$Tol_space, "define the area of tolerance around the deformation. [default = 4]"],
  ["-blur_determinant", "float", 1, \$Blur, "Blurring kernel size for blurring deformation determinant blurring kernel 0-1", 'default=0.25'],
  ["-error", "float", 1, \$Def_Tol, "Specify the amount of error that is allowed between the specified determinant and the final determinant (per voxel)", 'default =0.00001'],
  ["-iteration", "integer", 1, \$iteration,"Specify the maximum number of iterations to update the deformations field (-1 means until convergence)",'<iteration>']
);

#none of the following option are used 
my @ArgvanEede =
 (
   ["-n", "integer", 1, \$neighbors,"Specify the number of neighbors to use in the determinant calculation (possibilities: 6, 14)",'default = 6'],              
   ["-s", "boolean", 1, \$simulatedannealing, "Use simulated annealing to create the deformation field", 'default = 0'],
   ["-g","boolean",1,  \$save_intermediate_grid_fields, "Store the intermediate grid fields at every 10 iterations of the process", 'default = 0'],
   ["-v","boolean",1,\$verbose,"output messages", 'default = 0'],
   ["-k","boolean",1,\$keeptemp, "Keep temporary files",'default = 0'],
);

&GetOptions ([@DefaultArgs,@Args, @ArgvanEede], \@ARGV) || die " \n";

RegisterPrograms(['mincreshape', 'mincmath', 'mincresample', 'minccalc', 'mincmorph', 'create_deformation.py', 'blur_determinant.py']);

die "You cannot provide both -mask and -coordinate\n" if defined $Mask && @Coordinate;
die "You must provide either -mask or -coordinate\n" if ! defined $Mask && ! @Coordinate;

check_output_dirs($TmpDir) if $Execute;  #NOT SURE WHAT THIS DOES

#DEFINE OUTPUT DATA STRUCTURE
mkdir $OutputDir;
$dir_for_temp_files= $OutputDir.'/TMP/';
mkdir $dir_for_temp_files;
$basename = $InputFile;
$basename =~ s/\.mnc$//;

#PREPARE AREAS AROUND THE DEFORMATION    
$Mask = MakeMask($InputFile, @Coordinate) unless defined $Mask;
$tolerance_area = TolerationRing($Mask, $Tol_space,$dir_for_temp_files);
print "$tolerance_area\n";
#CREATE DEFORMATION DETERMINANTS AND TRANSFORMATION MATRICES FOR EACH RATIO
my @Ratios = split(',', $DefRatios);
foreach my $r (@Ratios) {
    die "Deformation ratio $r must be in [0.1,1.5]\n" if (($r < 0.1) || ($r > 1.5));
    
    $r = 1 - $r if $r < 1;

    #PREPARE INTERMEDIATE OUTPUT FILE NAMES
    $determinant= $dir_for_temp_files.'determinant_r_'.$r.$Mask;
print "$determinant\n";
    $target_xfm=$dir_for_temp_files.'determinant_r_'.$r.'.xfm';
   # $OutputFile=$OutputDir.'/'.$basename.'_deformed_by_'.$r.'atROI'.$Mask;
    $OutputFile=$basename.'_deformed_by_'.$r.'atROI'.$Mask;
    #Create a target determinant can be from a mask
    Spawn(['minccalc', '-clobber', '-expression', "(abs(A[0] - 1) < 0.5) ? $r : 1", $Mask, $determinant])&&die;
    
    # Create transformation matrices
    if (defined $Blur) {
	#Blur the determinant file by a kernel
	my $blurred_determinant=$dir_for_temp_files.'blurred'.$Blur.'determinant_r_'.$r.$Mask;
	Spawn(['blur_determinant.py', '-b',$Blur,$determinant, $blurred_determinant])&&die;
	$determinant = $blurred_determinant;
    }

    #generate transformation files for local deformations
    Spawn(['create_deformation.py', '-m',$tolerance_area,'-t',$Def_Tol,'-d',$dir_for_temp_files,'-i',$iteration, $determinant, $target_xfm])&&die;

    #complete deformation
    Spawn(['mincresample', '-clobber', '-like', $InputFile,'-transformation', $target_xfm, $InputFile, $OutputFile])&&die;
}

sub MakeMask {
#This subroutine is used if the uses wants to generate a cubic mask area around coordinate x, y, z
   my ($input, $x, $y, $z, $sizex,$sizey,$sizez) = @_;
   my $reshaped =  'x'.$x.'-y'.$y.'-z'.$z.'dimx'.$sizex.'.dimy'.$sizey.'.dimz'.$sizez.'.mnc';
   my $block = $dir_for_temp_files.'/block.mnc';
   my $mask =  $dir_for_temp_files.'/mask.mnc';
   Spawn(['mincreshape', '-clobber', '-start', "$x,$y,$z", '-count', "${sizex},${sizey},${sizez}", $input, $block])&&die;
   Spawn(['minccalc', '-clobber', '-expression', "1", $block, $mask])&&die;  
   Spawn(['mincresample','-clobber', '-like', $input, $mask, $reshaped])&&die;
   return $reshaped;
}

sub TolerationRing {
    #this subroutine create a ring of tolerance around the mask area at which the deformation will be applied
    my ($inputfile, $Tolerance_space,$dir_for_temp_files) = @_;
    my $tmp = $dir_for_temp_files;
    my $D="D";
print "$D\n";
    my $D= "D" x $Tolerance_space;
print "$D\n";
    my $Tolerance_ring=$tmp.'/'.$D.'ring.mnc';
print "$Tolerance_ring\n";
    my $Dilated_mask = $tmp.'/'.$D.'dilated.mnc';  #this needs to be generalized
print "$Dilated_mask\n";
   die "Tolerance cannot be larger than 20" if ($Tolerance_space >19.5);
   Spawn(['mincmorph', '-clobber', '-successive', $D, $inputfile, $Dilated_mask])&&die;
   Spawn(['minccalc','-clobber', '-expression', 'if(A[0] == 1 && A[1] == 0) {out = 1;} else {out = 0;}', $Dilated_mask, $inputfile,$Tolerance_ring])&&die;
   return $Tolerance_ring;
}






