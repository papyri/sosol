Sosol::Application.configure do
  # Settings specified here will take precedence over those in config/application.rb

  # The production environment is meant for finished, "live" apps.
  # Code is not reloaded between requests
  config.cache_classes = true

  config.eager_load = true

  # Full error reports are disabled and caching is turned off
  config.consider_all_requests_local       = false
  config.action_controller.perform_caching = false
  config.action_controller.page_cache_directory = "#{Rails.root}/public/cache/"
  config.cache_store = :file_store, "/tmp/sosol/"

  # See everything in the log (default is :info)
  config.log_level = :info

  # Use a different logger for distributed setups
  # config.logger = SyslogLogger.new
  # STDOUT used for Tomcat/catalina.out logging
  config.logger = Logger.new(STDOUT)

  # Use a different cache store in production
  # config.cache_store = :mem_cache_store

  # Disable Rails's static file server
  # In production, Apache or nginx will already do this
  # config.serve_static_files = true
  config.public_file_server.enabled = true

  # Specifies the header that your server uses for sending files
  config.action_dispatch.x_sendfile_header = "X-Sendfile" unless config.public_file_server.enabled

  # For nginx:
  # config.action_dispatch.x_sendfile_header = 'X-Accel-Redirect'

  # If you have no front-end server that supports something like X-Sendfile,
  # just comment this out and Rails will serve the files


	# Compress JavaScripts and CSS
	config.assets.compress = true

	# Choose the compressors to use
	# config.assets.js_compressor  = :uglifier
	# config.assets.css_compressor = :yui

	# Don't fallback to assets pipeline if a precompiled asset is missed
	config.assets.compile = true

	# Generate digests for assets URLs.
	config.assets.digest = true

	# Defaults to Rails.root.join("public/assets")
	# config.assets.manifest = YOUR_PATH

	# Precompile additional assets (application.js, application.css, and all non-JS/CSS are already added)
	# config.assets.precompile += %w( search.js )

  # Enable serving of images, stylesheets, and javascripts from an asset server
  # config.action_controller.asset_host = "http://assets.example.com"

  # Disable delivery errors, bad email addresses will be ignored
  # config.action_mailer.raise_delivery_errors = false
  # Production action_mailer settings for papyri.info
  config.action_mailer.raise_delivery_errors = true
  config.action_mailer.delivery_method = :sendmail
  config.action_mailer.perform_deliveries = true

  # Enable threaded mode
  # config.threadsafe!

  # Enable locale fallbacks for I18n (makes lookups for any locale fall back to
  # the I18n.default_locale when a translation can not be found)
  config.i18n.fallbacks = true

  # Send deprecation notices to registered listeners
  config.active_support.deprecation = :notify

  # config/environments/production_secret.rb should set
  # RPX_API_KEY and RPX_REALM (site name) for RPX,
  # and possibly other unversioned secrets for development
  require File.join(File.dirname(__FILE__), 'production_secret')
  # configure email parameters
  config.site_email_from='admin@localhost'
end
