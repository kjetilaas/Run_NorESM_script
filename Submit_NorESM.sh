#!/bin/bash 

#Scrip to clone, build and run NorESM on Betzy

dosetup1=0 #do first part of setup
dosetup2=0 #do second part of setup (after first manual modifications)
dosetup3=0 #do second part of setup (after namelist manual modifications)
dosubmit=1 #do the submission stage
forcenewcase=1 #scurb all the old cases and start again
doanalysis=0 #analyze output (not yet coded up)

echo "setup1, setup2, setup3, submit, forcenewcase, analysis:", $dosetup1, $dosetup2, $dosetup3, $dosubmit, $forcenewcase, $doanalysis 

USER="kjetisaa"
project='nn9039k' #nn8057k: EMERALD, nn2806k: METOS, nn9188k: CICERO, nn9039k: NorESM (INES2)
machine='betzy'

casename="n1850.FATES-SP.ne30_tn14.alpha08d.20250102"
compset="1850_DATM%QIA_CLM60%FATES-SP_SICE_SOCN_MOSART_SGLC_SWAV"
resolution="ne30pg3_tn14"
project="nn9039k"

#NorESM dir
noresmrepo="NorESM_alpha08d" 

# aka where do you want the code and scripts to live?
workpath="/cluster/work/users/$USER/" 

# some more derived path names to simplify scripts
scriptsdir=$workpath$noresmrepo/cime/scripts/

#case dir
casedir=$workpath$casename

#path to results (history, check this!!) 
results_dir="$workpath/noresm/$casename"

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
        git checkout noresm2_5_alpha08d
        ./bin/git-fleximod update
        echo "Built model here: $workpath$noresmrepo"        

        #[cam]
        #protocol = git
        #tag = noresm2_5_015_cam6_3_158  
        #repo_url = https://github.com/NorESMhub/CAM
        #local_path = components/cam
        #externals = Externals_CAM.cfg
        #required = True

        #Run this manually (old setup)
        #./manage_externals/checkout_externals -v
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
        ./xmlchange RESUBMIT=1
        ./xmlchange --subgroup case.run JOB_WALLCLOCK_TIME=48:00:00
        ./xmlchange --subgroup case.st_archive JOB_WALLCLOCK_TIME=03:00:00        

        echo 'done with xmlchanges'        
        
        ./case.setup
        echo ' '
        echo "Done with Setup. Update namelists in $workpath$casename/user_nl_*"
        #./case.build
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
