require 'spec_helper'
require 'hypothesis-client/helpers'

describe HypothesisClient::Helpers::Uris::Perseus do

  context "successful match" do 
    let(:mapped) { HypothesisClient::Helpers::Uris::Perseus.new("http://data.perseus.org/citations/urn:cts:greekLit:tlg0012.tlg001.perseus-grc1:1\nAbas") }

    it 'mapped' do
      expect(mapped.can_match).to be true 
    end

    it 'created the uri' do
      expect(mapped.uris).to match_array(["http://data.perseus.org/citations/urn:cts:greekLit:tlg0012.tlg001.perseus-grc1:1"])
    end
  
    it 'created the urn' do 
      expect(mapped.cts).to match_array([ { 'uri' => "http://data.perseus.org/citations/urn:cts:greekLit:tlg0012.tlg001.perseus-grc1:1",
                                            'type' => 'http://lawd.info/ontology/Citation',
                                            'textgroup' => 'urn:cts:greekLit:tlg0012',
                                            'work' => 'urn:cts:greekLit:tlg0012.tlg001',
                                            'version' => 'urn:cts:greekLit:tlg0012.tlg001.perseus-grc1',
                                            'passage' => '1' } ])
    end
  
    it 'left the text' do 
      expect(mapped.text).to eq 'Abas'
    end
  end

  context "failed match" do 
    let(:mapped) { HypothesisClient::Helpers::Uris::Perseus.new("http://example.org/place") }

    it 'mapped' do
      expect(mapped.can_match).to be_falsey
    end

  end
end
