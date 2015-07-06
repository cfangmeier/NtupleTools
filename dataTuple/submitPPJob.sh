#This takes 2-3 arguments
  #1) the directory in /nfs-7/userdata/dataTuple/mergedLists/
  #2) the number file you want to make or remake
  #3) The jobtype

#You must run this script from inside the dataTuple directory!  

taskName=$1
number=$2
JOBTYPE=$3

#if [ "$#" -gt "2" ]
#then
#  BASEPATH=$3
#else
#  BASEPATH="$PWD/$BASEPATH"
#fi

#Set the environment variables
export inputListDirectory=$BASEPATH/mergedLists/$taskName/merged_list_$number.txt
export mData=$BASEPATH/mergedLists/$taskName/metaData_$number.txt
if [ "$JOBTYPE" == "cms3" ] 
then
  export outputDir=/hadoop/cms/store/user/$USER/dataTuple/$taskName/merged
  export dataSet=$taskName
  export workingDirectory=$PWD
  export executableScript=`readlink -f $PWD/../condorMergingTools/libsh/mergeScriptRoot6.sh`
  export isDataTuple=1

  if [ ! -d $outputDir ]
  then
    mkdir -p $outputDir
  fi

  pushd $PWD/../condorMergingTools/
  ./submitMergeJobs.sh
  popd
elif [ "$JOBTYPE" == "user" ] 
then
  export outputDir=/hadoop/cms/store/user/$USER/userjob_test/$taskName/merged
else
  echo "JOBTYPE in submitPPJob.sh not recognized!"
  exit 1
fi
