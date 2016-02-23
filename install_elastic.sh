#!/bin/bash

# This script installs elasticsearch for Debian Linux.
# It is designed for use in Docker.

# Source: https://www.elastic.co/guide/en/elasticsearch/reference/current/setup-repositories.html
wget -qO - https://packages.elastic.co/GPG-KEY-elasticsearch | sudo apt-key add -
sudo echo "deb http://packages.elastic.co/elasticsearch/2.x/debian stable main" | sudo tee -a /etc/apt/sources.list.d/elasticsearch-2.x.list
echo '*******************'
echo 'sudo apt-get update'
sudo apt-get update
echo '*************************************'
echo 'sudo apt-get install -y elasticsearch'
sudo apt-get install -y elasticsearch | tee -a /log/install_elastic.txt
echo '-----------------------------------------------------------------'
echo 'sudo cp config/etc-init_d-elasticsearch /etc/init.d/elasticsearch'
sudo cp config/etc-init_d-elasticsearch /etc/init.d/elasticsearch

# Necessary for writing to log files
# Source: http://stackoverflow.com/questions/24975895/elasticsearch-cant-write-to-log-files
echo '--------------------------------------------------------------'
echo 'sudo ln -s /etc/elasticsearch/ /usr/share/elasticsearch/config'
sudo ln -s /etc/elasticsearch/ /usr/share/elasticsearch/config
echo '**********************************************'
echo 'ElasticSearch is now installed and configured!'
echo 'The command "sudo service elasticsearch start" starts ElasticSearch.'
echo 'It is recommended that you dedicate a tmux window for running ElasticSearch.'
echo '*************************'
echo 'Now running ElasticSearch'
echo 'Press Ctrl-C to exit.'
echo '*********************'
sudo service elasticsearch start
