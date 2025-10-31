#!/bin/bash 

dosetup1=1 #do first part of setup
dosetup2=1 #do second part of setup (after first manual modifications)
dosetup3=1 #do second part of setup (after namelist manual modifications)
dosubmit=1 #do the submission stage! Before this step, set up to run on dedicated nodes!!
forcenewcase=1 #scurb all the old cases and start again
doanalysis=0 #analyze output (not yet coded up)
numCPUs=0 #Specify number of cpus. 0: use default


echo "setup1, setup2, setup3, submit, forcenewcase, analysis:", $dosetup1, $dosetup2, $dosetup3, $dosubmit, $forcenewcase, $doanalysis 

USER="kjetisaa"
project='nn9560k' #nn8057k: EMERALD, nn2806k: METOS, nn9188k: CICERO, nn9560k: NorESM (INES2), nn9039k: NorESM (UiB: Climate predition unit?), nn2345k: NorESM (EU projects)
machine='betzy'

#NorESM dir
noresmrepo="NorESM_3_0_beta03b_v2"
noresmversion="noresm3_0_beta03b"

resolution="ne16pg3_tn14" #f19_g17, ne30pg3_tn14, f45_f45_mg37
casename="n1850.$resolution.$noresmversion.CPLHIST_C8_4p8_ctsmV14.`date +"%Y-%m-%d"`"  #Update here
compset="1850_CAM70%LT%NORESM%CAMoslo_CLM60%FATES-NOCOMP_CICE_BLOM%HYB%ECO_MOSART_DGLC%NOEVOLVE_SWAV_SESP"

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
    if [[ -d "$noresmrepo" ]] 
    then
        cd $noresmrepo
        echo "Already have NorESM repo"
    else
        echo "Cloning NorESM"
        
        git clone https://github.com/NorESMhub/NorESM/ $noresmrepo
        cd $noresmrepo
        git checkout $noresmversion
        #replace string in .gitmodules: v1.12.11 to v1.12.12
        sed -i 's/v1.12.11/v1.12.12/g' .gitmodules
        echo "Updated .gitmodules to use v1.12.12 of BLOM:"
        grep -i -n 'v1.12.12' .gitmodules
        sed -i 's/ctsm5.3.045_noresm_v13/ctsm5.3.045_noresm_v14/g' .gitmodules
        echo "Updated .gitmodules to use ctsm5.3.045_noresm_v14:"
        grep -i -n 'ctsm5.3.045_noresm_v14' .gitmodules
        ./bin/git-fleximod update
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
        ./create_newcase --case $workpath$casename --compset $compset --res $resolution --project $project --machine betzy --compiler intel --run-unsupported --user-mods-dir $workpath$noresmrepo/cime_config/usermods_dirs/reduced_out_devsim/                
        cd $workpath$casename

        #XML changes
        echo 'updating settings'
        ./xmlchange NTASKS=1536,NTASKS_OCN=500,NTASKS_ICE=768,NTASKS_LND=768,ROOTPE_OCN=1536,ROOTPE_LND=768

        ./xmlchange RUN_TYPE=branch
        ./xmlchange RUN_STARTDATE=0321-01-01,START_TOD=00000    #Update here
        ./xmlchange RUN_REFCASE=n1850.ne16pg3_tn14.noresm3_0_beta03b.CPLHIST.2025-10-29 #Update here
        ./xmlchange RUN_REFDATE=0321-01-01,RUN_REFTOD=00000 #Update here
        ./xmlchange GET_REFCASE=FALSE
        ./xmlchange DRV_RESTART_POINTER=rpointer.cpl.0321-01-01-00000 #Update here

        ./xmlchange STOP_OPTION=nyears
        ./xmlchange STOP_N=5
        ./xmlchange REST_N=5
        ./xmlchange RESUBMIT=9        
        ./xmlchange REST_OPTION=nyears
        ./xmlchange DATA_ASSIMILATION_SCRIPT=$(./xmlquery --value SRCROOT)/tools/rerun_noresm.py
        ./xmlchange DATA_ASSIMILATION_CYCLES=2
        ./xmlchange --subgroup case.run JOB_WALLCLOCK_TIME=48:00:00
        ./xmlchange --subgroup case.st_archive JOB_WALLCLOCK_TIME=2:00:00
        ./xmlchange --subgroup case.compress JOB_WALLCLOCK_TIME=12:00:00        

        echo 'done with xmlchanges'        
        
        ./case.setup
        echo ' '       
        echo "Done with Setup. Updateing namelists in $workpath$casename/user_nl_*"    
## Changes to user_nl_* files goes here

cat <<EOF >> user_nl_cam
use_aerocom                = .false.
interpolate_nlat           = 96
interpolate_nlon           = 144
interpolate_output         = .true.,.true.
history_aerosol            = .false.
zmconv_c0_lnd              =  0.0075D0
zmconv_c0_ocn              =  0.0075D0
zmconv_ke                  =  5.0E-6
zmconv_ke_lnd              =  1.0E-5
clim_modal_aero_top_press  =  1.D-4
bndtvg                     = '/cluster/shared/noresm/inputdata/atm/cam/ggas/noaamisc.r8.nc'
dust_emis_method           = 'Leung_2023'
dust_emis_fact             = 6.1D0
rafsip_on                  = .true.
micro_mg_dcs               = 700.D-6
clubb_c8                   =  4.8
nhtfrq = 0, -24
mfilt  = 1,   30 
ndens  = 2,   2
fincl2 = 'Z500', 'T850', 'U850', 'V850'
EOF

cat <<EOF >> user_nl_cpl
ocean_albedo_scheme = 1
histaux_atm2med_file1_enabled = .true.
histaux_atm2med_file2_enabled = .true.
histaux_atm2med_file3_enabled = .true.
histaux_atm2med_file4_enabled = .true.
histaux_atm2med_file5_enabled = .true.
histaux_rof2med_file1_enabled = .true.
histaux_atm2med_file5_ntperfile = 1
histaux_atm2med_file5_history_n = 1
histaux_atm2med_file5_history_option = 'ndays'
histaux_rof2med_file1_ntperfile = 1
histaux_rof2med_file1_history_n = 1
histaux_rof2med_file1_history_option = 'ndays'
histaux_l2x1yrg = .true.
EOF

cat <<EOF >> user_nl_blom
BRINE_MLBASE_FRAC = 0.5
IWDFAC = 0.35
EOF

        echo "done with user_nl_* modifications"

        #more user_nl_*
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
    # copy restart files and pointers
    cp /cluster/work/users/kjetisaa/archive/n1850.ne16pg3_tn14.noresm3_0_beta03b.CPLHIST.2025-10-29/rest/0321-01-01-00000/*.r*.nc /cluster/work/users/kjetisaa/noresm/$casename/run/ #Update here
    cp /cluster/work/users/kjetisaa/archive/n1850.ne16pg3_tn14.noresm3_0_beta03b.CPLHIST.2025-10-29/rest/0321-01-01-00000/rpointer.*0321-01-01-00000 /cluster/work/users/kjetisaa/noresm/$casename/run/ #Update here
    echo "copied restart files and pointers"

    cd $workpath$casename
    ./case.submit
    echo " "
    echo 'done submitting'       
fi