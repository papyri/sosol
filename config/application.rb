# Be sure to restart your server when you modify this file

# Uncomment below to force Rails into production mode when
# you don't control web/app server and can't set it the proper way
ENV['RAILS_ENV'] ||= 'development'

# Specifies gem version of Rails to use when vendor/rails is not present
# RAILS_GEM_VERSION = '2.3.4' unless defined? RAILS_GEM_VERSION
require File.expand_path( '../boot', __FILE__ )
require 'rails/all'
require 'rexml/document'
Bundler.require( :default, Rails.env ) if defined?( Bundler )

module Sosol
  class Application < Rails::Application
    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.
    # See Rails::Configuration for more options.
    
    # Custom directories with classes and modules you want to be autoloadable.
    # config.autoload_paths += %W(#{config.root}/extras)
    config.autoload_paths += Dir["#{config.root}/lib/**/"]
    
    # The default locale is :en and all translations from config/locales/*.rb,yml are auto loaded.
    # config.i18n.load_path += Dir[Rails.root.join('my', 'locales', '*.{rb,yml}').to_s]
    # config.i18n.default_locale = :de
    I18n.config.enforce_available_locales = true
    
    # JavaScript files you want as :defaults (application.js is always included).
    config.action_view.javascript_expansions[:defaults] = %w(prototype effects dragdrop controls)

    # Configure the default encoding used in templates for Ruby 1.9.
    config.encoding = "utf-8"

    # Configure sensitive parameters which will be filtered from the log file.
    config.filter_parameters += [:password]
    
    # Skip frameworks you're not going to use. To use Rails without a database
    # you must remove the Active Record framework.
    # config.frameworks -= [ :active_record, :active_resource, :action_mailer ]
    
    # Specify gems that this application depends on. 
    # They can then be installed with "rake gems:install" on new installations.
    # config.gem "bj"
    # config.gem "hpricot", :version => '0.6', :source => "http://code.whytheluckystiff.net"
    # config.gem "aws-s3", :lib => "aws/s3"
    # config.gem "ruby-xslt", :lib => "xml/xslt"
    # config.gem "libxml-ruby", :lib => "xml/libxml"
    config.gem "haml", :version => "~> 3.0.25"
    # config.gem "capistrano", :version => ">= 2.5.5", :lib => false
    
    if ( RUBY_PLATFORM == 'java' )
      config.gem "json-jruby", :version => ">= 1.4.3.1", :lib => "json"
    else
      config.gem "json"
    end
    if ( RUBY_PLATFORM == 'java' )
      config.gem "jruby-openssl", :lib => false
      config.gem "activerecord-jdbc-adapter", :version => ">= 0.9.2", :lib => false
      config.gem "activerecord-jdbcsqlite3-adapter", :version => ">= 0.9.2", :lib => false
      config.gem "activerecord-jdbcmysql-adapter", :version => ">= 0.9.2", :lib => false
      config.gem "rack", :version => ">= 1.1.0", :lib => false
    end
    config.gem "shoulda", :version => ">= 2.11.3"
    config.gem "factory_girl", :version => "~> 1.2.2"
    config.gem 'airbrake', :version => ">= 3.0.5"
    config.gem 'grit',
      :lib     => 'grit',
      :source  => 'http://gemcutter.org',
      :version => '>= 2.0'
    config.gem 'rubyzip', :lib => 'zip/zip', :version => ">= 0.9.5"
    
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
    config.session_store( :cookie_store, {
      :key => '_protosite_session',
      :secret      => '9b3d1476080d8895ca5664177c4ce14b9cbe2acd74966996708adde079462003306356b8f59ea169f6aca77bee343c1296d0a3a5b3c980ed9819b7fe944d56e6',
      :httponly => false
    })
    
    # Rails logging. 
    # if defined?( Rails.logger )
    #   Rails.logger = Logger.new( STDOUT )
    # end
    
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
    config.rpx_base_url = 'https://rpxnow.com'
    SITE_NAME = 'Perseids'
    config.site_name = 'Perseids'
    SITE_FULL_NAME = 'Perseids'
    config.site_full_name = 'Perseids'
    SITE_TAG_LINE = 'powered by Son of Suda Online'
    config.site_tag_line = 'powered by Son of Suda Online'
    SITE_WIKI_LINK = '<a href="http://sites.tufts.edu/perseids">Perseids Blog and Documentation</a>.'
    config.site_wiki_link = '<a href="http://sites.tufts.edu/perseids">Perseids Blog and Documentation</a>.'
    SITE_LAYOUT = 'perseus'
    config.site_layout = 'perseus'
    SITE_IDENTIFIERS = 'TeiCTSIdentifier,TeiTransCTSIdentifier,CitationCTSIdentifier,EpiCTSIdentifier,EpiTransCTSIdentifier,OACIdentifier,CTSInventoryIdentifier,CommentaryCiteIdentifier,TreebankCiteIdentifier'
    config.site_identifiers = 'TeiCTSIdentifier,TeiTransCTSIdentifier,CitationCTSIdentifier,EpiCTSIdentifier,EpiTransCTSIdentifier,OACIdentifier,CTSInventoryIdentifier,CommentaryCiteIdentifier,TreebankCiteIdentifier'
    SITE_CTS_INVENTORIES = 'perseus|Tei,epifacs|Epi,perseids|Tei|'
    config.site_cts_inventories = 'perseus|Tei,epifacs|Epi,perseids|Tei|'
    SITE_CATALOG_SEARCH = "View In Catalog"
    config.site_catalog_search = "View In Catalog"
    SITE_USER_NAMESPACE = "data.perseus.org"
    config.site_user_namespace = "data.perseus.org"
    SITE_OAC_NAMESPACE = "http://data.perseus.org/annotations/sosoloacprototype"
    config.site_oac_namespace = "http://data.perseus.org/annotations/sosoloacprototype"
    SITE_CITE_COLLECTION_NAMESPACE = "http://data.perseus.org/collections"
    config.site_cite_collection_namespace = "http://data.perseus.org/collections"
    EXTERNAL_CTS_REPOS = 'perseids|http://localhost:8080/exist/rest/db/xq/CTS.xq?inv=perseids|http://perseids.org/citations,Athenaeus Sources|http://sosol.perseus.tufts.edu/exist/rest/db/xq/CTS.xq?inv=annotsrc|http://data.perseus.org/citations'
    config.external_cts_repos = 'perseids|http://localhost:8080/exist/rest/db/xq/CTS.xq?inv=perseids|http://perseids.org/citations,Athenaeus Sources|http://sosol.perseus.tufts.edu/exist/rest/db/xq/CTS.xq?inv=annotsrc|http://data.perseus.org/citations'
    ENVIRONMENT_BACKGROUPD = 'white'
    config.environment_backgroupd = 'white'
    SITE_EMAIL_FROM = 'admin@perseids.org'
    config.site_email_from = 'admin@perseids.org'
    REPOSITORY_ROOT = "/usr/local/gitrepos"
    config.repository_root = "/usr/local/gitrepos"
    CANONICAL_REPOSITORY = File.join( REPOSITORY_ROOT, 'canonical.git' )
    config.canonical_repository = File.join( config.repository_root, 'canonical.git' )
    GITWEB_BASE_URL = "http://127.0.0.1:1234/?p="
    config.gitweb_base_url = "http://127.0.0.1:1234/?p="
  end
end
