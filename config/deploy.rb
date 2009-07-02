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

# Tasks from Phusion Passenger User's Guide
namespace :deploy do
  task :start, :roles => :app do
    run "touch #{current_release}/tmp/restart.txt"
  end

  task :stop, :roles => :app do
    # Do nothing.
  end

  desc "Restart Application"
  task :restart, :roles => :app do
    run "touch #{current_release}/tmp/restart.txt"
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
