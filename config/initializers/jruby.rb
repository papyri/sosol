if(RUBY_PLATFORM == 'java')
  require 'java'
  
  JAR_PATH = File.join(RAILS_ROOT, 'lib', 'java')
  
  Dir.entries(JAR_PATH).sort.each do |entry|
    if entry =~ /.jar$/
      require File.join(JAR_PATH, entry)
    end
  end
end