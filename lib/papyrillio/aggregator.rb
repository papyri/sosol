module Papyrillio

  class Aggregator < Papyrillio::PapyrillioBase

    def combine publishees
      html = ''
      publishees.each {|publishee|
        html += publishee.html
      }
      html
    end

  end

end