#checks the status of post-processing for a given task and copies finished files, adds them to the donePP.txt list.

#Takes arguments:
#1) the target directory to mv file to
#2) taskname
#3) JOBTYPE

taskname=$1
JOBTYPE=$2

mergedDir="/hadoop/cms/store/user/$USER/dataTuple/$taskname/merged"
target="/hadoop/cms/store/group/snt/testData/$taskname/merged"

if [ ! -d $BASEPATH ]
then
  echo "BASEPATH in checkPP.sh does not exist!"
fi

if [ ! -d $target ]
then
  mkdir -p $target
fi

#make donelist
if [ ! -e donePP.txt ]
then
  touch donePP.txt
fi

#Run condor_q to get list of running jobs
condor_q $USER > temp_status.txt
sed -i '1,4d' temp_status.txt
sed -i '$d' temp_status.txt
sed -i '$d' temp_status.txt

#Delete old test files
rm heldPPList.txt 2>/dev/null

#Read condor_q output to fill lists.  
while read line
do
  if [ `echo $line | awk '{ print $6 }'` == "H" ]
  then
    echo `echo $line | awk '{ print $1 }'` >> heldPPList.txt
  fi	
done < temp_status.txt    
rm temp_status.txt

#Delete held jobs
if [ -e heldPPList.txt ]
then
  while read line
  do
    condor_rm $line
  done < heldPPList.txt
  rm heldPPList.txt
fi

counter="0"

while [ -e $BASEPATH/mergedLists/$taskname/metaData_$counter.txt ]
do
  echo "checking $BASEPATH/mergedLists/$taskname/metaData_$counter.txt"
  mergeFile="$mergedDir/merged_ntuple_$counter.root"
  echo "mergeFile is $mergeFile"
  
  #grep donePP.txt to see if PP already finished and mv'ed to hadoop
  grep "$mergeFile" donePP.txt > /dev/null
  isDone=$?
  if [ $isDone == 0 ]
  then
    counter=$[$counter+1]
    continue
  fi
  isRunning=`condor_q $USER -l | grep $mergeFile; echo $?`
  if [ $isRunning == 0 ]
  then
    counter=$[$counter+1]
    continue
  fi
  
  #FIXME: May want to check timestamp when submitted and kill if "stuck"
  #grep $mergeFile submitPPList.txt > /dev/null
  #wasSubmitted=$?
  
  if [ -e delayList.txt ]
  then
    grep $mergeFile delayList.txt > /dev/null
    wasDelayed=$?
  else
    wasDelayed=1
  fi
  
  if [ -e $mergeFile ]
  then 
    mergeFileEsc=`echo $mergeFile | sed 's,/,\\\/,g'`
    if [ $wasDelayed == 0 ]
    then 
      sed -i "/$mergeFileEsc/d" delayList.txt
      sed -i "/$mergeFileEsc/d" submitPPList.txt
      echo "moving $mergeFile to $target"
      mv $mergeFile $target
      echo "$mergeFile" >> donePP.txt
    else
      echo "$mergeFile exists, but might be copying. Adding to delaylist.txt"
      echo "$mergeFile" >> delayList.txt
    fi
  else
    if [ $wasDelayed == 0 ]
    then 
      sed -i "/$mergeFileEsc/d" delayList.txt
      echo "$mergeFile does not exist! Will resubmit."
      . submitPPJob.sh $taskName $counter $JOBTYPE
      submitTime=`date +%s`
      echo "/hadoop/cms/store/user/$USER/dataTuple/$taskName/merged/merged_ntuple_$counter.root $submitTime" >> submitPPList.txt
    else
      echo "Adding mergeFile to delaylist.txt"
      echo "$mergeFile" >> delayList.txt
    fi
  fi
  counter=$[$counter+1]
done
