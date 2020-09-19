#!/bin/bash
# This replaces the contents of the config map for the zammad helm chart deployment
set -e
rsync -av --delete --exclude 'config/database.yml' --exclude 'public/assets/images/*' --exclude 'storage/fs/*' "${ZAMMAD_TMP_DIR}/" "${ZAMMAD_DIR}"
rsync -av "${ZAMMAD_TMP_DIR}"/public/assets/images/ "${ZAMMAD_DIR}"/public/assets/images
sed -i -e "s/.*config.cache_store.*file_store.*cache_file_store.*/    config.cache_store = :dalli_store, 'zammad-memcached:11211'\\n    config.session_store = :dalli_store, 'zammad-memcached:11211'/" config/application.rb
sed -i -e "s#config.action_dispatch.trusted_proxies =.*#config.action_dispatch.trusted_proxies = ['127.0.0.1', '::1']#" config/environments/production.rb
if [ -n "${AUTOWIZARD_JSON}" ]; then
    echo "${AUTOWIZARD_JSON}" | base64 -d > auto_wizard.json
fi
echo "Installing custom Packages"
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
  if [ ! -f "/opt/package_auto_install.patch" ]; then
    git checkout HEAD package_auto_install.patch
    mv package_auto_install.patch /opt/.
    echo "Patching package.rb to add reinstall function"
    patch -u /opt/zammad/app/models/package.rb -i /opt/package_auto_install.patch
  fi
  cd $PREV_DIR
}
# Install packages
cd /opt/zammad
get_package https://github.com/abartrim/zammad_twilio_voice.git twilio_voice
# get_package https://github.com/abartrim/zammad-itshield-app zammad-mobileapp
# echo "Replacing site icon"
cd /opt/zammad
echo "Auto installing packages."
bundle exec rails r "Package.auto_reinstall"
echo "Rebuilding assets."
bundle exec rake assets:precompile &> /dev/null
chown -R "${ZAMMAD_USER}":"${ZAMMAD_USER}" "${ZAMMAD_DIR}"
echo "zammad init complete :)"