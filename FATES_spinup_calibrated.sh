#!/bin/bash 

#Scrip to clone, build and run NorESM on Betzy

dosetup1=0 #do first part of setup
dosetup2=1 #do second part of setup (after first manual modifications)
dosetup3=1 #do second part of setup (after namelist manual modifications)
dosubmit=1 #do the submission stage
forcenewcase=1 #scurb all the old cases and start again
forcenewclone=0 #scurb old clone and start again. Do this if more than about 30 days since last clone
doanalysis=0 #analyze output (not yet coded up)

echo "setup1, setup2, setup3, submit, forcenewcase, analysis:", $dosetup1, $dosetup2, $dosetup3, $dosubmit, $forcenewcase, $doanalysis 

USER="kjetisaa"
project='nn9560k' #nn8057k: EMERALD, nn2806k: METOS, nn9188k: CICERO, nn9560k: NorESM (INES2), nn9039k: NorESM (UiB: Climate predition unit?)
machine='betzy'

STAGE=COLDSTART_SPINUP_1850 #Previously AD spinup step
#STAGE=CONTINUE_SPINUP #Previously postAD spinup step
#STAGE=TRANSIENT_LU_CONSTANT_CO2_CLIMATE
#STAGE=TRANSIENT_LU_TRANSIENT_CO2_CLIMATE

#Case name
if [ "$STAGE" = "COLDSTART_SPINUP_1850" ]; then
    case_label="_coldstart_adrianas_tuning_v2"
elif [ "$STAGE" = "CONTINUE_SPINUP_1850" ]; then
    case_label="_continue_adrianas_tuning"
elif [ "$STAGE" = "TRANSIENT_LU_CONSTANT_CO2_CLIMATE" ]; then
    case_label="_transientLUspinup_adrianas_tuning"
fi

resolution="ne30pg3_tn14" #f19_g17, ne30pg3_tn14
casename="i1850.FATES-NOCOMP.$resolution.alpha08d.20250218$case_label"
casename_init="i1850.FATES-NOCOMP-postAD.ne30pg3_tn14.alpha08d.20250207" #If you want to restart from a previous case

compset="1850_DATM%QIA_CLM60%FATES_SICE_SOCN_SROF_SGLC_SWAV"

#NorESM dir
noresmrepo="NorESM_alpha08d_photosynthesis_update" 
echo "NorESM repo: $noresmrepo"
echo "Case name: $casename"

starttime="0001-01-01"
lastrestarttime="$starttime-00000"
echo $lastrestarttime   

# aka where do you want the code and scripts to live?
workpath="/cluster/work/users/$USER/" 

# some more derived path names to simplify scripts
scriptsdir=$workpath$noresmrepo/cime/scripts/

#case dir
casedir=$workpath$casename

#where are we now?
startdr=$(pwd)

#Download code and checkout externals
if [ $dosetup1 -eq 1 ] 
then
    cd $workpath

    pwd
    #go to repo, or checkout code
    if [[ -d "$noresmrepo" && $forcenewclone -eq 0 ]] 
    then
        cd $noresmrepo
        echo "Already have NorESM repo"
    else
        if [[ $forcenewclone -eq 1 ]]
        then
            echo "Removing old NorESM repo"
            rm -rf $noresmrepo
        fi

        echo "Cloning NorESM"                
        git clone https://github.com/NorESMhub/NorESM/ $noresmrepo #If this is crashing, try loging in to another node, e.g.: ssh -Y brukernavn@login-3.betzy.sigma2.no        
        cd $noresmrepo
        git checkout noresm2_5_alpha08d

        echo "updating externals"
        ./bin/git-fleximod update

        echo "Checking out correct CLM version"
        cd componensts/clm/src
        git fetch origin
        git checkout ctsm5.3.11-noresm_v0

        echo "Checking out correct FATES version"
        cd fates
        git remote add afoster https://github.com/adrifoster/fates.git
        git fetch afoster
        git checkout leaf_photo_update

        echo "Built model here: $workpath$noresmrepo"        

    fi
fi

