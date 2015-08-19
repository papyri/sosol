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
      desc "Clone Canonical idp.data Git database"
      task :clone => :environment do
        require 'config/boot'
        
        if ENV['RAILS_ENV'] == "test"
          CANONICAL_CLONE_URL = "git://github.com/ryanfb/idp.data.test.git"
        else
          CANONICAL_CLONE_URL = "git://github.com/papyri/idp.data.git"
        end
        
        if !File.exist?(Sosol::Application.config.canonical_repository)
          clone_command = ["git clone --bare",
                          CANONICAL_CLONE_URL,
                          "\"#{Sosol::Application.config.canonical_repository}\""].join(' ')
          
          system(clone_command)
        end
      end
    end
  end
end
