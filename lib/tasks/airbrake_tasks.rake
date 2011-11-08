# Don't load anything when running the gems:* tasks.
# Otherwise, airbrake will be considered a framework gem.
# https://thoughtbot.lighthouseapp.com/projects/14221/tickets/629
unless ARGV.any? {|a| a =~ /^gems/} 

  Dir[File.join(RAILS_ROOT, 'vendor', 'gems', 'airbrake-*')].each do |vendored_notifier|
    $: << File.join(vendored_notifier, 'lib')
  end

  require 'airbrake/tasks'

end
