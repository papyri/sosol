require 'test_helper'

class HGVMetaIdentifierTest < ActiveSupport::TestCase
  context "identifier mapping" do
    should "map the first identifier" do
      hgv1 = Factory.build(:HGVMetaIdentifier, :alternate_name => 'hgv1')
      assert_equal "HGV_meta_EpiDoc/HGV1/1.xml", hgv1.to_path
    end
  end
end