FROM debian:bullseye
LABEL org.opencontainers.image.authors="Ryan Baumann <ryan.baumann@gmail.com>"

# Install the Ubuntu packages.
# Install Ruby, RubyGems, Bundler, MySQL, Git, wget, svn, java
# openjdk-8-jre
# Install ruby-build build deps
ENV DEBIAN_FRONTEND=noninteractive
#Sets the HOME directory to /root entirely for /root/.gitconfig and git operations
ENV HOME=/root
RUN apt-get update && \
  apt-get install -y git wget subversion curl \
  autoconf bison build-essential libssl-dev libyaml-dev libreadline6-dev zlib1g-dev libncurses5-dev libffi-dev libgdbm6 libgdbm-dev locales \
  openjdk-11-jre cmake libgit2-dev pkg-config libpq-dev sendmail

# Set the locale.
RUN sed -i -e 's/# en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen && locale-gen
ENV LANG en_US.UTF-8
ENV LANGUAGE en_US:en
ENV LC_ALL en_US.UTF-8
WORKDIR /opt/sosol

# Install rbenv/ruby-build
RUN git clone https://github.com/rbenv/rbenv.git .rbenv
ENV RBENV_ROOT /opt/sosol/.rbenv
ENV PATH /opt/sosol/.rbenv/bin:/opt/sosol/.rbenv/shims:$PATH
RUN echo 'eval "$(rbenv init -)"' > /etc/profile.d/rbenv.sh
RUN chmod +x /etc/profile.d/rbenv.sh
RUN git clone https://github.com/rbenv/ruby-build.git "$(rbenv root)"/plugins/ruby-build && cd "$(rbenv root)"/plugins/ruby-build

RUN git clone https://github.com/rbenv/rbenv-vars.git $(rbenv root)/plugins/rbenv-vars

# Copy in secret files
# ADD development_secret.rb /root/sosol/config/environments/development_secret.rb
# ADD test_secret.rb /root/sosol/config/environments/test_secret.rb
# ADD production_secret.rb /root/sosol/config/environments/production_secret.rb

ADD . /srv/data/papyri.info/sosol/editor
WORKDIR /srv/data/papyri.info/sosol/editor

ARG RUBY_VERSION="jruby-9.4.13.0"
ARG BUNDLE_GEMFILE="Gemfile.jruby-9.4.13.0"
ENV RBENV_VERSION=$RUBY_VERSION
ENV BUNDLE_GEMFILE=$BUNDLE_GEMFILE

ENV RAILS_ENV=production
ENV RAILS_RELATIVE_URL_ROOT="/editor"
# Feel free to override this at runtime

RUN echo "${RUBY_VERSION}" > .ruby-version && rbenv install ${RUBY_VERSION} && rbenv rehash && gem install bundler:2.5.23 && rbenv rehash && bundle install && ruby -v && touch config/environments/development_secret.rb config/environments/production_secret.rb config/environments/test_secret.rb
RUN bundle exec cap local externals:setup
# RUN RAILS_ENV=test ./script/setup

RUN chgrp -R 0 /root && \
    chmod -R g=u /root

RUN chgrp -R 0 /srv/data/papyri.info/sosol/editor && \
    chmod -R g=u /srv/data/papyri.info/sosol/editor && \
    chmod +x script/server script/setup

RUN chgrp -R 0 /opt/sosol && \
    chmod -R g=u /opt/sosol
# Add git safe directory for the mounted canonical repo
RUN git config --global --add safe.directory /srv/data/papyri.info/sosol/repo/canonical.git

# Finally, start the application
EXPOSE 3000
CMD umask 002 && ./script/server
