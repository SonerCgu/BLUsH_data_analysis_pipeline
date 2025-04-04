#!/bin/sh

#Following script has been made by Naman Jain with following features included in the
#different version upgrades

##Calling all the functions that will be used in the upcoming script

#01.04.2025: Intial Script Planned, all functions called through external script

source ./All_functions_to_be_called.sh #converting data from either Bruker or Dicom format to NIFTI format

##In order to use awk, you need to convert xlsx file to csv file

root_location="/Volumes/pr_ohlendorf/fMRI"

cd $root_location/RawData
xlsx2csv Animal_Experiments_Sequences.xlsx Animal_Experiments_Sequences.csv

# Read the CSV file line by line, skipping the header
awk -F ',' 'NR>1 {print $0}' "Animal_Experiments_Sequences.csv" | while IFS=',' read -r col1 dataset_name project_name sub_project_name structural_name functional_name _
do
    # Trim any extra whitespace
    project_name=$(echo "$project_name" | xargs)
    
    if [[ "$project_name" == "Project_BLusH_XC_SC" ]]; then
        export Project_Name="$project_name"
        export Sub_project_Name="$sub_project_name"
        export Dataset_Name="$dataset_name"
        export run_number="$functional_name"
        
        Path_Raw_Data="$root_location/RawData/$project_name/$sub_project_name"
        Path_Analysed_Data="$root_location/AnalysedData/$project_name/$sub_project_name/$Dataset_Name"
        echo "Processing: $Path_Raw_Data"
        
        # Add your further processing steps here

        datapath=$(find "$Path_Raw_Data" -type d -name "*${Dataset_Name}*" 2>/dev/null)
        echo "$datapath"     
        
      
        echo "Dataset Currently Being Analysed is": $Dataset_Name "and run number is:" $run_number  

        if [ -d "$Path_Analysed_Data" ]; then
            echo "$Path_Analysed_Data does exist."
        else
            mkdir $Path_Analysed_Data
        fi

        cd $Path_Analysed_Data
        pwd

        LOG_DIR="$datapath/Data_Analysis_log" # Define the log directory where you want to store the script.
        user=$(whoami)
        log_execution "$LOG_DIR" || exit 1

        FUNC_PARAM_EXTARCT $datapath/$run_number

        CHECK_FILE_EXISTENCE "$Path_Analysed_Data/$run_number$SequenceName"
        cd $Path_Analysed_Data/$run_number''$SequenceName
        
        BRUKER_to_NIFTI $datapath $run_number $datapath/$run_number/method
        echo "This data is acquired using $SequenceName"

        log_function_execution "$LOG_DIR" "Motion Correction using AFNI executed on Run Number $run_number acquired using $SequenceName"|| exit 1
        MOTION_CORRECTION $MiddleVolume G1_cp.nii.gz mc_func
                    
        log_function_execution "$LOG_DIR" "Checked for presence of spikes in the data on Run Number $run_number acquired using $SequenceName"|| exit 1
        CHECK_SPIKES mc_func+orig

        log_function_execution "$LOG_DIR" "Temporal SNR estimated on Run Number $run_number acquired using $SequenceName"|| exit 1
        TEMPORAL_SNR_using_AFNI mc_func+orig

        log_function_execution "$LOG_DIR" "Smoothing using FSL executed on Run Number $run_number acquired using $SequenceName"|| exit 1
        SMOOTHING_using_FSL mc_func.nii.gz
 
        log_function_execution "$LOG_DIR" "Signal Change Map created for Run Number $run_number acquired using $SequenceName"|| exit 1
        SIGNAL_CHANGE_MAPS mc_func.nii.gz 50 250 $datapath/$run_number 5 5 mean_mc_func.nii.gz

    fi
done

# test
# # ## Main Script Starts from here
# # # File_with_Dataset_Names="/Volumes/pr_ohlendorf/fMRI/Project1_CBV_fMRI_NJ/RawData/DatasetNames.txt"
# # File_with_Dataset_Names="/Users/njain/Desktop/data.txt"

# # indices=(1 2) #enter the index number of the file name that you would like to analyse

# # for datasets in "${indices[@]}"; do
    
# #     DatasetName=$(awk -F "\"*,\"*" -v var="$datasets" 'NR == var {print $1}' $File_with_Dataset_Names)
# #     echo "Dataset Currently Being Analysed is": $DatasetName

# #     #Locate the source of Raw Data on the server, this needs to be changed by the user based on the paths defined in their system#
# #     Raw_Data_Path="/Volumes/pr_ohlendorf/fMRI/RawData/Project_MMP9_NJ_MP/test_animals/$DatasetName"
# #     Analysed_Data_Path="/Volumes/pr_ohlendorf/fMRI/AnalysedData/Project_MMP9_NJ_MP/test_animals/$DatasetName"

# #     # Raw_Data_Path="/Users/njain/Desktop/RawData/$DatasetName"
# #     # Analysed_Data_Path="/Users/njain/Desktop/AnalysedData/$DatasetName"

