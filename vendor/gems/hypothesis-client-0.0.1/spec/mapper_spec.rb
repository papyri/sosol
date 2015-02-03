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
    end

    it 'mapped the sourceText' do 
      expect(mapped[:data]["hasTarget"]["hasSource"]["@id"]).to eq("#{HypothesisClient::MapperPrototype::JOTH::SMITH_TEXT_CTS}:diomedes-1")
    end
    
    it 'mapped the motivation' do
      expect(mapped[:data]["motivatedBy"]).to eq("oa:identifying")
    end

    it 'made a title' do
      expect(mapped[:data]["dcterms:title"]).to eq("http://data.perseus.org/citations/urn:cts:greekLit:tlg0012.tlg001:6.222 identifies II. 6.222 as citation in #{HypothesisClient::MapperPrototype::JOTH::SMITH_TEXT_CTS}:diomedes-1")
    end

  end
  context "relation test" do 
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
end
