module Papyrillio

  #
  # Aggregator
  #
  # glues all body parts together
  #

  class Aggregator < Papyrillio::PapyrillioBase

    def combine publishees
      head = tail = content = ''

      publishees.each {|publishee|
        if head.empty? && tail.empty?
          head = publishee.html[/.+<office:text>/m]
          tail = publishee.html[/<\/office:text>.+/m]
        end
        content += publishee.html[/.*<office:text>(.+)<\/office:text>.*/m, 1]
      }

      head + content + tail
    end

  end

end