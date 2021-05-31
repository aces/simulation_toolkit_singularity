# Deformation field

This PERL script is a wrapper that is calling sequence of commands for generating deformation fields scrips
https://wiki.mouseimaging.ca/display/MICePub/Generating+deformation+fields
Source code for deformation pipeline and dependencies (MINC):
https://github.com/Mouse-Imaging-Centre/generate_deformation_fields

Usage

./deformation.pl -input ICBM_00100_t1_final.mnc <<this could be any anatomical minc file, for a collection of minc files>> -output dummy_hoho -deformation_ratio 0.6 -coordinate 70 100 70 10 10 10 -tolerance_space 4 <<default>> -blur_determinant 0.25 <<default>> -error 0.00001 <<default>> -iteration 100 


The output of running this command looks like this:
ICBM_00100_t1_final_deformed_by_0.4atROIx70-y100-z70dimx10.dimy10.dimz10.mnc. <the output file name is constructed based on input parameters>


We will also have a directory dummy_hoho/TMP that will contain the in-between-files. 



$:/dummy_hoho/TMP$ ls

block.mnc

blurred0.25determinant_r_0.4x70-y100-z70dimx10.dimy10.dimz10.mnc

DDDDdilated.mnc

DDDDring.mnc

determinant_r_0.4_grid.mnc

determinant_r_0.4x70-y100-z70dimx10.dimy10.dimz10.mnc

determinant_r_0.4.xfm

mask.mnc
