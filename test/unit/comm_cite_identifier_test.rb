require 'test_helper'

class CommentaryCiteIdentifierTest < ActiveSupport::TestCase
  
  context "identifier test" do
    setup do
      @creator = Factory(:user, :name => "Creator2")
      @publication = Factory(:publication, :owner => @creator, :creator => @creator, :status => "new")

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
      test1 = CommentaryCiteIdentifier.new_from_template(@publication,"urn:cite:perseus:testcoll","urn:cts:test")
      assert test1.urn_attribute == "urn:cite:perseus:testcoll.1.1"
      test2 = CommentaryCiteIdentifier.new_from_template(@publication,"urn:cite:perseus:testcoll","urn:cts:test")
      assert test2.urn_attribute == "urn:cite:perseus:testcoll.2.1"
      next_version = CommentaryCiteIdentifier.next_version_identifier(test2.urn_attribute)
      Rails.logger.info("Next Version = #{next_version}")
      assert next_version == "cite/perseus/testcoll.2.2"
      assert !test1.is_match?('perseus:citations/urn:cts:latinLit:phi0959.phi006:1.253-1.415')
      assert test1.is_match?('urn:cts:test')
   end  
   
   should "create object 1.1" do 
    test1 = CommentaryCiteIdentifier.new_from_template(@publication,"urn:cite:perseus:testcoll","urn:cts:test")
    Rails.logger.info("TEST1 URN=#{test1.urn_attribute}")
    Rails.logger.info("TEST1 PATH=#{test1.to_path}")
    assert test1.urn_attribute == "urn:cite:perseus:testcoll.1.1"
    assert test1.to_path == "CITE_COMMENTARY_XML/perseus/testcoll/1/testcoll.1.1.oac.xml"
   end

    should "fail with unknown collection" do
      assert_raises(RuntimeError) {
        CommentaryCiteIdentifier.new_from_template(@publication,"urn:cite:perseus:invalidcoll","urn:cts:test")
      }
    end
    
    should "create new version from existing" do
      test = CommentaryCiteIdentifier.new_from_inventory(@publication,"urn:cite:perseus:testcoll.1.1")
      assert test.urn_attribute == "urn:cite:perseus:testcoll.1.2"
      annotators = OacHelper::get_annotators(test.rdf)
      assert annotators.length == 2
      assert annotators.grep(test.make_annotator_uri())
    end
  
  end
  
   # TODO new version from existing version - same annotator 
   # TODO new version from existing version - new annotator (adds annotator)
   # TODO commentary length exceeded
   # TODO update commentary test

end