#!/System/Library/Frameworks/Ruby.framework/Versions/1.8/usr/bin/ruby
# frozen_string_literal: true

require "#{File.dirname(__FILE__)}/../config/environment" unless defined?(RAILS_ROOT)

# If you're using RubyGems and mod_ruby, this require should be changed to an absolute path one, like:
# "/usr/local/lib/ruby/gems/1.8/gems/rails-0.8.0/lib/dispatcher" -- otherwise performance is severely impaired
require 'dispatcher'

if defined?(Apache::RubyRun)
  ADDITIONAL_LOAD_PATHS.reverse.each do |dir|
    $LOAD_PATH.unshift(dir) if File.directory?(dir)
  end
end
Dispatcher.dispatch
