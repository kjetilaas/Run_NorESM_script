#!/bin/bash 

#Scrip to clone, build and run NorESM on Betzy

dosetup1=0 #do first part of setup
dosetup2=1 #do second part of setup (after first manual modifications)
dosetup3=1 #do second part of setup (after namelist manual modifications)
dosubmit=1 #do the submission stage
forcenewcase=1 #scurb all the old cases and start again
doanalysis=0 #analyze output (not yet coded up)

echo "setup1, setup2, setup3, submit, forcenewcase, analysis:", $dosetup1, $dosetup2, $dosetup3, $dosubmit, $forcenewcase, $doanalysis 

USER="kjetisaa"
project='nn9188k' #nn8057k: EMERALD, nn2806k: METOS, nn9188k: CICERO, nn9560k: NorESM (INES2), nn9039k: NorESM (UiB: Climate predition unit?), nn2345k: NorESM (EU projects)
machine='betzy'

#NorESM dir
noresmrepo="NorESM_3_0_alpha01" 
noresmversion="noresm3_0_alpha01"

resolution="ne30pg3_tn14" #f19_g17, ne30pg3_tn14, f45_f45_mg37
casename="i1850.FATES-NOCOMP-noLU_cal15_twosteam.$resolution.$noresmversion.20250326"
compset="1850_DATM%QIA_CLM60%FATES_SICE_SOCN_SROF_SGLC_SWAV"


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
        ./create_newcase --case $workpath$casename --compset $compset --res $resolution --project $project --run-unsupported --mach betzy --pecount L
        cd $workpath$casename

        #XML changes
        echo 'updating settings'
        ./xmlchange STOP_OPTION=nyears
        ./xmlchange STOP_N=10
        ./xmlchange RESUBMIT=9
        ./xmlchange --subgroup case.run JOB_WALLCLOCK_TIME=24:00:00
        ./xmlchange --subgroup case.st_archive JOB_WALLCLOCK_TIME=00:30:00        
        
        echo 'done with xmlchanges'        
        
        ./case.setup
        echo ' '
        echo "Done with Setup. Update namelists in $workpath$casename/user_nl_*"

        #Add following lines to user_nl_clm    
        #echo "flandusepftdat = '/cluster/shared/noresm/inputdata/share_kjetil/fates_landuse_pft_map_to_surfdata_ne30np4_conserve_cdf5.nc'" >> $workpath$casename/user_nl_clm
        echo "use_fates_luh = .false." >> $workpath$casename/user_nl_clm
        echo "use_fates_nocomp=.true." >> $workpath$casename/user_nl_clm
        echo "use_fates_fixed_biogeog=.true." >> $workpath$casename/user_nl_clm 
        echo "fates_radiation_model = 'twostream'" >> $workpath$casename/user_nl_clm       
        echo "fates_paramfile = '/cluster/shared/noresm/inputdata/lnd/clm2/paramdata/FATES_calibration/fates_params_api.38.0.0_14pft_noresm_Rosies_handtune_v15_20250326.nc'" >> $workpath$casename/user_nl_clm        
        #echo "use_fates_lupft = .true." >> $workpath$casename/user_nl_clm
        #echo "fates_harvest_mode = 'luhdata_area'" >> $workpath$casename/user_nl_clm
        #echo "use_fates_potentialveg = .false." >> $workpath$casename/user_nl_clm
        #echo "fluh_timeseries = '/cluster/shared/noresm/inputdata/share_kjetil/LUH2_timeseries_to_surfdata_ne30np4_conserve_cdf5.nc'" >> $workpath$casename/user_nl_clm
        #echo "hist_fincl1='TOTSOMC','TOTSOMN','TLAI','FATES_GPP','FATES_NPP','TWS','TOTECOSYSC','FATES_VEGC'" >> $workpath$casename/user_nl_clm
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