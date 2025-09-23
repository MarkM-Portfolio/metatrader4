#!/bin/bash

USERNAME=$!

echo -e "\n---++--- [ Setup Contabo Ubuntu 22.04 ] ---++---"
echo -e "Created by: Mark Mon Monteros\n"

[ -z $1 ] && echo "No user parameters "\$1" provided" && exit 1

echo -e "\nChange Timezone to PST..." \
    && rm -rf /etc/localtime \
    && ln -s /usr/share/zoneinfo/Asia/Manila /etc/localtime

echo -e "\nInstalling Dependencies..." \
    && apt-get -y update \
    && apt-get -y upgrade \
    && apt-get -y install xfce4 xfce4-goodies firefox stacer mmv \
    build-essential libssl-dev libffi-dev python3-dev \
    libbz2-dev libreadline-dev libsqlite3-dev llvm \
    libncurses5-dev libncursesw5-dev xz-utils tk-dev \
    ufw wget curl pkg-config unzip git \
    && wget "https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb" \
    && dpkg -i google-chrome-stable_current_amd64.deb \
    && apt-get install -f && rm google-chrome-stable_current_amd64.deb

echo -e "\nInstalling Python 3.12..." \
    && wget "https://www.python.org/ftp/python/3.12.2/Python-3.12.2.tgz" \
    && tar -xzf Python-3.12.2.tgz \
    && cd Python-3.12.2 && ./configure --enable-optimizations --with-ssl \
    && make -j 8 && make altinstall && cd - \
    && ln -s /usr/local/bin/python3.12 /usr/bin/python --force \
    && ln -s /usr/local/bin/python3.12 /usr/bin/python3 --force \
    && ln -s /usr/local/bin/pip3.12 /usr/bin/pip --force \
    && ln -s /usr/local/bin/pip3.12 /usr/bin/pip3 --force \
    && rm -rf Python-3.12.2 Python-3.12.2.tgz \
    && pip install --upgrade pip requests \
    && pip install requests selenium webdriver_manager pytz boto3

echo -e "\nCreating New User: ${USERNAME}..." \
    && adduser ${USERNAME} \
    && usermod -aG sudo,adm ${USERNAME} \
    && echo "${USERNAME}   ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers \
    && echo "0 0,3,6 * * * /usr/bin/python /home/${USERNAME}/metatrader4/news-scheduler-AWS.py" >> /var/spool/cron/crontabs/${USERNAME} \
    && sudo su - ${USERNAME} \
    && mkdir -p ~/.ssh && cd ~/.ssh \
    && touch authorized_keys && cd -

echo -e "\nInstalling RDP..." \
&& wget http://www.c-nergy.be/downloads/xRDP/xrdp-installer-1.4.zip \
    && cd /home/${USERNAME} \
    && unzip xrdp-installer-1.4.zip \
    && chmod +x xrdp-installer-1.4.sh \
    && ./xrdp-installer-1.4.sh \
    && rm -rf xrdp-installer-1.4*

echo -e "\nChange Ports for RDP & SSH" \
    && sed -i 's/3389/52189/g' /etc/xrdp/xrdp.ini \
    && sed -i 's/#Port 22/Port 52188/g' /etc/ssh/sshd_config \
    && ufw allow 52189 \
    && ufw allow 52188 \
    && ufw enable \
    && systemctl restart sshd.service \
    && systemctl restart xrdp

echo -e "\nDownloading MetaTrader 4..." \
    && mkdir -p /home/${USERNAME}/Downloads \
    && cd /home/${USERNAME}/Downloads \
    && wget https://download.mql5.com/cdn/web/metaquotes.software.corp/mt4/mt4ubuntu.sh \
    && chmod +x mt4ubuntu.sh

echo -e "\nSetup Ubuntu 22.04 DONE !!!"
