# Edit this Gemfile to bundle your application's dependencies.
# This preamble is the current preamble for Rails 3 apps; edit as needed.
source 'https://rubygems.org'
ruby "2.3.3", :engine => "jruby", :engine_version => "9.1.17.0"

gem 'rails', '~> 4.0.13'

# Needed for the new asset pipeline
gem 'sass-rails', '~> 4'
gem 'coffee-rails', '~> 4'
gem 'uglifier', '>= 1.0.3'
gem 'therubyrhino'

group :test do
  gem 'rake'
  gem 'mocha', '~> 1.1.0'
  gem 'shoulda-context'
  gem 'shoulda-matchers'
  gem 'shoulda'
  gem "factory_girl_rails", ">= 1.2"
  gem 'factory_girl', '>= 2.6.4'
end

gem 'jquery-rails'
gem 'jruby-jars', File.read('.ruby-version').chomp.sub(/^jruby-/,'')
gem 'haml', '= 4.0.6'
gem 'sass'
# gem 'json-jruby', '>= 1.6.6', :require => 'json', :platform => :jruby
gem 'json', '>=1.6.6'
gem 'jdbc-sqlite3', '>= 3.7.2', :platform => :jruby
gem 'activerecord-jdbc-adapter', '~> 1.3.25', :platform => :jruby
gem 'activerecord-jdbcsqlite3-adapter', '~> 1.3.25', :platform => :jruby
gem 'activerecord-jdbcmysql-adapter', '~> 1.3.25', :platform => :jruby
gem 'activerecord-jdbcpostgresql-adapter', '~> 1.3.25', :platform => :jruby
gem 'rack', '>= 1.1.0'
gem 'handle_invalid_percent_encoding_requests'
gem 'airbrake', '~> 5.6.1'
gem 'rubyzip', '~> 1.0'
gem 'zip-zip'
gem 'prototype-rails'
gem 'dynamic_form'
gem 'capistrano', '~> 2.15.0'
gem 'warbler', '~> 2.0'
gem 'puma'
gem 'database_cleaner'
gem 'sucker_punch', '~> 2.0'
gem 'with_advisory_lock', '~> 3.0.0'
gem 'silencer'
gem 'rack-attack', '~> 4.0'

gem 'test_after_commit', '= 0.4.1', :group => :test
gem 'test-unit-rails', '= 1.0.4', :group => :test
