#!/bin/bash

# This is the one-step build process for the Docker image customized for this project.
# This Docker container includes PostgreSQL, rbenv, this project's current Ruby version, and
# this project's current versions of the rails, pg, and nokogiri gems pre-installed.
# You can have everything working on your machine in minutes instead of hours.
# You can reinstall Ruby on Rails in seconds instead of hours.

# ENTERING THE CUSTOMIZED DOCKER IMAGE:
# 1.  Have Docker or Docker Machine installed on your host OS.
# 2.  Enter the following commands:
#     git clone https://github.com/jhsu802701/docker-32bit-debian-jessie
#     sh rbenv-rubygems.sh
#     cd rbenv-rubygems
#     sh download_new_image.sh

# GETTING STARTED
# 1.  Use tmux for simultaneous operations
# 2.  Enter "redis server" in one tmux window to run the Redis server.
# 3.  Enter "sudo service elasticsearch start" in another tmux window to run Elasticsearch.
# 4.  Use additional tmux windows for this rubygems.org app.
# 5.  Use the git clone to download this project.  From this project's root
#     directory, run this build_fast.sh script.

echo 'Welcome to the build script of the rubygems.org site!'
echo 'This script assumes that you are using the'
echo 'jhsu802701/debian-jessie-rbenv-rubygems Docker image to work on'
echo 'this project and that you are using the pre-installed tmux tool'
echo 'to provide simultaneous multiple windows to interact with the'
echo 'same Docker container.'
echo ''
echo 'The purpose of this script is to allow you to quickly and efficiently'
echo 'set up this project.  Setting up the project so that all tests pass'
echo 'will be something you can do in minutes instead of hours.'
echo ''
echo 'WARNING: '
echo ''
echo 'Before you continue, please check to make sure that you have satisfied'
echo 'the following prerequisites:'
echo '1. You are running these scripts in a 64-bit OS.  This project uses'
echo '   Toxiproxy, which is not available for 32-bit systems.'
echo '2. You are using one tmux window to run the Redis server.  (The'
echo '   command for starting this is "redis server".)'
echo '3. You are using a second tmux window to run Toxiproxy.  (The'
echo '   command for starting this is "toxiproxy".  If you have not'
echo '   already installed Toxiproxy, please run the build_prep.sh'
echo '   script in another tmux window to install and run Toxiproxy.'
echo '4. You are running this script in a third tmux window.'
echo '------------------------------------------------------------'
echo 'If you have satisfied the above requirements, press ENTER to' 
echo 'continue.'
echo 'Otherwise, press Ctrl-C to exit.'
echo '--------------------------------'
read cont
echo 'Continuing . . . .'

echo '--------------------------------'
echo 'sudo service elasticsearch start'
sudo service elasticsearch start

PG_VERSION="$(ls /etc/postgresql)"
PG_HBA="/etc/postgresql/$PG_VERSION/main/pg_hba.conf"
PG_CONF="/etc/postgresql/$PG_VERSION/main/postgresql.conf"

# Change the settings in the pg_hba.conf file
sudo bash -c "echo '# Database administrative login by Unix domain socket' > $PG_HBA"
sudo bash -c "echo 'local   all             postgres                                peer' >> $PG_HBA"
sudo bash -c "echo 'local   all             all                                     peer' >> $PG_HBA"
sudo bash -c "echo 'host    all             all             0.0.0.0/0            md5'  >> $PG_HBA"
sudo bash -c "echo 'host    all             all             ::1/128                 md5'  >> $PG_HBA"

# Configuring PG_CONF
sudo sed -i 's/^port = .*/port = 5432/' $PG_CONF
sudo sed -i "s/#listen_addresses = 'localhost'/listen_addresses = '*'/" $PG_CONF

echo '-------------------------------'
echo 'sudo service postgresql restart'
sudo service postgresql restart
wait

echo '**************'
echo 'bundle install'
bundle install

echo '-----------------------------'
echo 'Configure config/database.yml'
DB_DEV='gemcutter_development'
DB_TEST='gemcutter_test'
DB_USERNAME=$USERNAME
DB_PASSWORD='password1'

echo "Database (development): $DB_DEV"
echo "Database (test): $DB_TEST"
echo "Database username: $DB_USERNAME"
echo "Database password: $DB_PASSWORD"

echo 'default: &default' > config/database.yml
echo '  adapter: postgresql' >> config/database.yml
echo "  pool: 5" >> config/database.yml
echo '  timeout: 5000' >> config/database.yml
echo '' >> config/database.yml
echo "development:" >> config/database.yml
echo '  <<: *default' >> config/database.yml
echo "  database: $DB_DEV" >> config/database.yml
echo '' >> config/database.yml
echo 'test:' >> config/database.yml
echo '  <<: *default' >> config/database.yml
echo "  database: $DB_TEST" >> config/database.yml

# Give superuser privileges to regular user

sudo -u postgres psql -c"CREATE EXTENSION hstore;"
sudo -u postgres psql -c"CREATE EXTENSION plpgsql;"
sudo -u postgres psql -c"CREATE ROLE $DB_USERNAME SUPERUSER;"
sudo -u postgres psql -c"ALTER ROLE $DB_USERNAME WITH LOGIN;"
sudo -u postgres psql -c"CREATE DATABASE $DB_DEV WITH OWNER=$DB_USERNAME;"
sudo -u postgres psql -c"CREATE DATABASE $DB_TEST WITH OWNER=$DB_USERNAME;"

echo '***************************'
echo 'bundle exec rake db:migrate'
bundle exec rake db:migrate

echo '****************'
echo 'bundle exec rake'
bundle exec rake
