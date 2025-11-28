#!/bin/bash 

#Scrip to clone, build and run NorESM on Betzy

dosetup1=1 #do first part of setup
dosetup2=1 #do second part of setup (after first manual modifications)
dosetup3=1 #do second part of setup (after namelist manual modifications)
dosubmit=1 #do the submission stage
forcenewcase=1 #scurb all the old cases and start again

echo "setup1, setup2, setup3, submit, forcenewcase:", $dosetup1, $dosetup2, $dosetup3, $dosubmit, $forcenewcase

USER="kjetisaa"
project='nn9560k' #nn8057k: EMERALD, nn2806k: METOS, nn9188k: CICERO, nn9560k: NorESM (INES2), nn9039k: NorESM (UiB: Climate predition unit?), nn2345k: NorESM (EU projects)
machine='betzy'

#NorESM dir
noresmrepo="ctsm5.3.045_noresm_v15" 
noresmversion="ctsm5.3.045_noresm_v15"

resolution="ne16pg3_tn14" #f19_g17, ne30pg3_tn14, f45_f45_mg37, ne16pg3_tn14 
casename="i1850.$resolution.$noresmversion.CPLHIST_ADspinup.`date +"%Y-%m-%d"`"
echo "casename: $casename"
compset="1850_DATM%CPLHIST_CLM60%FATES-NOCOMP_SICE_SOCN_SROF_SGLC_SWAV_SESP"

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
        
        if [[ $noresmversion == ctsm* ]] ; then
            echo "Using CTSM version $noresmversion"
            git clone https://github.com/NorESMhub/CTSM/ $noresmrepo
        else
            echo "Using NorESM version $noresmversion"
            git clone https://github.com/NorESMhub/NorESM/ $noresmrepo
        fi
        cd $noresmrepo
        git checkout $noresmversion
        ./bin/git-fleximod update
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
        ./create_newcase --case $workpath$casename --compset $compset --res $resolution --project $project --run-unsupported --mach betzy

        cd $workpath$casename

        #XML changes
        echo 'updating settings' 
        ./xmlchange NTASKS_ATM=-1
        ./xmlchange NTASKS_OCN=-7
        ./xmlchange NTASKS_LND=-7
        ./xmlchange NTASKS_ICE=-7
        ./xmlchange NTASKS_ROF=-7
        ./xmlchange NTASKS_GLC=-7               
        ./xmlchange DATM_CPLHIST_CASE=n1850.ne16pg3_tn14.noresm3_0_beta03b.CPLHIST.2025-10-29
        ./xmlchange DATM_CPLHIST_DIR=/cluster/shared/noresm/inputdata/cplhist/noresm3_0/n1850.ne16pg3_tn14.noresm3_0_beta03b.CPLHIST.2025-10-29/cplhist/
        ./xmlchange DATM_PRESNDEP=none
        ./xmlchange DATM_YR_START=351
        ./xmlchange DATM_YR_END=410
        ./xmlchange CLM_ACCELERATED_SPINUP=on
        ./xmlchange DATM_PRESAERO=clim_1850 
        ./xmlchange RUN_STARTDATE=0001-01-01
        ./xmlchange STOP_OPTION=nyears
        ./xmlchange STOP_N=50
        ./xmlchange RESUBMIT=3
        ./xmlchange --subgroup case.run JOB_WALLCLOCK_TIME=24:00:00
        ./xmlchange --subgroup case.st_archive JOB_WALLCLOCK_TIME=00:30:00        
        
        echo 'done with xmlchanges'        
        
        ./case.setup
        echo ' '
        echo "Done with Setup. Update namelists in $workpath$casename/user_nl_*"

        #Add following lines to user_nl_clm   
cat <<EOF >> user_nl_clm
glacier_region_behavior = 'single_at_atm_topo','UNSET','virtual','virtual'      
use_fates_nocomp=.true.
use_fates_fixed_biogeog=.true.
fates_stomatal_model='medlyn2011'
fates_spitfire_mode=4
use_fates_luh=.true.
use_fates_lupft=.true.
fates_harvest_mode='luhdata_area'
use_fates_potentialveg=.false.
do_transient_lakes = .false.
do_transient_urban = .false.
fluh_timeseries='/cluster/shared/noresm/inputdata/LU_data_CMIP7/LUH2_states_transitions_management.timeseries_ne16_hist_steadystate_1850_2025-11-06_cdf5.nc'
flandusepftdat='/cluster/shared/noresm/inputdata/LU_data_CMIP7/fates_landuse_pft_map_to_surfdata_ne16np4_251106_cdf5.nc'
hist_empty_htapes = .true.
hist_fincl1 = 'TSA','RAIN','SNOW','EFLX_LH_TOT','FSH','QSOIL','TLAI','FCO2','TOTSOMC','TOTSOMC_1m','FATES_VEGC','FATES_GPP','FATES_NEP','FATES_NPP','TWS','H2OSNO','FSNO','PROD100C','PROD10C','FATES_LITTER_AG_CWD_EL','FATES_LITTER_AG_FINE_EL','FATES_LITTER_BG_CWD_EL','FATES_LITTER_BG_FINE_EL','FATES_GRAZING','FATES_FIRE_CLOSS','FATES_BURNFRAC'
hist_mfilt=1
hist_nhtfrq=0  
EOF

        #Add reservation in case.run and case.st_archive
        sed -i '10i\#SBATCH  --reservation=nn9560k' .case.run
        sed -i '10i\#SBATCH  --reservation=nn9560k' case.st_archive
        #Replace lines in case.st_archive to use 4 nodes and 4 tasks
        sed -i 's/#SBATCH  --nodes=1/#SBATCH  --nodes=4/g' case.st_archive
        sed -i 's/#SBATCH  --ntasks=1/#SBATCH  --ntasks=4/g' case.st_archive
        sed -i 's/#SBATCH  --partition=preproc/#SBATCH  --partition=normal/g' case.st_archive
        sed -i '/mem-per-cpu=1900M/d' case.st_archive
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
# - run land diag: https://github.com/NorESMhub/xesmf_clm_fates_diagnostic 
    # python run_diagnostic_full_from_terminal.py /nird/datalake/NS9560K/kjetisaa/i1850.FATES-NOCOMP-coldstart.ne30pg3_tn14.alpha08d.20250130/lnd/hist/ pamfile=short_nocomp.json outpath=/datalake/NS9560K/www/diagnostics/noresm/kjetisaa/
#Useful commands: 
# - cdo -fldmean -mergetime -apply,selvar,FATES_GPP,TOTSOMC,TLAI,TWS,TOTECOSYSC [ n1850.FATES-NOCOMP-AD.ne30_tn14.alpha08d.20250127_fixFincl1.clm2.h0.00* ] simple_mean_of_gridcells.nc