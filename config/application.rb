# Specifies gem version of Rails to use when vendor/rails is not present
# RAILS_GEM_VERSION = '2.3.4' unless defined? RAILS_GEM_VERSION
require File.expand_path( '../boot', __FILE__ )
require 'rails/all'
Bundler.require( :default, Rails.env ) if defined?( Bundler )

# This should probably all be moved into an environment in config/environments/
# RPX_BASE_URL = 'https://rpxnow.com'
# SITE_NAME = 'Perseids'
# SITE_FULL_NAME = 'Perseids'
# SITE_TAG_LINE = 'powered by Son of Suda Online'
# SITE_WIKI_LINK = '<a href="http://sites.tufts.edu/perseids">Perseids Blog and Documentation</a>.'
# SITE_LAYOUT = 'perseus'
# SITE_IDENTIFIERS = 'CitationCTSIdentifier,EpiCTSIdentifier,EpiTransCTSIdentifier,OACIdentifier,CTSInventoryIdentifier,CommentaryCiteIdentifier,TreebankCiteIdentifier,AlignmentCiteIdentifier,OaCiteIdentifier,OajCiteIdentifier'
# SITE_USER_NAMESPACE = "http://data.perseus.org/users/"
# SITE_OAC_NAMESPACE = "http://data.perseus.org/annotations/sosoloacprototype"
# SITE_CITE_COLLECTION_NAMESPACE = "http://data.perseus.org/collections"
# SITE_EMAIL_FROM = 'admin@perseids.org'
# REPOSITORY_ROOT = "/usr/local/gitrepos"
# CANONICAL_REPOSITORY = File.join( REPOSITORY_ROOT, 'canonical.git' )
# GITWEB_BASE_URL = "http://127.0.0.1:1234/?p="

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

    # Configure custom application parameters
    config.site_layout = 'pn'
    config.site_identifiers = 'DDBIdentifier,HGVMetaIdentifier,HGVTransIdentifier,BiblioIdentifier,APISIdentifier'
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
    config.site_email_from = 'admin@localhost'
    config.site_tag_line = 'powered by Son of Suda Online'

    config.site_oac_namespace = 'http://data.perseus.org/annotations/sosoloacprototype'
    config.site_cite_collection_namespace = 'http://data.perseus.org/collections'

    config.current_terms_version = 0

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
