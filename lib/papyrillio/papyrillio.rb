module Papyrillio

  #
  # Time consumption (working with about 55000 hgv files)
  #
  #   Collector 20 minutes
  #     * read data from hgv file: 7 minutes
  #     * parse xml document: 10 minutes
  #     * search for xpath within xml document: 3 minutes
  #     * evaluate regular expression for xpath (depends on how many xpaths are found)
  #     * retrieve corresponding ddb files (depends on how many xpaths are found)
  # 

  CARRIAGE_RETURN = "\r"
  CLEAR_FROM_CURSOR_TO_END_OF_LINE = "\e[0K"
  RESET_LINE = CARRIAGE_RETURN + CLEAR_FROM_CURSOR_TO_END_OF_LINE

  class PapyrillioBase
    def initialize
      @start = Time.new
    end

    def to_s
      self.class.to_s
    end

    def log message
      now = Time.new
      elapse = @start.class == Time ? ((now - @start) / 60).round().to_s : '???'
      puts now.strftime('%a %b %d %H:%M:%S> ' + message.to_s + ' (' + elapse + ' minutes)') 
    end

    def log_progress value, unit = ' %'
      print RESET_LINE + value.to_s + unit.to_s
    end

  end

  require File.dirname(__FILE__) + '/publisher.rb'
  require File.dirname(__FILE__) + '/collector.rb'
  require File.dirname(__FILE__) + '/organiser.rb'
  require File.dirname(__FILE__) + '/transformer.rb'
  require File.dirname(__FILE__) + '/aggregator.rb'
  require File.dirname(__FILE__) + '/decorator.rb'
  require File.dirname(__FILE__) + '/printer.rb'

end