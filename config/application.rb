# Specifies gem version of Rails to use when vendor/rails is not present
# RAILS_GEM_VERSION = '2.3.4' unless defined? RAILS_GEM_VERSION
require File.expand_path( '../boot', __FILE__ )
require 'rails/all'
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
    config.action_view.javascript_expansions[:defaults] = %w(prototype effects dragdrop controls rails)

    # Configure the default encoding used in templates for Ruby 1.9.
    config.encoding = "utf-8"

    # Configure sensitive parameters which will be filtered from the log file.
    config.filter_parameters += [:password]

    # Configure custom application parameters
    # see also config/initializers/site.rb which has site specific parameters now
    config.repository_root = File.join(::Rails.root.to_s, 'db', 'git')
    config.canonical_repository = File.join(config.repository_root, 'canonical.git')
    config.rpx_base_url = 'https://rpxnow.com'
    config.dev_init_files = []
    config.gitweb_base_url = 'http://127.0.0.1:1234/?p='
    # if allow_canonical_boards=true, canonical, i.e. non-community boards, will be fully available
    config.allow_canonical_boards = true
    # set submit_canonical_boards=false to prevent new submissions to non-community boards, to allow their phase-out
    config.submit_canonical_boards = true

    # Configure XSugar
    # These can be overridden in config/environments/*_secret.rb
    # Use a standalone XSugar server instead of JRuby+Rails internal transform
    # See: https://github.com/papyri/xsugar/tree/master/src/standalone
    config.xsugar_standalone_enabled = false
    # Use a Rails proxy URL for the standalone XSugar server
    # (useful if XSugar server URL would result in a cross-domain request)
    config.xsugar_standalone_use_proxy = false
    # URL for the standalone XSugar server
    config.xsugar_standalone_url = ''
  end
end

