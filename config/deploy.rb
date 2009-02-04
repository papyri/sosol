require 'mongrel_cluster/recipes'

set :application, "protosite"
set :repository,  "ssh://halsted.vis.uky.edu/srv/git/protosite.git"
set :scm, "git"
set :git_enable_submodules, true
set :branch, "master"

# If you aren't deploying to /u/apps/#{application} on the target
# servers (which is the default), you can specify the actual location
# via the :deploy_to variable:
set :deploy_to, "/var/rails/#{application}"
set :mongrel_conf, "#{current_path}/config/mongrel_cluster.yml"
set :mongrel_clean, true

# If you aren't using Subversion to manage your source code, specify
# your SCM below:
# set :scm, :subversion

role :app, "halsted.vis.uky.edu"
role :web, "halsted.vis.uky.edu"
role :db,  "halsted.vis.uky.edu", :primary => true

# Copy in unversioned files with secret info (API keys, DB passwords, etc.)
task :after_update_code, :roles => :app do
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
