module HypothesisClient
  module Helpers
    module Uris
      class Hypothesis

        URI_MATCH = /^(https:\/\/hypothes\.is\/a\/[^\/]+)$/

        attr_accessor :can_match, :error, :uris, :cts, :text

        def initialize(a_content)
          @content = a_content
          @can_match = false
          @uris = []
          @text = nil
          @cts = nil
          @error = nil
          @content.scan(URI_MATCH).each do |p|
            @can_match = true
            u = p[0]
            @uris << u
          end
        end
      end
    end 
  end
end
