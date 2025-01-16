require File.expand_path('boot', __dir__)

require 'logger'
require 'rails/all'

# If you have a Gemfile, require the gems listed there, including any gems
# you've limited to :test, :development, or :production.
if defined?(Bundler)
  # Require the gems listed in Gemfile, including any gems
  # you've limited to :test, :development, or :production.
  Bundler.require(*Rails.groups)
end

module Sosol
  class Application < Rails::Application
    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.

    # Custom directories with classes and modules you want to be autoloadable.
    # config.autoload_paths += %W(#{config.root}/extras)
    config.eager_load_paths << Rails.root.join('lib')
    config.autoload_paths += Dir["#{config.root}/lib/**/"]

    # Only load the plugins named here, in the order given (default is alphabetical).
    # :all can be used as a placeholder for all plugins not explicitly named.
    # config.plugins = [ :exception_notification, :ssl_requirement, :all ]

    # Activate observers that should always be running.
    # config.active_record.observers = :cacher, :garbage_collector, :forum_observer

    # Set Time.zone default to the specified zone and make Active Record auto-convert to this zone.
    # Run "rake -D time" for a list of tasks for finding time zone names. Default is UTC.
    # Eastern Time = America/New_York
    config.time_zone = 'Eastern Time (US & Canada)'

    # The default locale is :en and all translations from config/locales/*.rb,yml are auto loaded.
    # config.i18n.load_path += Dir[Rails.root.join('my', 'locales', '*.{rb,yml}').to_s]
    # config.i18n.default_locale = :de
    I18n.config.enforce_available_locales = true

    # JavaScript files you want as :defaults (application.js is always included).
    # config.action_view.javascript_expansions[:defaults] = %w(prototype effects dragdrop controls jquery rails)

    # Configure the default encoding used in templates for Ruby 1.9.
    config.encoding = 'utf-8'

    # Configure sensitive parameters which will be filtered from the log file.
    config.filter_parameters += [:password]

    # Configure custom application parameters
    config.site_layout = 'pn'
    config.site_identifiers = 'DDBIdentifier,HGVMetaIdentifier,DCLPMetaIdentifier,DCLPTextIdentifier,HGVTransIdentifier,BiblioIdentifier,APISIdentifier'
    config.repository_root = File.join(::Rails.root.to_s, 'db', 'git')
    config.canonical_repository = File.join(config.repository_root, 'canonical.git')
    config.rpx_base_url = 'https://rpxnow.com'
    config.site_name = 'SoSOL'
    config.site_full_name = 'Son of Suda On Line'
    config.site_wiki_link = 'the <a href="http://idp.atlantides.org/trac/idp/wiki">Integrating Digital Papyrology wiki</a>'
    config.dev_init_files = []
    config.site_catalog_search = 'View in PN'
    config.gitweb_base_url = 'http://127.0.0.1:1234/?p='
    config.site_user_namespace = 'papyri.info'

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

    config.assets.enabled = true
    config.assets.version = '1.0'
    config.assets.precompile += ['*.css', '*.css.scss', '*.css.sass', '*.sass.erb', '*.scss.erb']
    config.assets.precompile += %w[
      apis-mapping.js
      apis.js
      biblio.js
      clipboard.js
      commentary.js
      confirm.js
      dashboard.js
      dclp.js
      docos.js
      edit_mask.js
      formX.js
      helper.js
      leiden.js
      menu-for-applications.js
      meta.js
      overlib/overlib.js
      translation_helper.js
      translation_leiden.js
    ]
  end
end
