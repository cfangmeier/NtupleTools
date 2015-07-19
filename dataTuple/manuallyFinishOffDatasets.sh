#!/bin/bash

#Figure out name
if [ "$USER" == "cgeorge" ]; then name="alex"; fi
if [ "$USER" == "jgran" ]; then name="jason"; fi
if [ "$USER" == "mark" ]; then name="mderdzinski"; fi

#Set Basepath
BASEPATH="/nfs-7/userdata/dataTuple/$name"

#Get list of datasets
for taskName in `ls $BASEPATH/mergedLists`
do
  #Verify that we need to do anything
  nEvents=`grep -r "nEvents" $BASEPATH/mergedLists/$taskName | awk '{print $3}'`
  if [ "$nEvents" == "0" ]; then continue; fi;
  
  #Merged file number
  mergedFileNumber=`grep -r "filling" $BASEPATH/mergedLists/$taskName | awk '{print $3}'`

  #Write metaData
  echo "n: $newTotalNevents" >> $BASEPATH/mergedLists/$taskName/metaData_$mergedFileNumber.txt
  echo "k: 1" >> $BASEPATH/mergedLists/$taskName/metaData_$mergedFileNumber.txt
  echo "f: 1" >> $BASEPATH/mergedLists/$taskName/metaData_$mergedFileNumber.txt
  echo "x: 1" >> $BASEPATH/mergedLists/$taskName/metaData_$mergedFileNumber.txt
  echo "file: merged_list_$mergedFileNumber.txt" >> $BASEPATH/mergedLists/$taskName/metaData_$mergedFileNumber.txt
 
  #Submit it
  . submitPPJob.sh $taskName $mergedFileNumber cms3
  if [ ! -e submitPPList.txt ]; then touch submitPPList.txt; fi
  submitTime=`date +%s`
  echo "/hadoop/cms/store/user/$USER/dataTuple/$taskName/merged/merged_ntuple_$mergedFileNumber.root $submitTime" >> submitPPList.txt

  #Update status logs
  sed -i "s/currently filling.*/currently filling: $(( $mergedFileNumber + 1 ))/" $BASEPATH/mergedLists/$taskName/status.txt
  sed -i "s/current\ size\ (bytes).*/current size (bytes): 0/" $BASEPATH/mergedLists/$taskName/status.txt
  sed -i "s/current\ nEvents.*/current nEvents: 0/" $BASEPATH/mergedLists/$taskName/status.txt
done
