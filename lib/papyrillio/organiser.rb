module Papyrillio
  class Organiser < Papyrillio::PapyrillioBase
    def sort publishees
      publishees.sort{|x, y| x.print_index <=> y.print_index }
    end
  end
end