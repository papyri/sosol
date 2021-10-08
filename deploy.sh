#!/bin/bash

BUNDLER_VERSION=$(fgrep -A1 'BUNDLED WITH' Gemfile.lock | tail -1 | sed -e 's/^ *//')
EDITOR_USER="papyri"

# make sure we can run jruby as $EDITOR_USER before doing anything
rbenv install -s && sudo -u $EDITOR_USER jruby --version
if [ $? -eq 0 ]; then
  if ! command -v bundle || ! bundle --version | fgrep ${BUNDLER_VERSION}; then
    gem install bundler:${BUNDLER_VERSION}
  fi
  sudo -u $EDITOR_USER JRUBY_OPTS="-J-Xmx4g" jruby -S bundle install
  # Needed for asset pipeline:
  sudo -u $EDITOR_USER jruby -S bundle exec rake assets:precompile RAILS_ENV=production RAILS_RELATIVE_URL_ROOT='/editor' RAILS_GROUPS=assets
  sudo /etc/init.d/papyri.info stop-tc
  sudo -u $EDITOR_USER jruby -S bundle exec cap local externals:setup
  sudo -u $EDITOR_USER jruby -S bundle exec rake db:migrate RAILS_ENV="production"
  sudo /etc/init.d/papyri.info start-tc
fi
