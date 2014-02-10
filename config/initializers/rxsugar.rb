require 'lib/rxsugar/lib/jruby_helper'

ActiveRecord::Base.send(:include, RXSugar::JRubyHelper)
