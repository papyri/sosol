# Settings specified here will take precedence over those in config/environment.rb

# The production environment is meant for finished, "live" apps.
# Code is not reloaded between requests
config.cache_classes = true

# Use a different logger for distributed setups
# config.logger = SyslogLogger.new

# Full error reports are disabled and caching is turned on
config.action_controller.consider_all_requests_local = false
config.action_controller.perform_caching             = true
config.action_controller.page_cache_directory = "#{RAILS_ROOT}/public/cache/"
config.cache_store = :file_store, "/tmp/sosol/"
config.log_level = :debug
#config.action_controller.page_cache_directory        = "public/cache"
#config.action_controller.page_cache_extension        = ".html.erb"
# config.action_view.cache_template_loading            = true

# Use a different cache store in production
# config.cache_store = :mem_cache_store

# Enable serving of images, stylesheets, and javascripts from an asset server
# config.action_controller.asset_host                  = "http://assets.example.com"

# Disable delivery errors, bad email addresses will be ignored
# config.action_mailer.raise_delivery_errors = false

config.action_mailer.raise_delivery_errors = true
config.action_mailer.delivery_method = :sendmail
config.action_mailer.smtp_settings = 
#{	
#	:address			=>	'localhost',
#	:port					=>	25,
#	:domain				=>	'halsted.vis.uky.edu',
#}


# config/environments/production_secret.rb should set
# RPX_API_KEY and RPX_REALM (site name) for RPX,
# and possibly other unversioned secrets for production
require File.join(File.dirname(__FILE__), 'production_secret')
