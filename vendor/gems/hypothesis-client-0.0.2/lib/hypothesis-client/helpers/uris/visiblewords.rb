module HypothesisClient
  module Helpers
    module Uris
      class VisibleWords

        PERSON_URI = "http://data.perseus.org/people/visiblewords:"
        BIO_MATCH = Regexp.new('(visiblewords:(\w+)(_\d+))')

        attr_accessor :can_match, :error, :uris, :cts, :text
        def initialize(a_content)
          @content = a_content
          @can_match = false
          @text = "#{@content}"
          @cts = nil
          @uris = []
          @content.scan(BIO_MATCH).each do |u|
            # normalize the person - should be lower case
            name = u[1].downcase
            @can_match = true
            @uris << "#{PERSON_URI}#{name}#{u[2]}#this" 
            # keep any text that isn't part of the uris
            @text.sub!(u[0],'')
            # make sure if a full person uri was already supplied we strip the whole thing out
            @text.sub!(PERSON_URI,'')
            @text.sub!(/^\n/,'')
            @text.sub!(/\n$/,'')
            @text.sub!(/\n/,' ')
          end
        end
      end
    end
  end 
end
