#!/bin/bash

echo -e "\n---++--- [ Meta Trader Deployer ] ---++---"
echo -e "Created by: Mark Mon Monteros\n"

OIFS="$IFS"
IFS=$'\n'

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
COMPILED_FILES+=(`find ./Custom -name '*.ico'`)

cd "$mql4_home"

# Remove txt Files
# rm -rf ./Files/*

# Deploy files to Meta Trader
for i in ${COMPILED_FILES[@]}; do
    parent=`dirname $i | sed -e 's/\/Custom//g'`
    ls "$parent/Custom" &> /dev/null
    if [[ $? -ne 0 ]]; then
        mkdir -p "$parent/Custom"
    fi
    cp "$current_dir/$i" "$parent/Custom"
done

IFS="$OIFS"

echo -e '\nDONE !!!'
