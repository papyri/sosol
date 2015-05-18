module HypothesisClient
  module Helpers
    module Uris
      class SmithText

        HOPPER_URI = Regexp.new('Perseus:text:1999.04.0104')
        TEXT_CTS = "urn:cts:pdlrefwk:viaf88890045.003.perseus-eng1"
        PERSON_URI = "http://data.perseus.org/people/smith:"
        BIO_ENTRY_MATCH = Regexp.new('entry=(\w+)-bio(-\d+)?')

        attr_accessor :can_match, :error, :uris, :cts, :text

        def initialize(a_content)
          @content = a_content
          @can_match = false
          @text = nil
          @cts = []
          @uris = []
          if (HOPPER_URI.match(@content))
            @can_match = true
            parts =  BIO_ENTRY_MATCH.match(@content)
            if (parts) 

              # normalize the person - should be lower case
              name = parts[1].downcase

              # smiths has a 2 level cite scheme with the first level being
              # the alphabetical grouping
              entry = name.slice(0,1).upcase!

              @uris = ["#{PERSON_URI}#{name}#{parts[2]}#this"]
              @cts = [ "#{TEXT_CTS}:#{entry}.#{name}#{parts[2].sub!(/-/,'_')}" ]
            else
              @error = "Unable to parse smith bio entry" 
            end
          end
        end
      end
    end 
  end
end
