#!/bin/bash

echo -e "\n---++--- [ Meta Trader Profile Generator ] ---++---"
echo -e "Created by: Mark Mon Monteros\n"

[ -z $1 ] && echo "No arguments provided" && exit 1

if [[ "$OSTYPE" == "darwin"* ]]; then
    # mt4_dir="${HOME}/Library/Application Support/MetaTrader 4/Bottles/metatrader64/drive_c/Program Files (x86)/MetaTrader 4"
    mt4_dir="${HOME}/Library/Application Support/net.metaquotes.wine.metatrader4/drive_c/Program Files (x86)/MetaTrader 4"
    get_pids=`ps aux | grep MetaTrader | grep -v wine | awk '{print$2}'`
elif [[ "$OSTYPE" == "win32" ]]; then
    mt4_dir="C:\Users\Administrator\AppData\Roaming\MetaQuotes\Terminal\60464E72AB1410FB355EEFF02B5B34F9"
    get_pids=``
else
    mt4_dir="${HOME}/.mt4/drive_c/Program Files (x86)/MetaTrader 4"
    get_pids=`ps aux | grep terminal.exe | grep -v wine | awk '{print$2}'`
fi

settings_dir="./mt4-settings"
rm -rf "$mt4_dir"/config/terminal.ini "$mt4_dir"/profiles/lastprofile.ini "$mt4_dir"/profiles/default "$mt4_dir/MQL4/Presets"
cp -R $settings_dir/config $settings_dir/templates "$mt4_dir"
cp -R $settings_dir/mt4-profiles/$1/profiles/* "$mt4_dir/profiles"
cp -R $settings_dir/Presets "$mt4_dir/MQL4"

echo -e "\n[*] - Restarting Meta Trader Application...\n"

declare -a PIDs=($get_pids)

sec=5
while [ $sec -gt 0 ]; do
    echo -e "\t.. $sec .." && sleep 1
    let sec=sec-1
    if [ $sec -eq 0 ]; then
        echo -e "\n\xE2\x9D\x8C Closing Now !"
        kill -9 ${PIDs[@]} >> //dev/null 2<&1
    fi
done

if [[ "$OSTYPE" == "darwin"* ]]; then
    open -a "/Applications/MetaTrader 4.app"
elif [[ "$OSTYPE" == "win32" ]]; then
    open_app=``
else
    wine "$mt4_dir"/terminal.exe
fi
