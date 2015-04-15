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
    PERSEUS_URI = Regexp.new("http:\/\/data.perseus.org\/citations\/urn:cts:[^\S\n]+" )
    CTS_PASSAGE_URN = Regexp.new("urn:cts:(.*?):([^\.]+)(?:\.([^\.]+))\.?(.*?)?:(.+)$")
    CTS_URN = Regexp.new("urn:cts:(.*?):([^\.]+)\.(?:([^\.]+)\.)?([^:]+)?$")
    SMITH_HOPPER_URI = Regexp.new('Perseus:text:1999.04.0104')
    SMITH_TEXT_CTS = "urn:cts:pdlrefwk:viaf88890045.003.perseus-eng1"
    SMITH_PERSON_URI = "http://data.perseus.org/people/smith:"
    SMITH_BIO_MATCH = Regexp.new('(\w+)-bio(-\d+)?')
    SMITH_BIO_ENTRY_MATCH = Regexp.new('entry=(\w+)-bio(-\d+)?')
    PLEIADES_URI_MATCH = /(http:\/\/pleiades.stoa.org\/places\/\d+)/
    ONTO_MAP = {
      'adoptedfamilyrelationship' => 'snap:AdoptedFamilyRelationship',
      'ancestor' => 'snap:AncestorOf',
      'aunt' => 'snap:AuntOf',
      'brother' => 'snap:BrotherOf',
      'child' => 'snap:ChildOf',
      'claimedfamilyrelationship' => 'snap:ClaimedFamilyRelationship',
      'cousin' => 'snap:CousinOf',
      'daughter' => 'snap:DaugherOf',
      'descendent' => 'snap:DescendentOf',
      'father' => 'snap:FatherOf',
      'fosterfamilyrelationship' => 'snap:FosterFamilyRelationship',
      'grandchild' => 'snap:GrandchildOf',
      'granddaughter' => 'snap:GranddaughterOf',
      'grandfather' => 'snap:GranfatherOf',
      'grandmother' => 'snap:GrandmotherOf',
      'grandparent' => 'snap:GrandparentOf',
      'grandson' => 'snap:GrandsonOf',
      'greatgrandfather' => 'snap:GreatGrandfatherOf',
      'greatgrandmother' => 'snap:GreatGrandmotherOf',
      'greatgrandparent' => 'snap:GreatGrandparentOf',
      'household' => 'snap:HouseHoldOf',
      'inlawfamilyrelationship' => 'snap:InLawFamilyRelationship',
      'intimaterelationship' => 'snap:IntimateRelationship',
      'maternalfamilyrelationship' => 'snap:MaternalFamilyRelationship',
      'mother' => 'snap:MotherOf',
      'nephew' => 'snap:NephewOf',
      'niece' => 'snap:NieceOf',
      'parent' => 'snap:ParentOf',
      'paternalfamilyrelationship' => 'snap:PaternalFamilyRelationship',
      'sibling' => 'snap:SiblingOf',
      'sister' => 'snap:SisterOf',
      'slave' => 'snap:SlaveOf',
      'son' => 'snap:SonOf',
      'stepfamilyrelationship' => 'snap:StepFamilyRelationship',
      'uncle' => 'snap:UncleOf',
      'companion' => 'perseusrdf:CompanionOf',
      'enemy' => 'perseusrdf:EnemyOf',
      'wife' => 'perseusrdf:WifeOf',
      'husband' => 'perseusrdf:HusbandOf'
    }

    OA_CONTEXT = "http://www.w3.org/ns/oa-context-20130208.json" 
    LAWD_CITATION = "http://lawd.info/ontology/Citation"
    LAWD_WRITTENWORK = "http://lawd.info/ontology/WrittenWork"
    LAWD_EMBODIES = "http://lawd.info/ontology/embodies"
    LAWD_CONCEPTUALWORK = "http://lawd.info/ontology/ConceptualWork"
    LAWD_REPRESENTS = "http://lawd.info/ontology/represents"
    LAWD_ATTESTATION = "http://lawd.info/ontology/Attestation"
    LAWD_HASATTESTATION = "http://lawd.info/ontology/hasAttestation"
        

    REL_GRAPH_CONTEXT =  {
      "snap" => "http://onto.snapdrgn.net/snap#",
      "lawd" => "http://lawd.info/ontology/",
      "perseusrdf" => "http://data.perseus.org/rdfvocab/addons/"
    }

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
            body_tags[s] = 1
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

      # and here is where we hack for the Journey of the Hero data model
      if SMITH_HOPPER_URI.match(data["uri"])
        parts = SMITH_BIO_ENTRY_MATCH.match(data["uri"])
        if (parts) 
           # normalize the person - should be lower case
           name = parts[1].downcase
           model[:motivation] ="oa:identifying"
           model[:targetPerson] = "#{SMITH_PERSON_URI}#{name}#{parts[2]}#this" 
           model[:targetCTS] = "#{SMITH_TEXT_CTS}:#{name}#{parts[2].sub!(/-/,'_')}"
           model[:bodyUri] = []
           model[:bodyCts] = []
           model[:relationTerms] = []
           if body_tags["relation"] && SMITH_BIO_MATCH.match(data["text"])
              model[:isRelation] = true
              relation_parts = SMITH_BIO_MATCH.match(data["text"])
              if relation_parts
                model[:bodyUri] << "#{SMITH_PERSON_URI}#{relation_parts[1]}#{relation_parts[2]}#this" 
              else
                data["text"].scan(URI.regexp) do |*matches|
                  model[:bodyUri] << $&
                end
              end
              if (model[:bodyUri].length == 0) 
                response[:errors] << "Unable to parse person from #{data["text"]}"
              end
              body_tags.keys.each do |k|
                mapped = ONTO_MAP[k.downcase]        
                unless mapped.nil?
                  model[:relationTerms] << mapped
                end
              end #end iteration of tags
              unless model[:relationTerms].length > 0
                response[:errors] << "No valid relation tag" 
              end
           elsif body_tags["place"] && PLEIADES_URI_MATCH.match(data["text"])
             model[:isPlace] = true
             # we support just pleiades uris for now
             data["text"].scan(PLEIADES_URI_MATCH).each do |p|
               model[:bodyUri] << "#{p}#this"
             end
             unless model[:bodyUri].length > 0
               response[:errors] << "No valid place uris found"
             end
           elsif body_tags["citation"] && PERSEUS_URI.match(data["text"])
             model[:isCitation] = true
             # we support just perseus uris for now
             data["text"].scan(PERSEUS_URI).each do |u|
              begin
                model[:bodyUri] << u
                model[:bodyCts] << parse_urn(u)
              rescue => e
                response[:errors] << "Invalid Citation URN #{u}"
              end
             end
             unless model[:bodyUri].length > 0
               response[:errors] << "No valid citation uris found"
             end
           elsif body_tags["attestation"] && PERSEUS_URI.match(data["text"])
             model[:isAttestation] = true
             model[:motivation] ="oa:describing"
             # we support just perseus uris for now
             model[:bodyText] = data["text"]
             data["text"].scan(PERSEUS_URI).each do |u|
                model[:bodyUri] << u
                model[:bodyCts] << parse_urn(u)
                # we want the text that isn't part of the uris
                model[:bodyText].sub!(u,'')
             end
             model[:bodyText].sub!(/^\n/,'')
             model[:bodyText].sub!(/\n$/,'')
             model[:bodyText].gsub!(/\n/,' ')
           # otherwise we assume it's a plain link
           else 
             model[:motivation] ="oa:linking"
             data["text"].scan(URI.regexp) do |*matches|
               model[:bodyUri] << $&
             end
             unless model[:bodyUri].length > 0
               response[:errors] << "No valid links found"
             end
           end
        else 
          response[:errors] << "Unable to parse smith bio entry"
        end #end test on person part of uri
      else 
        response[:errors] << "Unable to parse smith text entry"
      end #end test on original target uri 
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
      ## a graph id but I'm having trouble caring...
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
          "@context" => REL_GRAPH_CONTEXT,
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
          "@context" => REL_GRAPH_CONTEXT,
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
         raise "Invalid urn #{urn}"
        end
      end

      unless (ns && tg && wk)
         raise "Invalid urn #{urn}"
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
      elsif obj[:isCitation] 
        as_text = " as citation"
      elsif obj[:isAttestation] 
        as_text = " with an attestation of #{obj[:bodyText]}"
      end  
      "#{obj[:bodyUri].join(", ")} #{motivation_text} #{obj[:targetSelector]['exact']}#{as_text} in #{obj[:targetCTS]}"
    end

  end #end JOTH class
end #end Mapper Modul
