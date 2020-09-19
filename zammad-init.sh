#!/bin/bash
# Add this to the helm zammad-init container commands
apt update && apt install git -y
function get_package {
  echo "Downloading package ${2}"
  PREV_DIR=$(pwd)
  cd /opt
  git clone -n $1 --depth 1 $2
  cd $2
  git checkout HEAD ${2}.szpm
  mkdir -p /opt/zammad/auto_install
  mv ${2}.szpm /opt/zammad/auto_install/${2}.zpm
  # ls -l /opt/zammad/auto_install
  cd $PREV_DIR
#  rm -rf /opt/${2}
}

# Install packages
cd /opt/zammad
get_package https://github.com/abartrim/zammad_twilio_voice.git twilio_voice
# get_package https://github.com/abartrim/zammad-itshield-app zammad-mobileapp

# echo "Replacing site icon"
cd /opt/zammad
echo "Auto installing packages."
bundle exec rails r "Package.auto_install"
echo "Rebuilding assets."
bundle exec rake assets:precompile &> /dev/null
#echo "Restart rails server"
#pumactl restart -p $(ps a | grep puma | grep zammad | awk '{print $1}')
