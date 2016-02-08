# Be sure to restart your server when you modify this file.

Sosol::Application.config.session_store :cookie_store, { 
  :key => '_sosol_session',
  :secret => '9b3d1476080d8895ca5664177c4ce14b9cbe2acd74966996708adde079462003306356b8f59ea169f6aca77bee343c1296d0a3a5b3c980ed9819b7fe944d56e6', 
  :httponly => false,
  :domain => 'localhost'
}

# Use the database for sessions instead of the cookie-based default,
# which shouldn't be used to store highly confidential information
# (create the session table with "rails generate session_migration")
# Sosol::Application.config.session_store :active_record_store
