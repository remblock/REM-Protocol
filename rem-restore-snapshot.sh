#!/bin/bash

#****************************************************************************************************#
#                                        REM-RESTORE-SNAPSHOT                                        #
#****************************************************************************************************#

#----------------------------------------------------------------------------------------------------#
# CONFIGURATION VARIABLES                                                                            #
#----------------------------------------------------------------------------------------------------#

data_folder=/root/data
log_file=/root/remnode.log
config_folder=/root/config
state_folder=$data_folder/state
blocks_folder=$data_folder/blocks
snapshots_folder=$data_folder/snapshots

#----------------------------------------------------------------------------------------------------#
# INSTALLING CURL                                                                                    #
#----------------------------------------------------------------------------------------------------#

sudo apt install curl -y

#----------------------------------------------------------------------------------------------------#
# CREATE SNAPSHOT FOLDER IN DATA                                                                     #
#----------------------------------------------------------------------------------------------------#

if [ ! -d $snapshots_folder ]
then
  mkdir $snapshots_folder
fi

rm $snapshots_folder/*.bin 2> /dev/null

#----------------------------------------------------------------------------------------------------#
# GRACEFULLY STOP ORE-PROTOCOL                                                                       #
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
echo "================================"
echo "REM-RESTORE-SNAPSHOT HAS STARTED"
echo "================================"
latest_snapshot=$(curl -s https://remsnapshots.geordier.co.uk/snapshots/latestSnapshotType.php | awk '{print $3}')
latest_new_snapshot=$(echo $latest_snapshot)
echo ""
echo "Downloading Snapshot now..."
echo ""
curl -O https://www.geordier.co.uk/snapshots/$latest_new_snapshot
echo ""
echo "Downloaded $latest_new_snapshot"
gunzip $latest_new_snapshot
tar_file=$(ls *.tar | head -1)
sudo tar -xvf $tar_file
rm $tar_file
mv /root/root/data/snapshots/*.bin $snapshots_folder/
bin_file=$snapshots_folder/*.bin
echo ""
echo "Uncompressed $latest_new_snapshot"
rm -rf $blocks_folder
rm -rf $state_folder
cd ~
remnode --config-dir $config_folder/ --data-dir $data_folder/ --snapshot $bin_file >> $log_file 2>&1 &
sleep 4
while [ : ]
do
	systemdt=$(date '+%Y-%m-%dT%H:%M')

	if [ "$dt1" == "$systemdt" ]; then
		break
	else
		dt1=$(remcli get info | grep head_block_time | cut -c 23-38)
		dt1date=$(echo $dt1 | awk -F'T' '{print $1}' | awk -F'-' 'BEGIN {OFS="-"}{ print $3, $2, $1}')
		dt1time=$(echo $dt1 | awk -F'T' '{print $2}' | awk -F':' 'BEGIN {OFS=":"}{ print $1, $2}')

		dt2=$(tail -n 1 $log_file | awk '{print $2}'| awk -F'.' '{print $1}')
		dt2date=$(echo $dt2 | awk -F'T' '{print $1}' | awk -F'-' 'BEGIN {OFS="-"}{ print $3, $2, $1}')
		dt2time=$(echo $dt2 | awk -F'T' '{print $2}' | awk -F':' 'BEGIN {OFS=":"}{ print $1, $2}')

		echo "Fetching blocks for [${dt1date} | ${dt1time}] | Current block date [${dt2date} | ${dt2time}]"
	fi

	echo ""
	sleep 2
done
echo ""
echo "=================================="
echo "REM-RESTORE-SNAPSHOT HAS COMPLETED"
echo "=================================="
echo ""
