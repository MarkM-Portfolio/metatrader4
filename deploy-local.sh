#!/bin/bash

echo -e "\n---++--- [ Meta Trader Deployer ] ---++---"
echo -e "Created by: Mark Mon Monteros\n"

OIFS="$IFS"
IFS=$'\n'

if [[ "$OSTYPE" == "darwin"* ]]; then
    mql4_home="${HOME}/Library/Application Support/net.metaquotes.wine.metatrader4/drive_c/Program Files (x86)/MetaTrader 4/MQL4"
    wine="/Volumes/Macintosh HD/Applications/MetaTrader 4.app/Contents/SharedSupport/wine/bin/wine64"
elif [[ "$OSTYPE" == "win32" ]]; then
    mql4_home="C:\Users\Administrator\AppData\Roaming\MetaQuotes\Terminal\60464E72AB1410FB355EEFF02B5B34F9\MQL4"
else
    mql4_home="${HOME}/.mt4/drive_c/Program Files (x86)/MetaTrader 4/MQL4"
    wine=`which wine`
fi

current_dir=${PWD}

# Delete all ex4 files in current directory (Experts)
find "$current_dir"/Custom/Experts -name "*.ex4" | grep -v "HKD Corona\|HKD Tokwa" | sed -e "s/^/\"/g" -e "s/$/\"/g" | xargs rm -rf {};

declare -a DEPLOY_FILES=(`find ./Custom/Experts -type f \( -iname \*.mq4 -o -iname \*.mqh -o -iname "HKD Corona.ex4" -o -iname "HKD Tokwa.ex4" -o -iname \*.ico \) | sed -e 's/^.\///g' -e 's/^Custom\///g'`) 
DEPLOY_FILES+=(`find ./Custom/Indicators -type f \( -iname \*.mq4 -o -iname \*.ex4 \) | sed -e 's/^.\///g' -e 's/^Custom\///g'`) 
declare -a DLL_FILES+=(`find ./Custom/Libraries -type f \( -iname \*.dll \) | sed -e 's/^.\///g' -e 's/^Custom\///g'`) 

find ./Default/Indicators/* -name '*'| sed -e 's/^.\///g' -e 's/^Default\///g' | grep -v '.dat$' > "$current_dir"/.local.txt
find ./Default/Experts/* -name '*' | sed -e 's/^.\///g' -e 's/^Default\///g' | grep -v '.dat$' >> "$current_dir"/.local.txt

echo -e '\n[*] - Deploying MQL4 AI Scripts...\n'

cd "$mql4_home"

# Remove Files in MT4
# rm -rf ./Files/* # commented-out to not delete news details
rm -rf ./Indicators/Custom ./Experts/Custom

declare -a MATCH_FILES=(`find ./Indicators/* -name '*' | sed -e 's/^.\///g' | grep -v '.dat$' | cut -f 1 -d '.' | uniq && find ./Experts/* -name '*' | sed -e 's/^.\///g' | grep -v '.dat$' | cut -f 1 -d '.'  | uniq`)
find ./Indicators/* -name '*' | sed -e 's/^.\///g' | grep -v '.dat$\|Custom$' > "$current_dir"/.non-local.txt
find ./Experts/* -name '*' | sed -e 's/^.\///g' |  grep -v '.dat$\|Custom$' >> "$current_dir"/.non-local.txt

for i in ${MATCH_FILES[@]}; do
    grep -irnw "$current_dir/.local.txt" -e "$i" &> /dev/null
    if [[ $? -ne 0 ]]; then
        echo "$i" >> "$current_dir/.key.txt"
    fi
done

declare -a NON_DEFAULT_FILES=(`cat "$current_dir"/.non-local.txt | grep -f "$current_dir"/.key.txt`)

rm -rf "$current_dir/.local.txt" "$current_dir/.non-local.txt" "$current_dir/.key.txt"

# Move non-default scripts to Custom folder
for i in ${NON_DEFAULT_FILES[@]}; do
    parent=`dirname $i | sed -e 's/\/Custom//g'`
    base=`basename $i`
    ls $parent/Custom/$base &> /dev/null
    if [[ $? -ne 0 ]]; then
        mkdir -p "$parent/Custom"
        mv "$i" "$parent/Custom"
    fi
done

# Copy files to Meta Trader
for i in ${DEPLOY_FILES[@]}; do
    parent=`dirname $i`
    base=`basename $i`
    ls $parent/Custom/$base &> /dev/null
    if [[ $? -ne 0 ]]; then
        mkdir -p "$parent/Custom"
    fi
    # old_compiled=`echo "$parent/Custom/$base" | sed -e 's/.mq4$/.ex4/g'`
    # echo $old_compiled
    # rm -rf "$old_compiled"
    cp "$current_dir/Custom/$i" "$parent/Custom/$base"
    echo -e "\t\xE2\x9C\x94 $parent/Custom/$base"
done

# Copy DLL files to Meta Trader
for i in ${DLL_FILES[@]}; do
    parent=`dirname $i`
    base=`basename $i`
    cp "$current_dir/Custom/$i" "$parent/$base"
    echo -e "\t\xE2\x9C\x94 $parent/$base"
done

# Get folders in Meta Trader for compile
echo -e '\n[*] - Compiling Scripts...\n'

# declare -a PIDs=(`ps aux | grep compile`)
for pid in ${PIDs[@]}; do
    kill -9 $pid &> /dev/null
done

$wine ../metaeditor.exe /compile:"./Indicators/Custom" /log:"$current_dir/indicators.log"
$wine ../metaeditor.exe /compile:"./Experts/Custom" /log:"$current_dir/experts.log"

cat "$current_dir/indicators.log" && cat "$current_dir/experts.log"

echo -e "\n\n\xE2\x9C\x94 Deployment Complete !\n"

# Delete mq4 & mqh files in Meta Trader
find ./Indicators/Custom -type f \( -iname \*.mq4 -o -iname \*.mqh \) | sed -e "s/^/\"/g" -e "s/$/\"/g" | xargs rm -rf {};
find ./Experts/Custom -type f \( -iname \*.mq4 -o -iname \*.mqh \) | sed -e "s/^/\"/g" -e "s/$/\"/g" | xargs rm -rf {};

# Change all ex4 files to exec in Meta Trader
find ./Indicators -type f \( -iname \*.ex4 \) | sed -e "s/^/\"/g" -e "s/$/\"/g" | xargs -I {} chmod +x {};
find ./Experts -type f \( -iname \*.ex4 \) | sed -e "s/^/\"/g" -e "s/$/\"/g" | xargs -I {} chmod +x {};

# Fix Corona Indicator
cp Indicators/Custom/HKD\ Corona\ Indicators.ex4 Indicators/indicators.ex4

# # Copy compiled files to local repo
# declare -a COMPILED_FILES=(`find ./Indicators/Custom -name '*.ex4' && find ./Experts/Custom -name '*.ex4'`)

# for i in ${COMPILED_FILES[@]}; do
#     parent=`dirname $i | sed -e 's/\/Custom//g' | tr -d '^./'`
#     cp "$i" "$current_dir/Custom/$parent"
# done

IFS="$OIFS"

echo -e '\nDONE !!!'