# #     LOG_DIR="$Raw_Data_Path/Data_Analysis_log" # Define the log directory where you want to store the script.
# #     user=$(whoami)
# #     log_execution "$LOG_DIR" || exit 1

# #     CHECK_FILE_EXISTENCE $Analysed_Data_Path
   
# #     cd $Raw_Data_Path
# #     pwd
# #     for runnames in *; do #31.07.2024 instead of adding run numbers the code picks all the run numbers automatically located in the folder
# #     # if [[ $runname =~ ^[0-9]+$ ]]; then
       
# #         echo ""
# #         echo ""
# #         echo "Currently Analysing Run Number: $runnames"
# #         echo ""
# #         echo ""

# #         Raw_Data_Path_Run="$Raw_Data_Path/$runnames"
            
# #         FUNC_PARAM_EXTARCT $Raw_Data_Path_Run

# #         word_to_check="1_Localizer"
                
# #         if echo "$SequenceName" | grep -q "$word_to_check"; then
# #             echo "This data is acquired using '$word_to_check'. This will not be analyzed."
            
# #         else
# #             echo "This data is acquired using $SequenceName"

# #             CHECK_FILE_EXISTENCE "$Analysed_Data_Path/$runnames$SequenceName"
# #             cd $Analysed_Data_Path/$runnames''$SequenceName

#             BRUKER_to_NIFTI $Raw_Data_Path $runnames $Raw_Data_Path/$runnames/method

#             if [ "$NoOfRepetitions" == "1" ]; then
#                 echo "It is a Structural Scan or Test Scan acquired using $SequenceName"
                
#             else
#                 echo "It is an fMRI scan"
                                  
#                 if grep -q "PreBaselineNum" "$Raw_Data_Path_Run/method"; then
#                     echo "It is a baseline scan"
                    
#                     TaskDuration=$(echo "$Baseline_TRs + ($StimOn_TRs + $StimOff_TRs) * $NoOfEpochs" | bc)
                    
#                     BlockLength=$(($StimOn_TRs + $StimOff_TRs))
#                     MiddleVolume=$(($NoOfRepetitions / 2))
                        
#                     if [ $TaskDuration == $NoOfRepetitions ]; then
#                         echo "It is Stimulated Scan with a total of $NoOfRepetitions Repetitions"
                        
#                         STIMULUS_TIMING_CREATION $NoOfEpochs $BlockLength $Baseline_TRs stimulus_times.txt #16.08.2024 creating epoch times
#                         ACTIVATION_MAPS sm_mc_stc_func+orig stimulus_times.txt 6 stats_offset_sm_mc_stc_func #16.08.2024 adding a function to estimate activation maps from the data      
                        
                        
                        
#                         # CHECK_FILE_EXISTENCE TimeSeiesVoxels
                
#                         # CREATING_3_COLUMNS $NoOfEpochs $Baseline_TRs $BlockLength $VolTR
#                         # TIME_COURSE_PYTHON mc_stc_func.nii parenchyma.nii.gz parenchyma.txt activation_times.txt $BlockLength $NoOfEpochs #10.09.2024 function to get time course for individual voxel and averaged for all voxels in a mask
                        
#                         # TIME_SERIES $Analysed_Data_Path/$runnames''$SequenceName/NIFTI_file_header_info.txt
            
#                     else
#                         echo "It is a Baseline/ rs-fMRI Scan with a total of $NoOfRepetitions Repetitions"

#                         log_function_execution "$LOG_DIR" "Motion Correction using AFNI executed on Run Number $runnames acquired using $SequenceName"|| exit 1
#                         MOTION_CORRECTION $MiddleVolume G1_cp.nii.gz mc_func
                    
#                         log_function_execution "$LOG_DIR" "Checked for presence of spikes in the data on Run Number $runnames acquired using $SequenceName"|| exit 1
#                         CHECK_SPIKES mc_func+orig

#                         log_function_execution "$LOG_DIR" "Temporal SNR estimated on Run Number $runnames acquired using $SequenceName"|| exit 1
#                         TEMPORAL_SNR_using_AFNI mc_func+orig

#                         log_function_execution "$LOG_DIR" "Smoothing using FSL executed on Run Number $runnames acquired using $SequenceName"|| exit 1
#                         SMOOTHING_using_FSL mc_func.nii.gz

#                         log_function_execution "$LOG_DIR" "Signal Change Map created for Run Number $runnames acquired using $SequenceName"|| exit 1
#                         SIGNAL_CHANGE_MAPS mc_func.nii.gz 100 500 $Raw_Data_Path_Run 5 5 mean_mc_func.nii.gz

                       

#                     fi
                
#                 else 
#                     echo "It is a test scan"
                    
#                 fi
        
#             fi
        
#         fi
 
#     done 

# done


#    # if [ $? -eq 1 ]; then
#         #     echo "Run already analysed, moving to next run"
#         #     continue
#         # fi