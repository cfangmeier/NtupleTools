#!/bin/bash
if [ $# -eq 0 ] 
  then 
  echo "No arguments!" 
  return
fi

export PATH=$PATH:`pwd`
source /cvmfs/cms.cern.ch/crab3/crab.sh
export SCRAM_ARCH=slc6_amd64_gcc481
cmsrel CMSSW_7_2_0
cd CMSSW_7_2_0/src
cmsenv
git clone git@github.com:cmstas/NtupleMaker.git CMS3/NtupleMaker
cd CMS3/NtupleMaker
git checkout CMS3_V07-02-02
source setup/patchesToSource.sh
cd $CMSSW_BASE/src
scram b -j 10
cd ..
mkdir crab
cd crab
cp -r ../../condorMergingTools/* ${CMSSW_BASE}/crab/
cp ${CMSSW_BASE}/src/CMS3/NtupleMaker/test/Slim_MCProduction2012_NoFilter_cfg.py skeleton_cfg.py
cp ../../submitMergeJobs.sh .
cp ../../submit_crab_jobs.py  .
cp ../../$1 .
cp ../../monitor.py . 
cp ../../monitor.sh . 
cp ../../process.py .
cp ../../web_autoTuple .
python submit_crab_jobs.py $1
. monitor.sh $1