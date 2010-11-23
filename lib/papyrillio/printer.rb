module Papyrillio

  #
  # Printer
  #
  # simply writes content to disk
  #

  class Printer < Papyrillio::PapyrillioBase

    def initialize filepath = nil
      super()
      @filepath = filepath || @start.strftime('PapyrillioPrinter-%Y-%m-%d.html') 
    end

    def save html
      f = File.new @filepath, 'w'
      f.write html
      f.close
    end

  end

end