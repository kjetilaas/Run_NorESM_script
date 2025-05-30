FATES_LU_spinup_4x5_hist_fromNOpotveg.sh: FAILED. /cluster/work/users/kjetisaa/noresm/ihist.f45_f45_mg37.fatesnocomp.noresm3_0_alpha03c.hist_from_NOpotveg.20250527/run/cesm.log.1147966.250527-095550: ERROR: mismatch of input dimension         3033 with expected value         3471  for variable landunit
FATES_LU_spinup_4x5_hist_frompotveg.sh: FAILED. /cluster/work/users/kjetisaa/noresm/ihist.f45_f45_mg37.fatesnocomp.noresm3_0_alpha03c.hist_frompotveg.20250527/run/cesm.log.1147982.250527-111545: ERROR: mismatch of input dimension         3033 with expected value         3471  for variable landunit
FATES_LU_spinup_4x5_hist_steadystateLU.sh: FAILED. /cluster/work/users/kjetisaa/noresm/ihist.f45_f45_mg37.fatesnocomp.noresm3_0_alpha03c.hist_from_steadystateLU.20250527/run/cesm.log.1147964.250527-095332: EROR: check_dim_size ERROR: mismatch of input dimension         3033 with expected value         3471  for variable landunit
FATES_LU_spinup_4x5_LUH3_Hist_coldstart.sh: SUCCEESS. ihist.f45_f45_mg37.fatesnocomp.noresm3_0_alpha03c.LUH3_coldstart.20250522. 
FATES_LU_spinup_4x5_NOpotveg_coldstart.sh: SUCCESS . i1850.f45_f45_mg37.fatesnocomp.noresm3_0_alpha03c.NOpotveg_coldstart.20250522/6. 
FATES_LU_spinup_4x5_potveg_coldstart.sh: SUCCEESS. i1850.f45_f45_mg37.fatesnocomp.noresm3_0_alpha03c.potveg_coldstart.20250526. 
FATES_LU_spinup_4x5_steadystate_coldstart.sh: SUCCESS. i1850.f45_f45_mg37.fatesnocomp.noresm3_0_alpha03c.constLU_coldstart.20250526. 
FATES_LU_spinup_4x5_steadystate_fromNOpotveg.sh: FAILED. /cluster/work/users/kjetisaa/noresm/i1850.f45_f45_mg37.fatesnocomp.noresm3_0_alpha03c.steadystateLU_fromNOpotveg.20250527/run/cesm.log.1147989.250527-111628: ERROR in EDCanopyStructureMod.F90 at line 637
FATES_LU_spinup_4x5_steadystate_frompotveg.sh: SUCCESS. i1850.f45_f45_mg37.fatesnocomp.noresm3_0_alpha03c.steadystateLU_frompotveg.20250527
FATES_LU_spinup_4x5_steadystate_steadystate.sh: SUCCESS. i1850.f45_f45_mg37.fatesnocomp.noresm3_0_alpha03c.steadystateLU_steadystate.20250527
FATES_LU_spinup_4x5_transLU_fromSteadystateLU.sh: SUCCESS. i1850.f45_f45_mg37.fatesnocomp.noresm3_0_alpha03c.transLU_from_steadystateLU.20250527
FATES_LU_spinup_4x5_hist_steadystateLU_16pft.sh:: FAILED. /cluster/work/users/kjetisaa/noresm/ihist.f45_f45_mg37.fatesnocomp.noresm3_0_alpha03c.hist_from_steadystateLU_16pft.20250527/run/cesm.log.1148083.250527-134607: check_dim_size ERROR: mismatch of input dimension         3033   with expected value         3471  for variable landunit
CLM6_4x5_coldstart.sh: SUCCESS. i1850.f45_f45_mg37.clm6bgc.noresm3_0_alpha03c.coldstart.20250528
CLM6_4x5_hist_fromcoldfinidat.sh: FAILED. /cluster/work/users/kjetisaa/noresm/ihist.f45_f45_mg37.clm6bgc.noresm3_0_alpha03c.fromcoldstartfinidat.20250528/run/cesm.log.1148900.250528-153646: check_dim_size ERROR: mismatch of input dimension         3744 with expected value         4937  for variable landunit
CLM6_4x5_hist_fromcoldfinidat_interpTrue.sh: SUCCEESS. ihist.f45_f45_mg37.clm6bgc.noresm3_0_alpha03c.fromcoldstartfinidat_interpTrue.20250530

