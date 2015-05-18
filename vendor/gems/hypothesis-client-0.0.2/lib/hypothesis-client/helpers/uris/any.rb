module HypothesisClient
  module Helpers
    module Uris
      class Any

        attr_accessor :can_match, :error, :uris, :cts, :text

        def initialize(a_content)
          @content = a_content
          @can_match = false 
          @uris = []
          @text = nil
          @cts = nil
          @error = nil
          @content.scan(URI.regexp) do |*matches|
            @can_match = true
            @uris << $&
          end
        end
      end
    end 
  end
end
