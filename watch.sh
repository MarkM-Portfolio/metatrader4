#!/bin/bash


if [[ "$OSTYPE" == "darwin"* ]]; then
    mql4_files="${HOME}/Library/Application Support/MetaTrader 4/Bottles/metatrader64/drive_c/Program Files (x86)/MetaTrader 4/MQL4/Files/"
    arg='-j -f'
    datefmt='%b%d'
    timefmt='%H:%M'
elif [[ "$OSTYPE" == "win32" ]]; then
    mql4_files="C:\Users\Administrator\AppData\Roaming\MetaQuotes\Terminal\60464E72AB1410FB355EEFF02B5B34F9\MQL4\Files\\"
else
    mql4_files="${HOME}/.mt4/drive_c/Program Files (x86)/MetaTrader 4/MQL4/Files/"
    arg='-d'
    datefmt=''
    timefmt=''
fi

cd "$mql4_files"
declare -a CURRENCIES
declare -a ORDERTYPES
declare -a DATECONVERT
declare -a TIMECONVERT

# type=`ls "$mql4_files" | grep -e '15-orderType.txt$'`
# if [[ $? -ne 0  ]]; then
#     type='eagle-hunter'
# else 
#     type='vista-proxima'
# fi

# if [ $type == 'eagle-hunter' ]; then
#     echo -e "\n---++--- EAGLE HUNTER ---++---\n"
# else
#     echo -e "\n---++--- VISTA PROXIMA ---++---\n"
# fi

echo -e "\n---++--- HKD ---++---\n"

for i in `ls "$mql4_files" | grep -v "Summary.txt\|^S_\|^Auto\|takeProfit.txt\|Factor.txt\|RSI.txt\|news.txt"`; do
    CURRENCIES+=(`echo "$i" | cut -d "-" -f1 | sed 's/[0-9]//g'`)
    ORDERTYPES+=(`cat "$i" | tr '[:lower:]' '[:upper:]'`)
    DATECONVERT+=(`date $arg $datefmt $(ls -la "$i" | awk '{print$6$7}') '+%b/%d'`)
    TIMECONVERT+=(`date $arg $timefmt $(ls -la "$i" | awk '{print$8}') '+%I:%M%p'`)
    timeframe=(`echo "$i" | cut -d "-" -f1 | tr -d -c 0-9`)
done

for ((i=0;i<${#CURRENCIES[@]};i++)); do
    echo '['${DATECONVERT[i]}-${TIMECONVERT[i]}'] -' ${CURRENCIES[i]}" :" ${ORDERTYPES[i]}
done

# timeframe=$((timeframe/60))
if [[ $timeframe -eq 240 ]]; then
    timeframe='H4'
    datatimeframe='5 Hours'
elif [[ $timeframe -eq 60 ]]; then
    timeframe='H1'
    datatimeframe='Hourly'
elif [[ $timeframe -eq 30 ]]; then
    timeframe='M30'
    datatimeframe='30 Mins'
elif [[ $timeframe -eq 15 ]]; then
    timeframe='M15'
    datatimeframe='15 Mins'
elif [[ $timeframe -eq 5 ]]; then
    timeframe='M5'
    datatimeframe='5 Mins'
else 
    timeframe='M1'
    datatimeframe='1 Min'
fi

echo -e "\nChart Time: "$timeframe

echo -e "\n---++--- DATA from INVESTING.COM ---++---\n"
# cat ./Summary.txt | sort
# echo -e "\n"
# cat ./Gold-Summary.txt
# echo -e "\n"
cat ./News-Summary.txt | grep -v 'Holiday\|^All'
# echo -e "\nData Timeframe: $datatimeframe \n"
echo -e "\nData Timeframe: 5 Mins \n"
