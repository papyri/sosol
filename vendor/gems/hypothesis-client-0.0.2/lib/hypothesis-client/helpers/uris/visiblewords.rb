module HypothesisClient
  module Helpers
    module Uris
      class VisibleWords

        PERSON_URI = "http://data.perseus.org/people/visiblewords:"
        BIO_MATCH = Regexp.new('^visiblewords:(\w+)(_\d+)$')

        attr_accessor :can_match, :error, :uris, :cts, :text
        def initialize(a_content)
          @content = a_content
          @can_match = false
          @text = nil
          @cts = nil
          @uris = []
          parts = BIO_MATCH.match(@content)
          if parts
            # normalize the person - should be lower case
            name = parts[1].downcase
            @can_match = true
            @uris = ["#{PERSON_URI}#{name}#{parts[2]}#this" ]
          end
        end
      end
    end
  end 
end
