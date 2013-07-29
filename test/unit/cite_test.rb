require 'test_helper'

class CiteTest < ActiveSupport::TestCase
  
 context "lib test" do
  
  should "test valid urn" do
    urnObj = Cite::CiteLib.urn_obj('urn:cite:perseus:mythcoll.1.1') 
    assert urnObj.getNs() == 'perseus'
    assert urnObj.getVersion() == '1'
    assert urnObj.getObjectId() == '1'
    assert urnObj.getCollection() == 'mythcoll'
  end 
   
  should "assert collection urn" do 
    # TODO
  end  
   
  should "test collection title" do
    # TODO need test capabilities xml 
    assert_nothing_raised do Cite::CiteLib.get_collection_title('urn:cite:perseus:testcoll') end
    assert_nothing_raised do Cite::CiteLib.get_collection_title('urn:cite:perseus:testcoll.1.1') end 
  end
  
  should "test collection field max" do
    # TODO need test capabilities xml 
    max = Cite::CiteLib.get_collection_field_max('urn:cite:perseus:testcoll.1.1')
    assert max == 500
    max2 = Cite::CiteLib.get_collection_field_max('urn:cite:perseus:testcollun.1.1')
    assert max2 == -1
  end

 end
   
end