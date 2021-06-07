# Simulation Toolkit for Coticometry Pipeline

Tools in this repository can be used to simulate artificial lesions in the brain in order to estimate the sensitivity and specificity of lesion
detection, using different automated corticometry pipelines.

To set up software you need the following:

1. Install the software packages needed to run the deformation-2.pl script. Please follow steps in: https://github.com/aces/simulation_toolkit_singularity/blob/main/Singularity

2. Obtain data from 
https://ida.loni.usc.edu/collaboration/access/appLicense.jsp;jsessionid=B0278AF5FD413E9AC14512DF841FFCA4/ 

3. Run deformation pipeline"

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
    
  ./deformation.pl -input ICBM_00100_t1_final.mnc -output Debugging_Folder -deformation_ratio 0.6 -coordinate 70 100 70 10 10 10 -tolerance_space 4 -blur_determinant 0.25  -error 0.00001  -iteration 100 


The locally-deformed output file name includes input parameters to simplify creating GLM matrices for statistical analysis. 
    
ICBM_00100_t1_final_deformed_by_0.4atROIx70-y100-z70dimx10.dimy10.dimz10.mnc. 


There following intermediate files are generated to help you do quality control and can be deleted:
    
/Debugging_Folder/TMP/block.mnc
   
/Debugging_Folder/TMP/blurred0.25determinant_r_0.4x70-y100-z70dimx10.dimy10.dimz10.mnc
    
/Debugging_Folder/TMP/DDDDdilated.mnc   <<number of D's corresponds to the number of times the tolerance space (defined to be 4 in the commandline) is dilated
    
/Debugging_Folder/TMP/DDDDring.mnc
    
/Debugging_Folder/TMP/determinant_r_0.4_grid.mnc
    
/Debugging_Folder/TMP/determinant_r_0.4x70-y100-z70dimx10.dimy10.dimz10.mnc
    
/Debugging_Folder/TMP/determinant_r_0.4.xfm
    
/Debugging_Folder/TMPmask.mnc
    
ALTERNATIVELY: If you don't want to use this Perl wrapper, then follow the instructions for creating your own deformations:
https://wiki.mouseimaging.ca/display/MICePub/Generating+deformation+fields

Source code for deformation pipeline and dependencies (MINC):
https://github.com/Mouse-Imaging-Centre/generate_deformation_fields

    
4. Example Data, Scripts and Statistical analysis used in our Frontier's Paper can be found here: https://github.com/aces/simulation_toolkit_statistics

5. All these tools and data needed will be made available via CBRAIN. To learn more, please contact us at cbrain-support.mni@mcgill.ca. In the subject line, pleasee be sure to write SIMULATION TOOLKIT.
