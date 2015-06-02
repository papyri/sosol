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
            # eventually we would want to produce a full CTS URN with selector
            # here but for now leave the uris and cts empty to 
            # flag that the target should be used as is with its selector
          end
        end

      end  #end class
    end
  end
end
