require 'spec_helper'
require 'hypothesis-client/helpers'

describe HypothesisClient::Helpers::Uris::Smith do

  context "successful match" do 
    let(:mapped) { HypothesisClient::Helpers::Uris::Smith.new("alexander-bio-1") }

    it 'mapped' do
      expect(mapped.can_match).to be true 
    end

    it 'created the uri' do
      expect(mapped.uris).to match_array(["http://data.perseus.org/people/smith:alexander-1#this"])
    end
  end

  context "failed match" do 
    let(:mapped) { HypothesisClient::Helpers::Uris::Smith.new("alexander") }

    it 'mapped' do
      expect(mapped.can_match).to be_falsey
    end

  end
end
