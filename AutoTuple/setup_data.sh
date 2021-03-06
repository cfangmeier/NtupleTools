#!/bin/bash
if [ $# -eq 0 ] 
  then 
  echo "No arguments!" 
  return
fi

gtag=`sed -n '1p' $1`
tag=`sed -n '2p' $1`
export PATH=$PATH:`pwd`
source /cvmfs/cms.cern.ch/crab3/crab.sh
export SCRAM_ARCH=slc6_amd64_gcc491
scramv1 p -n CMSSW_7_4_1 CMSSW CMSSW_7_4_1
if [ ! -e /nfs-7/userdata/libCMS3/lib_$tag.tar.gz ]
then
  echo "Trying to make this on the fly.  Might not work......"
  source ../cms3withCondor/make_libCMS3.sh $tag
  mv lib_$tag.tar.gz /nfs-7/userdata/libCMS3/lib_$tag.tar.gz
  cd $CMSSW_BASE
else
  cd CMSSW_7_4_1
  cmsenv
  cp /nfs-7/userdata/libCMS3/lib_$tag.tar.gz . 
  tar -xzvf lib_$tag.tar.gz
  scram b -j 10
fi
mkdir crab
cd crab
cp -r ../../../condorMergingTools/* ${CMSSW_BASE}/crab/
cp ${CMSSW_BASE}/src/CMS3/NtupleMaker/test/DataProduction2012_NoFilter_cfg.py skeleton_cfg.py
sed -i s/process.GlobalTag.globaltag\ =\ .*/process.GlobalTag.globaltag\ =\ \"$gtag\"/ skeleton_cfg.py
cp ../../submitMergeJobs.sh .
cp ../../submit_crab_jobs.py  .
cp ../../$1 .
cp ../../monitor.sh . 
cp ../../process.py .
cp ../../pirate.txt .
cp ../../FindLumisPerJob.sh . 
cp ../../das_client.py . 
cp ../../crabPic.png .
cp ../../copy.sh .
cp ../../numEventsROOT.C .
cp ../../../checkCMS3/checkCMS3.C . 
cp ../../../checkCMS3/das_client.py .
mkdir crab_status_logs
python submit_crab_jobs.py $1
. monitor.sh $1 
