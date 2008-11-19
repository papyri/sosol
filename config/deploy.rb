require 'mongrel_cluster/recipes'

set :application, "protosite"
set :repository,  "ssh://halsted.vis.uky.edu/srv/git/protosite.git"
set :scm, "git"
set :user, "idp2"
set :scm_passphrase, "eik9aeDo"
set :branch, "master"

# If you aren't deploying to /u/apps/#{application} on the target
# servers (which is the default), you can specify the actual location
# via the :deploy_to variable:
set :deploy_to, "/var/rails/#{application}"
set :mongrel_conf, "#{current_path}/config/mongrel_cluster.yml"

# If you aren't using Subversion to manage your source code, specify
# your SCM below:
# set :scm, :subversion

role :app, "halsted.vis.uky.edu"
role :web, "halsted.vis.uky.edu"
role :db,  "halsted.vis.uky.edu", :primary => true
