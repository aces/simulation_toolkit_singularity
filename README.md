# Deformation field

This PERL script is a wrapper that is calling sequence of commands for generating deformation fields scrips
https://wiki.mouseimaging.ca/display/MICePub/Generating+deformation+fields
Source code for deformation pipeline and dependencies (MINC):
https://github.com/Mouse-Imaging-Centre/generate_deformation_fields

Usage
Usage: deformation.pl -input <.mnc> -output <outputdir> [options] 

Mandatory options:
    -deformation_ratio    provide the ratio of deformation, values must be between 0.1 [shrinkage] to 1.50 [expansion] [e.g. 0.1,1.2,0.6,…]
    -mask                 Specify a tolerance map file (.mnc) indicating voxels that have a different amount of error allowed e.g., CSF, background [e.g. your-mask.mnc]
    -coordinate           Specify a hyperslab starting at <x> <y> <z> and extending in respective directions by <sizex> <sizey> <sizez> [e.g. 70 100 80 5 5 5]
    -tolerance_space      Define the buffer area around the deformation region [default = 4]
    
Other options:
    -blur_determinant     Blurring kernel size for blurring deformation determinant blurring kernel 0-1
    -error                Specify the amount of error that is allowed between the specified determinant and the final determinant (per voxel) [default =0.00001]
    -iteration            Specify the maximum number of iterations to update the deformations field (-1 means until convergence) [default 1000]

Example:
  ./deformation.pl -input ICBM_00100_t1_final.mnc -output dummy_hoho -deformation_ratio 0.6 -coordinate 70 100 70 10 10 10 -tolerance_space 4 -blur_determinant 0.25  -error 0.00001  -iteration 100 


The locally-deformed output of running this command looks like this:
ICBM_00100_t1_final_deformed_by_0.4atROIx70-y100-z70dimx10.dimy10.dimz10.mnc. <the output file name is constructed based on input parameters>


There following intermediate files can be deleted:
/dummy_hoho/TMP/block.mnc
/dummy_hoho/TMP/blurred0.25determinant_r_0.4x70-y100-z70dimx10.dimy10.dimz10.mnc
/dummy_hoho/TMP/DDDDdilated.mnc
/dummy_hoho/TMP/DDDDring.mnc
/dummy_hoho/TMP/determinant_r_0.4_grid.mnc
/dummy_hoho/TMP/determinant_r_0.4x70-y100-z70dimx10.dimy10.dimz10.mnc
/dummy_hoho/TMP/determinant_r_0.4.xfm
/dummy_hoho/TMPmask.mnc
