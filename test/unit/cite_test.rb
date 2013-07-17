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
      assert Cite::CiteLib.
   end  
 end
   
end