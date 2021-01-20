ENV["RAILS_ENV"] = "test"
require File.expand_path(File.dirname(__FILE__) + "/../config/environment")
require 'rails/test_help'
require 'factory_girl_rails'
require 'factory_girl'
require 'shoulda'
require 'shoulda/matchers'
require 'active_support'
require 'active_support/test_case'
require 'database_cleaner'
require 'sucker_punch/testing/inline'
require 'test/unit'
require 'test/unit/active_support'

class ActiveSupport::TestCase
  # Transactional fixtures accelerate your tests by wrapping each test method
  # in a transaction that's rolled back on completion.  This ensures that the
  # test database remains unchanged so your fixtures don't have to be reloaded
  # between every test method.  Fewer database queries means faster tests.
  #
  # Read Mike Clark's excellent walkthrough at
  #   http://clarkware.com/cgi/blosxom/2005/10/24#Rails10FastTesting
  #
  # Every Active Record database supports transactions except MyISAM tables
  # in MySQL.  Turn off transactional fixtures in this case; however, if you
  # don't care one way or the other, switching from MyISAM to InnoDB tables
  # is recommended.
  #
  # The only drawback to using transactional fixtures is when you actually
  # need to test transactions.  Since your test is bracketed by a transaction,
  # any transactions started in your code will be automatically rolled back.
  # self.use_transactional_fixtures = true

  # Instantiated fixtures are slow, but give you @david where otherwise you
  # would need people(:david).  If you don't want to migrate your existing
  # test cases which use the @david style and don't mind the speed hit (each
  # instantiated fixtures translates to a database query per test method),
  # then set this back to true.
  # self.use_instantiated_fixtures  = false

  # Setup all fixtures in test/fixtures/*.(yml|csv) for all tests in alphabetical order.
  #
  # Note: You'll currently still have to declare fixtures explicitly in integration tests
  # -- they do not yet inherit this setting
  # fixtures :all

  # Add more helper methods to be used by all tests here...
  def assert_path_equal(path_array, path_string)
    assert_equal File.join(@path_prefix, path_array), path_string
  end

  def setup_test_repository
    if (!File.directory?(Sosol::Application.config.canonical_repository)) && File.directory?(Sosol::Application.config.canonical_canonical_repository)
      clone_command = ["git clone --bare",
                    Sosol::Application.config.canonical_canonical_repository,
                    Sosol::Application.config.canonical_repository, '>/dev/null', '2>&1'].join(' ')

      `#{clone_command}`
      return $?.success?
    else
      return true
    end
  end
  
  def setup_database_cleaner
    DatabaseCleaner.strategy = :truncation
    DatabaseCleaner.start
  end

  def teardown_database_cleaner
    DatabaseCleaner.clean
  end

  def setup_flock
    ENV['FLOCK_DIR'] = Dir.mktmpdir
  end

  def teardown_flock
    FileUtils.remove_entry_secure ENV['FLOCK_DIR']
  end

  setup :setup_test_repository
  setup :setup_database_cleaner
  setup :setup_flock
  teardown :teardown_database_cleaner
  teardown :teardown_flock
end
