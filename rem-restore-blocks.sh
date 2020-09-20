#!/bin/bash

#****************************************************************************************************#
#                                        REM-RESTORE-BLOCKS                                          #
#****************************************************************************************************#

#----------------------------------------------------------------------------------------------------#
# CONFIGURATION VARIABLES                                                                            #
#----------------------------------------------------------------------------------------------------#

data_folder=/root/data
log_file=/root/remnode.log
config_folder=/root/config
state_folder=$data_folder/state
blocks_folder=$data_folder/blocks

#----------------------------------------------------------------------------------------------------#
# INSTALLING CURL                                                                                    #
#----------------------------------------------------------------------------------------------------#

sudo apt install curl -y

#----------------------------------------------------------------------------------------------------#
# CREATE BLOCKS AND STATE FOLDER IN DATA                                                             #
#----------------------------------------------------------------------------------------------------#

if [ ! -d $blocks_folder ]
then
  mkdir -p $blocks_folder
fi
if [ ! -d $state_folder ]
then
  mkdir -p $state_folder
fi

#----------------------------------------------------------------------------------------------------#
# GRACEFULLY STOP REM-PROTOCOL                                                                       #
#----------------------------------------------------------------------------------------------------#

remnode_pid=$(pgrep remnode)
if [ ! -z "$remnode_pid" ]
then
  if ps -p $remnode_pid > /dev/null; then
     kill -SIGINT $remnode_pid
  fi
  while ps -p $remnode_pid > /dev/null; do
  sleep 1
  done
fi

#----------------------------------------------------------------------------------------------------#
# MAIN PART OF THE SCRIPT                                                                            #
#----------------------------------------------------------------------------------------------------#

echo ""
echo "====================================="
echo "DOWNLOADING OF REM BLOCKS HAS STARTED"
echo "====================================="
latest_blocks=$(curl -s https://remsnapshots.geordier.co.uk/snapshots/latestSnapshotType.php?type=blocks | awk ' { print $2 }')
echo ""
echo "Downloading blocks now..."
echo ""
curl -O https://remsnapshots.geordier.co.uk/snapshots/blocks/$latest_blocks
echo ""
echo "Downloaded $latest_blocks"
gunzip $latest_blocks
tar_file=$(ls *.tar | head -1)
sudo tar -xvf $tar_file
rm $tar_file
rm -rf $blocks_folder/*
rm -rf $state_folder/*
mv /root/root/data/blocks/* $blocks_folder/
rm -r /root/root/
echo ""
echo "Uncompressed $latest_blocks"
echo ""
remnode --config-dir $config_folder --data-dir $data_folder --replay-blockchain > $log_file 2>&1 &
sleep 5
while [ : ]
do
       block1=$(tail -n 1 $log_file | awk '{print $7}')
       block2=$(tail -n 1 $log_file | awk '{print $9}')
       if [[ "$block1" -ge "$block2" ]]; then break
       elif [[ "$block1" -eq "remnode" ]]; then break
       else
        echo "Current replay block [${block1} | ${block2}]"
       fi
       echo ""
       sleep 2
done
rm ./rem-restore-blocks.sh
echo ""
echo "======================================="
echo "DOWNLOADING OF REM BLOCKS HAS COMPLETED"
echo "======================================="
echo ""
