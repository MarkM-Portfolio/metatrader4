#!/bin/bash

echo -e '\n[*] - Adding MQ4 compiler to profile..'

rc_file=`ls -a ~ | grep -e 'rc$' | grep 'bash\|zsh'`

echo -e '\n\t\xE2\x9C\x94 Updating '$rc_file...

echo -e '\n# METATRADER 4' >> ~/$rc_file

if [[ "$OSTYPE" == "darwin"* ]]; then
    # mql4_home="${HOME}/Library/Application Support/MetaTrader 4/Bottles/metatrader64/drive_c/Program Files (x86)/MetaTrader 4/MQL4"
    # echo -e alias mql4_home=\"cd \~/Library/Application\\ Support/MetaTrader\\ 4/Bottles/metatrader64/drive_c/Program\\ Files\\ \\\(x86\\\)/MetaTrader\\ 4/MQL4\" >> ~/$rc_file
    # echo -e alias metaeditor=\"\~/Library/Application\\ Support/MetaTrader\\ 4/Bottles/metatrader64/drive_c/Program\\ Files\\ \\\(x86\\\)/MetaTrader\\ 4/metaeditor.exe\" >> ~/$rc_file
    # echo -e alias wine=\"\'/Volumes/Macintosh HD/Applications/MetaTrader 4.app/Contents/SharedSupport/metatrader4/bin/wine\'\" >> ~/$rc_file

    echo -e alias mql4_home=\"cd \~/Library/Application\\ Support/net.metaquotes.wine.metatrader4/drive_c/Program\\ Files\\ \\\(x86\\\)/MetaTrader\\ 4/MQL4\" >> ~/$rc_file
    echo -e alias metaeditor=\"\~/Library/Application\\ Support/net.metaquotes.wine.metatrader4/drive_c/Program\\ Files\\ \\\(x86\\\)/MetaTrader\\ 4/metaeditor.exe\" >> ~/$rc_file
    echo -e alias wine=\"\'/Volumes/Macintosh HD/Applications/MetaTrader 4.app/Contents/SharedSupport/wine/bin/wine64\'\" >> ~/$rc_file
elif [[ "$OSTYPE" == "win32" ]]; then
    mql4_home="C:\Users\Administrator\AppData\Roaming\MetaQuotes\Terminal\60464E72AB1410FB355EEFF02B5B34F9\MQL4"
else
    # mql4_home="${HOME}/.wine/drive_c/Program Files (x86)/Fullerton Markets Inc MT4/MQL4"
    echo -e alias mql4_home=\"cd \\${HOME}/.mt4/drive_c/Program\\ Files\\ \\\(x86\\\)/MetaTrader\\ 4\\/MQL4\" >> ~/$rc_file
    echo -e alias metaeditor=\"\\${HOME}/.mt4/drive_c/Program\\ Files\\ \\\(x86\\\)/MetaTrader\\ 4\\/MQL4/metaeditor.exe\" >> ~/$rc_file
fi

echo -e alias mql4_compiler=\"compile_mql4\" >> ~/$rc_file

echo -e '\ncompile_mql4() {' >> ~/$rc_file
echo -e '\tlogfile=./mq4.log' >> ~/$rc_file
echo -e '\techo -e "\\n---++--- [ MQL4 Compiler ] ---++---"' >> ~/$rc_file
echo -e '\techo -e "Created by: Mark Mon Monteros\\n"' >> ~/$rc_file

# echo -e '\tfind $1 -name "*.ex4" | sed -e "s/^/\"/g" -e "s/$/\"/g" | xargs rm -rf {};' >> ~/$rc_file
if [[ "$OSTYPE" == "darwin"* ]]; then
    echo -e '\twine ~/Library/Application\ Support/MetaTrader\ 4/Bottles/metatrader64/drive_c/Program\ Files\ \(x86\)/MetaTrader\ 4/metaeditor.exe /compile:$1 /log:$logfile' >> ~/$rc_file
fi

echo -e '\tcat $logfile && rm -rf $logfile' >> ~/$rc_file
echo -e '\techo -e "\\nDONE!"' >> ~/$rc_file
echo -e '}' >> ~/$rc_file
echo -e '\n\t\xE2\x9C\x94 Sourcing '$rc_file...
source ~/$rc_file >> /dev/null 2>&1

echo -e '\nDONE !!!'
