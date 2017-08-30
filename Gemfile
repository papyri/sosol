# Edit this Gemfile to bundle your application's dependencies.
# This preamble is the current preamble for Rails 3 apps; edit as needed.
source 'http://rubygems.org'

gem 'rails', '~> 3.2.22'

# Needed for the new asset pipeline
group :assets do
  gem 'sass-rails', '~> 3.2.3'
  gem 'coffee-rails', '~> 3.2.1'
  gem 'uglifier', '>= 1.0.3'
end

group :test do
  gem 'rake'
  gem 'mocha', "= 1.1.0" # later versions of mocha cause stubbing to fail under jruby-1.7.26 in 2.0 mode
  gem 'timecop'
end

gem 'jquery-rails'
gem 'jruby-jars', File.read('.ruby-version').chomp.sub(/^jruby-/,'')
gem 'haml', '= 4.0.6'

gem 'sass'
# gem 'json-jruby', '>= 1.6.6', :require => 'json', :platform => :jruby
gem 'json', '>=1.6.6'
gem 'jdbc-sqlite3', '>= 3.6.3.054', :platform => :jruby
gem 'activerecord-jdbc-adapter', '>= 0.9.2', :platform => :jruby
gem 'activerecord-jdbcsqlite3-adapter', '>= 0.9.2', :platform => :jruby
gem 'activerecord-jdbcmysql-adapter', '>= 0.9.2', :platform => :jruby
gem 'rack', '>= 1.1.0'
gem 'shoulda-matchers', '>= 2.0.0'
gem 'shoulda', '>= 2.11.3'
gem "factory_girl_rails", ">= 1.2"
gem 'factory_girl', '>= 2.6.4'
gem 'airbrake', '4.3.0'
gem 'grit', '~> 2.4.0'
gem 'rubyzip', '~> 1.0.0', :require => 'zip/zip'
gem 'zip-zip'
gem 'prototype-rails'
gem 'dynamic_form'
gem 'capistrano', '~> 2.15.0'
gem 'warbler'
gem 'puma'
gem 'database_cleaner'
gem 'sucker_punch', '~> 1.0'
gem 'uuid'
gem 'xmlcanonicalizer'
gem 'nokogiri', '>= 1.6.6.2'
gem 'mocha', "= 1.1.0" # later versions of mocha cause stubbing to fail under jruby-1.7.26 in 2.0 mode
gem 'ruby-debug'
gem 'mediawiki_api', :git => 'https://github.com/sosol/mediawiki-ruby-api'
gem 'hypothesis-client', :git => 'https://github.com/PerseusDL/hypothesis-client'
gem 'jruby-openssl', '>=0.9.8', :platform => :jruby
gem 'ruby-saml', :platform => :jruby, :git => 'https://github.com/onelogin/ruby-saml', :ref => '3b81caa'
gem 'with_advisory_lock'

gem 'test_after_commit', "= 0.4.1", :group => :test
gem 'faraday_middleware'
gem 'doorkeeper', "=2.2.2"
gem 'swagger-blocks'
gem 'bagit'
gem 'validatable'
gem 'rda-collections-client', :git => 'https://github.com/RDACollectionsWG/ruby-collections-client', :tag => 'v1.0.1'


