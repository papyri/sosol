require 'spec_helper'
require 'hypothesis-client/helpers'

describe HypothesisClient::Helpers::Uris::Pleiades do

  context "successful match" do 
    let(:mapped) { HypothesisClient::Helpers::Uris::Pleiades.new("http://pleiades.stoa.org/places/579885") }

    it 'mapped' do
      expect(mapped.can_match).to be true 
    end

    it 'created the uri' do
      expect(mapped.uris).to match_array(["http://pleiades.stoa.org/places/579885#this"])
    end
  end

  context "successful match with this" do 
    let(:mapped) { HypothesisClient::Helpers::Uris::Pleiades.new("http://pleiades.stoa.org/places/579885#this") }

    it 'mapped' do
      expect(mapped.can_match).to be true 
    end

    it 'created the uri' do
      expect(mapped.uris).to match_array(["http://pleiades.stoa.org/places/579885#this"])
    end
  end

  context "successful match with multiple" do 
    let(:mapped) { HypothesisClient::Helpers::Uris::Pleiades.new("http://pleiades.stoa.org/places/579885#this http://pleiades.stoa.org/places/579886" ) }

    it 'mapped' do
      expect(mapped.can_match).to be true 
    end

    it 'created the uri' do
      expect(mapped.uris).to match_array(["http://pleiades.stoa.org/places/579885#this","http://pleiades.stoa.org/places/579886#this" ])
    end
  end

  context "failed match" do 
    let(:mapped) { HypothesisClient::Helpers::Uris::Pleiades.new("http://example.org/place") }

    it 'mapped' do
      expect(mapped.can_match).to be_falsey
    end

  end
end
