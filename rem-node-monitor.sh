#!/bin/bash

function remnodelogtime_to_date() {
  temp_date="$( echo $1 | awk -F '.' '{ print $1}' | tr '-' '/' | tr 'T' ' ')"
  echo $(date "+%s" -d "$temp_date")
}

second_date=$(date +%s)

#-----------------------------------------------------------------------------------------------------
# CHECK BLOCK CONDITION
#-----------------------------------------------------------------------------------------------------

last_remcli_block_date=$(remcli -u https://remchain.remme.io get table rem rem producers -L remblock21bp -U remblock21bp | grep 'last_block_time' | awk '{print $2}' | tr -d '"' | tr -d ',')
last_block=$(remnodelogtime_to_date "$last_remcli_block_date")
block_result=$(expr $second_date - $last_block)
block_minute=$(expr $block_result / 60)
if [[ $block_result -le "300" ]]
then
  echo "" &>/dev/null
else
  curl -s -X POST https://api.telegram.org/bot711425317:AAG5nKmZarIlFwhOLSlLN5tYxpKNxTu9iYo/sendMessage -d chat_id=704178267 -d text="Warning: Stopped producing blocks $block_minute minutes ago." &>/dev/null
fi

#-----------------------------------------------------------------------------------------------------
# CHECK ORACLE CONDITION
#-----------------------------------------------------------------------------------------------------

last_oracle_date=$(remcli -u https://remchain.remme.io get table rem.oracle rem.oracle pricedata -L remblock21bp -U remblock21bp | grep 'last_update' | awk '{print $2}' | tr -d '"')
last_oracle=$(remnodelogtime_to_date "$last_oracle_date")
oracle_result=$(expr $second_date - $last_oracle)
if [[ $oracle_result -le "4000" ]]
then
  echo "" &>/dev/null
else
  curl -s -X POST https://api.telegram.org/bot711425317:AAG5nKmZarIlFwhOLSlLN5tYxpKNxTu9iYo/sendMessage -d chat_id=704178267 -d text="Warning: Oracle plugin for producer has stopped operating." &>/dev/null
fi
