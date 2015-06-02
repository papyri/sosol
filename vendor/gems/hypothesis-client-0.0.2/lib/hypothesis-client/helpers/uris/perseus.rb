module HypothesisClient
  module Helpers
    module Uris
      class Perseus

        PERSEUS_URI = Regexp.new("http:\/\/data.perseus.org\/citations\/urn:cts:[^\S\n]+" )
        CTS_PASSAGE_URN = Regexp.new("urn:cts:(.*?):([^\.]+)(?:\.([^\.]+))\.?(.*?)?:(.+)$")
        CTS_URN = Regexp.new("urn:cts:(.*?):([^\.]+)\.(?:([^\.]+)\.)?([^:]+)?$")
        LAWD_WRITTENWORK = "http://lawd.info/ontology/WrittenWork"
        LAWD_CITATION = "http://lawd.info/ontology/Citation"
        LAWD_CONCEPTUALWORK = "http://lawd.info/ontology/ConceptualWork"

        attr_accessor :can_match, :error, :uris, :cts, :text
        def initialize(a_content)
          @content = a_content
          @can_match = false
          @text = "#{@content}"
          @cts = []
          @uris = []
          @error = nil
          errors = []
 
          @content.scan(PERSEUS_URI).each do |u|
            begin
              @can_match = true
              @uris << u
              @cts << parse_urn(u)
              # we want any text that isn't part of the uris
              @text.sub!(u,'')
              @text.sub!(/^\n/,'')
              @text.sub!(/\n$/,'')
              @text.sub!(/\n/,' ')
            rescue => e
              errors << e.to_s
            end
          end
          if (errors.length > 0) 
            @error = errors.join("\n")
          end
        end


        def parse_urn(uri)
          urn_passage_parts = CTS_PASSAGE_URN.match(uri)
          if (urn_passage_parts) 
            ns = urn_passage_parts[1]
            tg = urn_passage_parts[2]
            wk = urn_passage_parts[3]
            ver = urn_passage_parts[4]
            psg = urn_passage_parts[5]
          else
            urn_parts = CTS_URN.match(uri)
            if (urn_parts)
              ns = urn_parts[1]
              tg = urn_parts[2]
              wk = urn_parts[3]
	      ver = urn_parts[4]
            else
             raise "Invalid Citation URN #{uri}"
            end
          end

          unless (ns && tg && wk)
             raise "Invalid Citation URN #{uri}"
          end
          if psg == '' || psg.nil?
            if ver == '' || ver.nil?
              # it's conceptual
              type = LAWD_CONCEPTUALWORK
            else
              # if we have a version, it's a written work
              type = LAWD_WRITTENWORK
            end
          else
            # if we have a passage, its a citation
            type = LAWD_CITATION
          end

          { 
            'uri' => uri,   
            "type" => type,
            'textgroup' => "urn:cts:#{ns}:#{tg}",
            'work' => "urn:cts:#{ns}:#{tg}.#{wk}",
            'version' => ver == '' || ver.nil? ? nil : "urn:cts:#{ns}:#{tg}.#{wk}.#{ver}",
            'passage' => type == LAWD_CITATION ? psg : nil
          }
        end

      end  #end class
    end
  end
end
