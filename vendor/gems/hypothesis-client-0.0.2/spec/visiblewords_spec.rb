require 'spec_helper'
require 'hypothesis-client/helpers'

describe HypothesisClient::Helpers::Uris::VisibleWords do

  context "successful match" do 
    let(:mapped) { HypothesisClient::Helpers::Uris::VisibleWords.new("visiblewords:JohnDoe_1") }

    it 'mapped' do
      expect(mapped.can_match).to be true 
    end

    it 'created the uri' do
      expect(mapped.uris).to match_array(["http://data.perseus.org/people/visiblewords:johndoe_1#this"])
    end
  end

  context "failed match" do 
    let(:mapped) { HypothesisClient::Helpers::Uris::VisibleWords.new("JohnDoe") }

    it 'mapped' do
      expect(mapped.can_match).to be_falsey
    end

  end
end
