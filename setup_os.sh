#!/bin/bash

echo -e "\nChange Timezone to PST..."
sudo rm -rf /etc/localtime
sudo ln -s /usr/share/zoneinfo/Asia/Manila /etc/localtime

mkdir -p ~/Downloads ~/ssl
openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout ~/ssl/nginx.key -out ~/ssl/nginx.crt

echo -e "\nInstalling Docker..."
sudo apt -y update
sudo apt -y install apt-transport-https ca-certificates curl software-properties-common
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt -y update
apt-cache policy docker-ce
sudo apt -y install docker-ce docker-compose
sudo systemctl status docker
echo -e "\nEnable Docker to user ${USER}..."
sudo usermod -aG docker ${USER}
logout

# wget https://download.mql5.com/cdn/web/metaquotes.software.corp/mt4/mt4ubuntu.sh ; chmod +x mt4ubuntu.sh ; ./mt4ubuntu.sh

echo -e "\nUser logged out. Please re-login !!!"
