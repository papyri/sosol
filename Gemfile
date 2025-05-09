# Edit this Gemfile to bundle your application's dependencies.
# This preamble is the current preamble for Rails 3 apps; edit as needed.
source 'https://rubygems.org'
ruby '3.1.4', engine: 'jruby', engine_version: '9.4.9.0'

gem 'rails', '~> 7.0', '< 7.1'

# Needed for the new asset pipeline
gem 'coffee-rails'
gem 'sass-rails', '~> 6'
gem 'therubyrhino'
gem 'uglifier', '>= 1.0.3'

group :test do
  gem 'database_cleaner-active_record'
  gem 'factory_bot_rails'
  gem 'mocha'
  gem 'rails-controller-testing'
  gem 'rake'
  gem 'shoulda-context'
  gem 'shoulda-matchers'
end

group :development, :test do
  gem 'rubocop'
  gem 'rubocop-minitest'
  gem 'rubocop-performance'
  gem 'rubocop-rails'
  gem 'rubocop-rake'
end

gem 'haml-rails', '~> 2.0'
gem 'jquery-rails'
gem 'jruby-jars', File.read('.ruby-version').chomp.sub(/^jruby-/, '')
gem 'logger'
gem 'sass'
# gem 'json-jruby', '>= 1.6.6', :require => 'json', :platform => :jruby
gem 'actionpack-page_caching'
gem 'activerecord-jdbc-adapter', '>= 61.3', '~> 70', platform: :jruby
gem 'activerecord-jdbcmysql-adapter', '>= 61.3', '~> 70', platform: :jruby
gem 'activerecord-jdbcpostgresql-adapter', '>= 61.3', '~> 70', platform: :jruby
gem 'activerecord-jdbcsqlite3-adapter', '>= 61.3', '~> 70', platform: :jruby
gem 'activerecord-session_store'
gem 'airbrake'
gem 'airbrake-ruby', '6.2.0'
gem 'capistrano', '~> 2.15.0'
gem 'devise', '~> 4.8'
gem 'dotenv-rails'
gem 'dynamic_form'
gem 'handle_invalid_percent_encoding_requests'
gem 'httpclient'
gem 'i18n'
gem 'jdbc-mysql', require: false
gem 'jdbc-sqlite3', '>= 3.7.2', platform: :jruby
gem 'json', '>=1.6.6'
gem 'lograge'
gem 'nokogiri'
gem 'omniauth-google-oauth2'
gem 'omniauth-rails_csrf_protection'
gem 'pry', '~> 0.15.0'
gem 'pry-rails', '~> 0.3.9'
gem 'puma', '< 7'
gem 'rack', '>= 1.1.0'
gem 'rack-attack', '~> 6.0'
gem 'rapporteur'
gem 'rexml'
gem 'rubyzip', '~> 2'
gem 'silencer'
gem 'sucker_punch', '~> 3.0'
gem 'thwait'
gem 'tzinfo-data', platform: :jruby
gem 'webrick'
gem 'with_advisory_lock'
gem 'zip-zip'
