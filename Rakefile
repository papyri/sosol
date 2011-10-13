# Add your own tasks in files placed in lib/tasks ending in .rake,
# for example lib/tasks/capistrano.rake, and they will automatically be available to Rake.

require(File.join(File.dirname(__FILE__), 'config', 'boot'))

require 'rake'
require 'rake/testtask'
require 'rdoc'
if Gem.loaded_specs['rdoc'].version >= Gem::Version.create('2.4.2')
  require 'rdoc/task'
else
  require 'rake/rdoctask'
end

require 'tasks/rails'
