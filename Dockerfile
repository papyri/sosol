FROM debian:bullseye
LABEL org.opencontainers.image.authors="Ryan Baumann <ryan.baumann@gmail.com>"

# Install the Ubuntu packages.
# Install Ruby, RubyGems, Bundler, MySQL, Git, wget, svn, java
# openjdk-8-jre
# Install ruby-build build deps
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && \
  apt-get install -y git wget subversion curl \
  autoconf bison build-essential libssl-dev libyaml-dev libreadline6-dev zlib1g-dev libncurses5-dev libffi-dev libgdbm6 libgdbm-dev locales \
  openjdk-11-jre

# Set the locale.
RUN sed -i -e 's/# en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen && locale-gen
ENV LANG en_US.UTF-8
ENV LANGUAGE en_US:en
ENV LC_ALL en_US.UTF-8
WORKDIR /root

# Install rbenv/ruby-build
RUN git clone https://github.com/rbenv/rbenv.git .rbenv
ENV PATH /root/.rbenv/bin:/root/.rbenv/shims:$PATH
RUN echo 'eval "$(rbenv init -)"' > /etc/profile.d/rbenv.sh
RUN chmod +x /etc/profile.d/rbenv.sh
# Removed specific ruby-build version someone seems to have mistakenly considered jruby.sh a 
# windows only file and launcher (remove_windows_files) deletes the file
# https://github.com/rbenv/ruby-build/pull/2517 https://github.com/jruby/jruby-launcher/pull/48#issuecomment-2772272290
RUN git clone https://github.com/rbenv/ruby-build.git "$(rbenv root)"/plugins/ruby-build && cd "$(rbenv root)"/plugins/ruby-build

RUN git clone https://github.com/rbenv/rbenv-vars.git $(rbenv root)/plugins/rbenv-vars

# Copy in secret files
# ADD development_secret.rb /root/sosol/config/environments/development_secret.rb
# ADD test_secret.rb /root/sosol/config/environments/test_secret.rb
# ADD production_secret.rb /root/sosol/config/environments/production_secret.rb

ADD . /root/sosol/
WORKDIR /root/sosol
RUN rbenv install && rbenv rehash && gem install bundler:2.5.23 && rbenv rehash && bundle install && jruby -v && java -version && touch config/environments/development_secret.rb config/environments/production_secret.rb config/environments/test_secret.rb
RUN bundle exec cap local externals:setup
# RUN RAILS_ENV=test ./script/setup

# Finally, start the application
EXPOSE 3000
CMD cd sosol && ./script/server
