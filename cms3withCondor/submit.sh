#!/bin/bash

files=$1
DO_NTUPLE_NUMBER=$2

CMS3_TAG="CMS3_V07-02-06"
GLOBAL_TAG="PHYS14_25_V2::All"

while  ! voms-proxy-info -exist
do echo "No Proxy found issuing \"voms-proxy-init -voms cms\""
   voms-proxy-init -hours 168 -voms cms 
done

PSET="MCProduction2015_NoFilter_cfg.py"
INPUT="$PSET, $libCMS3"
SITE="T2_US_UCSD,T2_US_Nebraska,T2_US_Wisconsin,T2_US_MIT,T2_US_FLORIDA"
PROXY=$(voms-proxy-info -path)
SUBMITLOGDIR="${PWD}/submit_logs"
JOBLOGDIR="${PWD}/job_logs"
JOBCFGDIR="${PWD}/job_cfg/`date "+%m%d%y_%s"`"
LOG="${SUBMITLOGDIR}/condor_`date "+%m_%d_%Y"`.log"
OUT="${JOBLOGDIR}/1e.\$(Cluster).\$(Process).out"
ERR="${JOBLOGDIR}/1e.\$(Cluster).\$(Process).err"

if [ -e /nfs-7/userdata/libCMS3/lib_${CMS3_TAG}.tar.gz]
then
  libCMS3=/nfs-7/userdata/libCMS3/lib_${CMS3_TAG}.tar.gz
  echo "Using existing libCMS3 file: $libCMS3"
else
  echo "libCMS3 file does not exist, will make on the fly."
  echo "Need to implement this feature, exit for now."
  return 1
fi


if [ ! -d "${SUBMITLOGDIR}" ]; then
    mkdir -p ${SUBMITLOGDIR}
fi

if [ ! -d "${JOBLOGDIR}" ]; then
    mkdir -p ${JOBLOGDIR}
fi

if [ ! -d "${JOBCFGDIR}" ]; then
    mkdir -p ${JOBCFGDIR}
fi

number=0
while read line
do

  let "number=$number+1"

  INPUT_FILE_NAME=$line

  if (( $# == 2 )) && ["$DO_NTUPLE_NUMBER" == "true"]; 
  then
    OUTPUT_FILE_NAME="ntuple_$number.root"
  elif (( $# == 2 )) && ["$DO_NTUPLE_NUMBER" != "true"]; 
    echo "Need to supply OUTPUT_FILE_NAME argument or set DO_NTUPLE_NUMBER = true"
    return 1
  elif (( $# == 3 )) && ["$DO_NTUPLE_NUMBER" == "true"]; 
    echo "Error: If passing OUTPUT_FILE_NAME argument, must set DO_NTUPLE_NUMBER = false"
    return 1
  else
    OUTPUT_FILE_NAME=$3
  fi

  echo "
  universe=grid
  Grid_Resource=condor cmssubmit-r1.t2.ucsd.edu glidein-collector.t2.ucsd.edu
  when_to_transfer_output = ON_EXIT
  transfer_input_files=${INPUT}
  +DESIRED_Sites=\"${SITE}\"
  +Owner = undefined
  log=${LOG}
  output=${OUT}
  error =${ERR}
  notification=Never
  x509userproxy=${PROXY}
  executable=condorExecutable.sh
  transfer_executable=True
  arguments=$PSET $libCMS3 $GLOBAL_TAG $INPUT_FILE_NAME $OUTPUT_DIR $OUTPUT_FILE_NAME
  queue
  " > ${JOBCFGDIR}/condor_$number.cmd
  
  condor_submit ${JOBCFGDIR}/condor_$number.cmd

done < $files
