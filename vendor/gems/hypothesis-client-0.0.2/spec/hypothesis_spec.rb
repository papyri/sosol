require 'spec_helper'
require 'hypothesis-client/helpers'

describe HypothesisClient::Helpers::Uris::Hypothesis do

  context "successful match" do 
    let(:mapped) { HypothesisClient::Helpers::Uris::Hypothesis.new("https://hypothes.is/a/jtsBhicGR_mEoN1tu8I8hw") }

    it 'mapped' do
      expect(mapped.can_match).to be true 
    end

    it 'created the uri' do
      expect(mapped.uris).to match_array(["https://hypothes.is/a/jtsBhicGR_mEoN1tu8I8hw"])
    end
  end

  context "failed match" do 
    let(:mapped) { HypothesisClient::Helpers::Uris::Hypothesis.new("http://example.org") }

    it 'mapped' do
      expect(mapped.can_match).to be_falsey
    end

  end
end
