require 'spec_helper'
require 'hypothesis-client/helpers'

describe HypothesisClient::Helpers::Uris::Perseids do

  context "successful match" do 
    let(:mapped) { HypothesisClient::Helpers::Uris::Perseids.new("http://sosol.perseids.org/sosol/publications/12018/epi_cts_identifiers/15754/preview") }

    it 'mapped' do
      expect(mapped.can_match).to be true 
    end

    it 'created the uri' do
      expect(mapped.uris).to match_array([])
    end
  end

  context "failed match" do 
    let(:mapped) { HypothesisClient::Helpers::Uris::Perseids.new("http://sosol.perseids.org/sosol/publications/12018/epi_cts_identifiers/15754/editxml") }

    it 'mapped' do
      expect(mapped.can_match).to be_falsey
    end

  end
end
