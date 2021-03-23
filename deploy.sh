#!/bin/bash

BUNDLER_VERSION="2.2.15"

# workaround for puppet permissions on dev
chmod a+rx ~

# make sure we can run jruby as tomcat before doing anything
rbenv install -s && sudo -u tomcat jruby --version
if [ $? -eq 0 ]; then
  if ! command -v bundle || ! bundle --version | fgrep ${BUNDLER_VERSION}; then
    gem install bundler:${BUNDLER_VERSION}
  fi
  sudo -u tomcat JRUBY_OPTS="-J-Xmx4g" jruby -S bundle install
  # Needed for asset pipeline:
  sudo -u tomcat jruby -S bundle exec rake assets:precompile RAILS_ENV=production RAILS_RELATIVE_URL_ROOT='/editor' RAILS_GROUPS=assets
  sudo /etc/init.d/papyri.info stop-tc
  sudo -u tomcat jruby -S bundle exec cap local externals:setup
  sudo -u tomcat jruby -S bundle exec rake db:migrate RAILS_ENV="production"
  sudo /etc/init.d/papyri.info start-tc
fi
