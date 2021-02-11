#!/bin/bash

# workaround for puppet permissions on dev
chmod a+rx ~

# make sure we can run jruby as tomcat before doing anything
rbenv install -s && sudo -u tomcat jruby --version
if [ $? -eq 0 ]; then
sudo -u tomcat JRUBY_OPTS="-J-Xmx4g" jruby -S bundle install
sudo -u tomcat jruby -S bundle exec cap local externals:setup
sudo -u tomcat jruby -S bundle exec rake db:migrate RAILS_ENV="production"
# Needed for asset pipeline:
sudo -u tomcat jruby -S bundle exec rake assets:precompile RAILS_ENV=production RAILS_RELATIVE_URL_ROOT='/editor' RAILS_GROUPS=assets
sudo -u tomcat jruby -S bundle exec warble war
BACKUP_WAR="editor.war.bak$(date +"%Y%m%d.%H.%M.%S")"
sudo cp -v /usr/local/tomcat-sosol/webapps/editor.war ${BACKUP_WAR}
sudo ln -sfv ${BACKUP_WAR} editor.war.previous
sudo /etc/init.d/papyri.info stop-tc
sudo cp -v editor.war /usr/local/tomcat-sosol/webapps/
sudo rm -r /usr/local/tomcat-sosol/webapps/editor
sudo /etc/init.d/papyri.info start-tc
fi
