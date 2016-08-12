require 'test_helper'

class CiteTest < ActiveSupport::TestCase
  
 context "pid api test" do
    # TODO test pid with sequencer
    # TODO test UUID
    should "return a sequenced urn not parsing any props" do
      cb = lambda do |u| return 1 end
      assert_equal "urn:cite:perseus:pdlcomm.1.1", Cite::CiteLib.pid("CommentaryCiteIdentifier",{},cb)
    end

    should "return a sequenced urn parsing props" do
      cb = lambda do |u| return 1 end
      assert_equal "urn:cite:perseus:grctb.1.1", Cite::CiteLib.pid("TreebankCiteIdentifier",{"language" => "grc"},cb)
    end

    should "return a uuid urn" do
      cb = lambda do |u| return 1 end
      assert_match /^urn:cite:perseus:pdlann.\w+\.1$/, Cite::CiteLib.pid("OaCiteIdentifier",{},nil)
    end
 end

 context "cite api test" do
    # TODO test getCapabilities
    # TODO test getValidReff
    # TODO test getObject
 end

 context "cite lib test" do
  
  should "test valid urn" do
    urnObj = Cite::CiteLib.urn_obj('urn:cite:perseus:mythcoll.1.1') 
    assert urnObj.getNs() == 'perseus'
    assert urnObj.getVersion() == '1'
    assert urnObj.getObjectId() == '1'
    assert urnObj.getCollection() == 'mythcoll'
  end

    # TODO test is_collection_urn?
    # TODO test is_object_urn?
    # TODO test is_version_urn?
    # TODO test object_uuid_urn
    # TODO test add_version

 end
   
end
