set :application, "protosite"
set :repository,  "ssh://halsted.vis.uky.edu/srv/git/protosite.git"
set :scm, "git"
set :user, "idp2"
set :scm_verbose, true
set :git_enable_submodules, true
set :branch, "master"

# If you aren't deploying to /u/apps/#{application} on the target
# servers (which is the default), you can specify the actual location
# via the :deploy_to variable:
set :deploy_to, "/var/rails/#{application}"
set :use_sudo, false

role :app, "halsted.vis.uky.edu"
role :web, "halsted.vis.uky.edu"
role :db,  "halsted.vis.uky.edu", :primary => true

# Variables for production server running Glassfish
set :context_root, "protosite"
set :jruby_location, "/opt/jruby/"
set :gf_port, "3000"
set :environment, "production"
set :jruby_runtimes, "1"
set :jruby_min_runtimes, "1"
set :jruby_max_runtimes, "1"
set :rake, "/opt/jruby/bin/jruby -S rake"

# Tasks adapted from Glassfish Capistrano recipes http://tinyurl.com/yhu8jdw
namespace :deploy do
  desc "Start Glassfish Gem from a shutdown state"
  task :cold , :roles => :app do
    update
    start
  end
  
  desc "Starts a server running Glassfish Gem"
  task :start, :roles => :app do
    run "CLASSPATH='#{release_path}/lib/java/*' #{jruby_location}bin/jruby -S glassfish --contextroot #{context_root} --port #{gf_port} --environment #{environment} --runtimes #{jruby_runtimes} --runtimes-min #{jruby_min_runtimes} --runtimes-max #{jruby_max_runtimes} -P #{shared_path}/capistrano-#{application} --daemon #{release_path}"
  end

  desc "Stop a server running Glassfish Gem"
  task :stop, :roles => :app do
    run "kill -INT $(cat #{shared_path}/capistrano-#{application})"  
  end

  desc "Restart Application"
  task :restart, :roles => :app do
    stop
    start
  end
end

# Copy in unversioned files with secret info (API keys, DB passwords, etc.)
# TODO: add git repo stuff here
task :after_update_code, :roles => :app do
  git_path = "#{shared_path}/db/git"
  run "mkdir -p #{git_path}"
  run "rm -rf #{release_path}/db/git"
  run "ln -s #{git_path} #{release_path}/db/git"
  
  db_config = "#{shared_path}/config/database.yml.production"
  run "cp #{db_config} #{release_path}/config/database.yml"
  
  secret_config = "#{shared_path}/config/environments/production_secret.rb"
  run "cp #{secret_config} #{release_path}/config/environments/production_secret.rb"
end

namespace :gems do
  desc "Install gems"
  task :install, :roles => :app do
    run "cd #{current_path} && #{sudo} rake RAILS_ENV=production gems:install"
  end
end

# Dir[File.join(File.dirname(__FILE__), '..', 'vendor', 'gems', 'hoptoad_notifier-*')].each do |vendored_notifier|
#   $: << File.join(vendored_notifier, 'lib')
# end
# 
# require 'hoptoad_notifier/capistrano'
