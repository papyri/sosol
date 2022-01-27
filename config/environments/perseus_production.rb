# frozen_string_literal: true

# Settings specified here will take precedence over those in config/environment.rb

# The production environment is meant for finished, "live" apps.
# Code is not reloaded between requests
config.cache_classes = true

# Use a different logger for distributed setups
config.logger = Logger.new($stdout)

# Full error reports are disabled and caching is turned on
config.action_controller.consider_all_requests_local = false
config.action_controller.perform_caching             = false
config.action_controller.page_cache_directory = "#{RAILS_ROOT}/public/cache/"
config.log_level = :debug
# config.cache_store = :file_store, "#{RAILS_ROOT}/public/cache/"
# config.action_controller.page_cache_directory        = "public/cache"
# config.action_controller.page_cache_extension        = ".html.erb"
# config.action_view.cache_template_loading            = true

# Use a different cache store in production
# config.cache_store = :mem_cache_store

# Enable serving of images, stylesheets, and javascripts from an asset server
# config.action_controller.asset_host                  = "http://assets.example.com"

# Disable delivery errors, bad email addresses will be ignored
# config.action_mailer.raise_delivery_errors = false

config.action_mailer.raise_delivery_errors = true
config.action_mailer.delivery_method = :smtp
config.action_mailer.smtp_settings =
  {
    address: 'localhost',
    port: 25,
    domain: 'tufts.edu'
  }

# config/environments/production_secret.rb should set
# RPX_API_KEY and RPX_REALM (site name) for RPX,
# and possibly other unversioned secrets for production
REPOSITORY_ROOT = '/usr/local/gitrepos'
CANONICAL_REPOSITORY = File.join(REPOSITORY_ROOT, 'canonical.git')
XSUGAR_STANDALONE_URL = 'http://localhost:9999/'
XSUGAR_STANDALONE_USE_PROXY = 'true'
EXIST_STANDALONE_URL = 'http://localhost:8800'
require File.join(File.dirname(__FILE__), 'production_secret')
