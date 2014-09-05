require 'test_helper'

class OaCiteIdentifierTest < ActiveSupport::TestCase
  
  context "identifier test" do
    setup do
      @creator = FactoryGirl.create(:user, :name => "Creator2")
      @publication = FactoryGirl.create(:publication, :owner => @creator, :creator => @creator, :status => "new")

      # branch from master so we aren't just creating an empty branch
      @publication.branch_from_master
    
    end
    
    teardown do
      unless @publication.nil?
        @publication.destroy
      end
      unless @creator.nil?
        #@creator.destroy
      end
    end
   
    should "create objects 1.1 and 2.1" do 
      test1 = OaCiteIdentifier.new_from_template(@publication,"urn:cite:perseus:pdlann",["urn:cts:test"])
      assert test1.urn_attribute == "urn:cite:perseus:pdlann.1.1"
      test2 = OaCiteIdentifier.new_from_template(@publication,"urn:cite:perseus:pdlann",["urn:cts:test"])
      test3 = OaCiteIdentifier.new_from_template(@publication,"urn:cite:perseus:pdlann",["urn:cts:test:1.1-1.2"])
      assert test2.urn_attribute == "urn:cite:perseus:pdlann.2.1"
      next_version = OaCiteIdentifier.next_version_identifier(test2.urn_attribute)
      Rails.logger.info("Next Version = #{next_version}")
      assert next_version == "cite/perseus/pdlann.2.2"
      assert !test1.is_match?('perseus:citations/urn:cts:latinLit:phi0959.phi006:1.253-1.415')
      assert test1.is_match?('urn:cts:test')
      assert ! test3.is_match?('urn:cts:test:1.1-1.3')
   end  
   
   should "create object 1.1" do 
    test1 = OaCiteIdentifier.new_from_template(@publication,"urn:cite:perseus:pdlann",["urn:cts:test"])
    Rails.logger.info("TEST1 URN=#{test1.urn_attribute}")
    Rails.logger.info("TEST1 PATH=#{test1.to_path}")
    assert test1.urn_attribute == "urn:cite:perseus:pdlann.1.1"
    assert test1.to_path == "CITE_OA_XML/perseus/pdlann/1/pdlann.1.1.oac.xml"
   end

    should "fail with unknown collection" do
      assert_raises(RuntimeError) {
        OaCiteIdentifier.new_from_template(@publication,"urn:cite:perseus:invalidcoll",["urn:cts:test"])
      }
    end
    
    should "create new version from existing" do
      test = OaCiteIdentifier.new_from_inventory(@publication,"urn:cite:perseus:pdlann.1.1")
      assert test.urn_attribute == "urn:cite:perseus:pdlann.1.2"
      annotators = OacHelper::get_annotators(test.get_annotation())
      # TODO this should be 2 annotators
      assert annotators.length == 1
      assert annotators.grep(test.make_annotator_uri())
    end
  
  end
  
   # TODO new version from existing version - same annotator 
   # TODO new version from existing version - new annotator (adds annotator)
   # TODO rename updates uri

end
