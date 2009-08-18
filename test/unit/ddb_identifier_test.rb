require 'test_helper'

class DDBIdentifierTest < ActiveSupport::TestCase  
  context "identifier mapping" do
    setup do
      @path_prefix = DDBIdentifier::PATH_PREFIX
    end
    
    should "map the first identifier" do
      bgu_1_1 = Factory.build(:DDBIdentifier, :name => "oai:papyri.info:identifiers:ddbdp:0001:1:1")
      assert_path_equal %w{bgu bgu.1 bgu.1.1.xml}, bgu_1_1.to_path
    end
    
    should "map ambiguous collections" do
      bgu_ppetr_2_1 = Factory.build(:DDBIdentifier, :name => "oai:papyri.info:identifiers:ddbdp:0187:2:1")
      assert_path_equal %w{p.petr p.petr.2 p.petr.2.1.xml}, bgu_ppetr_2_1.to_path
      
      bgu_ppetr2_1 = Factory.build(:DDBIdentifier, :name => "oai:papyri.info:identifiers:ddbdp:0186::1")
      assert_path_equal %w{p.petr.2 p.petr.2.1.xml}, bgu_ppetr2_1.to_path
    end
  end
end