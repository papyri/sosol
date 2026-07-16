#!/usr/bin/env ruby
## lib/tasks/git.rake
#
# Rake task to fully copy your master database into a new database for current branch.
# Sample usage:
#
#   rake git:db:clone
#
# What gets run:
#
#   cp #{from} #{target}
#   mysqldump -u #{user} #{from} | mysql -u #{user} #{target}
#
namespace :git do
  namespace :db do
    namespace :canonical do
      desc 'Clone Canonical idp.data Git database'
      task clone: :environment do
        require File.expand_path('../../config/boot', __dir__)

        CANONICAL_CLONE_URL = if ENV['RAILS_ENV'] == 'test'
                                'https://gitlab.oit.duke.edu/papyri/idp.data.test.git'
                              elsif File.exist?('/srv/data/papyri.info/idp.data')
                                '/srv/data/papyri.info/idp.data'
                              else
                                'https://github.com/papyri/idp.data.git'
                              end

        unless File.exist?(Sosol::Application.config.canonical_repository)
          clone_command = ['git clone --bare',
                           CANONICAL_CLONE_URL,
                           "\"#{Sosol::Application.config.canonical_repository}\""].join(' ')

          clone_command += ' >/dev/null 2>&1' if ENV['RAILS_ENV'] == 'test'
          system(clone_command)
        end
      end
    end
  end
end
