if RUBY_PLATFORM == 'java'
  require 'java'

  JAR_PATH = File.join(::Rails.root.to_s, 'lib', 'java')

  Dir.entries(JAR_PATH).sort.each do |entry|
    require File.join(JAR_PATH, entry) if /.jar$/.match?(entry)
  end

  if RUBY_VERSION.to_f < 2.0
    warning_message = "WARNING: Running in an environment where RUBY_VERSION is < 2.0 (actual value: #{RUBY_VERSION}). This is deprecated and may lead to errors. Set JRUBY_OPTS=\"--2.0\" before invoking."
    Rails.logger.error(warning_message)
    Airbrake[:default].notify(warning_message)
  end
end
