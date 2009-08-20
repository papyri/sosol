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
    
    should "map files with '+' in the identifier" do
      chla_5_299FrA_B_C = Factory.build(:DDBIdentifier, :name => "oai:papyri.info:identifiers:ddbdp:0279:5:299FrA+B+C")
      assert_path_equal %w{chla chla.5 chla.5.299FrA+B+C.xml}, chla_5_299FrA_B_C.to_path
    end
    
    should "map files with ',' in the identifier" do
      bgu_13_2230_1 = Factory.build(:DDBIdentifier, :name => "oai:papyri.info:identifiers:ddbdp:0001:13:2230,1")
      assert_path_equal %w{bgu bgu.13 bgu.13.2230-1.xml}, bgu_13_2230_1.to_path
    end
    
    should "map files with '/' in the identifier" do
      o_bodl_2_1964_1967 = Factory.build(:DDBIdentifier, :name => "oai:papyri.info:identifiers:ddbdp:0014:2:1964/1967")
      assert_path_equal %w{o.bodl o.bodl.2 o.bodl.2.1964_1967.xml}, o_bodl_2_1964_1967.to_path
    end
    
  end
end