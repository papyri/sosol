# Be sure to restart your server when you modify this file

# Uncomment below to force Rails into production mode when
# you don't control web/app server and can't set it the proper way
# ENV['RAILS_ENV'] ||= 'production'

# Specifies gem version of Rails to use when vendor/rails is not present
RAILS_GEM_VERSION = '2.2.2' unless defined? RAILS_GEM_VERSION

# Bootstrap the Rails environment, frameworks, and default configuration
require File.join(File.dirname(__FILE__), 'boot')
require 'git_conf'

require 'rexml/document'

Rails::Initializer.run(:process, GitConf.new) do |config|
  # Settings in config/environments/* take precedence over those specified here.
  # Application configuration should go into files in config/initializers
  # -- all .rb files in that directory are automatically loaded.
  # See Rails::Configuration for more options.

  # Skip frameworks you're not going to use. To use Rails without a database
  # you must remove the Active Record framework.
  # config.frameworks -= [ :active_record, :active_resource, :action_mailer ]

  # Specify gems that this application depends on. 
  # They can then be installed with "rake gems:install" on new installations.
  # config.gem "bj"
  # config.gem "hpricot", :version => '0.6', :source => "http://code.whytheluckystiff.net"
  # config.gem "aws-s3", :lib => "aws/s3"
	config.gem "ruby-xslt", :lib => "xml/xslt"
	config.gem "libxml-ruby", :lib => "xml/libxml"
	config.gem "haml"
	
	config.gem 'mojombo-grit',
	  :lib     => 'grit',
	  :source  => 'http://gems.github.com',
	  :version => '>= 0.9.4'

  # Only load the plugins named here, in the order given. By default, all plugins 
  # in vendor/plugins are loaded in alphabetical order.
  # :all can be used as a placeholder for all plugins not explicitly named
  # config.plugins = [ :exception_notification, :ssl_requirement, :all ]

  # Add additional load paths for your own custom dirs
  # config.load_paths += %W( #{RAILS_ROOT}/extras )

  # Force all environments to use the same logger level
  # (by default production uses :info, the others :debug)
  # config.log_level = :debug

  # Make Time.zone default to the specified zone, and make Active Record store time values
  # in the database in UTC, and return them converted to the specified local zone.
  # Run "rake -D time" for a list of tasks for finding time zone names. Comment line to use default local time.
  config.time_zone = 'UTC'

  # Your secret key for verifying cookie session data integrity.
  # If you change this key, all old sessions will become invalid!
  # Make sure the secret is at least 30 characters and all random, 
  # no regular words or you'll be exposed to dictionary attacks.
  config.action_controller.session = {
    :session_key => '_protosite_session',
    :secret      => '9b3d1476080d8895ca5664177c4ce14b9cbe2acd74966996708adde079462003306356b8f59ea169f6aca77bee343c1296d0a3a5b3c980ed9819b7fe944d56e6'
  }

  # Use the database for sessions instead of the cookie-based default,
  # which shouldn't be used to store highly confidential information
  # (create the session table with "rake db:sessions:create")
  # config.action_controller.session_store = :active_record_store

  # Use SQL instead of Active Record's schema dumper when creating the test database.
  # This is necessary if your schema can't be completely dumped by the schema dumper,
  # like if you have constraints or database-specific column types
  # config.active_record.schema_format = :sql

  # Activate observers that should always be running
  # config.active_record.observers = :cacher, :garbage_collector
  
  # RPX application configuration
  RPX_BASE_URL = 'https://rpxnow.com'
  
  SITE_NAME = 'SoSOL'
  SITE_FULL_NAME = 'Son of Suda On Line'
  
  CANONICAL_REPOSITORY = "#{RAILS_ROOT}/db/canonical.git"
  USER_REPOSITORY_ROOT = "#{RAILS_ROOT}/db/git"
  GITWEB_BASE_URL = "http://127.0.0.1:1234/?p=db/git/"
end
