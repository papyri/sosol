#!/usr/bin/env ruby
## lib/tasks/git.rake
# 
# Sample usage:
# 
#   jruby -S rake hgv:print_sammelbuch
#
# Command line tools for html to pdf conversion:
#
#   xhtml2pdf --encoding utf-8 -s in.html out.pdf
#   /System/Library/Printers/Libraries/convert -f in.html -o out_macPrinterConvert.pdf
#

require 'jruby_xml'
require 'papyrillio/papyrillio'

namespace :hgv do

  desc 'Gather print information for Sammelbuch'

  task :print_sammelbuch => :environment do

    attribute = :plannedForFuturePrintRelease
    pattern = /.*[sS][bB][; ]28.*/

    c = Papyrillio::CollectorXpathPattern.new attribute, pattern
    #c = Papyrillio::FakeCollector.new
    t = Papyrillio::Transformer.new 16321
    p = Papyrillio::OpenOfficePrinter.new

    publisher = Papyrillio::Publisher.new :collector => c, :transformer => t, :printer => p
    publisher.release

  end
end
