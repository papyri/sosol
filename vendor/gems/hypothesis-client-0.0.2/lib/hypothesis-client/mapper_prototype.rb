# a prototype of a mapper module which takes
# a Hypothes.is annotation which adheres to a pre-defined
# set of rules for tagging and contents and represents this
# as an OA Annotation (JSON-LD serialization) using the 
# LAWD and SNAP ontology. See https://github.com/PerseusDL/perseids_docs/issues/212
module HypothesisClient::MapperPrototype

  class JOTH

    # some hardcoded URIs and match strings for the mapping
    CATALOG_URI = 'http://data.perseus.org/catalog/'
    TEXT_URI = 'http://data.perseus.org/texts/'
    OA_CONTEXT = "http://www.w3.org/ns/oa-context-20130208.json" 
    LAWD_CITATION = "http://lawd.info/ontology/Citation"
    LAWD_WRITTENWORK = "http://lawd.info/ontology/WrittenWork"
    LAWD_EMBODIES = "http://lawd.info/ontology/embodies"
    LAWD_CONCEPTUALWORK = "http://lawd.info/ontology/ConceptualWork"
    LAWD_REPRESENTS = "http://lawd.info/ontology/represents"
    LAWD_ATTESTATION = "http://lawd.info/ontology/Attestation"
    LAWD_HASATTESTATION = "http://lawd.info/ontology/hasAttestation"
        

    REL_GRAPH_CONTEXT =  {
      "lawd" => "http://lawd.info/ontology/",
    }

    # TODO This bit of dealing with different annotation types
    # and wiring the up to the appropriate helpers should all be 
    # moved to a configurable manager class
    def is_annotation_type?(a_tag)
        a_tag == 'joth' || a_tag == 'visiblewords'
    end

    def get_annotation_type(a_tag)
      type = nil
      if (a_tag == 'joth')
        type = { 
          :type =>  a_tag,
          :ontology => HypothesisClient::Helpers::Ontology::SNAP.new,
          :uris =>  {
            'attestation' => [ HypothesisClient::Helpers::Uris::Perseus ],
            'citation' => [ HypothesisClient::Helpers::Uris::Perseus ],
            'place' => [ HypothesisClient::Helpers::Uris::Pleiades ],
            'relation' => [ HypothesisClient::Helpers::Uris::Smith, HypothesisClient::Helpers::Uris::Any ],
            'target' => [ HypothesisClient::Helpers::Uris::SmithText ]
          }
        }
      elsif (a_tag == 'visiblewords')
        type = { 
          :type =>  a_tag,
          :ontology => HypothesisClient::Helpers::Ontology::SNAP.new,
          :uris =>  {
            'attestation' => [ HypothesisClient::Helpers::Uris::Perseus ],
            'citation' => [ HypothesisClient::Helpers::Uris::Perseus ],
            'place' => [ HypothesisClient::Helpers::Uris::Pleiades ],
            'relation' => [ HypothesisClient::Helpers::Uris::VisibleWords, HypothesisClient::Helpers::Uris::Any ],
            'person' => [ HypothesisClient::Helpers::Uris::VisibleWords, HypothesisClient::Helpers::Uris::Any ],
            'target' => [ HypothesisClient::Helpers::Uris::Perseids ]
          }
        } 
      end
      return type
    end

    def find_match(a_type,a_tags,a_content)
      # iterate through the tags looking for the matchers
      # for this type and tag
      match_result = nil
      a_tags.each do |t|
        matchers = a_type[:uris][t]
        if (matchers)
          # iterate through the matchers until we get a result
          # or else fall through to the end
          matchers.each do |m| 
            match_result = m.new(a_content)
            if match_result.can_match
              break;
            end 
          end
        end
      end
      match_result
    end


    # Map the data as provided by Hypothes.is to our expected data model
    # @param agent the URI for the hypothes.is software agent
    # @param uri the URI for the new annotation
    # @param data the Hypothes.is data
    # @param format expected output format -- only HypothesisClient::Client::FORMAT_OALD supported
    # @param owner uri for the annotation
    def map(agent,uri,data,format,owner=nil)
      response = {} 
      response[:errors] = []
      model = {}
      # first some general parsing to pick the pieces we want from
      # the hypothes.is data object
      begin
        model[:id] = uri
        model[:agentUri] = agent
        model[:sourceUri] = data[:sourceUri]
        model[:userid] = owner.nil? ? data["user"].sub!(/^acct:/,'') : owner
        # if we have updated at, use that as annotated at, otherwise use created 
        model[:date] = data["updated"] ? data["updated"]: data["created"]
        body_tags = {}
        data["tags"].each do |t|
          # we do some normalization here in case tags merged
          t.split(/\s+/).each do |s|
            # also make sure we have lower case
            s.downcase!
            if is_annotation_type?(s)
              @annotation_type = get_annotation_type(s)
            else 
              body_tags[s] = 1
            end
          end # end split iteration
        end #end data tags iteration
        # we only support a single target for now so last gets kept
        data["target"].each do |t|
          model[:targetUri] = t["source"]
          model[:targetSelector] = {}
          # we only want the textquoteselector for now
          t["selector"].each do |s|
            if ! s.nil? && s["type"] == 'TextQuoteSelector'
              model[:targetSelector] = s
            end #end test on quote selector
          end #end iteration of selectors
        end #end iteration of targets
      rescue => e
        response[:errors] << e.to_s
      end # end begin on parsing data

      if @annotation_type.nil?
        # todo should fail but backwards compatibility for now
        @annotation_type = get_annotation_type('joth')
      end
      target_matcher = find_match(@annotation_type,['target'],data["uri"])
      if (target_matcher.nil?)
        response[:errors] << "Unknown target type #{data["uri"]}"
      elsif (target_matcher.error)
        response[:errors] << target_matcher.error
      end
      body_matcher = find_match(@annotation_type,body_tags.keys,data["text"])
      if (body_matcher.nil?)
        response[:errors] << "Unknown body type #{data["text"]} #{body_tags.keys.inspect}"
      elsif (body_matcher.error)
        response[:errors] << body_matcher.error
      end

      # only continue if we are error free
      if (response[:errors].length == 0)
        model[:ontology] = @annotation_type[:ontology]
        model[:motivation] ="oa:identifying"
        model[:targetPerson] = (target_matcher.uris)[0]
        model[:targetCTS] = (target_matcher.cts)[0]
        model[:bodyUri] = []
        model[:bodyCts] = []
        model[:relationTerms] = []
        model[:bodyUri] = body_matcher.uris
        if (model[:bodyUri].length == 0) 
          response[:errors] << "Unable to parse body uri from #{data["text"]}"
        end
        if body_tags["relation"] 
          model[:isRelation] = true
          body_tags.keys.each do |k|
            mapped = model[:ontology].get_term(k)        
            unless mapped.nil?
              model[:relationTerms] << mapped
            end
          end #end iteration of tags
          unless model[:relationTerms].length > 0
            response[:errors] << "No valid relation tag" 
          end
        elsif body_tags["person"] 
          model[:isPerson] = true 
        elsif body_tags["place"] 
          model[:isPlace] = true
        elsif body_tags["citation"]
          model[:isCitation] = true
          model[:bodyCts] = body_matcher.cts
        elsif body_tags["attestation"] 
          model[:isAttestation] = true
          model[:motivation] ="oa:describing"
          model[:bodyText] = body_matcher.text
          model[:bodyCts] = body_matcher.cts
        else 
          # otherwise we assume it's a plain link
          model[:motivation] ="oa:linking"
        end
      end 

      if (response[:errors].length == 0)
        if (format == HypothesisClient::Client::FORMAT_OALD)
          response[:data] = to_oa(model)
        else
          response[:errors] << "Only OA JSON-LD format supported"
        end
      end
      response
    end

    def to_oa(obj)
      oa = {}
      oa['@context'] = OA_CONTEXT
      # leave oa[@id] and oa[@annotatedBy] to be set from calling code?
      # ideally we would preserve the provenance chain better here
      oa['@id'] = obj[:id] 
      oa['annotatedBy'] = { 
        "@type" => "foaf:Person", 
        "@id" => obj[:userid]
      }
      oa['@type'] = "oa:Annotation"
      oa['dcterms:source'] = obj[:sourceUri]
      oa['dcterms:title'] = make_title(obj)
      oa['annotatedAt'] = obj[:date]
      oa['motivatedBy'] = obj[:motivation]
      oa['serializedBy'] = {}  
      oa['serializedBy']['@id'] = obj[:agentUri]
      oa['serializedBy']['@type'] = "prov:SoftwareAgent"
      oa['hasTarget'] = {
        "@id" => "#{obj[:id]}#target-1",
        "@type" => "oa:SpecificResource", 
        "hasSource" => { '@id' => obj[:targetCTS] },
        "hasSelector" => {
          "@id" => "#{obj[:id]}#target-1-sel-1",
          "@type" => "oa:TextQuoteSelector",
          "exact" => obj[:targetSelector]["exact"],
          "prefix" => obj[:targetSelector]["prefix"],
          "suffix" => obj[:targetSelector]["suffix"]
        }
      }
      ## THIS TECHNICALLY ISN'T VALID OA to EMBED A JSON-LD named graph without
      ## a graph id  ... fix at some point soon 
      if obj[:isRelation]
        graph = []
        obj[:relationTerms].each_with_index do |t,i|
          bond_uri = "#{obj[:id]}#bond-#{i+1}"
          graph << 
              {
                "@id" =>  obj[:targetPerson],
                "snap:has-bond" =>  {
                  "@id" => bond_uri
                 }
              }
          obj[:bodyUri].each do |u|
	    graph << 
              {
                "@id" => bond_uri,
                "@type" => t,
                "snap:bond-with" => {
                  "@id" => u
                }
              }
          end
        end  
        oa['hasBody'] = { 
          "@context" => REL_GRAPH_CONTEXT.merge(obj[:ontology].get_context()),
          "@graph" => graph 
        }
      elsif obj[:isCitation]
         oa['hasBody'] = []
         obj[:bodyCts].each do |u|
           oa['hasBody'] << make_citation_graph(u)
         end
      elsif obj[:isAttestation]
        graph = []
        obj[:bodyCts].each_with_index do |u,i|
          attest_uri = "#{obj[:id]}#attest-#{i+1}"
          graph << 
            {
              "@id" =>  obj[:targetPerson],
              LAWD_HASATTESTATION => attest_uri
            }
          graph << 
            {
              "@id" =>  attest_uri,
              "@type" => [LAWD_ATTESTATION,'cnt:ContentAsText'],
              "http://purl.org/spar/cito/citesAsEvidence" => u['uri'],
              "cnt:chars" => obj[:bodyText]
            }
          graph << make_citation_graph(u)
        end
        oa['hasBody'] = { 
          "@context" => REL_GRAPH_CONTEXT.merge(obj[:ontology].get_context()),
          "@graph" => graph 
        }
      else
         oa['hasBody'] = []
         obj[:bodyUri].each do |u|
           oa['hasBody'] << { "@id" => u }
         end
      end
      oa
    end

    def make_citation_graph(u)
      graph = {
        "@id"  => u['uri'],
        "@type" => u['type'],
        "foaf:homepage" => { 
          "@id"  => u['uri']
        }
      }
     conceptualwork = {  
       '@id' => "#{TEXT_URI}#{u['work']}",
       '@type' => LAWD_CONCEPTUALWORK
     } 
     writtenwork = {
       '@id' => "#{TEXT_URI}#{u['version']}",
       '@type' => LAWD_WRITTENWORK,
       LAWD_EMBODIES => conceptualwork,
       'rdfs:isDefinedBy' => { 
         '@id' => "#{CATALOG_URI}#{u['version']}"
       }
     }
     if u['type'] == LAWD_CITATION && ! u['version'].nil?
       graph[LAWD_REPRESENTS] = writtenwork
     elsif u['type'] == LAWD_WRITTENWORK && ! u['version'].nil?
       graph[LAWD_EMBODIES] = conceptualwork
       graph['rdfs:isDefinedBy'] = { '@id' => "#{CATALOG_URI}#{u['version']}"}
     else
       graph['rdfs:isDefinedBy'] = { '@id' => "#{CATALOG_URI}#{u['work']}"}
     end
     return graph
    end

    # make a descriptive title for the annotation in the form of
    # bodyUri <is linked to|identifies> <text> [as <relationship>] in bodyUri
    def make_title(obj) 
      if obj[:motivation] == 'oa:linking' 
        motivation_text = 'is linked to' 
      elsif obj[:motivation] == 'oa:describing' 
        motivation_text = 'describes' 
      else  
        motivation_text = 'identifies'
      end
      as_text = ""
      if (obj[:relationTerms].length > 0)
        as_text = " as #{obj[:relationTerms].join(", ")}" 
      elsif obj[:isPlace] 
        as_text = " as place"
      elsif obj[:isPerson] 
        as_text = " as person"
      elsif obj[:isCitation] 
        as_text = " as citation"
      elsif obj[:isAttestation] 
        as_text = " with an attestation of #{obj[:bodyText]}"
      end  
      "#{obj[:bodyUri].join(", ")} #{motivation_text} #{obj[:targetSelector]['exact']}#{as_text} in #{obj[:targetCTS]}"
    end

  end #end JOTH class
end #end Mapper Modul