FATES_LU_spinup_4x5_hist_steadystateLU_16pft_interpTrue.sh: FAILES. /cluster/work/users/kjetisaa/noresm/ihist.f45_f45_mg37.fatesnocomp.noresm3_0_alpha03c.hist_from_steadystateLU_16pft_interpTrue.20250530/run/cesm.log.1151060.250530-110901: forrtl: severe (174): SIGSEGV, segmentation fault occurred. (FatesRestartInterfaceMod.F90)
FATES_LU_spinup_4x5_hist_steadystateLU_16pft_lakeUrbFalse.sh: SUCCESS (but ran out of time). ihist.f45_f45_mg37.fatesnocomp.noresm3_0_alpha03c.hist_from_steadystateLU_16pft_LakeUrbFalse.20250530



Relevant input files:
i1850-case w transLU (SUCCEESS): (i1850.f45_f45_mg37.fatesnocomp.noresm3_0_alpha03c.transLU_from_steadystateLU.20250527)
- finidat = '/cluster/work/users/kjetisaa/archive/i1850.f45_f45_mg37.fatesnocomp.noresm3_0_alpha03c.constLU_coldstart.20250526/rest/0011-01-01-00000/i1850.f45_f45_mg37.fatesnocomp.noresm3_0_alpha03c.constLU_coldstart.20250526.clm2.r.0011-01-01-00000.nc'
- flandusepftdat = '/cluster/shared/noresm/inputdata/share_kjetil/LU_data_CMIP7/fates_landuse_pft_map_to_surfdata_4x5_hist_1850_16pfts_c241007_250522_cdf5.nc'
- fluh_timeseries = '/cluster/shared/noresm/inputdata/share_kjetil/LU_data_CMIP7/LUH2_timeseries_to_surfdata_4x5_hist_1850_16pfts_c241007_250522_cdf5.nc'
- fsurdat = '/cluster/shared/noresm/inputdata/lnd/clm2/surfdata_esmf/ctsm5.3.0/surfdata_4x5_hist_1850_16pfts_c241007.nc'

 
ihist-coldstart (SUCCEESS): ihist.f45_f45_mg37.fatesnocomp.noresm3_0_alpha03c.LUH3_coldstart.20250522
- flandusepftdat = '/cluster/shared/noresm/inputdata/share_kjetil/LU_data_CMIP7/fates_landuse_pft_map_to_surfdata_4x5_hist_1850_16pfts_c241007_250522_cdf5.nc'
- fluh_timeseries = '/cluster/shared/noresm/inputdata/share_kjetil/LU_data_CMIP7/LUH2_timeseries_to_surfdata_4x5_hist_1850_16pfts_c241007_250522_cdf5.nc'
- fsurdat = '/cluster/shared/noresm/inputdata/lnd/clm2/surfdata_esmf/ctsm5.3.0/surfdata_4x5_hist_1850_16pfts_c241007.nc'
- flanduse_timeseries = '/cluster/shared/noresm/inputdata/lnd/clm2/surfdata_esmf/ctsm5.3.0/landuse.timeseries_4x5_SSP2-4.5_1850-2100_78pfts_c240908.nc'

ihist-finidat-16pdf (FAILED): (ihist.f45_f45_mg37.fatesnocomp.noresm3_0_alpha03c.hist_from_steadystateLU_16pft.20250527)
- finidat = '/cluster/work/users/kjetisaa/archive/i1850.f45_f45_mg37.fatesnocomp.noresm3_0_alpha03c.constLU_coldstart.20250526/rest/0011-01-01-00000/i1850.f45_f45_mg37.fatesnocomp.noresm3_0_alpha03c.constLU_coldstart.20250526.clm2.r.0011-01-01-00000.nc'
- flandusepftdat = '/cluster/shared/noresm/inputdata/share_kjetil/LU_data_CMIP7/fates_landuse_pft_map_to_surfdata_4x5_hist_1850_16pfts_c241007_250522_cdf5.nc'
- fluh_timeseries = '/cluster/shared/noresm/inputdata/share_kjetil/LU_data_CMIP7/LUH2_timeseries_to_surfdata_4x5_hist_1850_16pfts_c241007_250522_cdf5.nc'
- fsurdat = '/cluster/shared/noresm/inputdata/lnd/clm2/surfdata_esmf/ctsm5.3.0/surfdata_4x5_hist_1850_16pfts_c241007.nc'
- flanduse_timeseries = '/cluster/shared/noresm/inputdata/lnd/clm2/surfdata_esmf/ctsm5.3.0/landuse.timeseries_4x5_SSP2-4.5_1850-2100_16pfts_c241007.nc'

Todo:
- test interp on initialization
- test LU lakes and urban = off
- overwrite surface file with transient LU pct_pftmax (Does FATES use this)?
- Ask Charlie how he runs transient simulations
- Check if the iHIST case with FATES match the CLM LU file? (Is the transitions read correctly?)