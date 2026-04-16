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
noresmrepo="ctsm_jn_ncsrevise" 
noresmversion="ncsrevise"

resolution="ne16pg3_tn14" #f19_g17, ne30pg3_tn14, f45_f45_mg37, ne16pg3_tn14 
casename="ihist.$resolution.$noresmversion.CPLHIST_postADspinup.`date +"%Y-%m-%d"`"
echo "casename: $casename"
compset="HIST_DATM%CPLHIST_CLM60%FATES-NOCOMP_SICE_SOCN_SROF_SGLC_SWAV_SESP"

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
        
        echo "Using CTSM version $noresmversion"
        git clone https://github.com/JessicaNeedham/CTSM/ $noresmrepo
        
	cd $noresmrepo
        git checkout $noresmversion
        ./bin/git-fleximod update
        cd src/fates
        git remote add jessie_fates https://github.com/JessicaNeedham/fates
        git fetch jessie_fates
        git checkout ncsrevise

	# Created param file from pr52 on NorESMhub/fates/:
	# 1144  2026-04-01T12:58:40 git fetch origin pull/52/head:pr52
	# 1145  2026-04-01T12:58:57 git checkout pr52
	# 1146  2026-04-01T12:59:01 git branch
	# 1147  2026-04-01T13:00:14 git diff pr52 ncsrevise  parameter_files/fates_params_default.cdl 
	# 1148  2026-04-01T13:01:20 git diff pr52 ncsrevise 
	# 1149  2026-04-01T13:01:52 loadmods
	# 1150  2026-04-01T13:03:41 ncgen -o /cluster/home/kjetisaa/Run_NorESM_script/Apr26/fates_param_pr52_c260401.nc parameter_files/fates_params_default.cdl 

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
        ./create_newcase --case $workpath$casename --compset $compset --res $resolution --project $project --run-unsupported --mach betzy --pecount L --compiler intel

        cd $workpath$casename
        export LMOD_IGNORE_CACHE=1
        #XML changes
        echo 'updating settings'         
        ./xmlchange DATM_CPLHIST_CASE=n1850.ne16pg3_tn14.noresm3_0_beta10.Run6.2026-01-23
        ./xmlchange DATM_CPLHIST_DIR=/cluster/work/users/kjetisaa/archive/n1850.ne16pg3_tn14.noresm3_0_beta10.Run6.2026-01-23/cpl/hist/
        ./xmlchange DATM_PRESNDEP=none
        ./xmlchange DATM_YR_START=406
        ./xmlchange DATM_YR_END=455
        ./xmlchange CLM_ACCELERATED_SPINUP=off
        ./xmlchange DATM_PRESAERO=hist 
        ./xmlchange RUN_STARTDATE=1850-01-01
        ./xmlchange STOP_OPTION=nyears
        ./xmlchange STOP_N=55
        ./xmlchange RESUBMIT=3
        ./xmlchange --subgroup case.run JOB_WALLCLOCK_TIME=12:00:00
        ./xmlchange --subgroup case.st_archive JOB_WALLCLOCK_TIME=00:30:00        
        
        echo 'done with xmlchanges'        
        
        ./case.setup
        echo ' '
        echo "Done with Setup. Update namelists in $workpath$casename/user_nl_*"

        #Add following lines to user_nl_clm   
cat <<EOF >> user_nl_dglc
datamode = "noevolve"
model_datafiles_list = "/cluster/shared/noresm/inputdata/glc/cism/Antarctica/antarctica_8km_epsg3031_c20250403.nc:/cluster/shared/noresm/inputdata/glc/cism/Greenland/greenland_4km_epsg3413_c20250227.nc"
model_internal_gridsize = 8000, 4000
model_meshfiles_list = "/cluster/shared/noresm/inputdata/share/meshes/antarctica_8km_epsg3031_ESMFmesh_c20250303.nc:/cluster/shared/noresm/inputdata/share/meshes/greenland_4km_epsg3413_ESMFmesh_c20250303.nc"
nx_global = 761, 421
ny_global = 761, 721
EOF

cat <<EOF >> user_nl_clm
glacier_region_behavior = 'single_at_atm_topo','UNSET','virtual','virtual'   
glcmec_downscale_longwave = .false. 
precip_repartition_glc_all_rain_t = 2. 
precip_repartition_glc_all_snow_t = 0. 
snow_thermal_cond_glc_method = 'Jordan1991'
albice = 0.6,0.4   
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
finidat = '/cluster/work/users/kjetisaa/archive/i1850.ne16pg3_tn14.ncsrevise.CPLHIST_ADspinup.2026-04-02/rest/0401-01-01-00000/i1850.ne16pg3_tn14.ncsrevise.CPLHIST_ADspinup.2026-04-02.clm2.r.0401-01-01-00000.nc'
fsurdat='/cluster/shared/noresm/inputdata/lnd/clm2/surfdata_esmf/ctsm5.4.0/surfdata_ne16np4.pg3_hist_1850_16pfts_c260209.nc'
fates_paramfile = '/cluster/home/kjetisaa/Run_NorESM_script/Apr26/fates_param_pr52_c260402.nc'
paramfile = '/cluster/shared/noresm/inputdata/lnd/clm2/paramdata/ctsm60_params.5.3.045_noresm_v14_c260117.nc'
fluh_timeseries='/cluster/shared/noresm/inputdata/LU_data_CMIP7/LUH3_timeseries_to_surfdata_ne16np4_260209_cdf5.nc'
flandusepftdat='/cluster/shared/noresm/inputdata/LU_data_CMIP7/fates_landuse_pft_map_to_surfdata_ne16np4_260209_cdf5.nc'
hist_fincl1 = 'FATES_NOCOMP_PATCHAREA_PF', "TOTEXICE_VOL", "TOTSOILICE", "TOTSOILLIQ",'ALT','ALTMAX','TSL','FATES_FRACTION','TSA','RAIN','SNOW','EFLX_LH_TOT','FSH','QSOIL','TLAI','FCO2','TOTSOMC','TOTSOMC_1m','FATES_VEGC','FATES_GPP','FATES_NEP',"TOT_WOODPRODC_LOSS", "FATES_SEEDS_IN_EXTERN_EL", "TOTLITC", "SOM_C_LEACHED", "FATES_SEED_BANK",'FATES_NPP','TWS','H2OSNO','FSNO','TOT_WOODPRODC','PROD100C','PROD10C','FATES_LITTER_AG_CWD_EL','FATES_LITTER_AG_FINE_EL','FATES_LITTER_BG_CWD_EL','FATES_LITTER_BG_FINE_EL','FATES_GRAZING','FATES_FIRE_CLOSS','FATES_BURNFRAC', 'SOM_C_LEACHED', 'FATES_SEED_BANK'
EOF

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
