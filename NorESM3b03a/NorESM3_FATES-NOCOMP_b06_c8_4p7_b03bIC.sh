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
noresmrepo="NorESM_3_0_beta06"
noresmversion="noresm3_0_beta06"

resolution="ne16pg3_tn14" #f19_g17, ne30pg3_tn14, f45_f45_mg37
casename="n1850.$resolution.$noresmversion.PPEbasedTuning.`date +"%Y-%m-%d"`"
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
        #sed -i 's/ctsm5.3.045_noresm_v14/ppe-scramble-tag-for-ctsm-on-norems3-beta04/g' .gitmodules
        #echo "Updated .gitmodules to use ppe-scramble-tag-for-ctsm-on-norems3-beta04 of CLM:"
        #grep -i -n 'ppe-scramble-tag-for-ctsm-on-norems3-beta04' .gitmodules        
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
        ./xmlchange RUN_TYPE=hybrid
        ./xmlchange RUN_STARTDATE=0391-01-01   #Update here
        ./xmlchange RUN_REFCASE=n1850.ne16pg3_tn14.noresm3_0_beta03b.CPLHIST.2025-10-29  #Update here
        ./xmlchange RUN_REFDATE=0391-01-01 #Update here
        ./xmlchange GET_REFCASE=FALSE
        ./xmlchange STOP_OPTION=nyears
        ./xmlchange STOP_N=5
        ./xmlchange REST_N=5
        ./xmlchange RESUBMIT=3        
        ./xmlchange REST_OPTION=nyears
    	./xmlchange DRV_RESTART_POINTER=rpointer.cpl.0391-01-01-00000 #updates needed
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
clubb_c8                   =  4.7
nhtfrq = 0, -24
mfilt  = 1,   30 
ndens  = 2,   2
fincl2 = 'Z500', 'T850', 'U850', 'V850'
EOF

cat <<EOF >> user_nl_clm
use_fates_nocomp=.true.
use_fates_fixed_biogeog=.true.
fates_spitfire_mode=4
fates_stomatal_model='medlyn2011'
finidat = '/cluster/work/users/kjetisaa/archive/n1850.ne16pg3_tn14.noresm3_0_beta06.Best_c8_4p7.2025-12-01/rest/0511-01-01-00000/n1850.ne16pg3_tn14.noresm3_0_beta06.Best_c8_4p7.2025-12-01.clm2.r.0511-01-01-00000.nc'
EOF

cat <<EOF >> user_nl_cpl
ocean_albedo_scheme = 1
EOF

cat <<EOF >> user_nl_blom
BRINE_MLBASE_FRAC = 0.5
IWDFAC = 0.35
EOF
        echo "done with user_nl_* modifications"

        #Add reservation in case.run and case.st_archive
        sed -i '10i\#SBATCH  --reservation=nn9560k' .case.run
        sed -i '10i\#SBATCH  --reservation=nn9560k' case.st_archive
        #Replace lines in case.st_archive to use 4 nodes and 4 tasks
        sed -i 's/#SBATCH  --nodes=1/#SBATCH  --nodes=4/g' case.st_archive
        sed -i 's/#SBATCH  --ntasks=1/#SBATCH  --ntasks=4/g' case.st_archive
        sed -i 's/#SBATCH  --partition=preproc/#SBATCH  --partition=normal/g' case.st_archive
        sed -i '/mem-per-cpu=1900M/d' case.st_archive

	
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

    # copy restart files and pointers
    cp /cluster/work/users/kjetisaa/archive/n1850.ne16pg3_tn14.noresm3_0_beta03b.CPLHIST.2025-10-29/rest/0391-01-01-00000/*.r*.nc /cluster/work/users/kjetisaa/noresm/$casename/run/ #Update here
    cp /cluster/work/users/kjetisaa/archive/n1850.ne16pg3_tn14.noresm3_0_beta03b.CPLHIST.2025-10-29/rest/0391-01-01-00000/rpointer.*0391-01-01-00000 /cluster/work/users/kjetisaa/noresm/$casename/run/ #Update here
    cp /cluster/work/users/kjetisaa/archive/n1850.ne16pg3_tn14.noresm3_0_beta03b.CPLHIST.2025-10-29/rest/0391-01-01-00000/n1850.ne16pg3_tn14.noresm3_0_beta03b.CPLHIST.2025-10-29.cam.i.0391-01-01-00000.nc /cluster/work/users/kjetisaa/noresm/$casename/run/ #Update here
    echo "copied restart files and pointers"
fi

#Submit job
if [[ $dosubmit -eq 1 ]] 
then
    cd $workpath$casename
    ./case.submit
    echo " "
    echo 'done submitting'       
fi
