Sosol::Application.configure do
  # Settings specified here will take precedence over those in config/application.rb

  # In the development environment your application's code is reloaded on
  # every request.  This slows down response time but is perfect for development
  # since you don't have to restart the webserver when you make code changes.
  config.cache_classes = false

  config.eager_load = false

  # Show full error reports and disable caching
  config.consider_all_requests_local       = true
  # config.action_view.debug_rjs             = true
  config.action_controller.perform_caching = false

  # Don't care if the mailer can't send
  config.action_mailer.raise_delivery_errors = false

  # Print deprecation notices to the Rails logger
  config.active_support.deprecation = :log

  # Only use best-standards-support built into browsers
  config.action_dispatch.best_standards_support = :builtin

  # config/environments/development_secret.rb should set
  # RPX_API_KEY and RPX_REALM (site name) for RPX,
  # and possibly other unversioned secrets for development
  begin
    require File.join(File.dirname(__FILE__), 'development_secret')
  rescue LoadError
    warn('WARNING: config/environments/development_secret.rb missing, no secrets loaded!')
  end
  # configure email parameters
  config.site_email_from = 'admin@localhost'
  config.action_mailer.default_url_options = { host: 'localhost' }

  # Don't compress assets in development mode
  config.assets.compress = false
  # Expands the lines which load the assets
  config.assets.debug = true
end
