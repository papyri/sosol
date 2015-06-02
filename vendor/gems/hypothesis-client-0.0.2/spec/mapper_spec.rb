require 'spec_helper'
require 'hypothesis-client/client'
require 'hypothesis-client/mapper_prototype'

describe HypothesisClient::MapperPrototype do
  let(:client) { HypothesisClient::Client.new(HypothesisClient::MapperPrototype::JOTH.new) }

  context "basic test" do 
    input = File.read(File.join(File.dirname(__FILE__), 'support', 'test1.json')) 
    let(:mapped) { client.map("test",JSON.parse(input))}

    it 'produced oa' do 
      expect(mapped[:errors]).to match_array([])
      expect(mapped[:data]).to be_truthy
    end

    it 'mapped the source uri' do
      expect(mapped[:data]["dcterms:source"]).to eq(nil)
    end

    it 'mapped the body text' do
      expect(mapped[:data]["hasBody"][0]["@id"]).to eq("http://data.perseus.org/citations/urn:cts:greekLit:tlg0012.tlg001:6.222")
      expect(mapped[:data]["hasBody"][0]["@type"]).to eq(HypothesisClient::MapperPrototype::JOTH::LAWD_CITATION)
      expect(mapped[:data]["hasBody"][0]["foaf:homepage"]["@id"]).to eq("http://data.perseus.org/citations/urn:cts:greekLit:tlg0012.tlg001:6.222")
      expect(mapped[:data]["hasBody"][0]['rdfs:isDefinedBy']["@id"]).to eq("http://data.perseus.org/catalog/urn:cts:greekLit:tlg0012.tlg001")
    end

    it 'mapped the sourceText' do 
      expect(mapped[:data]["hasTarget"]["hasSource"]["@id"]).to eq("#{HypothesisClient::Helpers::Uris::SmithText::TEXT_CTS}:D.diomedes_1")
    end
    
    it 'mapped the motivation' do
      expect(mapped[:data]["motivatedBy"]).to eq("oa:identifying")
    end

    it 'made a title' do
      expect(mapped[:data]["dcterms:title"]).to eq("http://data.perseus.org/citations/urn:cts:greekLit:tlg0012.tlg001:6.222 identifies II. 6.222 as citation in #{HypothesisClient::Helpers::Uris::SmithText::TEXT_CTS}:D.diomedes_1")
    end

  end
  context "bad cites test" do 
    input = File.read(File.join(File.dirname(__FILE__), 'support', 'testbadcite.json')) 
    let(:mapped) { client.map("test",JSON.parse(input))}
    it 'reports error' do
      expect(mapped[:errors]).to match_array(["Invalid Citation URN http://data.perseus.org/citations/urn:cts:foo"])
    end
  end
  context "cites test" do 
    input = File.read(File.join(File.dirname(__FILE__), 'support', 'testcite.json')) 
    let(:mapped) { client.map("test",JSON.parse(input))}
    it 'mapped the body text' do
      expect(mapped[:data]["hasBody"][0]["@id"]).to eq("http://data.perseus.org/citations/urn:cts:greekLit:tlg0012.tlg001.perseus-grc1:6.222")
      expect(mapped[:data]["hasBody"][0]["@type"]).to eq(HypothesisClient::MapperPrototype::JOTH::LAWD_CITATION)
      expect(mapped[:data]["hasBody"][0]["foaf:homepage"]["@id"]).to eq("http://data.perseus.org/citations/urn:cts:greekLit:tlg0012.tlg001.perseus-grc1:6.222")
      expect(mapped[:data]["hasBody"][0][HypothesisClient::MapperPrototype::JOTH::LAWD_REPRESENTS]["@id"]).to eq("http://data.perseus.org/texts/urn:cts:greekLit:tlg0012.tlg001.perseus-grc1")
      expect(mapped[:data]["hasBody"][0][HypothesisClient::MapperPrototype::JOTH::LAWD_REPRESENTS]['rdfs:isDefinedBy']["@id"]).to eq("http://data.perseus.org/catalog/urn:cts:greekLit:tlg0012.tlg001.perseus-grc1")
      expect(mapped[:data]["hasBody"][0][HypothesisClient::MapperPrototype::JOTH::LAWD_REPRESENTS]["@type"]).to eq(HypothesisClient::MapperPrototype::JOTH::LAWD_WRITTENWORK)
      expect(mapped[:data]["hasBody"][0][HypothesisClient::MapperPrototype::JOTH::LAWD_REPRESENTS][HypothesisClient::MapperPrototype::JOTH::LAWD_EMBODIES]['@id']).to eq('http://data.perseus.org/texts/urn:cts:greekLit:tlg0012.tlg001')
      expect(mapped[:data]["hasBody"][0][HypothesisClient::MapperPrototype::JOTH::LAWD_REPRESENTS][HypothesisClient::MapperPrototype::JOTH::LAWD_EMBODIES]['@type']).to eq(HypothesisClient::MapperPrototype::JOTH::LAWD_CONCEPTUALWORK)
    end
  end
  context "relation 1 test" do 
    input = File.read(File.join(File.dirname(__FILE__), 'support', 'relation1.json')) 
    let(:mapped) { client.map("test",JSON.parse(input))}

    it 'produced oa' do 
      expect(mapped[:errors]).to match_array([])
      expect(mapped[:data]).to be_truthy
    end

    it 'graphed the relation' do
      expect(mapped[:data]["hasBody"]).to be_truthy
      expect(mapped[:data]["hasBody"]["@graph"]).to be_truthy
      expect(mapped[:data]["hasBody"]["@graph"][0]).to be_truthy
      expect(mapped[:data]["hasBody"]["@graph"][0]["@id"]).to eq("http://data.perseus.org/people/smith:clytaemnestra-1#this")
      expect(mapped[:data]["hasBody"]["@graph"][1]["@id"]).to eq("test#bond-1-1")
      expect(mapped[:data]["hasBody"]["@graph"][2]["@id"]).to eq("test#bond-2-1")
      expect(mapped[:data]["hasBody"]["@graph"][2]["@id"]).to eq("test#bond-2-1")
      expect(mapped[:data]["hasBody"]["@graph"][2]["snap:bond-with"]["@id"]).to eq("http://data.perseus.org/people/smith:castor-1#this")
    end
  end
  context "relation 2 test" do 
    input = File.read(File.join(File.dirname(__FILE__), 'support', 'relation2.json')) 
    let(:mapped) { client.map("test",JSON.parse(input))}

    it 'produced oa' do 
      expect(mapped[:errors]).to match_array([])
      expect(mapped[:data]).to be_truthy
    end

    it 'graphed the relation' do
      expect(mapped[:data]["hasBody"]).to be_truthy
      expect(mapped[:data]["hasBody"]["@graph"]).to be_truthy
      expect(mapped[:data]["hasBody"]["@graph"][0]).to be_truthy
      expect(mapped[:data]["hasBody"]["@graph"][0]["@id"]).to eq("http://data.perseus.org/people/smith:clytaemnestra-1#this")
      expect(mapped[:data]["hasBody"]["@graph"][1]["@id"]).to eq("test#bond-1-1")
      expect(mapped[:data]["hasBody"]["@graph"][3]["@id"]).to eq("test#bond-3-1")
      expect(mapped[:data]["hasBody"]["@graph"][3]["snap:bond-with"]["@id"]).to eq("http://data.perseus.org/people/smith:castor-1#this")
    end
  end

  context "relation makes up for missing relation tag  test" do 
    input = File.read(File.join(File.dirname(__FILE__), 'support', 'relationnotag1.json')) 
    let(:mapped) { client.map("test",JSON.parse(input))}
    it 'produced oa' do 
      expect(mapped[:errors]).to match_array([])
      expect(mapped[:data]).to be_truthy
    end
  end

  context "missing relation and relation tag test" do 
    input = File.read(File.join(File.dirname(__FILE__), 'support', 'relationnotag2.json')) 
    let(:mapped) { client.map("test",JSON.parse(input))}
    it 'produced error' do 
      expect(mapped[:errors]).to match_array(["Unknown body type http://www.lgpn.ox.ac.uk/id/V1-37350 []"] )
    end
  end

  context "attestation test" do 
    input = File.read(File.join(File.dirname(__FILE__), 'support', 'attest1.json')) 
    let(:mapped) { client.map("test",JSON.parse(input))}

    it 'graphed the attestation' do
      expect(mapped[:data]["motivatedBy"]).to eq("oa:describing")
      expect(mapped[:data]["hasBody"]).to be_truthy
      expect(mapped[:data]["hasBody"]["@graph"]).to be_truthy
      expect(mapped[:data]["hasBody"]["@graph"][0]).to be_truthy
      expect(mapped[:data]["hasBody"]["@graph"][0]["@id"]).to eq("http://data.perseus.org/people/smith:clytaemnestra-1#this")
      expect(mapped[:data]["hasBody"]["@graph"][1]["@id"]).to eq("test#attest-1")
      expect(mapped[:data]["hasBody"]["@graph"][1]["http://purl.org/spar/cito/citesAsEvidence"]).to eq("http://data.perseus.org/citations/urn:cts:greekLit:tlg0525.tlg001.perseus-eng1:10.35.1")
      expect(mapped[:data]["hasBody"]["@graph"][1]["cnt:chars"]).to eq("Abas")
      expect(mapped[:data]["hasBody"]["@graph"][2]["@id"]).to eq("http://data.perseus.org/citations/urn:cts:greekLit:tlg0525.tlg001.perseus-eng1:10.35.1")
      expect(mapped[:data]["hasBody"]["@graph"][2]["@type"]).to eq(HypothesisClient::MapperPrototype::JOTH::LAWD_CITATION)
      expect(mapped[:data]["dcterms:title"]).to eq("http://data.perseus.org/citations/urn:cts:greekLit:tlg0525.tlg001.perseus-eng1:10.35.1 describes *)Abai=os) with an attestation of Abas in #{HypothesisClient::Helpers::Uris::SmithText::TEXT_CTS}:C.clytaemnestra_1")
    end
  end
  context "cts urn test" do
    $mapper = HypothesisClient::Helpers::Uris::Perseus.new("")

    it 'parsed a full urn' do 
       parsed = $mapper.parse_urn("urn:cts:greekLit:tlg0012.tlg001.perseus-grc1:1.1")
       expect(parsed['textgroup']).to eq("urn:cts:greekLit:tlg0012")
       expect(parsed['work']).to eq("urn:cts:greekLit:tlg0012.tlg001")
       expect(parsed['version']).to eq("urn:cts:greekLit:tlg0012.tlg001.perseus-grc1")
       expect(parsed['passage']).to eq("1.1")
    end

    it 'parsed a work with passage urn' do 
       parsed = $mapper.parse_urn("urn:cts:greekLit:tlg0012.tlg001:1.1")
       expect(parsed['type']).to eq(HypothesisClient::MapperPrototype::JOTH::LAWD_CITATION)
       expect(parsed['textgroup']).to eq("urn:cts:greekLit:tlg0012")
       expect(parsed['work']).to eq("urn:cts:greekLit:tlg0012.tlg001")
       expect(parsed['version']).to be_nil
       expect(parsed['passage']).to eq("1.1")
    end

    it 'parsed a full urn without passage' do 
       parsed = $mapper.parse_urn("urn:cts:greekLit:tlg0012.tlg001.perseus-grc1")
       expect(parsed['textgroup']).to eq("urn:cts:greekLit:tlg0012")
       expect(parsed['work']).to eq("urn:cts:greekLit:tlg0012.tlg001")
       expect(parsed['version']).to eq("urn:cts:greekLit:tlg0012.tlg001.perseus-grc1")
       expect(parsed['passage']).to be_nil
       expect(parsed['type']).to eq(HypothesisClient::MapperPrototype::JOTH::LAWD_WRITTENWORK)
    end

    it 'raised an error' do 
       expect { parsed = $mapper.parse_urn("urn:cts:greekLit:tlg0012")}.to raise_error
    end
  end
  context "owner test" do 
    input = File.read(File.join(File.dirname(__FILE__), 'support', 'test1.json')) 
    let(:mapped) { client.map("test",JSON.parse(input),'http://example.org/user/abc')}

    it 'mapped the source uri' do
      expect(mapped[:data]["annotatedBy"]['@id']).to eq('http://example.org/user/abc')
    end
  end
  context "place test" do 
    input = File.read(File.join(File.dirname(__FILE__), 'support', 'place2.json')) 
    let(:mapped) { client.map("test",JSON.parse(input))}

    it 'produced oa' do 
      expect(mapped[:errors]).to match_array([])
      expect(mapped[:data]).to be_truthy
    end
  end
  context "attestation plus case test" do 
    input = File.read(File.join(File.dirname(__FILE__), 'support', 'attest2.json')) 
    let(:mapped) { client.map("test",JSON.parse(input))}

    it 'graphed the attestation' do
      expect(mapped[:data]["motivatedBy"]).to eq("oa:describing")
      expect(mapped[:data]["hasBody"]).to be_truthy
      expect(mapped[:data]["hasBody"]["@graph"]).to be_truthy
      expect(mapped[:data]["hasBody"]["@graph"][0]["@id"]).to eq("http://data.perseus.org/people/smith:clytaemnestra-1#this")
    end
  end

  context "attestation of annotation" do 
    input = File.read(File.join(File.dirname(__FILE__), 'support', 'attest3.json')) 
    let(:mapped) { client.map("test",JSON.parse(input))}

    it 'graphed the attestation' do
      expect(mapped[:data]["motivatedBy"]).to eq("oa:describing")
      expect(mapped[:data]["hasBody"]).to be_truthy
      expect(mapped[:data]["hasBody"]["@graph"]).to be_truthy
      expect(mapped[:data]["hasBody"]["@graph"][0]["@id"]).to eq("https://hypothes.is/a/jtsBhicGR_mEoN1tu8I8hw")
    end
  end

  context "relation and attestation" do 
    input = File.read(File.join(File.dirname(__FILE__), 'support', 'attest4.json')) 
    let(:mapped) { client.map("test",JSON.parse(input))}

    it 'graphed the attestation' do
      expect(mapped[:data]["motivatedBy"]).to eq("oa:identifying")
      expect(mapped[:data]["hasBody"]).to be_truthy
      expect(mapped[:data]["hasBody"]["@graph"]).to be_truthy
      expect(mapped[:data]["hasBody"]["@graph"][0]["@id"]).to eq("test#rel-target")
      expect(mapped[:data]["hasBody"]["@graph"][0]["http://www.w3.org/ns/oa#hasSelector"]).to be_truthy
      expect(mapped[:data]["hasBody"]["@graph"][1]["@id"]).to eq("test#bond-1-1")
      expect(mapped[:data]["hasBody"]["@graph"][1]["@type"]).to eq("snap:FatherOf")
      expect(mapped[:data]["hasBody"]["@graph"][1]["http://lawd.info/ontology/hasAttestation"]).to be_truthy
      expect(mapped[:data]["hasBody"]["@graph"][1]["snap:bond-with"]["@id"]).to eq("http://data.perseus.org/people/visiblewords:johndoe_1#this")
      expect(mapped[:data]["hasBody"]["@graph"][2]["@type"]).to eq("http://lawd.info/ontology/Attestation")
    end
  end

  context "basic visiblewords test" do 
    input = File.read(File.join(File.dirname(__FILE__), 'support', 'person1.json')) 
    let(:mapped) { client.map("test",JSON.parse(input))}

    it 'produced oa' do 
      expect(mapped[:errors]).to match_array([])
      expect(mapped[:data]).to be_truthy
    end

    it 'mapped the source uri' do
      expect(mapped[:data]["dcterms:source"]).to eq(nil)
    end

    it 'mapped the body text' do
      expect(mapped[:data]["hasBody"][0]["@id"]).to eq("http://data.perseus.org/people/visiblewords:johndoe_1#this")
    end

    it 'mapped the motivation' do
      expect(mapped[:data]["motivatedBy"]).to eq("oa:identifying")
    end

    it 'made a title' do
      expect(mapped[:data]["dcterms:title"]).to eq("http://data.perseus.org/people/visiblewords:johndoe_1#this identifies Boeotia as person in http://sosol.perseids.org/sosol/publications/12018/epi_cts_identifiers/15754/preview")
    end
  end
  context "realdata visiblewords test" do 
    input = File.read(File.join(File.dirname(__FILE__), 'support', 'visiblewords.json')) 
    let(:mapped) { client.map("test",JSON.parse(input))}

    it 'produced oa' do 
      expect(mapped[:errors]).to match_array([])
      expect(mapped[:data]).to be_truthy
    end
  end

  context "visiblewords hasattestation" do
    input = File.read(File.join(File.dirname(__FILE__), 'support', 'hasattest1.json')) 
    let(:mapped) { client.map("test",JSON.parse(input))}
    it 'graphed the attestation' do
      expect(mapped[:data]["motivatedBy"]).to eq("oa:describing")
      expect(mapped[:data]["hasBody"]).to be_truthy
      expect(mapped[:data]["hasBody"]["@graph"]).to be_truthy
      expect(mapped[:data]["hasBody"]["@graph"][0]["@id"]).to eq("https://hypothes.is/a/qOT8PSbRSfi12cc23SyPsQ")
      expect(mapped[:data]["hasBody"]["@graph"][0]["http://lawd.info/ontology/hasAttestation"]).to eq("test#attest-1")
      expect(mapped[:data]["hasBody"]["@graph"][1]["@id"]).to eq("test#attest-1")
      expect(mapped[:data]["hasBody"]["@graph"][1]["@type"]).to eq("http://lawd.info/ontology/Attestation")
      expect(mapped[:data]["hasBody"]["@graph"][1]["http://lawd.info/ontology/hasCitation"]).to eq("test#cite-1")
      expect(mapped[:data]["hasBody"]["@graph"][1]["http://purl.org/spar/cito/citesAsEvidence"]).to eq("http://sosol.perseids.org/sosol/publications/12078/epi_cts_identifiers/15840/preview")
      expect(mapped[:data]["hasBody"]["@graph"][2]["@id"]).to eq("test#cite-1")
      expect(mapped[:data]["hasBody"]["@graph"][2]["@type"]).to eq(["http://lawd.info/ontology/Citation", "cnt:ContentAsText"])
      expect(mapped[:data]["hasBody"]["@graph"][2]["cnt:chars"]).to eq("\u03a4\u03b7\u03bb\u03ad\u03bc\u03b1\u03c7\u03bf\u03c2 \u03a0\u03b9\u03b8\u03ae\u03ba\u03bf\u03c5")
    end
  end
end
