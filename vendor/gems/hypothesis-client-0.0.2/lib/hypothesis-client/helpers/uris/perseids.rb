module HypothesisClient
  module Helpers
    module Uris
      class Perseids

        PERSEIDS_URI = Regexp.new("http:\/\/sosol.perseids.org\/sosol\/publications\/.*?\/epi_cts_identifiers\/.*?\/preview")

        attr_accessor :can_match, :error, :uris, :cts, :text
        def initialize(a_content)
          @content = a_content
          @can_match = false
          @text = @content
          @cts = []
          @uris = []
          @error = nil
 
          @content.scan(PERSEIDS_URI).each do |u|
            @can_match = true
            @uris << u
            # leave the cts the same as the uri for now
            # ideally the perseids url would list it or we will
            # do a callback for it
            @cts << u
          end
        end

      end  #end class
    end
  end
end
