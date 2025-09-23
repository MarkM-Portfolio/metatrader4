#!/bin/bash

echo -e "\n---++--- [ Meta Trader Refresh AI ] ---++---"
echo -e "Created by: Mark Mon Monteros\n"

if [[ "$OSTYPE" == "darwin"* ]]; then
    # mql4_home="${HOME}/Library/Application Support/MetaTrader 4/Bottles/metatrader64/drive_c/Program Files (x86)/MetaTrader 4/MQL4"
    mql4_home="${HOME}/Library/Application Support/net.metaquotes.wine.metatrader4/drive_c/Program Files (x86)/MetaTrader 4/MQL4"
elif [[ "$OSTYPE" == "win32" ]]; then
    mql4_home="C:\Users\Administrator\AppData\Roaming\MetaQuotes\Terminal\60464E72AB1410FB355EEFF02B5B34F9\MQL4"
else
    mql4_home="${HOME}/.mt4/drive_c/Program Files (x86)/MetaTrader 4/MQL4"
fi

current_dir=${PWD}
declare -a COMPILED_FILES=(`find ./Custom -name '*.ex4'`)

cd "$mql4_home"

echo -e "\nStopping CRONJOB..."
# service cron stop
service cron status

echo -e "\nRemoving All EAs..."
rm -rf ./Experts/Custom/*

# echo -e "\nRemoving All Data Files..."
rm -rf ./Files/*

echo -e '\nDONE !!!'
echo -e '\nNOTE: Dont forget to REMOVE ALL Attached EAs and RESUME CRONJOB.'
