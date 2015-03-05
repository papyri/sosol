# Settings specified here will take precedence over those in config/environment.rb


config.log_level = :info

# The test environment is used exclusively to run your application's
# test suite.  You never need to work with it otherwise.  Remember that
# your test database is "scratch space" for the test suite and is wiped
# and recreated between test runs.  Don't rely on the data there!
config.cache_classes = true

# Log error messages when you accidentally call methods on nil.
config.whiny_nils = true

# Show full error reports and disable caching
config.action_controller.consider_all_requests_local = true
config.action_controller.perform_caching             = false

# Disable request forgery protection in test environment
config.action_controller.allow_forgery_protection    = false

# Tell Action Mailer not to deliver emails to the real world.
# The :test delivery method accumulates sent emails in the
# ActionMailer::Base.deliveries array.
config.action_mailer.delivery_method = :test

# config/environments/production_secret.rb should set
# RPX_API_KEY and RPX_REALM (site name) for RPX,
# and possibly other unversioned secrets for test
require File.join(File.dirname(__FILE__), 'test_secret')

REPOSITORY_ROOT = File.join(RAILS_ROOT, 'db', 'test', 'git')
CANONICAL_CANONICAL_REPOSITORY = CANONICAL_REPOSITORY
CANONICAL_REPOSITORY = File.join(REPOSITORY_ROOT, 'canonical.git')
EXIST_STANDALONE_URL="http://localhost:8080"
SITE_IDENTIFIERS = 'TeiCTSIdentifier,TeiTransCTSIdentifier,CitationCTSIdentifier,EpiCTSIdentifier,EpiTransCTSIdentifier,OACIdentifier,CTSInventoryIdentifier,CommentaryCiteIdentifier,TreebankCiteIdentifier,AlignmentCiteIdentifier,OajCiteIdentifier'
SITE_CTS_INVENTORIES = 'testepi|Epi'
