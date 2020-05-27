#!/bin/bash

# workaround for puppet permissions on dev
chmod a+rx ~

# make sure we can run jruby --2.0 as tomcat before doing anything
sudo -u tomcat jruby --2.0 --version
if [ $? -eq 0 ]; then
sudo -u tomcat JRUBY_OPTS="-J-Xmx4g --2.0" jruby --2.0 -S bundle install
sudo -u tomcat JRUBY_OPTS="--2.0" jruby --2.0 -S bundle exec cap local externals:setup
sudo -u tomcat JRUBY_OPTS="--2.0" jruby --2.0 -S bundle exec rake db:migrate RAILS_ENV="production"
# Only needed for asset pipeline in future versions of Rails:
# sudo -u tomcat jruby --2.0 -S bundle exec rake assets:precompile RAILS_ENV=production JRUBY_OPTS="--2.0"
sudo -u tomcat JRUBY_OPTS="--2.0" jruby --2.0 -S bundle exec warble war
BACKUP_WAR="editor.war.bak$(date +"%Y%m%d.%H.%M.%S")"
sudo cp -v /usr/local/tomcat-sosol/webapps/editor.war ${BACKUP_WAR}
sudo ln -sfv ${BACKUP_WAR} editor.war.previous
sudo /etc/init.d/papyri.info stop-tc
sudo cp -v editor.war /usr/local/tomcat-sosol/webapps/
sudo rm -r /usr/local/tomcat-sosol/webapps/editor
sudo /etc/init.d/papyri.info start-tc
fi
