#!/bin/bash

echo -e "\n---++--- [ Installing Meta Trader 4 ] ---++---"

installer_path="${HOME}/Downloads"
# installer=`ls "$installer_path" | grep -e '.exe$' | grep -i 'fullerton'`
# wine "$installer_path"/$installer
"$installer_path"/mt4ubuntu.sh

./deploy.sh
./rc_compiler_env.sh