#Make case
if [[ $dosetup2 -eq 1 ]] 
then
    cd $scriptsdir

    if [[ $forcenewcase -eq 1 ]]
    then 
        if [[ -d "$workpath$casename" ]] 
        then    
        echo "$workpath$casename exists on your filesystem. Removing it!"
        rm -rf $workpath$casename
        rm -r $workpath/noresm/$casename
        rm -r $workpath/archive/$casename
        rm -r $casename
        fi
    fi
    if [[ -d "$workpath$casename" ]] 
    then    
        echo "$workpath$casename exists on your filesystem."
    else
        
        echo "making case:" $workpath$casename        
        ./create_newcase --case $workpath$casename --compset $compset --res $resolution --project $project --run-unsupported --mach betzy -pecount L
        cd $workpath$casename

        #XML changes
        echo 'updating settings'
        ./xmlchange STOP_OPTION=nyears
        ./xmlchange STOP_N=2
        ./xmlchange RESUBMIT=4
        ./xmlchange --subgroup case.run JOB_WALLCLOCK_TIME=02:00:00
        ./xmlchange --subgroup case.st_archive JOB_WALLCLOCK_TIME=02:00:00        
        ./xmlchange RUN_STARTDATE=$starttime
        
        if [ "$STAGE" = "COLDSTART_SPINUP_1850" ]; then
            ./xmlchange CLM_ACCELERATED_SPINUP="on"
        elif [ "$STAGE" = "CONTINUE_SPINUP" ]; then
            ./xmlchange CLM_ACCELERATED_SPINUP="off"
        fi

        echo 'done with xmlchanges'        
        
        ./case.setup
        echo ' '
        echo "Done with Setup. Update namelists in $workpath$casename/user_nl_*"

        #Add following lines to user_nl_clm   
        echo "fates_paramfile='/cluster/work/users/rosief/git/calibration_parameter_files/SP_calib/fates_params_psupdate_branch_5.3.10_AFupdates.nc'" >> $workpath$casename/user_nl_clm
        #echo "fates_paramfile = '/cluster/work/users/rosief/git/calibration_parameter_files/SP_calib/fates_params_det_alpha09.nc'" >> $workpath$casename/user_nl_clm
        echo "use_fates_nocomp=.true." >> $workpath$casename/user_nl_clm
        echo "use_fates_fixed_biogeog=.true." >> $workpath$casename/user_nl_clm
        
        if [ "$STAGE" = "COLDSTART_SPINUP_1850" ]; then
            echo 'here'
            cat >> $workpath$casename/user_nl_clm <<EOF            
            hist_empty_htapes = .true.
            hist_fincl1 =   'TOTSOMC','TOTSOMN','TLAI','FSH','EFLX_LH_TOT','TOTEXICE_VOL','TWS','TSA','TBOT',
                            'FATES_GPP','FATES_NPP','TOTECOSYSC','FATES_VEGC',
                            'FATES_STOREC', 'FATES_VEGC','FATES_SAPWOODC', 'FATES_FROOTC', 'FATES_REPROC', 'FATES_STRUCTC', 'FATES_NONSTRUCTC',
                            'FATES_VEGC_ABOVEGROUND', 'FATES_CANOPY_VEGC', 'FATES_USTORY_VEGC'
EOF
        elif [ "$STAGE" = "CONTINUE_SPINUP" ]; then
            # Set the finidat file to the last restart file saved in previous step
            echo " finidat = '/cluster/work/users/kjetisaa/archive/${casename_init}/rest/${lastrestarttime}/${casename_init}.clm2.r.$lastrestarttime.nc' " >> user_nl_clm
            
        fi

        

    fi
fi

#Build case case
if [[ $dosetup3 -eq 1 ]] 
then
    cd $workpath$casename
    echo "Currently in" $(pwd)
    ./case.build
    echo ' '    
    echo "Done with Build"
fi

#Submit job
if [[ $dosubmit -eq 1 ]] 
then
    cd $workpath$casename
    ./case.submit
    echo " "
    echo 'done submitting'       
fi

#After it has finised:
# - copy to NIRD: https://noresm-docs.readthedocs.io/en/noresm2/output/archive_output.html
    #e.g.: rsync -aP --chown=OWNER:GROUP n1850.FATES-NOCOMP-postAD.ne30pg3_tn14.alpha08d.20250129_fixFincl1/ kjetisaa@login.nird.sigma2.no:/nird/datalake/NS9560K/noresm3/cases/n1850.FATES-NOCOMP-postAD.ne30pg3_tn14.alpha08d.20250129_fixFincl1/
    #First need to create folder on nird
# - run land diag: https://github.com/NorESMhub/xesmf_clm_fates_diagnostic 
    
#Useful commands: 
# - cdo -fldmean -mergetime -apply,selvar,FATES_GPP,TOTSOMC,TLAI,TWS,TOTECOSYSC [ n1850.FATES-NOCOMP-AD.ne30_tn14.alpha08d.20250127_fixFincl1.clm2.h0.00* ] simple_mean_of_gridcells.nc