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
    assert_nothing_raised do Cite::CiteLib.get_collection_title('urn:cite:perseus:pdlann') end
    assert_nothing_raised do Cite::CiteLib.get_collection_title('urn:cite:perseus:pdlann.1.1') end 
  end
  
  should "test collection field max" do
    # TODO need test capabilities xml 
    max = Cite::CiteLib.get_collection_field_max('urn:cite:perseus:mythcomm.1.1')
    assert_equal(525,max)
    max2 = Cite::CiteLib.get_collection_field_max('urn:cite:perseus:pdlann.1.1')
    assert_equal(-1,max2)
  end
  
  should "test default collection" do
    coll = Cite::CiteLib.get_default_collection_urn()
    assert coll == 'urn:cite:perseus:pdlcomm'
  end

 end
   
end
