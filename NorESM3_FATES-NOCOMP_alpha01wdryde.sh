#!/bin/bash 

#Scrip to clone, build and run NorESM on Betzy
#This version follows setup for NorESM3 alpha01 (except for FATES-NOCOMP settings):
#https://github.com/NorESMhub/noresm3_dev_simulations/issues/101


dosetup1=0 #do first part of setup
dosetup2=0 #do second part of setup (after first manual modifications)
dosetup3=1 #do second part of setup (after namelist manual modifications)
dosubmit=1 #do the submission stage
forcenewcase=1 #scurb all the old cases and start again
doanalysis=0 #analyze output (not yet coded up)
numCPUs=0 #Specify number of cpus. 0: use default


echo "setup1, setup2, setup3, submit, forcenewcase, analysis:", $dosetup1, $dosetup2, $dosetup3, $dosubmit, $forcenewcase, $doanalysis 

USER="kjetisaa"
project='nn9560k' #nn8057k: EMERALD, nn2806k: METOS, nn9188k: CICERO, nn9560k: NorESM (INES2), nn9039k: NorESM (UiB: Climate predition unit?), nn2345k: NorESM (EU projects)
machine='betzy'

resolution="ne30pg3_tn14" #f19_g17, ne30pg3_tn14, f45_f45_mg37
casename="n1850.$resolution.hybrid_fates-nocomp.3.0a01.20250404"
compset="1850_CAM70%LT%NORESM%CAMoslo_CLM60%FATES_CICE_BLOM%HYB%ECO_MOSART_DGLC%NOEVOLVE_SWAV_SESP"

#NorESM dir
noresmrepo="NorESM_3_0_alpha01_wdrydep"
noresmversion="noresm3_0_alpha01"

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

        ### Manual setup steps ###
        #cd components/clm
        #git remote add rosie https://github.com/rosiealice/ctsm
        #git fetch rosie
        #git checkout rosie/rebased_drydep
        #go to .gitmodules
        #copy fates tag
        #cd src/fates
        #git checkout <fates_tag>
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
        ./create_newcase --case $workpath$casename --compset $compset --res $resolution --project $project --run-unsupported --mach betzy --pecount M
        cd $workpath$casename

        #XML changes
        echo 'updating settings'
        ./xmlchange NTASKS=1920
        ./xmlchange NTASKS_OCN=256
        ./xmlchange ROOTPE=0
        ./xmlchange ROOTPE_OCN=1920
        ./xmlchange STOP_OPTION=nyears
        ./xmlchange STOP_N=7
        ./xmlchange RESUBMIT=1
        ./xmlchange --subgroup case.run JOB_WALLCLOCK_TIME=48:00:00
        ./xmlchange --subgroup case.st_archive JOB_WALLCLOCK_TIME=03:00:00

        if [[ $numCPUs -ne 0 ]]
            then 
                echo "setting #CPUs to $numCPUs"
                ./xmlchange NTASKS_ATM=$numCPUs
                ./xmlchange NTASKS_OCN=$numCPUs
                ./xmlchange NTASKS_LND=$numCPUs
                ./xmlchange NTASKS_ICE=$numCPUs
                ./xmlchange NTASKS_ROF=$numCPUs
                ./xmlchange NTASKS_GLC=$numCPUs
            fi

        echo 'done with xmlchanges'        
        
        ./case.setup
        echo ' '
        echo "Done with Setup. Update namelists in $workpath$casename/user_nl_*"

        #Add following lines to user_nl_clm    
        echo "use_fates_nocomp=.true." >> $workpath$casename/user_nl_clm
        echo "use_fates_fixed_biogeog=.true." >> $workpath$casename/user_nl_clm
        echo "use_fates_luh = .false." >> $workpath$casename/user_nl_clm
        echo "fates_radiation_model = 'twostream'" >> $workpath$casename/user_nl_clm       
        echo "finidat = '/cluster/work/users/kjetisaa/archive/i1850.FATES-NOCOMP-noLU_cal15_twosteam.ne30pg3_tn14.noresm3_0_alpha01.20250326/rest/0101-01-01-00000/i1850.FATES-NOCOMP-noLU_cal15_twosteam.ne30pg3_tn14.noresm3_0_alpha01.20250326.clm2.r.0101-01-01-00000.nc'" >> $workpath$casename/user_nl_clm

        #Add following lines to user_nl_cice
        echo "ice_ic = '/cluster/shared/noresm/inputdata/restart/NOIIAJRAOC20TR_TL319_tn14_ppm_20240816/rest/1775-01-01-00000/NOIIAJRAOC20TR_TL319_tn14_ppm_20240816.cice.r.1775-01-01-00000.nc'" >> $workpath$casename/user_nl_cice   

        #Add following lines to user_nl_blom
        echo 'ICFILE = "/cluster/shared/noresm/inputdata/restart/NOIIAJRAOC20TR_TL319_tn14_ppm_20240816/rest/1775-01-01-00000/NOIIAJRAOC20TR_TL319_tn14_ppm_20240816.blom.r.1775-01-01-00000.nc"' >> $workpath$casename/user_nl_blom
        
        #Add following lines to user_nl_cam
        echo 'use_aerocom = .true.' >> $workpath$casename/user_nl_cam
        echo 'interpolate_nlat = 192' >> $workpath$casename/user_nl_cam
        echo 'interpolate_nlon = 288' >> $workpath$casename/user_nl_cam
        echo 'interpolate_output = .true.' >> $workpath$casename/user_nl_cam
        echo 'history_aerosol = .true.' >> $workpath$casename/user_nl_cam
        echo 'zmconv_c0_lnd = 0.0075D0' >> $workpath$casename/user_nl_cam
        echo 'zmconv_c0_ocn = 0.0300D0' >> $workpath$casename/user_nl_cam
        echo 'zmconv_ke = 5.0E-6' >> $workpath$casename/user_nl_cam
        echo 'zmconv_ke_lnd = 1.0E-5' >> $workpath$casename/user_nl_cam
        echo 'clim_modal_aero_top_press = 1.D-4' >> $workpath$casename/user_nl_cam
        echo 'bndtvg = "/cluster/shared/noresm/inputdata/atm/cam/ggas/noaamisc.r8.nc"' >> $workpath$casename/user_nl_cam

        #Add following lines to user_nl_cpl
        echo 'histaux_l2x1yrg = .true.' >> $workpath$casename/user_nl_cpl
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