# Be sure to restart your server when you modify this file.

Sosol::Application.config.session_store :active_record_store, key: '_sosol_session'
ActiveSupport::Logger.send :include, ActiveSupport::LoggerSilence
