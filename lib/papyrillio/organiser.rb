module Papyrillio
  class Organiser < Papyrillio::PapyrillioBase
    def sort publishees
      log '--> Organiser'

      # retrieve print index from print id (sb;28;2134) or from publication title (SoSOL 2010 1234)
      publishees.each{|publishee|
        if publishee.hgv_meta_identifier[:plannedForFuturePrintRelease][/.*\w+[; ]\d+[; ](\d+).*/, 1]
          publishee.print_index = $1.to_i
        elsif publishee.publication.title[/.*\w+ \d+ (\d+).*/, 1]
          publishee.print_index = $1.to_i
        else
          publishee.print_index = 0
        end
        log publishee.label + ' has print index #' + publishee.print_index.to_s
      }

      # sort all the 0 values to the end, the rest is sorted accordingly to the print index
      publishees = publishees.sort{|x, y| x.print_index == 0 ? 1 : ( y.print_index == 0 ? -1 : x.print_index <=> y.print_index) }
    end
  end
end