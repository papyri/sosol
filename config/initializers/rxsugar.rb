require 'jruby_helper'

ActiveRecord::Base.send(:include, RXSugar::JRubyHelper)