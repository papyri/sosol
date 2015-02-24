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
      expect(mapped[:data]["dcterms:source"]).to eq('test')
    end

    it 'mapped the body text' do
      expect(mapped[:data]["hasBody"][0]["@id"]).to eq("http://data.perseus.org/citations/urn:cts:greekLit:tlg0012.tlg001:6.222")
      expect(mapped[:data]["hasBody"][0]["@type"]).to eq(HypothesisClient::MapperPrototype::JOTH::LAWD_CITATION)
      expect(mapped[:data]["hasBody"][0]["foaf:homepage"]["@id"]).to eq("http://data.perseus.org/citations/urn:cts:greekLit:tlg0012.tlg001:6.222")
      expect(mapped[:data]["hasBody"][0]['rdfs:isDefinedBy']["@id"]).to eq("http://data.perseus.org/catalog/urn:cts:greekLit:tlg0012.tlg001")
    end

    it 'mapped the sourceText' do 
      expect(mapped[:data]["hasTarget"]["hasSource"]["@id"]).to eq("#{HypothesisClient::MapperPrototype::JOTH::SMITH_TEXT_CTS}:diomedes_1")
    end
    
    it 'mapped the motivation' do
      expect(mapped[:data]["motivatedBy"]).to eq("oa:identifying")
    end

    it 'made a title' do
      expect(mapped[:data]["dcterms:title"]).to eq("http://data.perseus.org/citations/urn:cts:greekLit:tlg0012.tlg001:6.222 identifies II. 6.222 as citation in #{HypothesisClient::MapperPrototype::JOTH::SMITH_TEXT_CTS}:diomedes_1")
    end

  end
  context "cites test" do 
    input = File.read(File.join(File.dirname(__FILE__), 'support', 'testcite.json')) 
    let(:mapped) { client.map("test",JSON.parse(input))}
    it 'mapped the body text' do
      puts mapped[:data]["hasBody"]
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
      expect(mapped[:data]["hasBody"]["@graph"][1]["@id"]).to eq("test#bond-1")
      expect(mapped[:data]["hasBody"]["@graph"][3]["@id"]).to eq("test#bond-2")
      expect(mapped[:data]["hasBody"]["@graph"][3]["snap:bond-with"]["@id"]).to eq("http://data.perseus.org/people/smith:castor-1#this")
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
      expect(mapped[:data]["hasBody"]["@graph"][1]["@id"]).to eq("test#bond-1")
      expect(mapped[:data]["hasBody"]["@graph"][3]["@id"]).to eq("test#bond-2")
      expect(mapped[:data]["hasBody"]["@graph"][5]["@id"]).to eq("test#bond-3")
      expect(mapped[:data]["hasBody"]["@graph"][5]["snap:bond-with"]["@id"]).to eq("http://data.perseus.org/people/smith:castor-1#this")
    end
  end
  context "cts urn test" do
    $mapper = HypothesisClient::MapperPrototype::JOTH.new

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
end
