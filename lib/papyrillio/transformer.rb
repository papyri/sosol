module Papyrillio

  class Transformer < Papyrillio::PapyrillioBase
    attr_accessor :base_index
    
    def initialize start_index = 1
      super()
      @base_index = start_index.to_i # number of first article
    end

    def convert publishees
      log '--> Transformer'
      if publishees.length

        index = 1.0
        total = publishees.length
        publishees.each{|publishee|
          publishee.html = publishee.publication.print({'sammelbuchIndex' => (@base_index + index -1).to_i.to_s})
          log_progress (index / total * 100).round()
          index += 1          
        }

        log_progress 100
        puts ''
      else
        log 'nothing to do'
      end
      publishees
    end
  end

end