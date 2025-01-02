#!/bin/bash 

#Scrip to clone, build and run NorESM on Betzy

dosetup1=0 #do first part of setup
dosetup2=0 #do second part of setup (after manual modifications)
dosubmit=0 #do the submission stage
forcenewcase=0 #scurb all the old cases and start again
doanalysis=0 #analyze output (not yet coded up)

echo "setup1, setup2, submit, analysis:", $dosetup1, $dosetup2, $dosubmit, $doanalysis 

USER="kjetisaa"
project='nn9039k' #nn8057k: EMERALD, nn2806k: METOS, nn9188k: CICERO, nn9039k: NorESM (INES2)
machine='betzy'
setCPUs=0 #For setting number of CPUs. 1: 1024

# what is your clone of the ctsm repo called? (or you want it to be called?) 
noresmrepo="NorESM_alpha07_fatessp_newradiation" 

#path to scratch (or where the model is built.)
scratch="/cluster/work/users/$USER/"
#where are we now?
startdr=$(pwd)
# aka where do you want the code and scripts to live?
workpath="/cluster/work/users/$USER/" #previously: 'gitpath'
# some more derived path names to simplify latter scripts
scriptsdir=$workpath$noresmrepo/cime/scripts/

#path to results (history) 
results_dir="/cluster/work/users/$USER/"

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
        
        #From Mariana
        git clone https://github.com/NorESMhub/NorESM/ $noresmrepo
        cd $noresmrepo
        git checkout noresm2_5_alpha07
        echo "Modify Externals.cfg, then continue"

        #[cam]
        #protocol = git
        #tag = noresm2_5_015_cam6_3_158  
        #repo_url = https://github.com/NorESMhub/CAM
        #local_path = components/cam
        #externals = Externals_CAM.cfg
        #required = True

        #Run this manually
        #./manage_externals/checkout_externals -v
    fi
fi

#Make case
if [[ $dosetup2 -eq 1 ]] 
then
    cd $scriptsdir

    if [[ $forcenewcase -eq 1 ]]
    then 
        if [[ -d "$casename" ]] 
        then    
        echo "$casename exists on your filesystem. Removing it!"
        rm -r $workpath/noresm/$casename
        rm -r $workpath/archive/$casename
        rm -r $casename
        fi
    fi
    if [[ -d "$casename" ]] 
    then    
        echo "$casename exists on your filesystem."
    else
        
        echo "making case:" $casename        
        ./create_newcase --case $results_dir/n1850.ne30_tn14.hybrid_fatessp.20241111 --compset 1850_CAM%DEV%LT%NORESM%CAMoslo_CLM60%FATES-SP_CICE_BLOM%ECO_MOSART_DGLC%NOEVOLVE_SWAV_SESP --res ne30pg3_tn14 --project nn9039k --run-unsupported --mach betzy 
        cd $casename #TODO: fix path here

        #XML changes
        echo 'updating settings'
        ./xmlchange NTASKS=1920
        ./xmlchange NTASKS_OCN=256
        ./xmlchange ROOTPE=0
        ./xmlchange ROOTPE_OCN=1920
        ./xmlchange BLOM_VCOORD=cntiso_hybrid,BLOM_TURBULENT_CLOSURE=
        ./xmlchange STOP_OPTION=nyears
        ./xmlchange STOP_N=7
        ./xmlchange REST_N=1
        ./xmlchange REST_OPTION=nyears
        ./xmlchange RESUBMIT=3
        ./xmlchange --subgroup case.run JOB_WALLCLOCK_TIME=48:00:00
        ./xmlchange --subgroup case.st_archive JOB_WALLCLOCK_TIME=03:00:00        

        echo 'done with xmlchanges'        
        
        ./case.setup
        echo "Update namelists"
        #./case.build
    fi
fi
#echo "Currently in" $(pwd)

#Submit job
if [[ $dosubmit -eq 1 ]] 
then
    cd $scriptsdir/$casename
    ./case.submit
    echo 'done submitting'  
    cd $startdr  

    #Check job (TODO)
    rund="$scratch/ctsm/$casename/run/"
    echo $rund
    #ls -lrt $rund   
    
    #Store key simulation information and paths
    echo "----$casename----" >> List_of_simulations.txt
    date >> List_of_simulations.txt
    echo /cluster/work/users/kjetisaa/ctsm/$casename/run >> List_of_simulations.txt
    echo /cluster/work/users/kjetisaa/archive/$casename/lnd/hist/ >> List_of_simulations.txt
    echo $scriptsdir/$casename >> List_of_simulations.txt
    echo $compset >> List_of_simulations.txt        
    echo $resolution >> List_of_simulations.txt
    echo $nl_casesetup_string >> List_of_simulations.txt 
    echo '' >> List_of_simulations.txt
fi
