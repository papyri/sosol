# Edit this Gemfile to bundle your application's dependencies.
# This preamble is the current preamble for Rails 3 apps; edit as needed.
source 'https://rubygems.org'
ruby "2.5.7", :engine => "jruby", :engine_version => "9.2.14.0"

gem 'rails', '~> 5.2.4.5'

# Needed for the new asset pipeline
gem 'sass-rails', '~> 5'
gem 'coffee-rails', '~> 4'
gem 'uglifier', '>= 1.0.3'
gem 'therubyrhino'

group :test do
  gem 'rake'
  gem 'mocha'
  gem 'shoulda-context'
  gem 'shoulda-matchers'
  gem 'shoulda'
  gem 'factory_bot_rails'
  gem 'database_cleaner-active_record'
  gem 'rails-controller-testing'
end

gem 'jquery-rails'
gem 'jruby-jars', File.read('.ruby-version').chomp.sub(/^jruby-/,'')
gem 'haml-rails', '~> 2.0'
gem 'sass'
# gem 'json-jruby', '>= 1.6.6', :require => 'json', :platform => :jruby
gem 'json', '>=1.6.6'
gem 'jdbc-sqlite3', '>= 3.7.2', :platform => :jruby
gem 'activerecord-jdbc-adapter', '>= 1.3.25', '~> 52', :platform => :jruby
gem 'activerecord-jdbcsqlite3-adapter', '>= 1.3.25', '~> 52', :platform => :jruby
gem 'activerecord-jdbcmysql-adapter', '>= 1.3.25', '~> 52', :platform => :jruby
gem 'activerecord-jdbcpostgresql-adapter', '>= 1.3.25', '~> 52', :platform => :jruby
gem 'jdbc-mysql', require: false
gem 'activerecord-session_store'
gem 'tzinfo-data', :platform => :jruby
gem 'actionpack-page_caching'
gem 'rack', '>= 1.1.0'
gem 'handle_invalid_percent_encoding_requests'
gem 'airbrake'
gem 'rubyzip', '~> 1.0'
gem 'zip-zip'
gem 'dynamic_form'
gem 'capistrano', '~> 2.15.0'
gem 'warbler', '~> 2.0'
gem 'puma'
gem 'sucker_punch', '~> 2.0'
gem 'with_advisory_lock'
gem 'silencer'
gem 'rack-attack', '~> 4.0'
gem 'i18n', '< 1.8.8'
gem "pry", "~> 0.14.0"
gem "pry-rails", "~> 0.3.9"
gem 'devise', github: 'heartcombo/devise', branch: 'master'
gem 'omniauth-google-oauth2'
gem 'dotenv-rails'
gem 'omniauth-rails_csrf_protection'
